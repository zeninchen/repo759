//include the thrust library header
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/sort.h>
#include <cuda_runtime.h>

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <vector>

//take in arg
int main(int argc, char* argv[]) {
    //default 10
    int n = 10;
    if (argc > 1) {
        n = atoi(argv[1]);
    }
    //Create and fill with random float numbers in the range [-1.0, 1.0] a thrust::host vectorof length n, where n is the first command line argument as below.
    thrust::host_vector<float> h_in(n);
    for (int i = 0; i < n; i++) {
        h_in[i] = (float)(rand() % 10) / 5.0f - 1.0f; // Random floats between -1.0 and 1.0
    }
    //Use the built-in function in Thrust to copy the thrust::host vector into athrust::device vector.
    thrust::device_vector<float> d_in = h_in;

    //Call the thrust::reduce function to perform a reduction on the previously generatedthrust::device vector.
    //record the time taken to perform the reduction and print the result of the reduction and the time taken.
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);
    float sum = thrust::reduce(d_in.begin(), d_in.end(), 0.0f, thrust::plus<float>());
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    cudaEventElapsedTime(&ms, start, stop);
    //print the result of the reduction and the time taken.
    std::cout <<sum << std::endl;
    //print the time taken to perform the reduction
    std::cout << ms <<std::endl;

     return 0;
}
