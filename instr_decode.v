//Combinational module 
module riscv_core_id (
    input [31:0]         instr,
    output [4:0]         rsj,
    output               rsj_valid,
    output [4:0]         rsk,
    output               rsk_valid,
    output [31:0]        immed,
    output [9:0]         alu_funct,
    output [31:0]        pc,
    output [5:0]         branch_funct,
    output [31:0]        target,
    output [6:0]         mem_funct,
    output               illegal_instr
);

localparam OPCODE_IMM       = 6'b0010011;
localparam OPCODE_LUI       = 6'b0110111;
localparam OPCODE_AUIPC     = 6'b0010111;
localparam OPCODE_OP        = 6'b0110011;
localparam OPCODE_JAL       = 6'b1101111;
localparam OPCODE_JALR      = 6'b1100111;
localparam OPCODE_BRANCH    = 6'b1100011;
localparam OPCODE_LOAD      = 6'b0000011;
localparam OPCODE_STORE     = 6'b0100011;
localparam OPCODE_MISC_MEM  = 6'b0001111;
localparam OPCODE_SYSTEM    = 6'b1110011;

localparam FUNCT_ADD_RAW    = 10'b0000000000;
localparam FUNCT_SUB_RAW    = 10'b0100000000;
localparam FUNCT_OR_RAW     = 10'b0000000110;
localparam FUNCT_XOR_RAW    = 10'b0000000100;
localparam FUNCT_AND_RAW    = 10'b0000000111;
localparam FUNCT_SLT_RAW    = 10'b0000000010;
localparam FUNCT_SLTU_RAW   = 10'b0000000011;
localparam FUNCT_SLL_RAW    = 10'b0000000001;
localparam FUNCT_SRL_RAW    = 10'b0000000101;
localparam FUNCT_SRA_RAW    = 10'b0100000101;

localparam FUNCT_NOP_OH     = 10'b0000000000;
localparam FUNCT_ADD_OH     = 10'b0000000001;
localparam FUNCT_SUB_OH     = 10'b0000000010;
localparam FUNCT_OR_OH      = 10'b0000000100;
localparam FUNCT_XOR_OH     = 10'b0000001000;
localparam FUNCT_AND_OH     = 10'b0000010000;
localparam FUNCT_STL_OH     = 10'b0000100000;
localparam FUNCT_STLU_OH    = 10'b0001000000;
localparam FUNCT_SLL_OH     = 10'b0010000000;
localparam FUNCT_SRL_OH     = 10'b0100000000;
localparam FUNCT_SRA_OH     = 10'b1000000000;

localparam MEM_FUNCT_LB_RAW  = 3'b000;
localparam MEM_FUNCT_LH_RAW  = 3'b001;
localparam MEM_FUNCT_LW_RAW  = 3'b010;
localparam MEM_FUNCT_LBU_RAW = 3'b100;
localparam MEM_FUNCT_LHU_RAW = 3'b101;
//Decoded in seperate processes
localparam MEM_FUNCT_SB_RAW  = 3'b000;
localparam MEM_FUNCT_SH_RAW  = 3'b001;
localparam MEM_FUNCT_SW_RAW  = 3'b010;

localparam MEM_FUNCT_NOP_OH = 8'b00000000;
localparam MEM_FUNCT_LB_OH  = 8'b00000001;
localparam MEM_FUNCT_LH_OH  = 8'b00000010;
localparam MEM_FUNCT_LW_OH  = 8'b00000100;
localparam MEM_FUNCT_LBU_OH = 8'b00001000;
localparam MEM_FUNCT_LHU_OH = 8'b00010000;
localparam MEM_FUNCT_SB_OH  = 8'b00100000;
localparam MEM_FUNCT_SH_OH  = 8'b01000000;
localparam MEM_FUNCT_SW_OH  = 8'b10000000;

localparam BR_FUNCT_BEQ_RAW  = 3'b000;
localparam BR_FUNCT_BNE_RAW  = 3'b001;
localparam BR_FUNCT_BLT_RAW  = 3'b100;
localparam BR_FUNCT_BGE_RAW  = 3'b101;
localparam BR_FUNCT_BLTU_RAW = 3'b110;
localparam BR_FUNCT_BGEU_RAW = 3'b111;

