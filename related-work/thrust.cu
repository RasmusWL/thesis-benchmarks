// https://github.com/thrust/thrust/blob/8551c97870cd722486ba7834ae9d867f13e299ad/examples/sum_rows.cu

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/generate.h>
#include <thrust/reduce.h>
#include <thrust/functional.h>
#include <thrust/random.h>
#include <iostream>

// convert a linear index to a row index
template <typename T>
struct linear_index_to_row_index : public thrust::unary_function<T,T>
{
  T C; // number of columns

  __host__ __device__
  linear_index_to_row_index(T C) : C(C) {}

  __host__ __device__
  T operator()(T i)
  {
    return i / C;
  }
};

const int NUM_REPS = 10;

cudaEvent_t startEvent, stopEvent;
float ms;

int test(thrust::device_vector<int>& array, int R, int C)
{
  // int R = 5;     // number of rows
  // int C = 8;     // number of columns


  // allocate storage for row sums and indices
  thrust::device_vector<int> row_sums(R);
  thrust::device_vector<int> row_indices(R);

  thrust::reduce_by_key
      (thrust::make_transform_iterator(thrust::counting_iterator<int>(0), linear_index_to_row_index<int>(C)),
       thrust::make_transform_iterator(thrust::counting_iterator<int>(0), linear_index_to_row_index<int>(C)) + (R*C),
       array.begin(),
       row_indices.begin(),
       row_sums.begin(),
       thrust::equal_to<int>(),
       thrust::plus<int>());

  cudaEventRecord(startEvent, 0);

  for (int i = 0; i < NUM_REPS; i++) {
      // compute row sums by summing values with equal row indices
      thrust::reduce_by_key
          (thrust::make_transform_iterator(thrust::counting_iterator<int>(0), linear_index_to_row_index<int>(C)),
           thrust::make_transform_iterator(thrust::counting_iterator<int>(0), linear_index_to_row_index<int>(C)) + (R*C),
           array.begin(),
           row_indices.begin(),
           row_sums.begin(),
           thrust::equal_to<int>(),
           thrust::plus<int>());
  }

  cudaEventRecord(stopEvent, 0);
  cudaEventSynchronize(stopEvent);
  cudaEventElapsedTime(&ms, startEvent, stopEvent);

  printf("%15.0f", (ms / NUM_REPS) * 1e3 );

  return 0;
}

void dothatbench(int THEPOWER, int start) {

//        int start=0;
        int end=THEPOWER;

        int total_elems = 1 << THEPOWER;

        printf("Benchmarking Thrust %i.%i.%i TotalElems=%i\n",
               THRUST_MAJOR_VERSION, THRUST_MINOR_VERSION, THRUST_SUBMINOR_VERSION, total_elems);

        thrust::default_random_engine rng;
        thrust::uniform_int_distribution<int> dist(10, 99);

        // initialize data
        thrust::device_vector<int> array(total_elems);
        for (size_t i = 0; i < array.size(); i++)
            array[i] = dist(rng);

        printf("initialized array\n");

        for(int powy=start; powy<=end; powy++) {
            int powx = THEPOWER-powy;

            int num_segments = 1 << powy;
            int segment_size = 1 << powx;

            char buf[16];
            snprintf(buf, 16, "2^%i 2^%i", powy, powx);
            printf("%15s", buf);

            test(array, num_segments, segment_size);
        }
}

int main(int argc, char** argv) {

    cudaEventCreate(&startEvent);
    cudaEventCreate(&stopEvent);

    dothatbench(20, 0);
    dothatbench(26, 0);

    cudaEventDestroy(startEvent);
    cudaEventDestroy(stopEvent);
}
