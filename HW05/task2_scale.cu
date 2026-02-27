// task2_scale.cu
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>

#include "reduce.cuh"   // must provide: __host__ void reduce(float** input, float** output, unsigned int N, unsigned int threads_per_block);

static void dieCuda(cudaError_t e, const char* msg) {
    if (e != cudaSuccess) {
        std::fprintf(stderr, "CUDA error (%s): %s\n", msg, cudaGetErrorString(e));
        std::exit(EXIT_FAILURE);
    }
}

// Fast-ish deterministic pseudo-random fill in [-1, 1] on host.
// (Still "random numbers in [-1,1]" per assignment; much faster than <random> for huge N.)
static void fill_random_minus1_to_1(float* h, size_t N) {
    uint32_t x = 123456789u;
    for (size_t i = 0; i < N; i++) {
        // LCG
        x = 1664525u * x + 1013904223u;
        // Convert to [0,1) using top 24 bits, then map to [-1,1]
        uint32_t mant = (x >> 8) & 0x00FFFFFFu; // 24 bits
        float u = (float)mant / (float)(1u << 24); // [0,1)
        h[i] = 2.0f * u - 1.0f;
    }
}

int main() {
    const unsigned int threads_per_block = 1024;
    const int p_min = 10;
    const int p_max = 30;

    FILE* fp = std::fopen("task2_scale.csv", "w");
    if (!fp) {
        std::fprintf(stderr, "Failed to open task2_scale.csv for writing.\n");
        return EXIT_FAILURE;
    }
    std::fprintf(fp, "N,time_ms\n");

    cudaEvent_t start, stop;
    dieCuda(cudaEventCreate(&start), "event create start");
    dieCuda(cudaEventCreate(&stop), "event create stop");

    for (int p = p_min; p <= p_max; p++) {
        size_t N = (size_t)1 << p;

        // Host allocate + fill
        float* h = (float*)std::malloc(N * sizeof(float));
        if (!h) {
            std::fprintf(stderr, "Host malloc failed at N=%zu\n", N);
            break;
        }
        fill_random_minus1_to_1(h, N);

        // Device alloc input
        float* d_input = nullptr;
        cudaError_t e = cudaMalloc((void**)&d_input, N * sizeof(float));
        if (e != cudaSuccess) {
            std::fprintf(stderr, "cudaMalloc d_input failed at N=%zu: %s\n", N, cudaGetErrorString(e));
            std::free(h);
            break; // stop scaling if GPU memory not enough
        }

        // Copy to device
        dieCuda(cudaMemcpy(d_input, h, N * sizeof(float), cudaMemcpyHostToDevice), "H2D copy input");

        // Device alloc output sized for FIRST reduction call
        unsigned int num_blocks = (unsigned int)((N + (threads_per_block * 2ull - 1ull)) / (threads_per_block * 2ull));
        float* d_output = nullptr;
        e = cudaMalloc((void**)&d_output, (size_t)num_blocks * sizeof(float));
        if (e != cudaSuccess) {
            std::fprintf(stderr, "cudaMalloc d_output failed at N=%zu: %s\n", N, cudaGetErrorString(e));
            cudaFree(d_input);
            std::free(h);
            break;
        }

        // Optional warm-up (reduces first-run overhead noise)
        reduce(&d_input, &d_output, (unsigned int)N, threads_per_block);
        dieCuda(cudaDeviceSynchronize(), "warmup sync");

        // Time ONLY reduce()
        dieCuda(cudaEventRecord(start), "record start");
        reduce(&d_input, &d_output, (unsigned int)N, threads_per_block);
        dieCuda(cudaEventRecord(stop), "record stop");
        dieCuda(cudaEventSynchronize(stop), "sync stop");

        float ms = 0.0f;
        dieCuda(cudaEventElapsedTime(&ms, start, stop), "elapsed");

        // Write CSV row
        std::fprintf(fp, "%zu,%.6f\n", N, ms);
        std::fflush(fp);

        // Cleanup per-iteration
        cudaFree(d_input);
        cudaFree(d_output);
        std::free(h);

        std::fprintf(stderr, "Done N=2^%d (%zu), time=%.6f ms\n", p, N, ms);
    }

    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    std::fclose(fp);

    return 0;
}