`define EX_FUNCT_W  10
`define EX_NOP      10'b0000000000
`define EX_ADD      10'b0000000001
`define EX_SUB      10'b0000000010
`define EX_OR       10'b0000000100
`define EX_XOR      10'b0000001000
`define EX_AND      10'b0000010000
`define EX_STL      10'b0000100000
`define EX_STLU     10'b0001000000
`define EX_SLL      10'b0010000000
`define EX_SRL      10'b0100000000
`define EX_SRA      10'b1000000000

`define MEM_FUNCT_W  8
`define MEM_NOP      8'b00000000
`define MEM_LB       8'b00000001
`define MEM_LH       8'b00000010
`define MEM_LW       8'b00000100
`define MEM_LBU      8'b00001000
`define MEM_LHU      8'b00010000
`define MEM_SB       8'b00100000
`define MEM_SH       8'b01000000
`define MEM_SW       8'b10000000

`define LD_FUNCT_W  5
`define LD_NOP      5'b00000
`define LD_LB       5'b00001
`define LD_LH       5'b00010
`define LD_LW       5'b00100
`define LD_LBU      5'b01000
`define LD_LHU      5'b10000

