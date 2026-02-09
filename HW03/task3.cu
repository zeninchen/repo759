#include <stdio.h>
#include <stdlib.h>
#include "vscale.cu" // Include the vscale kernel

int main(int argc, char* argv[])
{
    int n= 10;
    if(argc > 1) {
        n = atoi(argv[1]); // Get the size of the arrays from command line argument
    }
    //Creates two arrays of length n filled by random numbers1 where n 
    //is read from the firstcommand line argument. The range of values 
    //for array a is [-10.0, 10.0], whereas the rangeof values for array b is [0.0, 1.0].
    float *da = nullptr; // device pointer for array a
    float *db = nullptr; // device pointer for array b
    float *ha = (float*)malloc(n * sizeof(float)); // host array a
    float *hb = (float*)malloc(n * sizeof(float)); // host array b
    //allocate the arrays on the device
    cudaMalloc((void**)&da, n * sizeof(float));
    cudaMalloc((void**)&db, n * sizeof(float));

    //fill the host arrays with random values
    for (int i = 0; i < n; ++i) {
        ha[i] = (float)(rand() % 2001 - 1000) / 100.0f; // Random float in [-10.0, 10.0]
        hb[i] = (float)(rand() % 101) / 100.0f; // Random float in [0.0, 1.0]
    }
    //print a and b array
    printf("Array a:\n");
    for (int i = 0; i < n; ++i) {
        printf("%f ", ha[i]);
    }
    printf("\nArray b:\n");
    for (int i = 0; i < n; ++i) {
        printf("%f ", hb[i]);
    }
    printf("\n");
    //copy the host arrays to the device
    cudaMemcpy(da, ha, n * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(db, hb, n * sizeof(float), cudaMemcpyHostToDevice);

    //Launch the vscale kernel with enough blocks and threads to cover n elements
    int threads =512;
    int blocks =1;
    //time the kernel execution
    cudaEvent_t start;
    cudaEvent_t stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    vscale<<<blocks, threads>>>(da, db, n);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    // Get the elapsed time in milliseconds
    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    printf("%f\n", ms);

    //Copy the resulting array b back to the host and print the results
    cudaMemcpy(hb, db, n * sizeof(float), cudaMemcpyDeviceToHost);
    //print the first element of b
    printf("%f\n", hb[0]);
    //print the last element of b
    printf("%f\n", hb[n-1]);

    //print the b array
    for (int i = 0; i < n; ++i) {
        printf("%f ", hb[i]);
    }
    printf("\n");
    
    //free the device memory
    cudaFree(da);
    cudaFree(db);
    //free the host memory
    free(ha);
    free(hb);
}