#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/reduce.h>
#include <thrust/fill.h>

#include "count.cuh"

void count(const thrust::device_vector<int>& d_in,
           thrust::device_vector<int>& values,
           thrust::device_vector<int>& counts)
{
    if (d_in.empty()) {
        values.clear();
        counts.clear();
        return;
    }

    // Make a sorted copy of the input
    thrust::device_vector<int> d_sorted = d_in;
    thrust::sort(d_sorted.begin(), d_sorted.end());

    // One "1" per input element
    thrust::device_vector<int> ones(d_sorted.size(), 1);

    // Worst case -> every element is unique, so output size is greater or equal to input size
    values.resize(d_sorted.size());
    counts.resize(d_sorted.size());

    // Reduce equal keys and sum their 1s
    auto end_pair = thrust::reduce_by_key(
        d_sorted.begin(), d_sorted.end(),
        ones.begin(),
        values.begin(),
        counts.begin()
    );

    // Shrink outputs to actual number of unique values
    values.resize(end_pair.first - values.begin());
    counts.resize(end_pair.second - counts.begin());
}