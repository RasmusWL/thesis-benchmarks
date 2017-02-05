FUTFILES := ${wildcard *.fut}
BINS := ${FUTFILES:.fut=.bin}

.PHONY: segredomap
segredomap: FUT_OPENCL=../../bin-segredomap/futhark-opencl
segredomap: ../../bin-segredomap ${BINS}


.PHONY: vanilla
vanilla: FUT_OPENCL=../../bin-vanilla/futhark-opencl
vanilla: ../../bin-vanilla ${BINS}

%.bin: %.fut
	$(FUT_OPENCL) -o $@ $<

.PHONY: clean
clean:
	rm -rf $(BINS) ${FUTFILES:.fut=.c}
