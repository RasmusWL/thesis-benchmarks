NVCC = nvcc

MODERNGPUPATH := moderngpu-src

INCLUDES := -I $(MODERNGPUPATH)/include

GENCODE_SM20 := -gencode arch=compute_20,code=sm_20
GENCODE_SM30 := -gencode arch=compute_30,code=sm_30
GENCODE_SM35 := -gencode arch=compute_35,code=sm_35

GENCODE_FLAGS := $(GENCODE_SM20) $(GENCODE_SM35)

# Put any value here to turn them on
CPP11 :=
OPTIMIZE :=

NVCCFLAGS =
NVCCFLAGS += $(INCLUDES)
NVCCFLAGS += $(GENCODE_FLAGS)

ifdef OPTIMIZE
	NVCCFLAGS += -O3
endif

ifdef CPP11
	NVCCFLAGS += -std=c++11
endif

# If using CPP11, we must also do the other funky flags to make my ubuntu work
HOSTNAME := $(shell hostname)
ifeq ($(HOSTNAME), RasmusWL-S430)
# CUDA 7.5.17 on my laptop (Ubuntu 16.04) needs these flags
	ifdef CPP11
		NVCCFLAGS += -D_MWAITXINTRIN_H_INCLUDED
	endif
	ifdef OPTIMIZE
		NVCCFLAGS += -D_FORCE_INLINES
	endif
endif

BINS := moderngpu

.PHONY: all
all: $(BINS)


moderngpu: moderngpu.cu $(MODERNGPUPATH)
	$(NVCC) $(NVCCFLAGS) -o $@ $< $(MODERNGPUPATH)/src/mgpucontext.cu $(MODERNGPUPATH)/src/mgpuutil.cpp

#moderngpu: $(MODERNGPUPATH)

# moderngpu: moderngpu.o mgpucontext.o mgpuutil.o
# 	nvcc $(NVCCFLAGS) -o $@ $+

# moderngpu.o: moderngpu.cu
# 	nvcc $(NVCCFLAGS) -o $@ -c $<

# mgpucontext.o: $(MODERNGPUPATH)/src/mgpucontext.cu
# 	nvcc $(NVCCFLAGS) -o $@ -c $<

# mgpuutil.o: $(MODERNGPUPATH)/src/mgpuutil.cpp
# 	nvcc $(NVCCFLAGS) -o $@ -c $<



# .SECONDEXPANSION:
# $(BINS): $$@.cu
# 	$(NVCC) $(NVCCFLAGS) -o $@ $<


# Fetch moderngpu from the last commit before 2.0
$(MODERNGPUPATH):
	git clone https://github.com/moderngpu/moderngpu.git $(MODERNGPUPATH) && \
	cd $(MODERNGPUPATH) && \
	git reset --hard 1c1cc9e23463bf4e82bad29a3ab34a4ddac99e3d

.PHONY: clean
clean:
	rm -f moderngpu
