//main function for testing the scan function
#include <iostream>
#include "scan.h"
#include <string>
int main(int argc, char* argv[])
{
    //creates an array of n random float numbers between -1.0 and 1.0. n 
    //should be read asthe first command line argument as below.
    int n;
    if(argc < 2) {
        n=6;
    }
    else {
        std::string input = argv[1];
        //convert the first character to integer
        n = std::stoi(argv[1]);
    }
    float *arr = new float[n];
    for(int i = 0; i < n; i++) {
        //between -1.0 and 1.0
        arr[i] = static_cast<float>(rand()) / RAND_MAX * 2.0f - 1.0f;
    }
    //scans the array using your scan function.
    float *output = new float[n];
    //scan(arr, output, n);
    //Prints out the time taken by your scan function in milliseconds
    auto start = std::chrono::high_resolution_clock::now();
    scan(arr, output, n);
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::milli> elapsed = end - start;
    std::cout << "Time taken by scan function: " << elapsed.count() << " ms" << std::endl;
    //Prints the first element of the output scanned array (just the value)
    std::cout << "" << output[0] << std::endl;
    //Prints the last element of the output scanned array
    std::cout << "" << output[n-1] << std::endl;
    //print out all the elements of the output scanned array, and the array itself
    for(int i = 0; i < n; i++) {
        std::cout << "arr[" << i << "] = " << arr[i] << ", output[" << i << "] = " << output[i] << std::endl;
    }
    //Deallocates memory when necessary.
    delete[] arr;
    delete[] output;
    return 0;
}