#include "matmul.cuh"
#include <stdio.h>
#include <stdlib.h>
#define BLOCK_SIZE 16
int main( int argc, char** argv)
{
    //usage : ./task1 n block dim
    int n = 1000; // default matrix size
    int block_dim = 16; // default block dimension
    if (argc > 1) {
        n = atoi(argv[1]); // read matrix size from command line
    }
    if (argc > 2) {
        block_dim = atoi(argv[2]); // read block dimension from command line
    }
    // --- int version ---
    int *hAi, *hBi, *hCi;
    int *dAi, *dBi, *dCi;
    // allocate n*n ints, fill, cudaMalloc, cudaMemcpy, call matmul_1
    // copy back, print hCi[0], hCi[n*n-1]

    // --- float version ---
    float *hAf, *hBf, *hCf;
    float *dAf, *dBf, *dCf;
    // allocate n*n floats, fill, cudaMalloc, cudaMemcpy, call matmul_2
    // copy back, print hCf[0], hCf[n*n-1] with %f

    // --- double version ---
    double *hAd, *hBd, *hCd;
    double *dAd, *dBd, *dCd;
    // allocate n*n doubles, fill, cudaMalloc, cudaMemcpy, call matmul_3
    // copy back, print with %lf
    //allocate host memory
    hAi = (int*)malloc(n * n * sizeof(int));
    hBi = (int*)malloc(n * n * sizeof(int));
    hCi = (int*)malloc(n * n * sizeof(int));
    hAf = (float*)malloc(n * n * sizeof(float));
    hBf = (float*)malloc(n * n * sizeof(float));
    hCf = (float*)malloc(n * n * sizeof(float));
    hAd = (double*)malloc(n * n * sizeof(double));
    hBd = (double*)malloc(n * n * sizeof(double));
    hCd = (double*)malloc(n * n * sizeof(double));
    //fill the host arrays with random integers
    for (int i = 0; i < n * n; ++i) {
        hAi[i] = rand() % 10; // Fill A with random integers
        hBi[i] = rand() % 10; // Fill B with random integers
        hCi[i] = 0; // Initialize C to zero
    }
    //copy the integer value to the other two arrays
    for (int i = 0; i < n * n; ++i) {
        hAf[i] = (float)hAi[i]; // Copy integer values to float array
        hBf[i] = (float)hBi[i];
        hCf[i] = 0.0f; // Initialize C to zero

        hAd[i] = (double)hAi[i]; // Copy integer values to double array
        hBd[i] = (double)hBi[i];
        hCd[i] = 0.0; // Initialize C to zero
    }

    
    cudaMalloc((void**)&dAi, n * n * sizeof(int));
    cudaMalloc((void**)&dBi, n * n * sizeof(int));
    cudaMalloc((void**)&dAf, n * n * sizeof(float));
    cudaMalloc((void**)&dBf, n * n * sizeof(float));
    cudaMalloc((void**)&dAd, n * n * sizeof(double));
    cudaMalloc((void**)&dBd, n * n * sizeof(double));
    //copy the data to device

    cudaMemcpy(dAi, hAi, n * n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(dBi, hBi, n * n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(dAf, hAf, n * n * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(dBf, hBf, n * n * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(dAd, hAd, n * n * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(dBd, hBd, n * n * sizeof(double), cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dCi, n * n * sizeof(int));
    cudaMalloc((void**)&dCf, n * n * sizeof(float));
    cudaMalloc((void**)&dCd, n * n * sizeof(double));
    //count the time taken by the matmul_1 function
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    matmul_1(dAi, dBi, dCi, n, block_dim);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    //print the first element in C and the time taken
    //copy the result back to host and print the first element
    cudaMemcpy(hCi, dCi, n * n * sizeof(int), cudaMemcpyDeviceToHost);
    printf("%d\n", hCi[0]);
    //print the last element in C
    printf("%d\n", hCi[n * n - 1]);
    printf("%f\n", milliseconds);

    //do the same for matmul_2 and matmul_3
    cudaEventRecord(start);
    matmul_2(dAf, dBf, dCf, n, block_dim);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    //copy the result back to host and print the first element
    cudaMemcpy(hCf, dCf, n * n * sizeof(float), cudaMemcpyDeviceToHost);
    printf("%f\n", hCf[0]);
    //print the last element in C
    printf("%f\n", hCf[n * n - 1]);
    printf("%f\n", milliseconds);

    cudaEventRecord(start);
    matmul_3(dAd, dBd, dCd, n, block_dim);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    //copy the result back to host and print the first element
    cudaMemcpy(hCd, dCd, n * n * sizeof(double), cudaMemcpyDeviceToHost);
    printf("%lf\n", hCd[0]);
    //print the last element in C
    printf("%lf\n", hCd[n * n - 1]);
    printf("%f\n", milliseconds);

    //cleanup
    free(hAi);
    free(hBi);
    free(hAf);
    free(hBf);
    free(hAd);
    free(hBd);
    free(hCi);
    free(hCf);
    free(hCd);
    cudaFree(dAi);
    cudaFree(dBi);
    cudaFree(dAf);
    cudaFree(dBf);
    cudaFree(dAd);
    cudaFree(dBd);
    cudaFree(dCi);
    cudaFree(dCf);
    cudaFree(dCd);

    return 0;
}