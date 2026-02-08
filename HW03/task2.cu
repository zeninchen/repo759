#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
/*
    Each thread computes ax+y and writes the result in one distinct 
    entry of the dA array (takea look below at the expected output 
    of the program to figure out which entry of the array athread 
    needs to write to). 
*/
__global__ void compute(int* dA, int a) {
    int x = threadIdx.x; // get the thread index
    int y = blockIdx.x;  // get the block index
    int idx = blockIdx.x * blockDim.x + threadIdx.x;//we need to calculate the correct index
    dA[idx] = a * x + y; // compute ax+y and store in dA
}
int main() {
    //From the host, allocates an array of 16 ints on the device called dA
    const int N = 16;
    int* dA = nullptr;                          // device pointer
    
    cudaMalloc((void**)&dA, N * sizeof(int));   // allocate 16 ints on GPU

    const int RANGE = 9;
    int a = rand() % (RANGE + 1) + 1; // generate a random integer a in the range [1, 10]

    //Launch a kernel with 2 blocks and 8 threads per block 
    compute<<<2, 8>>>(dA, a); 

    // Copy the results back to host
    int hostArray[N];
    cudaMemcpy(hostArray, dA, N * sizeof(int), cudaMemcpyDeviceToHost);
    // Print the results
    for (int i = 0; i < N; ++i) {
        printf("%d\n", hostArray[i]);
    }   
    cudaFree(dA); // free device memory
}