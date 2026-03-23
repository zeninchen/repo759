#include "cluster.h"

#include <algorithm>
#include <chrono>
#include <iostream>
#include <vector>
#include <cstdlib>

int main(int argc, char* argv[]) {
    size_t n = std::stoull(argv[1]);
    size_t t = std::stoull(argv[2]);

    // arr
    std::vector<float> arr(n);
    for (size_t i = 0; i < n; i++) {
        arr[i] = static_cast<float>(rand()) / RAND_MAX * n;
    }

    std::sort(arr.begin(), arr.end());

    // centers
    std::vector<float> centers(t);
    for (size_t i = 0; i < t; i++) {
        centers[i] = (2.0f * i + 1) * n / (2.0f * t);
    }

    // dists
    std::vector<float> dists(t, 0.0f);

    // timing
    auto start = std::chrono::high_resolution_clock::now();
    cluster(n, t, arr.data(), centers.data(), dists.data());
    auto end = std::chrono::high_resolution_clock::now();

    double ms = std::chrono::duration<double, std::milli>(end - start).count();

    // max
    size_t idx = 0;
    for (size_t i = 1; i < t; i++) {
        if (dists[i] > dists[idx]) idx = i;
    }

    std::cout << dists[idx] << "\n";
    std::cout << idx << "\n";
    std::cout << ms << "\n";

    return 0;
}