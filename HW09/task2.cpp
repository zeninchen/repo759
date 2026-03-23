#include "montecarlo.h"

#include <vector>
#include <cstdlib>
#include <iostream>
#include <chrono>

int main(int argc, char* argv[]) {
    size_t n = std::stoull(argv[1]);
    int t = std::stoi(argv[2]);

    float r = 1.0f;

    // set threads
    omp_set_num_threads(t);

    // generate x, y in [-r, r]
    std::vector<float> x(n), y(n);
    for (size_t i = 0; i < n; i++) {
        x[i] = (static_cast<float>(rand()) / RAND_MAX) * 2 * r - r;
        y[i] = (static_cast<float>(rand()) / RAND_MAX) * 2 * r - r;
    }

    // timing
    auto start = std::chrono::high_resolution_clock::now();
    int incircle = montecarlo(n, x.data(), y.data(), r);
    auto end = std::chrono::high_resolution_clock::now();

    double ms = std::chrono::duration<double, std::milli>(end - start).count();

    // estimate pi
    float pi = 4.0f * incircle / n;

    std::cout << pi << "\n";
    std::cout << ms << "\n";

    return 0;
}