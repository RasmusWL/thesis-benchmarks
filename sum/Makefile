FUTFILES := ${wildcard *.fut}
BINS := ${FUTFILES:.fut=.bin}
SEGREDOMAP_BINS := ${BINS:.bin=.segredomap.bin}
VANILLA_BINS := ${BINS:.bin=.vanilla.bin}
ALL_BINS := ${SEGREDOMAP_BINS} ${VANILLA_BINS}

.PHONY: all
all: segredomap vanilla

.PHONY: segredomap
segredomap: FUT_OPENCL=../bin-segredomap/futhark-opencl
segredomap: ../bin-segredomap ${SEGREDOMAP_BINS}


.PHONY: vanilla
vanilla: FUT_OPENCL=../bin-vanilla/futhark-opencl
vanilla: ../bin-vanilla ${VANILLA_BINS}

%.vanilla.bin: %.fut
	$(FUT_OPENCL) -o $@ $<

%.segredomap.bin: %.fut
	$(FUT_OPENCL) -o $@ $<

.PHONY: clean
clean:
	rm -f ${ALL_BINS} ${ALL_BINS:.bin=.c}
