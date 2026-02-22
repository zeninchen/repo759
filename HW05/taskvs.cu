#include "matmul.cuh"
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>

#define CUDA_CHECK(call) do {                               \
    cudaError_t err = (call);                               \
    if (err != cudaSuccess) {                               \
        fprintf(stderr, "CUDA error %s:%d: %s\n",           \
                __FILE__, __LINE__, cudaGetErrorString(err));\
        exit(1);                                            \
    }                                                       \
} while(0)

// Initialize A and B deterministically on GPU so both methods use identical data
__global__ void init_AB(float* A, float* B, unsigned int n) {
    unsigned long long idx = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long long N = (unsigned long long)n * (unsigned long long)n;
    if (idx < N) {
        // simple deterministic pattern 0..9
        float v = (float)(idx % 10);
        A[idx] = v;
        B[idx] = (float)((idx * 3ULL) % 10);
    }
}

__global__ void zero_C(float* C, unsigned int n) {
    unsigned long long idx = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long long N = (unsigned long long)n * (unsigned long long)n;
    if (idx < N) C[idx] = 0.0f;
}

// Naive matmul: each thread computes one C element, global-memory reads
// 1D launch with 256 threads/block
__global__ void matmul_naive(const float* A, const float* B, float* C, unsigned int n) {
    unsigned long long idx = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long long N = (unsigned long long)n * (unsigned long long)n;
    if (idx >= N) return;

    unsigned int row = (unsigned int)(idx / n);
    unsigned int col = (unsigned int)(idx % n);

    float sum = 0.0f;
    // dot product over k
    for (unsigned int k = 0; k < n; ++k) {
        sum += A[(unsigned long long)row * n + k] * B[(unsigned long long)k * n + col];
    }
    C[idx] = sum;
}

static void print_first_last_and_time(const char* tag, float ms, const float* dC, unsigned int n) {
    float first = 0.0f, last = 0.0f;
    unsigned long long last_idx = (unsigned long long)n * (unsigned long long)n - 1ULL;

    CUDA_CHECK(cudaMemcpy(&first, dC, sizeof(float), cudaMemcpyDeviceToHost));
    CUDA_CHECK(cudaMemcpy(&last,  dC + last_idx, sizeof(float), cudaMemcpyDeviceToHost));

    printf("%s\n", tag);
    printf("C[0]      = %.6f\n", first);
    printf("C[last]   = %.6f\n", last);
    printf("time (ms) = %.6f\n\n", ms);
}

int main(int argc, char** argv) {
    // Usage: ./taskvs [n]
    unsigned int n = (1u << 14); // default 16384
    if (argc > 1) n = (unsigned int)atoi(argv[1]);

    // Naive uses 256 threads per block (1D)
    const int naive_threads = 256;

    // Tiled uses block_dim = 16 (2D inside matmul_2)
    const unsigned int tiled_block_dim = 16;

    unsigned long long N = (unsigned long long)n * (unsigned long long)n;
    size_t bytes = (size_t)N * sizeof(float);

    printf("n = %u (n^2 = %llu elements, ~%.2f GB per matrix)\n",
           n, N, (double)bytes / (1024.0 * 1024.0 * 1024.0));

    // Allocate device memory
    float *dA = nullptr, *dB = nullptr, *dC = nullptr;
    CUDA_CHECK(cudaMalloc((void**)&dA, bytes));
    CUDA_CHECK(cudaMalloc((void**)&dB, bytes));
    CUDA_CHECK(cudaMalloc((void**)&dC, bytes));

    // Init A,B once (shared by both methods); zero C
    {
        int blocks = (int)((N + naive_threads - 1ULL) / naive_threads);
        init_AB<<<blocks, naive_threads>>>(dA, dB, n);
        zero_C<<<blocks, naive_threads>>>(dC, n);
        CUDA_CHECK(cudaDeviceSynchronize());
    }

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    // --------------------
    // 1) Naive timing
    // --------------------
    {
        int blocks = (int)((N + naive_threads - 1ULL) / naive_threads);
        zero_C<<<blocks, naive_threads>>>(dC, n);
        CUDA_CHECK(cudaDeviceSynchronize());

        CUDA_CHECK(cudaEventRecord(start));
        matmul_naive<<<blocks, naive_threads>>>(dA, dB, dC, n);
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));

        float ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

        print_first_last_and_time("NAIVE (256 threads/block, global memory)", ms, dC, n);
    }

    // --------------------
    // 2) Tiled timing (your shared-memory tiled implementation)
    // --------------------
    {
        int blocks = (int)((N + naive_threads - 1ULL) / naive_threads);
        zero_C<<<blocks, naive_threads>>>(dC, n);
        CUDA_CHECK(cudaDeviceSynchronize());

        CUDA_CHECK(cudaEventRecord(start));
        matmul_2(dA, dB, dC, n, tiled_block_dim); // YOUR tiled version
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));

        float ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));

        print_first_last_and_time("TILED (shared memory, block_dim=16)", ms, dC, n);
    }

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(dA));
    CUDA_CHECK(cudaFree(dB));
    CUDA_CHECK(cudaFree(dC));

    return 0;
}