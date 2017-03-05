# Futhark benchmarks for my master's thesis

This will contain benchmarks for my master's thesis on segmented redomap.

Inspired by the benchmarks for Futhark papers (like https://github.com/HIPERFIT/futhark-pldi17/).

# Running benchmarks

This repo slowly got filled with all kinds of other files that I used in my
evaluation. To run the *actual* benchmarks from my thesis, do the following steps:

1. Install `stack` if it is not already present on your system: https://www.haskellstack.org/

2. Make a clone of the Futhark compiler repo from https://github.com/HIPERFIT/futhark

3. `cd` into the futhark directory

4. run `git reset --hard dd2d6651fd9ae9de6fcfe408ed02d54e4976b07e` to get the version of the compiler I used.

5. run `stack setup`

6. run `<path/to/thesis-benchmarks>/build-futhark.sh` -- this will build all
   four versions of the Futhark compiler I used in my thesis.

7. cd into the top level of this repo

8. run `make futhark-benchmarks`. This will get *only* the newest version of the
   futhark-benchmarks repo. If significant changes have been made, thereby
   making the compiler not work, you should manually get the benchmarks from the
   commit id `c5ae760d60749f08968be32c339e49dde3e94b1b`

9. run `make bench-res` This will run all the benchmarks used in my thesis, once
   for every version of the compiler (it will complain about the N-body
   benchmark not being able to be compiled, and for the versioned-code it will
   not be able to compute MRI-Q small.)

10. After waiting for some time, you should have , but will produce 4 json files
   in the `results` directory. These contain the runtime for all the benchmarks
   used in my thesis.
