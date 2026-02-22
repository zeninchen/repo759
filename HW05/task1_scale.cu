#include "matmul.cuh"
#include <cuda_runtime.h>

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <vector>

#define CUDA_CHECK(call)                                                     \
    do {                                                                     \
        cudaError_t err = (call);                                            \
        if (err != cudaSuccess) {                                            \
            std::fprintf(stderr, "CUDA error %s:%d: %s\n",                   \
                         __FILE__, __LINE__, cudaGetErrorString(err));       \
            std::exit(1);                                                    \
        }                                                                    \
    } while (0)

template <typename T>
__global__ void init_matrix(T* M, unsigned int n) {
    unsigned long long idx = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long long N = (unsigned long long)n * (unsigned long long)n;
    if (idx < N) {
        // Deterministic values 0..9 (fast, no rand())
        M[idx] = (T)(idx % 10);
    }
}

template <typename T>
__global__ void zero_matrix(T* M, unsigned int n) {
    unsigned long long idx = (unsigned long long)blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long long N = (unsigned long long)n * (unsigned long long)n;
    if (idx < N) M[idx] = (T)0;
}

static bool valid_block_dim_2d(unsigned int bd) {
    return bd > 0 && (unsigned long long)bd * (unsigned long long)bd <= 1024ULL;
}

struct Times {
    float t_int_ms = 0.f;
    float t_float_ms = 0.f;
    float t_double_ms = 0.f;
};

template <typename F>
static float time_one_call(F&& fn, cudaEvent_t start, cudaEvent_t stop) {
    CUDA_CHECK(cudaEventRecord(start));
    fn();  // call the lambda / functor
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));
    float ms = 0.f;
    CUDA_CHECK(cudaEventElapsedTime(&ms, start, stop));
    return ms;
}

