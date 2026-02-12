#include "matmul.cuh"
#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>

#define CUDA_CHECK(call) do {                                  \
    cudaError_t err = (call);                                  \
    if (err != cudaSuccess) {                                  \
        fprintf(stderr, "CUDA error %s:%d: %s\n",               \
                __FILE__, __LINE__, cudaGetErrorString(err));  \
        exit(1);                                               \
    }                                                          \
} while(0)

static float run_one_n(int n, unsigned int threads_per_block)
{
    size_t bytes = (size_t)n * (size_t)n * sizeof(float);

    // Host
    float *A = (float*)malloc(bytes);
    float *B = (float*)malloc(bytes);
    float *C = (float*)malloc(bytes);
    if (!A || !B || !C) {
        std::cerr << "Host malloc failed for n=" << n << "\n";
        exit(1);
    }

    for (int i = 0; i < n * n; ++i) {
        A[i] = (float)(rand() % 2001 - 1000) / 100.0f;
        B[i] = (float)(rand() % 2001 - 1000) / 100.0f;
    }

    // Device
    float *dA=nullptr, *dB=nullptr, *dC=nullptr;
    CUDA_CHECK(cudaMalloc((void**)&dA, bytes));
    CUDA_CHECK(cudaMalloc((void**)&dB, bytes));
    CUDA_CHECK(cudaMalloc((void**)&dC, bytes));

    CUDA_CHECK(cudaMemcpy(dA, A, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, B, bytes, cudaMemcpyHostToDevice));

    // Events
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    // Warm-up
    matmul(dA, dB, dC, n, threads_per_block);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    // Timed run
    CUDA_CHECK(cudaEventRecord(start));
    matmul(dA, dB, dC, n, threads_per_block);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

    // Cleanup
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(dA));
    CUDA_CHECK(cudaFree(dB));
    CUDA_CHECK(cudaFree(dC));
    free(A);
    free(B);
    free(C);

    return ms;
}

int main(int argc, char* argv[])
{
    // Optional: prefix for output files
    // Usage:
    //   ./task1          -> task1_1024.csv and task1_256.csv
    //   ./task1 myrun    -> myrun_1024.csv and myrun_256.csv
    std::string prefix = "task1";
    if (argc > 1) prefix = argv[1];

    const unsigned int tpb_list[2] = {1024, 256};

    for (unsigned int tpb : tpb_list) {
        std::string out_csv = prefix + "_" + std::to_string(tpb) + ".csv";
        std::ofstream csv(out_csv);
        if (!csv.is_open()) {
            std::cerr << "Failed to open " << out_csv << " for writing.\n";
            return 1;
        }

        csv << "n,time_ms\n";

        for (int p = 5; p <= 14; ++p) {
            int n = 1 << p;

            float ms = run_one_n(n, tpb);

            csv << n << "," << ms << "\n";
            std::cout << "[tpb=" << tpb << "] n=" << n << " time_ms=" << ms << "\n";
        }

        csv.close();
        std::cout << "Wrote: " << out_csv << "\n";
    }

    return 0;
}
