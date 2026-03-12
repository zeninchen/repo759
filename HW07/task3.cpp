#include <iostream>
#include <omp.h>

int main() {
    omp_set_num_threads(4);

    
        int tid = omp_get_thread_num();
        int nthreads = omp_get_num_threads();

        #pragma omp single
        {
            std::cout << "Number of threads: " << nthreads << "\n";
        }
        #pragma omp parallel
        {
            std::cout << "I am thread No. " << tid << "\n";
        }
        #pragma omp for
        for (int a = 1; a <= 8; ++a) {
            long long fact = 1;
            for (int i = 1; i <= a; ++i) {
                fact *= i;
            }
            std::cout << a << "!=" << fact << "\n";
        }
    

    return 0;
}