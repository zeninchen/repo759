#define CUB_STDERR // print CUDA runtime errors to console
#include <stdio.h>
#include <cub/util_allocator.cuh>
#include <cub/device/device_reduce.cuh>
#include "cub/util_debug.cuh"
using namespace cub;
CachingDeviceAllocator  g_allocator(true);  // Caching allocator for device memory

int main(int argc, char* argv[]) {
    int num_items = 10;
    if (argc > 1) {
        num_items = atoi(argv[1]);
    }
    //fill the host array with random floats in [-1, 1]
    float* h_in = (float*)malloc(sizeof(float) * num_items);
    for (int i = 0; i < num_items; i++) {
        h_in[i] = (float)(rand() % 10) / 5.0f - 1.0f; // Random floats between -1.0 and 1.0
    }
    float  sum = 0;
    for (unsigned int i = 0; i < num_items; i++)
        sum += h_in[i];

    // Set up device arrays
    float* d_in = NULL;
    CubDebugExit(g_allocator.DeviceAllocate((void**)& d_in, sizeof(float) * num_items));
    // Initialize device input
    CubDebugExit(cudaMemcpy(d_in, h_in, sizeof(float) * num_items, cudaMemcpyHostToDevice));
    // Setup device output array
    float* d_sum = NULL;
    CubDebugExit(g_allocator.DeviceAllocate((void**)& d_sum, sizeof(float) * 1));
    // Request and allocate temporary storage
    void* d_temp_storage = NULL;
    size_t temp_storage_bytes = 0;
    CubDebugExit(DeviceReduce::Sum(d_temp_storage, temp_storage_bytes, d_in, d_sum, num_items));
    CubDebugExit(g_allocator.DeviceAllocate(&d_temp_storage, temp_storage_bytes));
    //time the reduce operation
    cudaEvent_t start, stop;
    CubDebugExit(cudaEventCreate(&start));
    CubDebugExit(cudaEventCreate(&stop));
    CubDebugExit(cudaEventRecord(start));
    // Do the actual reduce operation
    CubDebugExit(DeviceReduce::Sum(d_temp_storage, temp_storage_bytes, d_in, d_sum, num_items));
    CubDebugExit(cudaEventRecord(stop));
    CubDebugExit(cudaEventSynchronize(stop));
    float ms = 0;
    CubDebugExit(cudaEventElapsedTime(&ms, start, stop));
    float gpu_sum;
    CubDebugExit(cudaMemcpy(&gpu_sum, d_sum, sizeof(float) * 1, cudaMemcpyDeviceToHost));
    // Check for correctness
    printf("%f\n", gpu_sum);
    //print the time taken to perform the reduction
    printf("%f\n", ms);


    // Cleanup
    if (d_in) CubDebugExit(g_allocator.DeviceFree(d_in));
    if (d_sum) CubDebugExit(g_allocator.DeviceFree(d_sum));
    if (d_temp_storage) CubDebugExit(g_allocator.DeviceFree(d_temp_storage));
    
    return 0;
}