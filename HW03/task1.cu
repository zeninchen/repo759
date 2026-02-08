#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
__global__ void factorial(int* dA) {
    int idx = threadIdx.x; // get the thread index
    int result = 1;
    for (int i = 1; i <= idx + 1; ++i) { // calculate factorial
        result *= i;
    }
    dA[idx] = result; // store the result in the device array
}
int main() {
    const int N = 8;

    int* dA = nullptr;                          // device pointer
    cudaMalloc((void**)&dA, N * sizeof(int));   // allocate 8 ints on GPU

    factorial<<<1, N>>>(dA); // launch kernel with 1 block and 8 threads

    // Copy the results back to host
    int hostArray[N];
    cudaMemcpy(hostArray, dA, N * sizeof(int), cudaMemcpyDeviceToHost);

    // Print the results
    for (int i = 0; i < N; ++i) {
        printf("%d\n", hostArray[i]);
    }
    cudaFree(dA); // free device memory
}