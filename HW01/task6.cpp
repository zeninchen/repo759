#include <iostream>
#include <string>

int main(int argc, char* argv[]) {
    int n;
    if(argc < 2) {
        n=6;
    }
    else {
        std::string input = argv[1];
        //convert the first character to integer
        n = static_cast<int>(input[0]);
    }
    
    for(int i = 0; i <= n; ++i) {
        printf("%d ",i);
    }
    printf("\n");
    for (int i = n; i >= 0; --i) {
        std::cout << i << " ";
    }
    printf("\n");
    return 0;
}