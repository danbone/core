WAVES ?= 1

SRCS  := ../src/test/riscv_ex_pipe_tb.v  \
	 ../src/lib/rand_staller.v      \
	 ../src/lib/sync_fifo.v  	\
	 ../src/main/riscv_ex_pipe.v     \
	 ../src/main/riscv_ex.v          \
	 ../src/main/riscv_mem.v

CARGS := -I ../src/main


ifeq ($(WAVES), 1)
CARGS += -DWAVES
endif

all:
	iverilog $(CARGS) $(SRCS)

clean:
	rm -v a.out 
	rm -rf waves.vcd
