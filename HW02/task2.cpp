#include <iostream>
#include <string>
#include <chrono>
#include <cstdlib>   // rand, RAND_MAX
#include "convolution.h"

int main(int argc, char* argv[]) {
    int n = (argc < 2) ? 4 : std::stoi(argv[1]);
    int m = (argc < 3) ? 3 : std::stoi(argv[2]);

    float *image  = new float[n * n];
    float *mask   = new float[m * m];
    float *output = new float[n * n];

    // random image in [-10, 10]
    for (int i = 0; i < n * n; i++) {
        image[i] = static_cast<float>(rand()) / RAND_MAX * 20.0f - 10.0f;
    }
    // random mask in [-1, 1]
    for (int i = 0; i < m * m; i++) {
        mask[i] = static_cast<float>(rand()) / RAND_MAX * 2.0f - 1.0f;
    }

    // Prints out the time taken by your convolve function in milliseconds
    auto start = std::chrono::high_resolution_clock::now();
    convolve(image, output, n, mask, m);
    auto end   = std::chrono::high_resolution_clock::now();

    std::chrono::duration<double, std::milli> elapsed = end - start;
    std::cout  << elapsed.count() << std::endl;
    //Prints the first element of the resulting convolved array.
    std::cout << output[0] << std::endl;
    //Prints the last element of the resulting convolved array.
    std::cout << output[n * n - 1] << std::endl;

    delete[] image;
    delete[] mask;
    delete[] output;
    return 0;
}
