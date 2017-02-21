/******************************************************************************
 * Copyright (c) 2013, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/******************************************************************************
 *
 * Original code and text by Sean Baxter, NVIDIA Research See
 * http://nvlabs.github.io/moderngpu for repository and documentation.
 *
 ******************************************************************************/

#include "kernels/segreducecsr.cuh"

using namespace mgpu;

enum TestType {
        TestTypeNormal,
        TestTypeIndirect,
        TestTypePreprocess
};

// count = total number of elements
//
template<typename T>
void TestCsrReduce(int count, int segSize, int numIterations,
        TestType testType, bool supportEmpty, CudaContext& context) {

#ifdef _DEBUG
        numIterations = 1;
#endif

        std::vector<int> segCountsHost, csrHost;
        int total = 0;
        int numValidRows = 0;
        while(total < count) {
                numValidRows += 0 != segSize;
                csrHost.push_back(total ? (csrHost.back() + segCountsHost.back()) : 0);
                segCountsHost.push_back(segSize);
                total += segSize;
        }
        int numRows = (int)segCountsHost.size();

        // FIXME: This one is only used for the indirect test. Not sure what it
        // does.
        std::vector<int> sourcesHost(numRows);
        for(int i = 0; i < numRows; ++i)
                sourcesHost[i] = Rand(0, max(0, count - segSize));

        MGPU_MEM(int) csrDevice = context.Malloc(csrHost);
        MGPU_MEM(int) sourcesDevice = context.Malloc(sourcesHost);

        // Generate random ints as input.
        std::vector<T> dataHost(count);
        for(int i = 0; i < count; ++i)
                dataHost[i] = (T)Rand(1, 9);
        MGPU_MEM(T) dataDevice = context.Malloc(dataHost);

        MGPU_MEM(T) resultsDevice = context.Malloc<T>(numRows);

        std::auto_ptr<SegReducePreprocessData> preprocessData;
        SegReduceCsrPreprocess<T>(count, csrDevice->get(), numRows, supportEmpty,
                &preprocessData, context);

        context.Start();
        for(int it = 0; it < numIterations; ++it) {
                if(TestTypeNormal == testType)
                        SegReduceCsr(dataDevice->get(), csrDevice->get(), count, numRows,
                                supportEmpty, resultsDevice->get(), (T)0, mgpu::plus<T>(),
                                context);
                else if(TestTypeIndirect == testType)
                        IndirectReduceCsr(dataDevice->get(), csrDevice->get(),
                                sourcesDevice->get(), count, numRows, supportEmpty,
                                resultsDevice->get(), (T)0, mgpu::plus<T>(), context);
                else
                        SegReduceApply(*preprocessData, dataDevice->get(), (T)0,
                                mgpu::plus<T>(), resultsDevice->get(), context);
        }
        double elapsed = context.Split();

        printf("%12.3lf microseconds\n", elapsed * 1e6);

        std::vector<T> resultsHost;
        resultsDevice->ToHost(resultsHost);

        std::vector<T> resultsRef(numRows);
        for(int row = 0; row < numRows; ++row) {
                int begin = csrHost[row];
                int end = (row + 1 < numRows) ? csrHost[row + 1] : count;
                int count = end - begin;

                begin = (TestTypeIndirect == testType) ? sourcesHost[row] : begin;
                end = begin + count;

                T x = 0;
                for(int i = begin; i < end; ++i)
                        x = x + dataHost[i];

                resultsRef[row] = x;
        }

        for(int i = 0; i < numRows; ++i) {
                if(resultsRef[i] != resultsHost[i]) {
                        printf("REDUCTION ERROR ON SEGMENT %d\n", i);
                        exit(0);
                }
        }
}

const int RWL_NUM_ITERATIONS = 10;

template<typename T>
void BenchmarkSegReduce(TestType testType, bool supportEmpty,
                         CudaContext& context, int THEPOWER) {

        const char* typeString;
        if(TestTypeNormal == testType) typeString = "seg";
        else if(TestTypeIndirect == testType) typeString = "indirect";
        else typeString = "preprocess";

        int start=0;
        int end=THEPOWER;

        int total_elems = 1 << THEPOWER;

        printf("Benchmarking %s-reduce type %s. TotalElems=%i\n",
               typeString, TypeIdName<T>(), total_elems);

        for(int powy=start; powy<=end; powy++) {
            int powx = THEPOWER-powy;

//            int num_segments = 1 << powy;
            int segment_size = 1 << powx;

            char buf[16];
            snprintf(buf, 16, "2^%i 2^%i", powy, powx);

            printf("%15s", buf);

            TestCsrReduce<T>(total_elems, segment_size, RWL_NUM_ITERATIONS, testType,
                             supportEmpty, context);

            context.GetAllocator()->Clear();
        }
        printf("\n");
}

int main(int argc, char** argv) {
        ContextPtr context = CreateCudaDevice(argc, argv, true);

        bool supportEmpty = false;
        TestType testType = TestTypeNormal;

        BenchmarkSegReduce<float>(testType, supportEmpty, *context, 20);
        BenchmarkSegReduce<float>(testType, supportEmpty, *context, 26);

        return 0;
}
