#include <cstdio>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include "count.cuh"

int main(int argc, char* argv[])
{
    thrust::host_vector<int> h_in = {3, 5, 1, 2, 3, 1};
    thrust::device_vector<int> d_in = h_in;

    thrust::device_vector<int> values;
    thrust::device_vector<int> counts;

    count(d_in, values, counts);

    thrust::host_vector<int> h_values = values;
    thrust::host_vector<int> h_counts = counts;

    for (size_t i = 0; i < h_values.size(); ++i) {
        printf("Value: %d, Count: %d\n", h_values[i], h_counts[i]);
    }

    return 0;
}