#include "scan.h"

// Performs an inclusive scan on input array arr and stores
// the result in the output array
// arr and output are arrays of n elements
void scan(const float *arr, float *output, std::size_t n)
{
    if (n == 0) return;
    output[0] = arr[0];
    for (std::size_t i = 1; i < n; ++i)
    {
        output[i] = output[i - 1] + arr[i];
    }
}