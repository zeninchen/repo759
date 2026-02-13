#include "stencil.cuh"
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

static float run_one_n(int n, int R, unsigned int threads_per_block)
{
    size_t img_bytes  = (size_t)n * sizeof(float);
    size_t mask_bytes = (size_t)(2 * R + 1) * sizeof(float);

    // Host alloc
    float* h_image  = (float*)malloc(img_bytes);
    float* h_mask   = (float*)malloc(mask_bytes);
    float* h_output = (float*)malloc(img_bytes);
    if (!h_image || !h_mask || !h_output) {
        std::cerr << "Host malloc failed for n=" << n << "\n";
        exit(1);
    }

    // Fill random [-1, 1]
    for (int i = 0; i < n; i++)
        h_image[i] = (float)rand() / RAND_MAX * 2.0f - 1.0f;
    for (int i = 0; i < 2 * R + 1; i++)
        h_mask[i] = (float)rand() / RAND_MAX * 2.0f - 1.0f;

    // Device alloc
    float *d_image=nullptr, *d_mask=nullptr, *d_output=nullptr;
    CUDA_CHECK(cudaMalloc(&d_image, img_bytes));
    CUDA_CHECK(cudaMalloc(&d_mask, mask_bytes));
    CUDA_CHECK(cudaMalloc(&d_output, img_bytes));

    CUDA_CHECK(cudaMemcpy(d_image, h_image, img_bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_mask,  h_mask,  mask_bytes, cudaMemcpyHostToDevice));

    // Timing events
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    // Warm-up
    stencil(d_image, d_mask, d_output, n, R, threads_per_block);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    // Timed run
    CUDA_CHECK(cudaEventRecord(start));
    stencil(d_image, d_mask, d_output, n, R, threads_per_block);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

    // Optional correctness spot check (uncomment if you want)
    // CUDA_CHECK(cudaMemcpy(h_output, d_output, img_bytes, cudaMemcpyDeviceToHost));
    // std::cout << "last=" << h_output[n-1] << "\n";

    // Cleanup
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_image));
    CUDA_CHECK(cudaFree(d_mask));
    CUDA_CHECK(cudaFree(d_output));
    free(h_image);
    free(h_mask);
    free(h_output);

    return ms;
}

int main(int argc, char* argv[])
{
    // Usage:
    //   ./task2                -> task2_1024.csv and task2_256.csv with R=2
    //   ./task2 myprefix       -> myprefix_1024.csv and myprefix_256.csv with R=2
    //   ./task2 myprefix 3     -> myprefix_1024.csv and myprefix_256.csv with R=3
    std::string prefix = "task2";
    int R = 2;

    if (argc > 1) prefix = argv[1];
    if (argc > 2) R = atoi(argv[2]);

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

            float ms = run_one_n(n, R, tpb);
            csv << n << "," << ms << "\n";

            std::cout << "[tpb=" << tpb << "] R=" << R
                      << " n=" << n << " time_ms=" << ms << "\n";
        }

        csv.close();
        std::cout << "Wrote: " << out_csv << "\n";
    }

    return 0;
}
