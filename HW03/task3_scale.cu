// task3_scale.cu
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <string>

#include "vscale.cuh" // must declare: __global__ void vscale(const float* a, float* b, unsigned int n);

static void cudaCheck(cudaError_t err, const char* msg) {
    if (err != cudaSuccess) {
        std::fprintf(stderr, "CUDA error (%s): %s\n", msg, cudaGetErrorString(err));
        std::exit(1);
    }
}

static void fill_random(float* ha, float* hb, size_t n) {
    // a in [-10, 10], b in [0, 1]
    for (size_t i = 0; i < n; ++i) {
        ha[i] = (float)(std::rand() % 2001 - 1000) / 100.0f;
        hb[i] = (float)(std::rand() % 101) / 100.0f;
    }
}

int main(int argc, char** argv) {
    // Usage:
    //   ./task3_scale                 -> threads=512, output=task3_scale.csv
    //   ./task3_scale 16              -> threads=16,  output=task3_scale.csv
    //   ./task3_scale 16 out16.csv    -> threads=16,  output=out16.csv
    int threads = 512;
    std::string out_csv = "task3_scale.csv";

    if (argc >= 2) threads = std::atoi(argv[1]);
    if (argc >= 3) out_csv = argv[2];

    if (threads <= 0 || threads > 1024) {
        std::fprintf(stderr, "Invalid threads_per_block=%d (must be 1..1024)\n", threads);
        return 1;
    }

    // Optional: print GPU name (helps when grading)
    cudaDeviceProp prop{};
    cudaCheck(cudaGetDeviceProperties(&prop, 0), "cudaGetDeviceProperties");
    std::fprintf(stderr, "GPU: %s\n", prop.name);

    std::FILE* f = std::fopen(out_csv.c_str(), "w");
    if (!f) {
        std::perror("fopen");
        return 1;
    }
    std::fprintf(f, "n,threads_per_block,blocks,ms\n");

    // Create timing events once
    cudaEvent_t start{}, stop{};
    cudaCheck(cudaEventCreate(&start), "cudaEventCreate(start)");
    cudaCheck(cudaEventCreate(&stop),  "cudaEventCreate(stop)");

    // To reduce timing noise, do a warmup kernel launch (small n)
    {
        const unsigned int warm_n = 1u << 10;
        float *da=nullptr, *db=nullptr;
        cudaCheck(cudaMalloc((void**)&da, warm_n * sizeof(float)), "cudaMalloc warm da");
        cudaCheck(cudaMalloc((void**)&db, warm_n * sizeof(float)), "cudaMalloc warm db");
        int blocks = (warm_n + threads - 1) / threads;
        vscale<<<blocks, threads>>>(da, db, warm_n);
        cudaCheck(cudaGetLastError(), "warmup launch");
        cudaCheck(cudaDeviceSynchronize(), "warmup sync");
        cudaFree(da);
        cudaFree(db);
    }

    // Sweep n = 2^10 .. 2^29
    for (int p = 10; p <= 29; ++p) {
        const unsigned int n = 1u << p;
        const size_t bytes = (size_t)n * sizeof(float);

        // Host buffers
        float* ha = (float*)std::malloc(bytes);
        float* hb = (float*)std::malloc(bytes);
        if (!ha || !hb) {
            std::fprintf(stderr, "Host malloc failed at n=%u (bytes=%zu)\n", n, bytes);
            return 1;
        }
        fill_random(ha, hb, n);

        // Device buffers
        float *da=nullptr, *db=nullptr;
        cudaError_t e1 = cudaMalloc((void**)&da, bytes);
        cudaError_t e2 = cudaMalloc((void**)&db, bytes);
        if (e1 != cudaSuccess || e2 != cudaSuccess) {
            std::fprintf(stderr, "Device malloc failed at n=%u (bytes=%zu). Try smaller max n.\n", n, bytes);
            std::fprintf(stderr, "cudaMalloc da: %s\n", cudaGetErrorString(e1));
            std::fprintf(stderr, "cudaMalloc db: %s\n", cudaGetErrorString(e2));
            if (da) cudaFree(da);
            if (db) cudaFree(db);
            std::free(ha);
            std::free(hb);
            break;
        }

        cudaCheck(cudaMemcpy(da, ha, bytes, cudaMemcpyHostToDevice), "H2D da");
        cudaCheck(cudaMemcpy(db, hb, bytes, cudaMemcpyHostToDevice), "H2D db");

        int blocks = (n + threads - 1) / threads;

        // Measure kernel time (ms)
        cudaCheck(cudaEventRecord(start), "event record start");
        vscale<<<blocks, threads>>>(da, db, n);
        cudaCheck(cudaGetLastError(), "kernel launch");
        cudaCheck(cudaEventRecord(stop), "event record stop");
        cudaCheck(cudaEventSynchronize(stop), "event sync stop");

        float ms = 0.0f;
        cudaCheck(cudaEventElapsedTime(&ms, start, stop), "elapsed time");

        // Optional correctness sanity: pull 2 values (cheap-ish)
        cudaCheck(cudaMemcpy(hb, db, bytes, cudaMemcpyDeviceToHost), "D2H db");
        // (You can remove prints if your autograder expects only CSV output)
        std::fprintf(stderr, "n=%u blocks=%d threads=%d time=%f ms hb0=%f hblast=%f\n",
                     n, blocks, threads, ms, hb[0], hb[n-1]);

        std::fprintf(f, "%u,%d,%d,%.6f\n", n, threads, blocks, ms);

        cudaFree(da);
        cudaFree(db);
        std::free(ha);
        std::free(hb);
    }

    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    std::fclose(f);

    return 0;
}
