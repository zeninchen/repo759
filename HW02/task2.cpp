
#include <iostream>
#include "convolution.h"
#include <string>
int main(int argc, char* argv[])
{
    int n;
    int m;
    if( argc < 2 ) {
        n=4;
    }
    else {
        std::string input = argv[1];
        n = std::stoi(argv[1]);
    }
    if(argc < 3 ) {
        m=3;
    }
    else {
        std::string input = argv[2];
        m = std::stoi(argv[2]);
    }
    //f= 
    // 1 3 4 8
    // 6 5 2 4
    // 3 4 6 8
    // 1 4 5 2
    //for testing purposes, we will create the image and fixed values above
    float *image = new float[n*n];
    image[0]=1; image[1]=3; image[2]=4; image[3]=8;
    image[4]=6; image[5]=5; image[6]=2; image[7]=4;
    image[8]=3; image[9]=4; image[10]=6; image[11]=8;
    image[12]=1; image[13]=4; image[14]=5; image[15]=2;
    // float *image = new float[n*n];
    // for(int i = 0; i < n*n; i++) {
    //     image[i] = static_cast<float>(rand()) / RAND_MAX * 10.0f; // random values between 0 and 10
    // }
    //w= 
    //0 0 1
    //0 1 0
    //1 0 0
    float *mask = new float[m*m];
    mask[0]=0; mask[1]=0; mask[2]=1;
    mask[3]=0; mask[4]=1; mask[5]=0;
    mask[6]=1; mask[7]=0; mask[8]=0;

    float *output = new float[n*n];
    convolve(image, output, n, mask, m);
    //print out the output image
    for(int i = 0; i < n; i++) {
        for(int j = 0; j < n; j++) {
            std::cout << output[i*n + j] << " ";
        }
        std::cout << std::endl;
    }

    //deallocate memory
    delete[] image;
    delete[] mask;
    delete[] output;


    return 0;
}