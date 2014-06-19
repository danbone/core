`include "instr_decode_defines.vh"

module instr_decoder_tb();

//Instructions 
localparam    ADDI  = 0;
localparam    ORI   = 1;  
localparam    XORI  = 2;
localparam    ANDI  = 3;
localparam    SLTI  = 4;
localparam    SLTUI = 5;
localparam    SLLI  = 6;
localparam    SRLI  = 7;
localparam    SRAI  = 8;
localparam    LUI   = 9;
localparam    AUIPC = 10;
localparam    ADD   = 11;
localparam    SUB   = 12;
localparam    OR    = 13;
localparam    XOR   = 14;
localparam    AND   = 15;
localparam    SLT   = 16;
localparam    SLTU  = 17;
localparam    SLL   = 18;
localparam    SRL   = 19;
localparam    SRA   = 20;
localparam    JALR  = 21;
localparam    JAL   = 22;
localparam    SB    = 23;
localparam    SH    = 24;
localparam    SW    = 25;
localparam    LB    = 26;
localparam    LH    = 27;
localparam    LW    = 28;
localparam    LBU   = 29;
localparam    LHU   = 30;
localparam    BEQ   = 31;
localparam    BNE   = 32;
localparam    BLT   = 33;
localparam    BLTU  = 34;
localparam    BGE   = 35;
localparam    BGEU  = 36;

localparam    NUM_INSTRS = 37;

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

localparam INSTR_ADD    = 10'b0000000000;
localparam INSTR_SUB    = 10'b0100000000;
localparam INSTR_OR     = 10'b0000000110;
localparam INSTR_XOR    = 10'b0000000100;
localparam INSTR_AND    = 10'b0000000111;
localparam INSTR_SLT    = 10'b0000000010;
localparam INSTR_SLTU   = 10'b0000000011;
localparam INSTR_SLL    = 10'b0000000001;
localparam INSTR_SRL    = 10'b0000000101;
localparam INSTR_SRA    = 10'b0100000101;
//MEM
localparam INSTR_LB     = 3'b000;
localparam INSTR_LH     = 3'b001;
localparam INSTR_LW     = 3'b010;
localparam INSTR_LBU    = 3'b100;
localparam INSTR_LHU    = 3'b101;
localparam INSTR_SB     = 3'b000;
localparam INSTR_SH     = 3'b001;
localparam INSTR_SW     = 3'b010;
//Branch
localparam INSTR_BEQ    = 3'b000;
localparam INSTR_BNE    = 3'b001;
localparam INSTR_BLT    = 3'b100;
localparam INSTR_BGE    = 3'b101;
localparam INSTR_BLTU   = 3'b110;
localparam INSTR_BGEU   = 3'b111;
//JALR
localparam INSTR_JALR   = 3'b000;

task get_function_and_opcode(input integer instr_enum,
                             output [9:0]  funct,
                             output [6:0]  opcode);
begin
    case (instr_enum) 
        ADDI : {funct, opcode} = {INSTR_ADD,  OPCODE_IMM};
        ORI  : {funct, opcode} = {INSTR_OR,   OPCODE_IMM};
        XORI : {funct, opcode} = {INSTR_XOR,  OPCODE_IMM};
        ANDI : {funct, opcode} = {INSTR_AND,  OPCODE_IMM};
        SLTI : {funct, opcode} = {INSTR_SLT,  OPCODE_IMM};
        SLTUI: {funct, opcode} = {INSTR_SLTU, OPCODE_IMM};
        SLLI : {funct, opcode} = {INSTR_SLL,  OPCODE_IMM};
        SRLI : {funct, opcode} = {INSTR_SRL,  OPCODE_IMM};
        SRAI : {funct, opcode} = {INSTR_SRA,  OPCODE_IMM};
        LUI  : {funct, opcode} = {10'b0,      OPCODE_LUI};
        AUIPC: {funct, opcode} = {10'b0,      OPCODE_AUIPC};
        ADD  : {funct, opcode} = {INSTR_ADD,  OPCODE_OP};
        SUB  : {funct, opcode} = {INSTR_SUB,  OPCODE_OP};   
        OR   : {funct, opcode} = {INSTR_OR,   OPCODE_OP};    
        XOR  : {funct, opcode} = {INSTR_XOR,  OPCODE_OP};    
        AND  : {funct, opcode} = {INSTR_AND,  OPCODE_OP};    
        SLT  : {funct, opcode} = {INSTR_SLT,  OPCODE_OP};    
        SLTU : {funct, opcode} = {INSTR_SLTU, OPCODE_OP};    
        SLL  : {funct, opcode} = {INSTR_SLL,  OPCODE_OP};    
        SRL  : {funct, opcode} = {INSTR_SRL,  OPCODE_OP};    
        SRA  : {funct, opcode} = {INSTR_SRA,  OPCODE_OP};  
        JALR : {funct, opcode} = {INSTR_JALR, OPCODE_JALR};
        JAL  : {funct, opcode} = {10'b0,      OPCODE_JAL};
        SB   : {funct, opcode} = {INSTR_SB  ,  OPCODE_STORE};
        SH   : {funct, opcode} = {INSTR_SH  ,  OPCODE_STORE};
        SW   : {funct, opcode} = {INSTR_SW  ,  OPCODE_STORE};
        LB   : {funct, opcode} = {INSTR_LB  , OPCODE_LOAD};
        LH   : {funct, opcode} = {INSTR_LH  ,  OPCODE_LOAD};
        LW   : {funct, opcode} = {INSTR_LW  ,  OPCODE_LOAD};
        LBU  : {funct, opcode} = {INSTR_LBU ,  OPCODE_LOAD};
        LHU  : {funct, opcode} = {INSTR_LHU ,  OPCODE_LOAD};
        BEQ  : {funct, opcode} = {INSTR_BEQ ,  OPCODE_BRANCH};
        BNE  : {funct, opcode} = {INSTR_BNE ,  OPCODE_BRANCH};
        BLT  : {funct, opcode} = {INSTR_BLT , OPCODE_BRANCH};
        BLTU : {funct, opcode} = {INSTR_BLTU,  OPCODE_BRANCH};
        BGE  : {funct, opcode} = {INSTR_BGE ,  OPCODE_BRANCH};
        BGEU : {funct, opcode} = {INSTR_BGEU,  OPCODE_BRANCH};
    endcase
end
endtask

function [31:0] sign_extend_imm (input integer high, low,  input [31:0] data);
integer i;
reg sign_bit;
begin
    sign_bit = data[high];
    for (i = 0; i < 32; i = i + 1) begin
        if (i < low) 
            sign_extend_imm[i] = 0;
        else if (i > high) 
            sign_extend_imm[i] = sign_bit;
        else
            sign_extend_imm[i] = data[i];
    end
end
endfunction


task generate_instruction(output [31:0] instr, 
                          output integer instr_enum,
                          output [4:0]   rsj, rsk, rsd,
                          output [31:0]  immediate);
reg [31:0] rand_val;
reg [7:0]  opcode;
reg [9:0]  funct_l;
integer    instr_enum_l;
reg [31:0] imm;
begin
    rsj = 0;
    rsk = 0;
    rsd = 0;
    immediate = 0;
    instr_enum_l = $urandom % NUM_INSTRS;
    get_function_and_opcode(instr_enum_l, funct_l, opcode);
    instr_enum = instr_enum_l;
    //rand_val = $urandom;
    instr[6:0] = opcode;
    case (opcode) 
    OPCODE_IMM : begin
        rsj = $urandom % (1<<5);
        rsd = $urandom % (1<<5);
        imm = $urandom % (1<<12);
        instr[11:7]  = rsd;
        instr[19:15] = rsj;
        if (instr_enum_l == SRLI || instr_enum_l == SRAI || instr_enum_l == SRLI) begin
            imm = imm & 'h1f;
            instr[14:12] = funct_l[2:0];
            instr[24:20] = imm[4:0];
            instr[31:25] = funct_l[9:3];
        end
        else begin
            instr[14:12] = funct_l[2:0];
            instr[31:20] = imm[11:0];
        end
        immediate = sign_extend_imm(11, 0, imm);
    end   
    OPCODE_LUI,
    OPCODE_AUIPC : begin
        rsd = $urandom % (1<<5);
        imm = $urandom % (1<<20);
        instr[11:7] = rsd;
        instr[31:12] = imm[19:0];
        immediate = sign_extend_imm(31, 12, imm);
    end 
    OPCODE_OP : begin
        rsk = $urandom % (1<<5);
        rsj = $urandom % (1<<5);
        rsd = $urandom % (1<<5);
        instr[11:7]  = rsd;
        instr[14:12] = funct_l[2:0];
        instr[19:15] = rsj;
        instr[24:20] = rsk;
        instr[31:25] = funct_l[9:3];
    end    
    OPCODE_JAL : begin
        rsd = $urandom % (1<<5);
        imm = $urandom % (1<<20);
        imm = imm << 1;
        instr[11:7]  = rsd;
        instr[19:12] = imm[19:12];
        instr[20]    = imm[11];
        instr[30:21] = imm[10:1];
        instr[31]    = imm[20];
        immediate = sign_extend_imm(20, 1, imm);
    end   
    OPCODE_JALR : begin
        rsd = $urandom % (1<<5);
        rsj = $urandom % (1<<5);
        imm = $urandom % (1<<12);
        instr[11:7]  = rsd;
        instr[14:12] = funct_l[2:0];
        instr[19:15] = rsj;
        instr[31:20] = imm[11:0];
        immediate = sign_extend_imm(11, 0, imm);
    end  
    OPCODE_BRANCH : begin
        rsk = $urandom % (1<<5);
        rsj = $urandom % (1<<5);
        imm = $urandom % (1<<11);
        imm = imm << 1;
        instr[14:12] = funct_l[2:0];
        instr[19:15] = rsj;
        instr[24:20] = rsk;
        instr[7]     = imm[11];
        instr[11:8]  = imm[4:1];
        instr[30:25] = imm[10:5];
        instr[31]    = imm[12];
        immediate = sign_extend_imm(12, 1, imm);
    end
    OPCODE_LOAD : begin
        rsd = $urandom % (1<<5);
        rsj = $urandom % (1<<5);
        imm = $urandom % (1<<12);
        instr[11:7]  = rsd;
        instr[14:12] = funct_l[2:0];
        instr[19:15] = rsj;
        instr[31:20] = imm[11:0];
        immediate = sign_extend_imm(11, 0, imm);
    end  
    OPCODE_STORE : begin
        rsk = $urandom % (1<<5);
        rsj = $urandom % (1<<5);
        imm = $urandom % (1<<12);
        instr[11:7]  = imm[4:0];
        instr[14:12] = funct_l[2:0];
        instr[19:15] = rsj;
        instr[24:20] = rsj;
        instr[31:25] = imm[11:5];
        immediate = sign_extend_imm(11, 0, imm);
    end 
    endcase
end
endtask

reg [31:0]  instr; 
integer     instr_enum;
reg [4:0]   rsj, rsk, rsd;
reg [31:0]  immediate;

initial begin
    repeat (100) begin
        generate_instruction(instr, instr_enum, rsj, rsk, rsd, immediate);
        $display("instr : %x instr_enum : %x rsj :%x rsk :%x rsd : %x immediate : %x",
            instr, instr_enum, rsj, rsk, rsd, immediate);
    end
end


endmodule
