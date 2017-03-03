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
all: futhark-benchmarks results/vanilla.json results/segredomap.json \
	results/2pow26-sum results/2pow26-segsum-segredomap results/2pow26-segsum-vanilla \
	results/2pow20-sum results/2pow20-segsum-segredomap results/2pow20-segsum-vanilla \
	results/2pow26-mss results/2pow26-segmss-segredomap results/2pow26-segmss-vanilla \
	results/2pow20-mss results/2pow20-segmss-segredomap results/2pow20-segmss-vanilla

################################################################################

results/%.json: bin-%
	@mkdir -p results
	bin-$*/futhark-bench --compiler=bin-$*/futhark-opencl -r 10 --json=$@ ${BENCHMARKS}

################################################################################

results/2pow%-sum:
	make -C sum all
	./runtest.sh -1 -p 2 -r ${RUNS} -n $* sum/f32-reduce-comm.vanilla.bin sum/f32-reduce-nocomm.vanilla.bin > $@

results/2pow%-segsum-segredomap:
	make -C sum all
	./runtest.sh -2 -p 2 -r ${RUNS} -n $* sum/f32-segreduce-comm.segredomap.bin sum/f32-segreduce-nocomm.segredomap.bin > $@

results/2pow%-segsum-vanilla:
	make -C sum all
	./runtest.sh -2 -p 2 -r ${RUNS} -n $* sum/f32-segreduce-comm.vanilla.bin sum/f32-loopinmap.vanilla.bin > $@

################################################################################

results/2pow%-mss:
	make -C mss all
	./runtest.sh -1 -p 2 -r ${RUNS} -n $* mss/mss.vanilla.bin > $@

results/2pow%-segmss-segredomap:
	make -C mss all
	./runtest.sh -2 -p 2 -r ${RUNS} -n $* mss/segmss.segredomap.bin > $@

results/2pow%-segmss-vanilla:
	make -C mss all
	./runtest.sh -2 -p 2 -r ${RUNS} -n $* mss/segmss.vanilla.bin > $@

################################################################################

bin-vanilla:
	@echo "you must provide binaries for the vanilla futhark in '$@'"
	exit 1

bin-segredomap:
	@echo "you must provide binaries for the segmented-redomap enabled futhark in '$@'"
	exit 1

futhark-benchmarks:
	git clone --depth 1 https://github.com/HIPERFIT/futhark-benchmarks.git

.PHONY: clean
clean:
	@echo "this clean function is as good at cleaning up as a teenager.. sorry"
#	rm -rf futhark-benchmarks
	make -C sum clean
	make -C mss clean
	rm -rf results
