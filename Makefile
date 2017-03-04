RUNS=10

# I found the useful benchmarks by compiling everything, and checking which ones
# actually used my segmented redomap. Some of them are only turned on if
# version_code is used, but they currently seem to give worse performance
#
# find futhark-benchmarks -name '*.c' | xargs grep -l "segmented_redomap" | sed -e 's/\.c/.fut/'

BENCHMARKS =
BENCHMARKS += futhark-benchmarks/finpar/OptionPricing.fut
BENCHMARKS += futhark-benchmarks/parboil/tpacf/tpacf.fut
BENCHMARKS += futhark-benchmarks/rodinia/backprop/backprop.fut
BENCHMARKS += futhark-benchmarks/rodinia/kmeans/kmeans.fut

USE_VERSIONED_CODE=YES

ifdef USE_VERSIONED_CODE
BENCHMARKS += futhark-benchmarks/accelerate/crystal/crystal.fut
BENCHMARKS += futhark-benchmarks/accelerate/nbody/nbody.fut
BENCHMARKS += futhark-benchmarks/parboil/mri-q/mri-q.fut
endif

# TODO: if problems with make removing intermediate files, try adding
# .SECONDARY:

# $@ = the target (left of colon)
# $* = the % in the target
# $< = the first prerequisite
# $^ = the list of all prerequisite

.PHONY: all
all: bench-res sum-res mss-res

################################################################################

.PHONY: bench-res
bench-res: futhark-benchmarks results/vanilla.json results/segredomap.json \
	results/versioned.json results/versionedANDsegredomap.json

results/%.json: bin-%
	@mkdir -p results
# ignore errors when running the benchmark, we just want to json output
	-bin-$*/futhark-bench --compiler=bin-$*/futhark-opencl -r 10 --json=$@ ${BENCHMARKS}

bin-vanilla:
	@echo "you must provide binaries for the vanilla futhark in '$@'"
	exit 1

bin-segredomap:
	@echo "you must provide binaries for the segmented-redomap enabled futhark in '$@'"
	exit 1

bin-versioned:
	@echo "you must provide binaries for the versioned code futhark in '$@'"
	exit 1

bin-versionedANDsegredomap:
	@echo "you must provide binaries for the versionedANDsegredomap code futhark in '$@'"
	exit 1

futhark-benchmarks:
	git clone --depth 1 https://github.com/HIPERFIT/futhark-benchmarks.git


################################################################################

.PHONY: sum-res
sum-res: results/2pow26-sum results/2pow26-segsum-segredomap results/2pow26-segsum-vanilla \
	results/2pow20-sum results/2pow20-segsum-segredomap results/2pow20-segsum-vanilla


sum/%.vanilla.bin: sum/%.fut
	make -C sum all

sum/%.segredomap.bin: sum/%.fut
	make -C sum all

results/2pow%-sum: sum/f32-reduce-comm.vanilla.bin sum/f32-reduce-nocomm.vanilla.bin
	make -C sum all
	./runtest.sh -1 -p 2 -r ${RUNS} -n $* $^ > $@

results/2pow%-segsum-segredomap: sum/f32-segreduce-comm.segredomap.bin sum/f32-segreduce-nocomm.segredomap.bin
	make -C sum all
	./runtest.sh -2 -p 2 -r ${RUNS} -n $* $^ > $@

results/2pow%-segsum-vanilla: sum/f32-segreduce-comm.vanilla.bin sum/f32-loopinmap.vanilla.bin
	make -C sum all
	./runtest.sh -2 -p 2 -r ${RUNS} -n $* $^ > $@

################################################################################

.PHONY: mss-res
mss-res: results/2pow26-mss results/2pow26-segmss-segredomap results/2pow26-segmss-vanilla \
	results/2pow20-mss results/2pow20-segmss-segredomap results/2pow20-segmss-vanilla

mss/%.vanilla.bin: mss/%.fut
	make -C mss all

mss/%.segredomap.bin: mss/%.fut
	make -C mss all

results/2pow%-mss: mss/mss.vanilla.bin
	make -C mss all
	./runtest.sh -d i32 -1 -p 2 -r ${RUNS} -n $* $^  > $@

results/2pow%-segmss-segredomap: mss/segmss.segredomap.bin
	make -C mss all
	./runtest.sh -d i32 -2 -p 2 -r ${RUNS} -n $* $^ > $@

results/2pow%-segmss-vanilla: mss/segmss.vanilla.bin mss/loopinmap.vanilla.bin
	make -C mss all
	./runtest.sh -d i32 -2 -p 2 -r ${RUNS} -n $* $^ > $@

################################################################################

.PHONY: clean
clean:
	@echo "this clean function is as good at cleaning up as a teenager.. sorry"
#	rm -rf futhark-benchmarks
	make -C sum clean
	make -C mss clean
	rm -rf results
