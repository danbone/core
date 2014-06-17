module riscv_core_id (
    input  [31:0]        instr,
    input  [31:0]        pc_in,
    output [5:0]         branch_funct,
    output [9:0]         alu_funct,
    output [6:0]         mem_funct,
    output               alu_op1_sel,
    output               alu_op2_sel,
    output               rsj_valid,
    output               rsk_valid,
    output               rsd_valid,
    output [31:0]        alu_op1_immed,
    output [31:0]        alu_op2_immed,
    output [31:0]        br_immed,
    output               illegal_instr
);

localparam OPCODE_IMM       = 7'b0010011;
localparam OPCODE_LUI       = 7'b0110111;
localparam OPCODE_AUIPC     = 7'b0010111;
localparam OPCODE_OP        = 7'b0110011;
localparam OPCODE_JAL       = 7'b1101111;
localparam OPCODE_JALR      = 7'b1100111;
localparam OPCODE_BRANCH    = 7'b1100011;
localparam OPCODE_LOAD      = 7'b0000011;
localparam OPCODE_STORE     = 7'b0100011;
localparam OPCODE_MISC_MEM  = 7'b0001111;
localparam OPCODE_SYSTEM    = 7'b1110011;

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

assign sign   = instr[31];
assign funct7 = instr[31:25];
assign funct3 = instr[14:12];
assign opcode = instr[6:0];

//Generate alu_funct
wire [9:0] alu_funct_immediate;
wire [9:0] alu_funct_register;
wire [9:0] alu_funct_nxt;

function [9:0] decode_alu_funct(input [9:0] funct_in);
begin
    case (funct_in)
        FUNCT_ADD_RAW : decode_alu_funct = FUNCT_ADD_OH ;
        FUNCT_SUB_RAW : decode_alu_funct = FUNCT_SUB_OH ;
        FUNCT_OR_RAW  : decode_alu_funct = FUNCT_OR_OH  ;
        FUNCT_XOR_RAW : decode_alu_funct = FUNCT_XOR_OH ;
        FUNCT_AND_RAW : decode_alu_funct = FUNCT_AND_OH ;
        FUNCT_SLT_RAW : decode_alu_funct = FUNCT_STL_OH ;
        FUNCT_SLTU_RAW: decode_alu_funct = FUNCT_STLU_OH;
        FUNCT_SLL_RAW : decode_alu_funct = FUNCT_SLL_OH ;
        FUNCT_SRL_RAW : decode_alu_funct = FUNCT_SRL_OH ;
        FUNCT_SRA_RAW : decode_alu_funct = FUNCT_SRA_OH ;
        default       : decode_alu_funct = FUNCT_NOP_OH ;
    endcase
endfunction

