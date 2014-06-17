#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <stdbool.h>

#define OPCODE_IMM      0b0010011
#define OPCODE_LUI      0b0110111
#define OPCODE_AUIPC    0b0010111
#define OPCODE_OP       0b0110011
#define OPCODE_JAL      0b1101111
#define OPCODE_JALR     0b1100111
#define OPCODE_BRANCH   0b1100011
#define OPCODE_LOAD     0b0000011
#define OPCODE_STORE    0b0100011
#define OPCODE_MISC_MEM 0b0001111
#define OPCODE_SYSTEM   0b1110011

#define FUNCT_JALR_RAW  0b0000000000
#define FUNCT_SB_RAW    0b0000000000
#define FUNCT_SH_RAW    0b0000000001
#define FUNCT_SW_RAW    0b0000000010
#define FUNCT_LB_RAW    0b0000000000
#define FUNCT_LH_RAW    0b0000000001
#define FUNCT_LW_RAW    0b0000000010
#define FUNCT_LBU_RAW   0b0000000100
#define FUNCT_LHU_RAW   0b0000000101
#define FUNCT_BEQ_RAW   0b0000000000
#define FUNCT_BNE_RAW   0b0000000001
#define FUNCT_BLT_RAW   0b0000000100
#define FUNCT_BGE_RAW   0b0000000101
#define FUNCT_BLTU_RAW  0b0000000110
#define FUNCT_BGEU_RAW  0b0000000111
#define FUNCT_ADD_RAW   0b0000000000
#define FUNCT_SUB_RAW   0b0100000000
#define FUNCT_SLL_RAW   0b0000000001
#define FUNCT_SLT_RAW   0b0000000010
#define FUNCT_SLTU_RAW  0b0000000011
#define FUNCT_XOR_RAW   0b0000000100
#define FUNCT_SRL_RAW   0b0000000101
#define FUNCT_SRA_RAW   0b0100000101
#define FUNCT_OR_RAW    0b0000000110
#define FUNCT_AND_RAW   0b0000000111

typedef enum {
    ADDI,
    ORI,
    XORI,
    ANDI,
    SLTI,
    SLTUI,
    SLLI,
    SRLI,
    SRAI,
    LUI,
    AUIPC,
    ADD,
    SUB,
    OR,
    XOR,
    AND,
    SLT,
    SLTU,
    SLL,
    SRL,
    SRA,
    JALR,
    JAL,
    SB,
    SH,
    SW,
    LB,
    LH,
    LW,
    LBU,
    LHU,
    BEQ,
    BNE,
    BLT,
    BLTU,
    BGE,
    BGEU
} instr_e;

typedef enum {
    BR_BEQ,
    BR_BNE,
    BR_BLT,
    BR_BGE,
    BR_BLTU,
    BR_BGEU,
    BR_JUMP
} branch_funct_e;

typedef enum {
    ALU_ADD,
    ALU_SUB,
    ALU_AND,
    ALU_OR, 
    ALU_XOR,
    ALU_SLT,
    ALU_SLTU,
    ALU_SLL,
    ALU_SRL,
    ALU_SRA 
} alu_funct_e;

typedef enum {
    NOP,
    WR,
    RD
} mem_op_e;

typedef struct {
    //Filled at fetch
    uint32_t    pc;
    uint32_t    instruction_data;
    //Filled at decode
    uint32_t    rsd;
    uint32_t    rsj;
    uint32_t    rsk;
    uint32_t    immediate;
    instr_e     instruction;
    //This instruction will write a result back into the RF
    bool        reg_wb;
    //Filled at branch 
    bool        branch_taken;
    uint32_t    next_pc;
    //Filled at execute
    uint32_t    alu_result;
    //Filled at mem_access
    mem_op_e    mem_op;
    uint32_t    mem_addr;
    uint32_t    mem_mask;
    uint32_t    mem_wdata;
    uint32_t    mem_rdata;
    //Data to writeback
    uint32_t    wb_data;
} instr_t;
