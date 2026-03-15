#include <iostream>
#include <vector>
#include <chrono>
#include <cstdlib>
#include <omp.h>
#include "msort.h"

int main(int argc, char* argv[])
{
    int n = atoi(argv[1]);
    int t = atoi(argv[2]);
    int ts = atoi(argv[3]);

    omp_set_num_threads(t);

    std::vector<int> arr(n);

    // fill with random numbers [-1000,1000]
    for(int i = 0; i < n; i++)
        arr[i] = rand() % 2001 - 1000;

    auto start = std::chrono::high_resolution_clock::now();

    msort(arr.data(), n, ts);

    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();

    std::cout << arr[0] << std::endl;
    std::cout << arr[n-1] << std::endl;
    std::cout << time_ms << std::endl;

    return 0;
}