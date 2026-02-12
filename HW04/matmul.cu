#include <stdio.h>
#include <stdlib.h>
#include "matmul.cuh" // Include the matmul kernel

__global__ void matmul_kernel(const float* A, const float* B, float* C, size_t n)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x; // Calculate the global thread index
    if (idx < n * n) { // Ensure we don't go out of bounds
        int row = idx / n; // Calculate the row index
        int col = idx % n; // Calculate the column index
        float sum = 0.0f; // Initialize the sum for the dot product
        for (int k = 0; k < n; ++k) { // Compute the dot product of the row of A and column of B
            sum += A[row * n + k] * B[k * n + col];
        }
        C[row * n + col] = sum; // Store the result in C
    }
}

void matmul(const float* A, const float* B, float* C, size_t n, unsigned int threads_per_block)
{
    int blocks = (n * n + threads_per_block - 1) / threads_per_block; // Calculate the number of blocks needed
    //Launch the matmul kernel with enough blocks and threads to cover n*n elements
    matmul_kernel<<<blocks, threads_per_block>>>(A, B, C, n);
    // Synchronize to ensure the kernel has finished before returning
    cudaDeviceSynchronize();
}