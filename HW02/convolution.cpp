
#include <cstddef>
#include "convolution.h"

void convolve(const float *image, float *output, std::size_t n, const float *mask, std::size_t m)
{
    int half_m = (m - 1) / 2;
    for( int x = 0; x < n; ++x )
    {
        
        for( int y = 0; y < n; ++y )
        {
            float sum = 0.0f;
            //output at the current pixel is w[i][j]*f[x+i-(m-1)/2, y+j-(m-1)/2]
            for( int i = 0; i < m; ++i )
            {
                int image_i= (x + i - half_m);
                int image_i_x_n = image_i * n;
                for( int j = 0; j < m; ++j )
                {
                    int image_j = y + j - half_m;
                    float val = 1.0f;  // default for out-of-bounds
                    if (image_i >= 0 && image_i < (int)n && image_j >= 0 && image_j < (int)n) {
                        val = image[image_i_x_n + image_j];
                    }
                    sum += mask[i * m + j] * val;
                }
            }
            output[x * n + y] = sum;
        }
    }
}