localparam BR_FUNCT_NOP_OH  = 7'b0000000;
localparam BR_FUNCT_BEQ_OH  = 7'b0000001;
localparam BR_FUNCT_BNE_OH  = 7'b0000010;
localparam BR_FUNCT_BLT_OH  = 7'b0000100;
localparam BR_FUNCT_BGE_OH  = 7'b0001000;
localparam BR_FUNCT_BLTU_OH = 7'b0010000;
localparam BR_FUNCT_BGEU_OH = 7'b0100000;
//Handles JALR and JAL
localparam BR_FUNCT_JUMP_OH = 7'b1000000;

//Split the instruction up
wire       sign;
wire [6:0] funct7;
wire [2:0] funct3;
wire [6:0] opcode;
wire [4:0] rsj;
wire [4:0] rsk;
wire [4:0] rsd;

assign sign   = instr[31];
assign funct7 = instr[31:25];
assign funct3 = instr[14:12];
assign opcode = instr[6:0];
assign rd     = instr[11:7];
assign rsj    = instr[19:15];
assign rsk    = instr[24:20];

/*****************************************************************************/
/* ex_function generation                                                    */
/*****************************************************************************/
wire [9:0] ex_funct_immediate;
wire [9:0] ex_funct_register;

function [9:0] decode_ex_funct(input [9:0] funct_in);
begin
    case (funct_in)
        FUNCT_ADD_RAW : decode_ex_funct = FUNCT_ADD_OH ;
        FUNCT_SUB_RAW : decode_ex_funct = FUNCT_SUB_OH ;
        FUNCT_OR_RAW  : decode_ex_funct = FUNCT_OR_OH  ;
        FUNCT_XOR_RAW : decode_ex_funct = FUNCT_XOR_OH ;
        FUNCT_AND_RAW : decode_ex_funct = FUNCT_AND_OH ;
        FUNCT_SLT_RAW : decode_ex_funct = FUNCT_STL_OH ;
        FUNCT_SLTU_RAW: decode_ex_funct = FUNCT_STLU_OH;
        FUNCT_SLL_RAW : decode_ex_funct = FUNCT_SLL_OH ;
        FUNCT_SRL_RAW : decode_ex_funct = FUNCT_SRL_OH ;
        FUNCT_SRA_RAW : decode_ex_funct = FUNCT_SRA_OH ;
        default       : decode_ex_funct = FUNCT_NOP_OH ;
    endcase
endfunction

