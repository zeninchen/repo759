#include "reduce.cuh"
#include <cuda_runtime.h>

__global__ void reduce_kernel(float *g_idata, float *g_odata, unsigned int n)
{
    extern __shared__ float sdata[];
    unsigned int tid = threadIdx.x;
    unsigned int i   = blockIdx.x * (blockDim.x * 2) + tid;
    //reduction 4 load two elements per thread and add them during the load
    float sum = 0.0f;
    if (i < n) sum += g_idata[i];
    if (i + blockDim.x < n) sum += g_idata[i + blockDim.x];

    sdata[tid] = sum;
    __syncthreads();
    //reduction 3
    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) sdata[tid] += sdata[tid + s];
        __syncthreads();
    }

    if (tid == 0) g_odata[blockIdx.x] = sdata[0];
}

__host__ void reduce(float **input, float **output, unsigned int N,
                     unsigned int threads_per_block)
{
    float *d_in  = *input;
    float *d_out = *output;

    unsigned int n = N;
    unsigned int num_blocks = (n + (threads_per_block * 2 - 1)) / (threads_per_block * 2);

    // Keep reducing until we get a single value
    while (true) {
        reduce_kernel<<<num_blocks, threads_per_block, threads_per_block * sizeof(float)>>>(d_in, d_out, n);
        n = num_blocks;
        if (num_blocks == 1) break;

        num_blocks = (n + (threads_per_block * 2 - 1)) / (threads_per_block * 2);

        // swap buffers
        float *tmp = d_in;
        d_in = d_out;
        d_out = tmp;
    }

    // Ensure final answer is in (*input)[0]
    if (d_out != *input) {
        cudaMemcpy(*input, d_out, sizeof(float), cudaMemcpyDeviceToDevice);
    }

    cudaDeviceSynchronize();
}