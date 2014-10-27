
`define NUM_EX_FUNCTS   10
`define EX_FUNCT_W      10
`define EX_NOP          10'b0000000000
`define EX_ADD          10'b0000000001
`define EX_SUB          10'b0000000010
`define EX_OR           10'b0000000100
`define EX_XOR          10'b0000001000
`define EX_AND          10'b0000010000
`define EX_STL          10'b0000100000
`define EX_STLU         10'b0001000000
`define EX_SLL          10'b0010000000
`define EX_SRL          10'b0100000000
`define EX_SRA          10'b1000000000

`define NUM_LD_FUNCTS   5
`define LD_FUNCT_W      5
`define LD_NOP          5'b00000
`define LD_B            5'b00001
`define LD_H            5'b00010
`define LD_W            5'b00100
`define LD_BU           5'b01000
`define LD_HU           5'b10000

`define NUM_ST_FUNCTS   3
`define ST_FUNCT_W      3
`define ST_NOP          3'b000
`define ST_B            3'b001
`define ST_H            3'b010
`define ST_W            3'b100

