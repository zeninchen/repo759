#include "count.cuh"

int main(int argc, char* argv[])
{
    // Example usage
    thrust::device_vector<int> d_in = {3, 5, 1, 2, 3, 1};
    thrust::device_vector<int> values;
    thrust::device_vector<int> counts;

    count(d_in, values, counts);

    // Print results
    for (size_t i = 0; i < values.size(); ++i) {
        printf("Value: %d, Count: %d\n", values[i], counts[i]);
    }

    return 0;
}