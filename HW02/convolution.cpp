
#include <cstddef>
#include "convolution.h"

void convolve(const float *image, float *output, std::size_t n, const float *mask, std::size_t m)
{
    int half_m = (m - 1) / 2;
    for( int x = 0; x < (int)n; ++x )
    {
        
        for( int y = 0; y < (int)n; ++y )
        {
            float sum = 0.0f;
            //output at the current pixel is w[i][j]*f[x+i-(m-1)/2, y+j-(m-1)/2]
            for (int i = 0; i < (int)m; ++i) {
                int ii = x + i - half_m;
                bool in_i = (ii >= 0 && ii < (int)n);

                for (int j = 0; j < (int)m; ++j) {
                    int jj = y + j - half_m;
                    bool in_j = (jj >= 0 && jj < (int)n);

                    float val;
                    if (in_i && in_j) {
                        val = image[ii * n + jj];
                    } else if (in_i ^ in_j) {
                        val = 1.0f;          // edge (not corner)
                    } else {
                        val = 0.0f;          // corner
                    }

                    sum += mask[i * m + j] * val;
                }
            }
            output[x * n + y] = sum;
        }
    }
}