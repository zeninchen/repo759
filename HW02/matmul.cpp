#include "matmul.h"
#include <cstddef>
/*
mmul1 should have three for loops: the outer loop sweeps index i through the rows of C, the
middle loop sweeps index j through the columns of C, and the innermost loop sweeps index k
through; i.e., to carry out, the dot product of the i
th row A with the j
th column of B. Inside
the innermost loop, you should have a single line of code which increments Cij . Assume that
A and B are 1D arrays storing the matrices in row-major order.
*/
void mmul1(const double* A, const double* B, double* C, const unsigned int n)
{
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int j = 0; j < n; ++j) {
            double sum = 0.0;
            for (unsigned int k = 0; k < n; ++k) {
                //the dot product of the i th row A with the j th column of B
                sum += A[i * n + k] * B[k * n + j];
            }
            C[i * n + j] = sum;
        }
    }
}

/*
mmul2 should also have three for loops, but the two innermost loops should be swapped
relative to mmul1 (such that, if your original iterators are from outer to inner (i,j,k), then
they now become (i,k,j)). That is the only difference between mmul1 and mmul2.
*/

void mmul2(const double* A, const double* B, double* C, const unsigned int n)
{
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int k = 0; k < n; ++k) {
            double sum = 0.0;
            for (unsigned int j = 0; j < n; ++j) {
                //the dot product of the i th row A with the j th column of B
                sum += A[i * n + k] * B[k * n + j];
            }
            C[i * n + k] = sum;
        }
    }
}

/*
mmul3 should also have three for loops, but the outermost loop in mmul1 should become the
innermost loop in mmul3, and the other 2 loops do not change their relative positions (such that,
if your original iterators are from outer to inner (i,j,k), then they now become (j,k,i)).
That is the only difference between mmul1 and mmul3.
*/
void mmul3(const double* A, const double* B, double* C, const unsigned int n)
{
    for (unsigned int j = 0; j < n; ++j) {
        for (unsigned int k = 0; k < n; ++k) {
            double sum = 0.0;
            for (unsigned int i = 0; i < n; ++i) {
                //the dot product of the i th row A with the j th column of B
                sum += A[i * n + k] * B[k * n + j];
            }
            C[i * n + j] = sum;
        }
    }
}
/*
mmul4 should have the for loops ordered as in mmul1, but this time around A and B are stored
as std::vector<double>. That is the only difference between mmul1 and mmul4.
*/
void mmul4(const std::vector<double>& A, const std::vector<double>& B, double* C, const unsigned int n)
{
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int j = 0; j < n; ++j) {
            double sum = 0.0;
            for (unsigned int k = 0; k < n; ++k) {
                //the dot product of the i th row A with the j th column of B
                sum += A[i * n + k] * B[k * n + j];
            }
            C[i * n + j] = sum;
        }
    }
}