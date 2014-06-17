compile: 
	iverilog -DTB -o core.out riscv_core.v -s riscv_core_tb

clean:
	rm -rfv core.out a.out test.vcd
