
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
__global__ void vscale(const float *a, float *b, unsigned int n)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x; // Calculate global thread index
    if (idx < n) { // Ensure we don't go out of bounds
        b[idx] = a[idx] * b[idx]; // Scale element-wise and store in b
    }    
}

