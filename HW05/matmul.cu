#include "matmul.cuh"
#include <stdio.h>
#include <stdlib.h>
#define BLOCK_SIZE 16
__host__ void matmul_1(const int *A, const int *B, int *C, unsigned int n,
                       unsigned int block_dim)
{
    //Launch the matmul kernel with enough blocks and threads to cover n*n elements
    dim3 threads(block_dim, block_dim); // Define the number of threads per block
    dim3 blocks((n + block_dim - 1) / block_dim, (n + block_dim - 1) / block_dim); // Calculate the number of blocks needed
    matmul_kernel<int><<<blocks, threads>>>(A, B, C, n);
}
__host__ void matmul_2(const float *A, const float *B, float *C, unsigned int n,
                       unsigned int block_dim)
{

}
__host__ void matmul_3(const double *A, const double *B, double *C,
                       unsigned int n, unsigned int block_dim)
{

}

template<typename T>
_global__ void matmul_kernel(const T* A, const T* B, T* C, size_t n)
{
    int bx = blockIdx.x; // Block index
    int by = blockIdx.y; // Block index
    int tx = threadIdx.x; // Thread index
    int ty = threadIdx.y; // Thread index

    int aBegin = n * BLOCK_SIZE * by; // Starting index of the block in A
    int aEnd = aBegin + n - 1; // Ending index of the block in A
    int aStep = BLOCK_SIZE; // Step size for iterating through blocks of A

    int bBegin = BLOCK_SIZE * bx; // Starting index of the block in B
    int bStep = BLOCK_SIZE * n; // Step size for iterating through blocks of B
    
    T Csub = 0; // Initialize the value for C

    __shared__ T As[BLOCK_SIZE][BLOCK_SIZE];
    __shared__ T Bs[BLOCK_SIZE][BLOCK_SIZE];

    //loop over the blocks of A and B required to compute the block of C
    for (int a = aBegin, b = bBegin; a <= aEnd; a += aStep, b += bStep) {
        // Load the blocks of A and B into shared memory
        As[ty][tx] = A[a + n * ty + tx];
        Bs[ty][tx] = B[b + n * ty + tx];
        __syncthreads(); // Synchronize to ensure all threads have loaded their data

        // Compute the product of the two blocks
        for (int k = 0; k < BLOCK_SIZE; ++k) {
            Csub += As[ty][k] * Bs[k][tx];
        }
        __syncthreads(); // Synchronize to ensure all threads have completed their computation
    }
    int c= n * BLOCK_SIZE * by + BLOCK_SIZE * bx;; // Calculate the index for C
    C[c + tx + ty * n] = Csub;
}