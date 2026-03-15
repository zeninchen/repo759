#include "msort.h"
#include <algorithm>
#include <vector>

// merge two sorted halves
void merge(int* arr, int left, int mid, int right)
{
    int n1 = mid - left + 1;
    int n2 = right - mid;

    std::vector<int> L(n1);
    std::vector<int> R(n2);

    for(int i = 0; i < n1; i++)
        L[i] = arr[left + i];

    for(int j = 0; j < n2; j++)
        R[j] = arr[mid + 1 + j];

    int i = 0, j = 0, k = left;

    while(i < n1 && j < n2)
    {
        if(L[i] <= R[j])
            arr[k++] = L[i++];
        else
            arr[k++] = R[j++];
    }

    while(i < n1)
        arr[k++] = L[i++];

    while(j < n2)
        arr[k++] = R[j++];
}


// recursive merge sort
void msort_recursive(int* arr, int left, int right, std::size_t threshold)
{
    //base case 1
    if(left >= right)
        return;

    int size = right - left + 1;

    //base case 2
    if(size < threshold)
    {
        std::sort(arr + left, arr + right + 1);
        return;
    }

    int mid = left + (right - left) / 2;

    //task parallelism
    #pragma omp task
    msort_recursive(arr, left, mid, threshold);

    #pragma omp task
    msort_recursive(arr, mid + 1, right, threshold);

    #pragma omp taskwait

    merge(arr, left, mid, right);
}


// main function required by header
void msort(int* arr, const std::size_t n, const std::size_t threshold)
{
    #pragma omp parallel
    {
        #pragma omp single
        {
            msort_recursive(arr, 0, n - 1, threshold);
        }
    }
}