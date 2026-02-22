#include "matmul.cuh"

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
    // Allocate and initialize matrices A, B, and C in managed memory
    int* hA = (int*)malloc(n * n * sizeof(int));
    int* hB = (int*)malloc(n * n * sizeof(int));
    int* hC = (int*)malloc(n * n * sizeof(int));

    for (int i = 0; i < n * n; ++i) {
        hA[i] = rand() % 10; // Fill A with random integers
        hB[i] = rand() % 10; // Fill B with random integers
        hC[i] = 0; // Initialize C to zero
    }

    //allocate device memory and copy data from host to device
    int* dA;
    int* dB;
    int* dC;
    cudaMalloc((void**)&dA, n * n * sizeof(int));
    cudaMalloc((void**)&dB, n * n * sizeof(int));

    cudaMemcpy(dA, hA, n * n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(dB, hB, n * n * sizeof(int), cudaMemcpyHostToDevice);
    cudaMalloc((void**)&dC, n * n * sizeof(int));
    //count the time taken by the matmul_1 function
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    matmul_1(dA, dB, dC, n, block_dim);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    //print the first element in C and the time taken
    //copy the result back to host and print the first element
    cudaMemcpy(hC, dC, n * n * sizeof(int), cudaMemcpyDeviceToHost);
    printf("%d\n", hC[0]);
    //print the last element in C
    printf("%d\n", hC[n * n - 1]);
    printf("%f\n", milliseconds);

    //do the same for matmul_2 and matmul_3
    cudaEventRecord(start);
    matmul_2((float*)dA, (float*)dB, (float*)dC, n, block_dim);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    //copy the result back to host and print the first element
    cudaMemcpy(hC, dC, n * n * sizeof(int), cudaMemcpyDeviceToHost);
    printf("%d\n", hC[0]);
    //print the last element in C
    printf("%d\n", hC[n * n - 1]);
    printf("%f\n", milliseconds);

    cudaEventRecord(start);
    matmul_3((float*)dA, (float*)dB, (float*)dC, n, block_dim);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    //copy the result back to host and print the first element
    cudaMemcpy(hC, dC, n * n * sizeof(int), cudaMemcpyDeviceToHost);
    printf("%d\n", hC[0]);
    //print the last element in C
    printf("%d\n", hC[n * n - 1]);
    printf("%f\n", milliseconds);

    //cleanup
    free(hA);
    free(hB);
    free(hC);
    cudaFree(dA);
    cudaFree(dB);
    cudaFree(dC);

    return 0;
}