assign alu_funct_immediate = decode_alu_funct({7'b0,funct3});
assign alu_funct_register  = decode_alu_funct({funct7,funct3});

//Shifts are special as the immediate field is overloaded
assign decoded_shift = alu_funct_immediate == FUNCT_SRL_OH;

reg [7:0] mem_funct_load;
reg [7:0] mem_funct_store;
reg [7:0] mem_funct_nxt;

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

reg [5:0]  branch_funct_l;
reg [9:0]  alu_funct_l;
reg [6:0]  mem_funct_l;
reg        alu_op1_sel_l;
reg        alu_op2_sel_l;
reg        rsj_valid_l;
reg        rsk_valid_l;
reg        rsd_valid_l;
reg [31:0] alu_op1_immed_l;
reg [31:0] alu_op2_immed_l;
reg [31:0] br_immed_l;
reg        illegal_instr_l;

always @ (*) begin
    //Set the default values
    branch_funct_l = BR_FUNCT_NOP_OH;
    alu_funct_l    = FUNCT_NOP_OH;
    mem_funct_l    = MEM_FUNCT_NOP_OH;
    alu_op1_sel_l  = ALU_SEL_IMM;
    alu_op2_sel_l  = ALU_SEL_IMM;
    rsj_valid_l    = 1'b0;
    rsk_valid_l    = 1'b0;
    rsd_valid_l    = 1'b0;
    alu_op1_immed_l = 32'b0;
    alu_op2_immed_l = 32'b0;
    br_immed_l      = 32'b0;
    illegal_instr_l = 1'b0;
    case (opcode) 
        OPCODE_IMM       : begin
            rsj_valid_l     = 1'b1;
            rsd_valid_l     = 1'b1;
            if (decoded_shift) begin
                alu_funct_l    = alu_funct_register;
            end
            else begin
                alu_funct_l    = alu_funct_immediate;
            end
            alu_op1_sel     = ALU_SEL_REG;
            alu_op2_sel     = ALU_SEL_IMM;
            alu_op2_immed_l = i_im;
        end
        OPCODE_OP       : begin
            rsj_valid_l     = 1'b1;
            rsk_valid_l     = 1'b1;
            rsd_valid_l     = 1'b1;
            alu_funct_l    = alu_funct_register;
            alu_op1_sel     = ALU_SEL_REG;
            alu_op2_sel     = ALU_SEL_REG;
        end
        OPCODE_LUI       : begin
            rsd_valid_l     = 1'b1;
            alu_funct_l      = FUNCT_ADD_OH;
            alu_op1_sel     = ALU_SEL_IMM;
            alu_op1_immed_l  = 32'b0;
            alu_op2_sel     = ALU_SEL_IMM;
            alu_op2_immed_l  = u_im;
        end
        OPCODE_AUIPC     : begin
            rsd_valid_l     = 1'b1;
            alu_funct_l     = FUNCT_ADD_OH;
            alu_op1_immed_l = pc_in;
            alu_op1_sel     = ALU_SEL_IMM;
            alu_op2_immed_l = u_im;
            alu_op2_sel     = ALU_SEL_IMM;
        end
        OPCODE_LOAD      : begin
            mem_funct_l  = mem_funct_load;
            rsd_valid_l  = 1'b1;
            rsj_valid_l  = 1'b1;
            alu_funct_l  = FUNCT_ADD_OH;
            alu_op1_sel  = ALU_SEL_REG;
            alu_op2_sel  = ALU_SEL_IMM;
            alu_op2_immed_l = i_im;
        end
        OPCODE_STORE     : begin
            mem_funct_l  = mem_funct_store;
            rsk_valid_l  = 1'b1;
            rsj_valid_l  = 1'b1;
            alu_funct_l  = FUNCT_ADD_OH;
            alu_op1_sel  = ALU_SEL_REG;
            alu_op2_sel  = ALU_SEL_IMM;
            alu_op2_immed_l = s_im;
        end
        OPCODE_BRANCH    : begin
            br_funct_l      = br_funct_branch;
            rsk_valid_l     = 1'b1;
            rsj_valid_l     = 1'b1;
            br_immed_l      = i_im;
        end
        //rd <- PC + 4
        OPCODE_JALR      : begin
            rsd_valid_l     = 1'b1;
            br_funct_l      = BR_FUNCT_JUMP_OH;
            br_immed_l      = i_im;
            alu_funct_l     = FUNCT_ADD_OH;
            alu_op1_sel     = ALU_SEL_IMM;
            alu_op1_immed_l = pc_in;
            alu_op2_sel     = ALU_SEL_IMM;
            alu_op2_immed_l = 'h4;
        end
        OPCODE_JAL       : begin
            rsd_valid_l     = 1'b1;
            br_funct_l      = BR_FUNCT_JUMP_OH;
            br_immed_l      = j_im;
            alu_funct_l     = FUNCT_ADD_OH;
            alu_op1_sel     = ALU_SEL_IMM;
            alu_op1_immed_l = pc_in;
            alu_op2_sel     = ALU_SEL_IMM;
            alu_op2_immed_l = 'h4;
        end
        /* Not implemented */
        //OPCODE_MISC_MEM  : immediate_nxt = i_im;
        //OPCODE_SYSTEM    : immediate_nxt = i_im;
        default          : illegal_instr_l = 1'b1;

    endcase
end

assign branch_funct     = branch_funct_l;
assign alu_funct        = alu_funct_l;
assign mem_funct        = mem_funct_l;
assign alu_op1_sel      = alu_op1_sel_l;
assign alu_op2_sel      = alu_op2_sel_l;
assign rsj_valid        = rsj_valid_l;
assign rsk_valid        = rsk_valid_l;
assign rsd_valid        = rsd_valid_l;
assign alu_op1_immed    = alu_op1_immed_l;
assign alu_op2_immed    = alu_op2_immed_l;
assign br_immed         = br_immed_l;
assign illegal_instr    = illegal_instr_l;


endmodule
/*
module riscv_core_id (
    input  [31:0]        instr,
    input  [31:0]        pc_in,
    //Branch function and immediate for target generation
    output [5:0]         branch_funct,
    output [31:0]        br_immed,
    //ALU function, mux select (reg or immed), and immediates
    output [9:0]         alu_funct,
    output               alu_op1_sel,
    output               alu_op2_sel,
    output [31:0]        alu_op1_immed,
    output [31:0]        alu_op2_immed,
    //Memory function
    output [6:0]         mem_funct,
    output               illegal_instr
);

localparam OPCODE_IMM       = 7'b0010011;
localparam OPCODE_LUI       = 7'b0110111;
localparam OPCODE_AUIPC     = 7'b0010111;
localparam OPCODE_OP        = 7'b0110011;
localparam OPCODE_JAL       = 7'b1101111;
localparam OPCODE_JALR      = 7'b1100111;
localparam OPCODE_BRANCH    = 7'b1100011;
localparam OPCODE_LOAD      = 7'b0000011;
localparam OPCODE_STORE     = 7'b0100011;
localparam OPCODE_MISC_MEM  = 7'b0001111;
localparam OPCODE_SYSTEM    = 7'b1110011;

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

localparam MEM_FUNCT_LB_RAW  = 3'b000;
localparam MEM_FUNCT_LH_RAW  = 3'b001;
localparam MEM_FUNCT_LW_RAW  = 3'b010;
localparam MEM_FUNCT_LBU_RAW = 3'b100;
localparam MEM_FUNCT_LHU_RAW = 3'b101;
localparam MEM_FUNCT_SB_RAW  = 3'b000;
localparam MEM_FUNCT_SH_RAW  = 3'b001;
localparam MEM_FUNCT_SW_RAW  = 3'b010;

localparam BR_FUNCT_BNE_RAW  = 3'b001;
localparam BR_FUNCT_BLT_RAW  = 3'b100;
localparam BR_FUNCT_BGE_RAW  = 3'b101;
localparam BR_FUNCT_BLTU_RAW = 3'b110;
localparam BR_FUNCT_BGEU_RAW = 3'b111;

//Branch unit outputs
always @ (*) begin
    case (opcode) 
        OPCODE_BRANCH: begin
            br_funct_l  = branch_funct;
            br_immed_l  = b_im;
            br_op_sel_l = BR_SEL_PC;
        end
        OPCODE_JAL: begin
            br_funct_l  = BR_JUMP_OH;
            br_immed_l  = i_im;
            br_op_sel_l = BR_SEL_PC;
        end
        OPCODE_JALR: begin
            br_funct_l  = BR_JUMP_OH;
            br_immed_l  = j_im;
            br_op_sel_l = BR_SEL_REG;
        end
        default : begin
            br_funct_l  = BR_NOP_OH;
            br_immed_l  = 32'b0;
            br_op_sel_l = BR_SEL_PC;
        end
end

assign br_funct  = br_funct_l;
assign br_immed  = br_immed_l;
assign br_op_sel = br_op_sel_l;

//Memory unit outputs
always @ (*) begin
    case (opcode) 
end


assign br_funct     = (opcode == OPCODE_BRANCH) ? branch_funct :
                      (opcode == OPCODE_JAL ||
                       opcode == OPCODE_JARL)   ? BR_JUMP_OH   :
                                                  BR_NOP_OH;

assign br_immed     = (opcode == OPCODE_BRANCH) ? b_im         :
                      (opcode == OPCODE_JAL)    ? i_im         :
                      (opcode == OPCODE_JALR)   ? j_im         :
                                                  32'b0;

assign br_op_sel    = (opcode == OPCODE_JALR)   ? BR_SEL_REG   :
                                                  BR_SEL_PC;
assign alu_funct    = (opcode == OPCODE_OP ||
                      (opcode == OPCODE_IMM && 
                       decoded_shift))          ?  alu_funct_10 :
                      (opcode == OPCODE_IMM)    ?  alu_funct_3  :
                                                   ALU_ADD_OH;

assign alu_op1_sel  = (opcode == OPCODE_OP    ||
                       opcode == OPCODE_IMM   ||
                       opcode == OPCODE_LOAD  ||
                       opcode == OPCODE_STORE)  ? ALU_SEL_REG  :
                                                  ALU_SEL_IMM;

    output [9:0]         alu_funct,
    output               alu_op1_sel,
    output               alu_op2_sel,
    output [31:0]        alu_op1_immed,
    output [31:0]        alu_op2_immed,

*/
