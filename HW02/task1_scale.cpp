// task1.cpp
#include <iostream>
#include <chrono>
#include <cstdlib>   // rand, RAND_MAX
#include "scan.h"

int main() {
    using clock = std::chrono::high_resolution_clock;

    // CSV header (nice for plotting later)
    std::cout << "n,time_ms,first,last\n";

    for (int p = 10; p <= 30; ++p) {
        const int n = 1 << p;

        float* arr = new float[n];
        float* out = new float[n];

        // Fill random floats in [-1, 1]
        for (int i = 0; i < n; ++i) {
            arr[i] = static_cast<float>(rand()) / RAND_MAX * 2.0f - 1.0f;
        }

        auto start = clock::now();
        scan(arr, out, n);
        auto end = clock::now();

        std::chrono::duration<double, std::milli> elapsed = end - start;

        // CSV row
        std::cout << n << ","
                  << elapsed.count() << ","
                  << out[0] << ","
                  << out[n - 1] << "\n";

        delete[] arr;
        delete[] out;
    }

    return 0;
}
