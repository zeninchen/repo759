#include "stencil.cuh"
#include <stdio.h>
#include <stdlib.h>
// Computes the convolution of image and mask, storing the result in output.
// Each thread should compute _one_ element of the output matrix.
// Shared memory should be allocated _dynamically_ only.
//
// image is an array of length n.
// mask is an array of length (2 * R + 1).
// output is an array of length n.
// All of them are in device memory
//
// Assumptions:
// - 1D configuration
// - blockDim.x >= 2 * R + 1
//
// The following should be stored/computed in shared memory:
// - The entire mask
// - The elements of image that are needed to compute the elements of output corresponding to the threads in the given block
// - The output image elements corresponding to the given block before it is written back to global memory
__global__ void stencil_kernel(const float* image, const float* mask, float* output, unsigned int n, unsigned int R)
{
    extern __shared__ float sh[]; // dynamic shared memory

    const unsigned int tid = threadIdx.x;
    const unsigned int base = blockIdx.x * blockDim.x; // start index in global for this block
    const unsigned int g = base + tid;                 // global output index for this thread

    const unsigned int mask_len = 2 * R + 1;
    const unsigned int img_len  = blockDim.x + 2 * R;  // tile + halos
    const unsigned int out_len  = blockDim.x;

    float* sh_mask = sh;                        // [0 .. mask_len-1]
    float* sh_img  = sh + mask_len;             // [mask_len .. mask_len+img_len-1]
    float* sh_out  = sh + mask_len + img_len;   // [.. + out_len-1]

    if (tid < mask_len) {
        sh_mask[tid] = mask[tid];
    }
    for (unsigned int idx = tid; idx < img_len; idx += blockDim.x) {
        int gi = (int)base - (int)R + (int)idx; // global index for this shared element
        sh_img[idx] = (gi >= 0 && gi < (int)n) ? image[gi] : 0.0f; // zero-pad out of bounds
    }

    __syncthreads(); // ensure sh_mask and sh_img are ready

    float acc = 0.0f;
    if (g < n) {
        // The center pixel for thread tid is at sh_img[tid + R]
        // Neighborhood: sh_img[tid + R + k] for k in [-R, R]
        const unsigned int center = tid + R;
        for (int k = -(int)R; k <= (int)R; k++) {
            acc += sh_img[center + k] * sh_mask[k + (int)R];
        }
    }
    sh_out[tid] = acc;

    __syncthreads(); // ensure sh_out is fully written

    if (g < n) {
        output[g] = sh_out[tid];
    }
}
__host__ void stencil(const float* image,
                      const float* mask,
                      float* output,
                      unsigned int n,
                      unsigned int R,
                      unsigned int threads_per_block)
{
    const unsigned int mask_len = 2 * R + 1;
    const unsigned int img_len  = threads_per_block + 2 * R; // tile + halos


    const unsigned int shmem_size = (mask_len + img_len + out_len) * sizeof(float);

    const unsigned int num_blocks = (n + threads_per_block - 1) / threads_per_block;

    stencil_kernel<<<num_blocks, threads_per_block, shmem_size>>>(image, mask, output, n, R);
}