assign ex_funct_immediate = decode_ex_funct({7'b0,funct3});
assign ex_funct_register  = decode_ex_funct({funct7,funct3});

//Shifts are special as the immediate field is overloaded
assign decoded_shift = ex_funct_immediate == FUNCT_SRL_OH;

//Assign the ex_funct
always @ (*) begin
    case (opcode)
        OPCODE_IMM     : ex_funct_nxt = (decoded_shift) ?
                            ex_funct_register : ex_funct_immediate;
        OPCODE_OP      : ex_funct_nxt = ex_funct_register;
        default        : ex_funct_nxt = FUNCT_ADD_OH;
    endcase
end

/*****************************************************************************/
/* Memory function generation                                                */
/*****************************************************************************/
wire [7:0] mem_funct_load;
wire [7:0] mem_funct_store;
wire [7:0] mem_funct_nxt;

always @ (*) begin
    case (funct3)
        MEM_FUNCT_LB_RAW : mem_funct_load = MEM_FUNCT_LB_OH;
        MEM_FUNCT_LH_RAW : mem_funct_load = MEM_FUNCT_LH_OH;
        MEM_FUNCT_LW_RAW : mem_funct_load = MEM_FUNCT_LW_OH;
        MEM_FUNCT_LBU_RAW: mem_funct_load = MEM_FUNCT_LBU_OH;
        MEM_FUNCT_LHU_RAW: mem_funct_load = MEM_FUNCT_LHU_OH;
        default          : mem_funct_load = MEM_FUNCT_NOP_OH;
    endcase
end

always @ (*) begin
    case (funct3)
        MEM_FUNCT_SB_RAW : mem_funct_store = MEM_FUNCT_SB_OH;
        MEM_FUNCT_SH_RAW : mem_funct_store = MEM_FUNCT_SH_OH;
        MEM_FUNCT_SW_RAW : mem_funct_store = MEM_FUNCT_SW_OH;
        default          : mem_funct_store = MEM_FUNCT_NOP_OH;
    endcase
end

always @ (*) begin
    case (opcode) 
       OPCODE_LOAD  : mem_funct_nxt = mem_funct_load; 
       OPCODE_STORE : mem_funct_nxt = mem_funct_store; 
       default      : mem_funct_nxt = MEM_FUNCT_NOP_OH;
    endcase
end

/*****************************************************************************/
/* Immediate generation                                                      */
/*****************************************************************************/
reg [31:0] immediate_nxt;

wire [31:0] i_im;
wire [31:0] s_im;
wire [31:0] b_im;
wire [31:0] u_im;
wire [31:0] j_im;

assign i_im = {{20{sign}}, instr[30:20]};
assign s_im = {{20{sign}}, instr[30:25], instr[11:7]};
assign b_im = {{19{sign}}, instr[7], instr[30:25], instr[11:8], 1'b0};
assign u_im = {sign, instr[30:12], 12'b0};
assign j_im = {{11{sign}}, instr[19:12], instr[20], instr[30:21], 1'b0};

//Assign immediate
always @ (*) begin
    case (opcode)
        OPCODE_IMM       : immediate_nxt = i_im;
        OPCODE_LUI       : immediate_nxt = u_im;
        OPCODE_AUIPC     : immediate_nxt = u_im;
        OPCODE_LOAD      : immediate_nxt = i_im;
        OPCODE_STORE     : immediate_nxt = i_im;
        //rd <- PC + 4
        OPCODE_JALR      : immediate_nxt = 'h4;
        OPCODE_JAL       : immediate_nxt = 'h4;
        /* Not implemented */
        OPCODE_MISC_MEM  : immediate_nxt = i_im;
        OPCODE_SYSTEM    : immediate_nxt = i_im;
        default          : immediate_nxt = 0;
    endcase
end

//output port
assign immed = immediate_nxt;


always @ (*) begin
    case (opcode) 
        OPCODE_LUI  ,                 
        OPCODE_AUIPC,                 
        OPCODE_JAL  ,                 
        OPCODE_JALR : rsj_valid = 1'b0;
        default     : rsj_valid = 1'b1;
    endcase
end

always @ (*) begin
    case (opcode) 
        OPCODE_OP: rsk_valid = 1'b0;       
        default  : rsk_valid = 1'b1;
    endcase
end

/*****************************************************************************/
/* Branch function generation                                                */
/*****************************************************************************/

wire [6:0] br_funct_branch;
wire [6:0] br_funct_nxt;

always @ (*) begin
    case (funct3) 
        BR_FUNCT_BEQ_RAW  : br_funct_branch = BR_FUNCT_BEQ_OH;
        BR_FUNCT_BNE_RAW  : br_funct_branch = BR_FUNCT_BNE_OH;
        BR_FUNCT_BLT_RAW  : br_funct_branch = BR_FUNCT_BLT_OH;
        BR_FUNCT_BGE_RAW  : br_funct_branch = BR_FUNCT_BGE_OH;
        BR_FUNCT_BLTU_RAW : br_funct_branch = BR_FUNCT_BLTU_OH;
        BR_FUNCT_BGEU_RAW : br_funct_branch = BR_FUNCT_BGEU_OH;
        default           : br_funct_branch = BR_FUNCT_NOP_OH;
    endcase
end

always @ (*) begin
    case (opcode) 
        OPCODE_BRANCH : br_funct_nxt = br_funct_branch;
        OPCODE_JAL,
        OPCODE_JALR   : br_funct_nxt = BR_FUNCT_JUMP_OH;
        default       : br_funct_nxt = BR_FUNCT_NOP_OH;
    endcase
end

/*****************************************************************************/
/* Branch target generation                                                  */
/*****************************************************************************/

wire [31:0] br_imm;

always @ (*) begin
    case (opcode) 
        OPCODE_BRANCH : br_imm = b_imm;
        OPCODE_JAL    : br_imm = j_imm;
        OPCODE_JALR   : br_imm = i_imm;
        default       : br_imm = 32'b0;
    endcase
end

assign target = pc + br_imm;



/* TODO
 * Drive PC on ALU mux
 * Hazard logic
 * Stall back logic
 * Cache tag compare
 */


endmodule
