#include "matmul.cuh"
#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <string>

// Simple CUDA error check macro (helps catch silent failures)
#define CUDA_CHECK(call) do {                                  \
    cudaError_t err = (call);                                  \
    if (err != cudaSuccess) {                                  \
        fprintf(stderr, "CUDA error %s:%d: %s\n",               \
                __FILE__, __LINE__, cudaGetErrorString(err));  \
        exit(1);                                               \
    }                                                          \
} while(0)

int main(int argc, char* argv[])
{
    // Fixed per assignment
    const unsigned int threads_per_block = 1024;

    // Output CSV name (optional arg)
    // Usage:
    //   ./task1            -> writes task1.csv
    //   ./task1 out.csv    -> writes out.csv
    std::string out_csv = "task1.csv";
    if (argc > 1) out_csv = argv[1];

    std::ofstream csv(out_csv);
    if (!csv.is_open()) {
        std::cerr << "Failed to open " << out_csv << " for writing.\n";
        return 1;
    }

    // CSV header
    csv << "n,time_ms\n";

    // Create timing events once
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    // Loop n = 2^5 ... 2^14
    for (int p = 5; p <= 14; ++p) {
        int n = 1 << p;

        size_t bytes = (size_t)n * (size_t)n * sizeof(float);

        // Host allocations
        float *A = (float*)malloc(bytes);
        float *B = (float*)malloc(bytes);
        float *C = (float*)malloc(bytes);
        if (!A || !B || !C) {
            std::cerr << "Host malloc failed for n=" << n << "\n";
            return 1;
        }

        // Fill host matrices
        for (int i = 0; i < n * n; ++i) {
            A[i] = (float)(rand() % 2001 - 1000) / 100.0f; // [-10, 10]
            B[i] = (float)(rand() % 2001 - 1000) / 100.0f; // [-10, 10]
        }

        // Device allocations
        float *dA = nullptr, *dB = nullptr, *dC = nullptr;
        CUDA_CHECK(cudaMalloc((void**)&dA, bytes));
        CUDA_CHECK(cudaMalloc((void**)&dB, bytes));
        CUDA_CHECK(cudaMalloc((void**)&dC, bytes));

        // Copy inputs
        CUDA_CHECK(cudaMemcpy(dA, A, bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(dB, B, bytes, cudaMemcpyHostToDevice));

        // (Optional but recommended) warm-up once to reduce first-launch overhead
        matmul(dA, dB, dC, n, threads_per_block);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaDeviceSynchronize());

        // Time the kernel
        CUDA_CHECK(cudaEventRecord(start));
        matmul(dA, dB, dC, n, threads_per_block);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));

        float ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

        // Write to CSV
        csv << n << "," << ms << "\n";
        std::cout << "n=" << n << "  time_ms=" << ms << "\n";

        // Cleanup
        CUDA_CHECK(cudaMemcpy(C, dC, bytes, cudaMemcpyDeviceToHost)); // keep if you want correctness spot checks
        CUDA_CHECK(cudaFree(dA));
        CUDA_CHECK(cudaFree(dB));
        CUDA_CHECK(cudaFree(dC));
        free(A);
        free(B);
        free(C);
    }

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));

    csv.close();
    std::cout << "Wrote: " << out_csv << "\n";
    return 0;
}
