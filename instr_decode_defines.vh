`define NO_LOCKOUT    2'h0
`define ALU_LOCKOUT   2'h1
`define LOAD_LOCKOUT  2'h2

`define SEL_IM        1'b0
`define SEL_REG       1'b1

`define ALU_FUNCT_W   10
`define ALU_NOP       10'b0000000000             
`define ALU_ADD       10'b0000000001
`define ALU_SUB       10'b0000000010
`define ALU_AND       10'b0000000100
`define ALU_OR        10'b0000001000
`define ALU_XOR       10'b0000010000
`define ALU_SLT       10'b0000100000
`define ALU_SLTU      10'b0001000000
`define ALU_SLL       10'b0010000000
`define ALU_SRL       10'b0100000000
`define ALU_SRA       10'b1000000000      

`define BR_FUNCT_W    7
`define BR_NOP        7'b0000000 
`define BR_BNE        7'b0000001
`define BR_BEQ        7'b0000010
`define BR_BLT        7'b0000100
`define BR_BLTU       7'b0001000
`define BR_BGE        7'b0010000
`define BR_BGEU       7'b0100000
`define BR_JUMP       7'b1000000 

`define MEM_FUNCT_W   8
`define MEM_NOP       8'b00000000       
`define MEM_LB        8'b00000001      
`define MEM_LH        8'b00000010      
`define MEM_LW        8'b00000100      
`define MEM_LBU       8'b00001000       
`define MEM_LHU       8'b00010000       
`define MEM_SB        8'b00100000      
`define MEM_SH        8'b01000000      
`define MEM_SW        8'b10000000      



