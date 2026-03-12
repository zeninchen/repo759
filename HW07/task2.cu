#include <cstdio>
#include <cstdlib>
#include <ctime>

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>

#include <cuda_runtime.h>

#include "count.cuh"

int main(int argc, char* argv[])
{
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s n\n", argv[0]);
        return 1;
    }

    int n = std::atoi(argv[1]);
    if (n <= 0) {
        std::fprintf(stderr, "Error: n must be a positive integer.\n");
        return 1;
    }

    // Create and fill host vector with random ints in [0, 500]
    thrust::host_vector<int> h_in(n);
    std::srand((unsigned int)std::time(nullptr));
    for (int i = 0; i < n; ++i) {
        h_in[i] = std::rand() % 501;
    }

    // Copy to device
    thrust::device_vector<int> d_in = h_in;

    // Output vectors
    thrust::device_vector<int> values;
    thrust::device_vector<int> counts;

    // CUDA event timing
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    count(d_in, values, counts);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0.0f;
    cudaEventElapsedTime(&ms, start, stop);

    // Copy results back to host for printing
    thrust::host_vector<int> h_values = values;
    thrust::host_vector<int> h_counts = counts;

    // Print last element of values
    std::printf("%d\n", h_values[h_values.size() - 1]);

    // Print last element of counts
    std::printf("%d\n", h_counts[h_counts.size() - 1]);

    // Print elapsed time in milliseconds
    std::printf("%.2f\n", ms);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}