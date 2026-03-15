#include "matmul.h"
#include <omp.h>

void mmul(const float* A, const float* B, float* C, const std::size_t n) {
    //we want to have j in the inside, because that will have the best locality, and we want to have i in the outside, because that will allow us to parallelize the outer loop with OpenMP.
    #pragma omp parallel for
    for (unsigned int i = 0; i < n; ++i) {
        for (unsigned int k = 0; k < n; ++k) {
            for (unsigned int j = 0; j < n; ++j) {
                C[i*n + j] += A[i*n + k] * B[k*n + j];
            }
        }
    }
}