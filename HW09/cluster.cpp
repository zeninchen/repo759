#include "cluster.h"
#include <cmath>
#include <iostream>

void cluster(const size_t n, const size_t t, const float *arr,
             const float *centers, float *dists) {
#pragma omp parallel num_threads(t)
  {
    unsigned int tid = omp_get_thread_num();

    size_t chunk = n / t;
    size_t start = tid * chunk;
    size_t end = start + chunk;

    float local_dist = 0.0f;

    for (size_t i = start; i < end; i++) {
        local_dist += std::fabs(arr[i] - centers[tid]);
    }

    dists[tid] = local_dist;
  }
}
