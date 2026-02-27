// task2.cu
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <random>

#include "reduce.cuh"   // must declare: __host__ void reduce(float** input, float** output, unsigned int N, unsigned int threads_per_block);

static void checkCuda(cudaError_t e, const char* msg) {
    if (e != cudaSuccess) {
        std::fprintf(stderr, "CUDA error (%s): %s\n", msg, cudaGetErrorString(e));
        std::exit(EXIT_FAILURE);
    }
}

int main(int argc, char** argv) {

    unsigned int N = 10;             
    unsigned int threads_per_block = 256; 

    if (argc > 1) {
        N = (unsigned int) strtoul(argv[1], nullptr, 10);
    }
    if (argc > 2) {
        threads_per_block = (unsigned int) strtoul(argv[2], nullptr, 10);
    }

    // Host array: random floats in [-1, 1]
    float* h = (float*)std::malloc((size_t)N * sizeof(float));


    
    //fill the host array with random floats in [-1, 1]
    for(int i = 0; i < N; i++) {
        h[i] = static_cast<float>(rand()) / RAND_MAX * 2.0f - 1.0f;
    }
    //print out the element of array for debugging
    for (unsigned int i = 0; i < N; i++) {
        std::printf("%f ", h[i]);
    }
    std::printf("\n");
    // Device input
    float* d_input = nullptr;
    checkCuda(cudaMalloc((void**)&d_input, (size_t)N * sizeof(float)), "cudaMalloc d_input");
    checkCuda(cudaMemcpy(d_input, h, (size_t)N * sizeof(float), cudaMemcpyHostToDevice), "H2D copy input");

    // Device output length = blocks needed for FIRST kernel launch
    unsigned int num_blocks = (N + (threads_per_block * 2 - 1)) / (threads_per_block * 2);
    float* d_output = nullptr;
    checkCuda(cudaMalloc((void**)&d_output, (size_t)num_blocks * sizeof(float)), "cudaMalloc d_output");

    // Time ONLY the reduce(...) call
    cudaEvent_t start, stop;
    checkCuda(cudaEventCreate(&start), "event create start");
    checkCuda(cudaEventCreate(&stop), "event create stop");

    checkCuda(cudaEventRecord(start), "event record start");
    reduce(&d_input, &d_output, N, threads_per_block);
    checkCuda(cudaEventRecord(stop), "event record stop");
    checkCuda(cudaEventSynchronize(stop), "event sync stop");

    float ms = 0.0f;
    checkCuda(cudaEventElapsedTime(&ms, start, stop), "elapsed time");

    // Result should be in d_input[0] 
    float sum = 0.0f;
    checkCuda(cudaMemcpy(&sum, d_input, sizeof(float), cudaMemcpyDeviceToHost), "D2H copy sum");

    
    std::printf("%.0f\n", sum);     
    std::printf("%.3f\n", ms);

    
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_input);
    cudaFree(d_output);
    free(h);

    return 0;
}