int main(int argc, char** argv) {
    // Usage:
    //   ./task1_scale [block_dim_for_n_sweep]
    //
    // block_dim is for 2D blocks: block_dim x block_dim
    unsigned int block_dim_n_sweep = 16;
    if (argc > 1) block_dim_n_sweep = (unsigned int)std::atoi(argv[1]);

    if (!valid_block_dim_2d(block_dim_n_sweep)) {
        std::cerr << "Invalid block_dim=" << block_dim_n_sweep
                  << " for 2D blocks (block_dim^2 must be <= 1024). Try 16 or 32.\n";
        return 1;
    }

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    // -------------------------
    // CSV #1: n sweep 2^5..2^14
    // -------------------------
    {
        std::ofstream csv("n_sweep.csv");
        csv << "n,block_dim,int_ms,float_ms,double_ms,int_C0,int_Clast,float_C0,float_Clast,double_C0,double_Clast\n";

        for (int p = 5; p <= 14; ++p) {
            unsigned int n = 1u << p;
            std::cout << "[n_sweep] n=" << n << " block_dim=" << block_dim_n_sweep << "\n";

            // Allocate managed memory for each type
            int *Ai=nullptr, *Bi=nullptr, *Ci=nullptr;
            float *Af=nullptr, *Bf=nullptr, *Cf=nullptr;
            double *Ad=nullptr, *Bd=nullptr, *Cd=nullptr;

            size_t nn = (size_t)n * (size_t)n;

            // INT
            CUDA_CHECK(cudaMallocManaged(&Ai, nn * sizeof(int)));
            CUDA_CHECK(cudaMallocManaged(&Bi, nn * sizeof(int)));
            CUDA_CHECK(cudaMallocManaged(&Ci, nn * sizeof(int)));

            // FLOAT
            CUDA_CHECK(cudaMallocManaged(&Af, nn * sizeof(float)));
            CUDA_CHECK(cudaMallocManaged(&Bf, nn * sizeof(float)));
            CUDA_CHECK(cudaMallocManaged(&Cf, nn * sizeof(float)));

            // DOUBLE
            CUDA_CHECK(cudaMallocManaged(&Ad, nn * sizeof(double)));
            CUDA_CHECK(cudaMallocManaged(&Bd, nn * sizeof(double)));
            CUDA_CHECK(cudaMallocManaged(&Cd, nn * sizeof(double)));

            // Init on GPU
            const int threads = 256;
            const unsigned long long total = (unsigned long long)nn;
            const int blocks = (int)((total + threads - 1) / threads);

            init_matrix<int><<<blocks, threads>>>(Ai, n);
            init_matrix<int><<<blocks, threads>>>(Bi, n);
            zero_matrix<int><<<blocks, threads>>>(Ci, n);

            init_matrix<float><<<blocks, threads>>>(Af, n);
            init_matrix<float><<<blocks, threads>>>(Bf, n);
            zero_matrix<float><<<blocks, threads>>>(Cf, n);

            init_matrix<double><<<blocks, threads>>>(Ad, n);
            init_matrix<double><<<blocks, threads>>>(Bd, n);
            zero_matrix<double><<<blocks, threads>>>(Cd, n);

            CUDA_CHECK(cudaDeviceSynchronize());

            // Time matmul_1/2/3
            // Warm-up (optional, but helps stabilize timing)
            matmul_1(Ai, Bi, Ci, n, block_dim_n_sweep);
            matmul_2(Af, Bf, Cf, n, block_dim_n_sweep);
            matmul_3(Ad, Bd, Cd, n, block_dim_n_sweep);

            // Timed runs (1 each, matching your task1 behavior)
            float t1 = time_one_call([&]() { matmul_1(Ai, Bi, Ci, n, block_dim_n_sweep); }, start, stop);
            float t2 = time_one_call([&]() { matmul_2(Af, Bf, Cf, n, block_dim_n_sweep); }, start, stop);
            float t3 = time_one_call([&]() { matmul_3(Ad, Bd, Cd, n, block_dim_n_sweep); }, start, stop);

            CUDA_CHECK(cudaDeviceSynchronize());

            // Read first/last (managed memory is host-accessible after sync)
            int i0 = Ci[0];
            int ilast = Ci[nn - 1];

            float f0 = Cf[0];
            float flast = Cf[nn - 1];

            double d0 = Cd[0];
            double dlast = Cd[nn - 1];

            csv << n << "," << block_dim_n_sweep << ","
                << t1 << "," << t2 << "," << t3 << ","
                << i0 << "," << ilast << ","
                << f0 << "," << flast << ","
                << d0 << "," << dlast << "\n";

            // Free
            CUDA_CHECK(cudaFree(Ai)); CUDA_CHECK(cudaFree(Bi)); CUDA_CHECK(cudaFree(Ci));
            CUDA_CHECK(cudaFree(Af)); CUDA_CHECK(cudaFree(Bf)); CUDA_CHECK(cudaFree(Cf));
            CUDA_CHECK(cudaFree(Ad)); CUDA_CHECK(cudaFree(Bd)); CUDA_CHECK(cudaFree(Cd));
        }
    }

    // -----------------------------------------
    // CSV #2: block_dim sweep at n = 2^14
    // -----------------------------------------
    {
        unsigned int n = 1u << 14; // 16384
        std::ofstream csv("blockdim_sweep_n16384.csv");
        csv << "n,block_dim,threads_per_block,int_ms,float_ms,double_ms,int_C0,int_Clast,float_C0,float_Clast,double_C0,double_Clast\n";

        std::vector<unsigned int> block_dims = {8, 16, 32};

        for (unsigned int bd : block_dims) {
            if (!valid_block_dim_2d(bd)) continue;

            std::cout << "[blockdim_sweep] n=" << n << " block_dim=" << bd << "\n";

            size_t nn = (size_t)n * (size_t)n;

            int *Ai=nullptr, *Bi=nullptr, *Ci=nullptr;
            float *Af=nullptr, *Bf=nullptr, *Cf=nullptr;
            double *Ad=nullptr, *Bd=nullptr, *Cd=nullptr;

            CUDA_CHECK(cudaMallocManaged(&Ai, nn * sizeof(int)));
            CUDA_CHECK(cudaMallocManaged(&Bi, nn * sizeof(int)));
            CUDA_CHECK(cudaMallocManaged(&Ci, nn * sizeof(int)));

            CUDA_CHECK(cudaMallocManaged(&Af, nn * sizeof(float)));
            CUDA_CHECK(cudaMallocManaged(&Bf, nn * sizeof(float)));
            CUDA_CHECK(cudaMallocManaged(&Cf, nn * sizeof(float)));

            CUDA_CHECK(cudaMallocManaged(&Ad, nn * sizeof(double)));
            CUDA_CHECK(cudaMallocManaged(&Bd, nn * sizeof(double)));
            CUDA_CHECK(cudaMallocManaged(&Cd, nn * sizeof(double)));

            const int threads = 256;
            const unsigned long long total = (unsigned long long)nn;
            const int blocks = (int)((total + threads - 1) / threads);

            init_matrix<int><<<blocks, threads>>>(Ai, n);
            init_matrix<int><<<blocks, threads>>>(Bi, n);
            zero_matrix<int><<<blocks, threads>>>(Ci, n);

            init_matrix<float><<<blocks, threads>>>(Af, n);
            init_matrix<float><<<blocks, threads>>>(Bf, n);
            zero_matrix<float><<<blocks, threads>>>(Cf, n);

            init_matrix<double><<<blocks, threads>>>(Ad, n);
            init_matrix<double><<<blocks, threads>>>(Bd, n);
            zero_matrix<double><<<blocks, threads>>>(Cd, n);

            CUDA_CHECK(cudaDeviceSynchronize());

            // Warm-up
            matmul_1(Ai, Bi, Ci, n, bd);
            matmul_2(Af, Bf, Cf, n, bd);
            matmul_3(Ad, Bd, Cd, n, bd);

            float t1 = time_one_call([&]() { matmul_1(Ai, Bi, Ci, n, bd); }, start, stop);
            float t2 = time_one_call([&]() { matmul_2(Af, Bf, Cf, n, bd); }, start, stop);
            float t3 = time_one_call([&]() { matmul_3(Ad, Bd, Cd, n, bd); }, start, stop);

            CUDA_CHECK(cudaDeviceSynchronize());

            int i0 = Ci[0];
            int ilast = Ci[nn - 1];
            float f0 = Cf[0];
            float flast = Cf[nn - 1];
            double d0 = Cd[0];
            double dlast = Cd[nn - 1];

            csv << n << "," << bd << "," << (bd * bd) << ","
                << t1 << "," << t2 << "," << t3 << ","
                << i0 << "," << ilast << ","
                << f0 << "," << flast << ","
                << d0 << "," << dlast << "\n";

            CUDA_CHECK(cudaFree(Ai)); CUDA_CHECK(cudaFree(Bi)); CUDA_CHECK(cudaFree(Ci));
            CUDA_CHECK(cudaFree(Af)); CUDA_CHECK(cudaFree(Bf)); CUDA_CHECK(cudaFree(Cf));
            CUDA_CHECK(cudaFree(Ad)); CUDA_CHECK(cudaFree(Bd)); CUDA_CHECK(cudaFree(Cd));
        }
    }

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));

    std::cout << "Wrote n_sweep.csv and blockdim_sweep_n16384.csv\n";
    return 0;
}