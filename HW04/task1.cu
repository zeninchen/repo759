#include "matmul.cuh" // Include the matmul kernel
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[])
{
    
    int n = 10; // Default size
    unsigned int threads_per_block = 1024; // Default threads per block
    if (argc > 1) {
        n = atoi(argv[1]); // Get the size of the matrices from command line argument
    }
    if(argc > 2) {
        //get the threads per block from command line argument
        threads_per_block = atoi(argv[2]); // Get the threads per block from command line argument
    }
    // Create two nxn matrices A and B filled with random values, and an output matrix C
    float *A = (float*)malloc(n * n * sizeof(float)); // host matrix A
    float *B = (float*)malloc(n * n * sizeof(float)); // host matrix
    float *C = (float*)malloc(n * n * sizeof(float)); // host matrix C
    //Prepare arrays that are allocated as device memory (they will be passed to yourmatmul function.)
    float *dA = nullptr; // device pointer for matrix A
    float *dB = nullptr; // device pointer for matrix B
    float *dC = nullptr; // device pointer for matrix C
    // Allocate memory on the device for A, B, and C
    cudaMalloc((void**)&dA, n * n * sizeof(float));
    cudaMalloc((void**)&dB, n * n * sizeof(float));
    cudaMalloc((void**)&dC, n * n * sizeof(float));
    // Fill the host matrices A and B with random values
    for (int i = 0; i < n * n; ++i) {
        A[i] = (float)(rand() % 2001 - 1000) / 100.0f; // Random float in [-10.0, 10.0]
        B[i] = (float)(rand() % 2001 - 1000) / 100.0f; // Random float in [-10.0, 10.0]
    }
    //print A and B just to verify correctness
    printf("Matrix A:\n");
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            printf("%f ", A[i * n + j]);
        }
        printf("\n");
    }
    printf("Matrix B:\n");
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            printf("%f ", B[i * n + j]);
        }
        printf("\n");
    }
    // Copy the host matrices A and B to the device
    cudaMemcpy(dA, A, n * n * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(dB, B, n * n * sizeof(float), cudaMemcpyHostToDevice);

    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    // Launch the matmul kernel with enough blocks and threads to cover n*n elements
    matmul(dA, dB, dC, n, threads_per_block);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    
        // Get the elapsed time in milliseconds
    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    printf("%f\n", ms); // Print the elapsed time

    // Copy the result matrix C back to the host
    cudaMemcpy(C, dC, n * n * sizeof(float), cudaMemcpyDeviceToHost);
    //print just the last element of C to verify correctness
    printf("%f\n",C[(n-1)*n + (n-1)]); // Print the last element of C

    //print the entire matrix C just to verify correctness
    printf("Matrix C:\n");
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            printf("%f ", C[i * n + j]);
        }
        printf("\n");
    }
    //free the device memory
    cudaFree(dA);
    cudaFree(dB);
    cudaFree(dC);
    //free the host memory
    free(A);
    free(B);
    free(C);
}