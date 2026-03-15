#include <iostream>
#include <vector>
#include <chrono>
#include <omp.h>
#include "convolution.h"

int main(int argc, char* argv[])
{
    int n = atoi(argv[1]);
    int t = atoi(argv[2]);

    omp_set_num_threads(t);

    std::vector<float> image(n*n);
    std::vector<float> output(n*n, 0.0f);

    int m = 3;
    std::vector<float> mask(m*m);

    // fill image
    for(int i = 0; i < n*n; i++)
        image[i] = 1.0f;

    // simple mask
    for(int i = 0; i < m*m; i++)
        mask[i] = 1.0f;

    auto start = std::chrono::high_resolution_clock::now();

    convolve(image.data(), output.data(), n, mask.data(), m);

    auto end = std::chrono::high_resolution_clock::now();

    double time_ms =
        std::chrono::duration<double, std::milli>(end - start).count();

    std::cout << output[0] << std::endl;
    std::cout << output[n*n-1] << std::endl;
    std::cout << time_ms << std::endl;

    return 0;
}