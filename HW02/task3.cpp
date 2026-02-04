#include <iostream>
#include <string>
#include "matmul.h"
#include <chrono>
#include <cstdlib>   // rand, RAND_MAX
#include <vector>
int main()
{
    /*Generates two n×n matrices A and B containing random float numbers between 0.0 and
    1.0, where 1000 ≤ n ≤ 2000, stored in row-major order.
    */
    //1000 <= n <= 2000
    const unsigned int n =  1000 + rand() % 1001;
    //print n
    std::cout << n << std::endl;
    double *A = new double[n * n];
    double *B = new double[n * n];
    double *C = new double[n * n](); //initialize to 0
    //random float numbers between 0.0 and 1.0
    for (int i = 0; i < (int)(n * n); i++) {
        A[i] = static_cast<double>(rand()) / RAND_MAX;
        B[i] = static_cast<double>(rand()) / RAND_MAX;
    }
    //start timer
    auto start = std::chrono::high_resolution_clock::now();

    //call mmul1 function
    mmul1(A, B, C, n);

    //end timer
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    std::cout <<duration.count() <<std::endl;
    //print out the last element of matrix C
    std::cout << C[n * n - 1] << std::endl;

    //do mmul2 
    //reset matrix C to 0
    std::fill_n(C, n * n, 0.0);
    auto start2 = std::chrono::high_resolution_clock::now();

    mmul2(A, B, C, n);

    //end timer
    auto end2 = std::chrono::high_resolution_clock::now();
    auto duration2 = std::chrono::duration_cast<std::chrono::microseconds>(end2 - start2);
    std::cout <<duration2.count() <<std::endl;
    //print out the last element of matrix C
    std::cout << C[n * n - 1] << std::endl;

    //do mmul3
    //reset matrix C to 0
    std::fill_n(C, n * n, 0.0);
    auto start3 = std::chrono::high_resolution_clock::now();
    mmul3(A, B, C, n);
    //end timer
    auto end3 = std::chrono::high_resolution_clock::now();
    auto duration3 = std::chrono::duration_cast<std::chrono::microseconds>(end3 - start3);
    std::cout <<duration3.count() <<std::endl;
    //print out the last element of matrix C
    std::cout << C[n * n - 1] << std::endl;

    //do mmul4
    // rededine A_vector and B_vector to std::vector<double>&
    std::vector<double> A_vector(A, A + n * n);
    std::vector<double> B_vector(B, B + n * n);
    //reset matrix C to 0
    std::fill_n(C, n * n, 0.0);
    auto start4 = std::chrono::high_resolution_clock::now();
    mmul4(A_vector, B_vector, C, n);
    //end timer
    auto end4 = std::chrono::high_resolution_clock::now();
    auto duration4 = std::chrono::duration_cast<std::chrono::microseconds>(end4 - start4);
    std::cout <<duration4.count() <<std::endl;
    //print out the last element of matrix C
    std::cout << C[n * n - 1] << std::endl;

    delete[] A;
    delete[] B;
    delete[] C;
}
