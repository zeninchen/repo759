#include "montecarlo.h"
#include <cmath>

int montecarlo(const size_t n, const float *x, const float *y, const float radius) {
    int incircle = 0;
    float r2 = radius * radius;

    #pragma omp parallel
    {
        int local_count = 0;

        #pragma omp for
        for (size_t i = 0; i < n; i++) {
            float dist2 = x[i] * x[i] + y[i] * y[i];
            if (dist2 <= r2) {
                local_count++;
            }
        }

        #pragma omp atomic
        incircle += local_count;
    }

    return incircle;
}