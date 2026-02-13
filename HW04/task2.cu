#include "stencil.cuh"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char* argv[])
{
    int n = 10; // Default size
    unsigned int threads_per_block = 1024; // Default threads per block
    int R = 2; // Radius for the stencil

    if (argc > 1) {
        n = atoi(argv[1]); // Get the size of the matrix from command line argument
    }
    if(argc > 2) {
        //get the threads per block from command line argument
        threads_per_block = atoi(argv[2]); // Get the threads per block from command line argument
    }
    if(argc > 3) {
        R = atoi(argv[3]); // Get the radius from command line argument
    }
    //create image and mask on host
    float* h_image = (float*)malloc(n * sizeof(float));
    float* h_mask = (float*)malloc((2 * R + 1) * sizeof(float));
    float* h_output = (float*)malloc(n * sizeof(float));

    //fill the image and mask with random values [-1,1]
    for (int i = 0; i < n; i++) {
        h_image[i] = (float)rand() / RAND_MAX * 2.0f - 1.0f; // Random float in [-1, 1]
    }
    for (int i = 0; i < 2 * R + 1; i++) {
        h_mask[i] = (float)rand() / RAND_MAX * 2.0f - 1.0f; // Random float in [-1, 1]
    }
    //Prepare arrays that are allocated as device memory (they will be passed to yourstencil function.)
    float* d_image;
    float* d_mask;
    float* d_output;
    cudaMalloc(&d_image, n * sizeof(float));
    cudaMalloc(&d_mask, (2 * R + 1) * sizeof(float));
    cudaMalloc(&d_output, n * sizeof(float));
    //Copy the image and mask from host to device
    cudaMemcpy(d_image, h_image, n * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_mask, h_mask, (2 * R + 1) * sizeof(float), cudaMemcpyHostToDevice);
    //time the stencil function
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    //Call the stencil function
    stencil(d_image, d_mask, d_output, n, R, threads_per_block);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);
    printf("%f\n", milliseconds);

    //Copy the output from device to host
    cudaMemcpy(h_output, d_output, n * sizeof(float), cudaMemcpyDeviceToHost);

    //print the last element of the output
    printf("%f\n", h_output[n-1]);

    //Free device memory
    cudaFree(d_image);
    cudaFree(d_mask);
    cudaFree(d_output);
    //Free host memory
    free(h_image);
    free(h_mask);
    free(h_output);

}