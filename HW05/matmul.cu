#include "matmul.cuh"
#include <stdio.h>
#include <stdlib.h>
#define BLOCK_SIZE 16
__host__ void matmul_1(const int *A, const int *B, int *C, unsigned int n,
                       unsigned int block_dim)
{
    matmul_tiled<int>(A, B, C, n, block_dim);
}
__host__ void matmul_2(const float *A, const float *B, float *C, unsigned int n,
                       unsigned int block_dim)
{
    matmul_tiled<float>(A, B, C, n, block_dim);
}
__host__ void matmul_3(const double *A, const double *B, double *C,
                       unsigned int n, unsigned int block_dim)
{
    matmul_tiled<double>(A, B, C, n, block_dim);
}

template <typename T>
__global__ void matmul_kernel(const T* A, const T* B, T* C, unsigned int n)
{
    __shared__ T As[BLOCK_SIZE][BLOCK_SIZE];
    __shared__ T Bs[BLOCK_SIZE][BLOCK_SIZE];

    unsigned int row = blockIdx.y * BLOCK_SIZE + threadIdx.y;
    unsigned int col = blockIdx.x * BLOCK_SIZE + threadIdx.x;

    T sum = (T)0;

    // Loop over tiles in the K dimension
    for (unsigned int tile = 0; tile < (n + BLOCK_SIZE - 1) / BLOCK_SIZE; ++tile) {
        unsigned int kA = tile * BLOCK_SIZE + threadIdx.x; // col in A
        unsigned int kB = tile * BLOCK_SIZE + threadIdx.y; // row in B

        // Load A tile element or 0 if out of bounds
        As[threadIdx.y][threadIdx.x] =
            (row < n && kA < n) ? A[row * n + kA] : (T)0;

        // Load B tile element or 0 if out of bounds
        Bs[threadIdx.y][threadIdx.x] =
            (kB < n && col < n) ? B[kB * n + col] : (T)0;

        __syncthreads();

        #pragma unroll
        for (unsigned int k = 0; k < BLOCK_SIZE; ++k) {
            sum += As[threadIdx.y][k] * Bs[k][threadIdx.x];
        }

        __syncthreads();
    }

    if (row < n && col < n) {
        C[row * n + col] = sum;
    }
}

template <typename T>
__host__ void matmul_tiled(const T* A, const T* B, T* C, unsigned int n, unsigned int block_dim)
{
    // For this implementation we assume block_dim == BLOCK_SIZE
    dim3 threads(BLOCK_SIZE, BLOCK_SIZE);
    dim3 blocks((n + BLOCK_SIZE - 1) / BLOCK_SIZE,
                (n + BLOCK_SIZE - 1) / BLOCK_SIZE);

    matmul_kernel<T><<<blocks, threads>>>(A, B, C, n);
    cudaDeviceSynchronize();
}