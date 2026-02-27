// task2_scale.cu
// Generates two CSV files:
//   - task2_1024.csv  (threads_per_block = 1024)
//   - task2_256.csv   (threads_per_block = 256)
// Each file contains: N,time_ms for N = 2^10 ... 2^30
//
// Compile (per assignment style):
//   nvcc task2_scale.cu reduce.cu -Xcompiler -O3 -Xcompiler -Wall -Xptxas -O3 -std=c++17 -o task2_scale
//
// Run:
//   ./task2_scale

#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>

#include "reduce.cuh" // __host__ void reduce(float** input, float** output, unsigned int N, unsigned int threads_per_block);

static void dieCuda(cudaError_t e, const char* msg) {
    if (e != cudaSuccess) {
        std::fprintf(stderr, "CUDA error (%s): %s\n", msg, cudaGetErrorString(e));
        std::exit(EXIT_FAILURE);
    }
}

// Deterministic "random" floats in [-1, 1] (fast for huge N)
static void fill_random_minus1_to_1(float* h, size_t N) {
    uint32_t x = 123456789u;
    for (size_t i = 0; i < N; i++) {
        x = 1664525u * x + 1013904223u;              // LCG
        uint32_t mant = (x >> 8) & 0x00FFFFFFu;      // top 24 bits
        float u = (float)mant / (float)(1u << 24);   // [0,1)
        h[i] = 2.0f * u - 1.0f;                      // [-1,1)
    }
}

static float time_reduce_once(size_t N, unsigned int threads_per_block) {
    // Host allocate + fill
    float* h = (float*)std::malloc(N * sizeof(float));
    if (!h) {
        std::fprintf(stderr, "Host malloc failed at N=%zu\n", N);
        return -1.0f;
    }
    fill_random_minus1_to_1(h, N);

    // Device input
    float* d_input = nullptr;
    cudaError_t e = cudaMalloc((void**)&d_input, N * sizeof(float));
    if (e != cudaSuccess) {
        std::fprintf(stderr, "cudaMalloc d_input failed at N=%zu: %s\n", N, cudaGetErrorString(e));
        std::free(h);
        return -1.0f;
    }
    dieCuda(cudaMemcpy(d_input, h, N * sizeof(float), cudaMemcpyHostToDevice), "H2D copy input");

    // Device output sized for FIRST kernel launch
    unsigned int num_blocks = (unsigned int)((N + (threads_per_block * 2ull - 1ull)) / (threads_per_block * 2ull));
    float* d_output = nullptr;
    e = cudaMalloc((void**)&d_output, (size_t)num_blocks * sizeof(float));
    if (e != cudaSuccess) {
        std::fprintf(stderr, "cudaMalloc d_output failed at N=%zu: %s\n", N, cudaGetErrorString(e));
        cudaFree(d_input);
        std::free(h);
        return -1.0f;
    }

    // Create timing events (per run to keep it simple/robust)
    cudaEvent_t start, stop;
    dieCuda(cudaEventCreate(&start), "event create start");
    dieCuda(cudaEventCreate(&stop), "event create stop");

    // Warm-up (reduces first-launch overhead noise)
    reduce(&d_input, &d_output, (unsigned int)N, threads_per_block);
    dieCuda(cudaDeviceSynchronize(), "warmup sync");

    // Time ONLY reduce()
    dieCuda(cudaEventRecord(start), "record start");
    reduce(&d_input, &d_output, (unsigned int)N, threads_per_block);
    dieCuda(cudaEventRecord(stop), "record stop");
    dieCuda(cudaEventSynchronize(stop), "sync stop");

    float ms = 0.0f;
    dieCuda(cudaEventElapsedTime(&ms, start, stop), "elapsed");

    // Cleanup
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_input);
    cudaFree(d_output);
    std::free(h);

    return ms;
}

static void run_sweep_and_write_csv(const char* filename, unsigned int threads_per_block) {
    const int p_min = 10;
    const int p_max = 30;

    FILE* fp = std::fopen(filename, "w");
    if (!fp) {
        std::fprintf(stderr, "Failed to open %s for writing.\n", filename);
        std::exit(EXIT_FAILURE);
    }
    std::fprintf(fp, "N,time_ms\n");

    for (int p = p_min; p <= p_max; p++) {
        size_t N = (size_t)1 << p;

        float ms = time_reduce_once(N, threads_per_block);
        if (ms < 0.0f) {
            std::fprintf(stderr, "Stopping sweep for tpb=%u at N=2^%d due to allocation failure.\n",
                         threads_per_block, p);
            break;
        }

        std::fprintf(fp, "%zu,%.6f\n", N, ms);
        std::fflush(fp);

        std::fprintf(stderr, "[tpb=%u] Done N=2^%d (%zu), time=%.6f ms\n",
                     threads_per_block, p, N, ms);
    }

    std::fclose(fp);
}

int main() {
    // Generate both CSVs in one run
    run_sweep_and_write_csv("task2_1024.csv", 1024);
    run_sweep_and_write_csv("task2_256.csv", 256);
    return 0;
}