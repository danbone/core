`include "instr_decode_defines.vh"
module instr_decoder (
input  [31:0]              instr,
input  [31:0]              pc_in       ,
output                     use_rsj     ,
output                     use_rsk     ,
output                     use_rsd     ,
output [1:0]               rsd_lockout ,
output [`ALU_FUNCT_W-1:0]  alu_funct   ,
output                     alu_sel_a   ,
output                     alu_sel_b   ,
output [31:0]              alu_immed_a ,
output [31:0]              alu_immed_b ,
output [`BR_FUNCT_W-1:0]   br_funct    ,
output                     br_sel_a    ,
output  [31:0]             br_immed_a  ,
output  [31:0]             br_immed_b  ,
output  [`MEM_FUNCT_W-1:0] mem_funct  
);


//To decode the instruciton this module will create a packed array for each
//opcode and then select and unpack that array to drive the outputs

localparam PK_REG_W          = (1 + 1 + 1 + 1);
localparam PK_ALU_W          = (`ALU_FUNCT_W + 1 + 1 + 32 + 32);
localparam PK_BR_W           = (`BR_FUNCT_W + 1 + 32 + 32);
localparam PK_MEM_W          = (`MEM_FUNCT_W);
//TODO these are wrong
localparam PK_ILLEGAL_OFFSET = PK_REG_OFFSET + PK_REG_W;
localparam PK_REG_OFFSET     = PK_ALU_OFFSET + PK_ALU_W;
localparam PK_ALU_OFFSET     = PK_BR_OFFSET + PK_BR_W;
localparam PK_BR_OFFSET      = PK_MEM_OFFSET + PK_MEM_W;
localparam PK_MEM_OFFSET     = 0;
localparam PK_DATA_W         = 1 + PK_REG_W + PK_ALU_W + PK_BR_W + PK_MEM_W;

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

//Functions
//ALU
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

wire [PK_REG_W-1:0] reg_imm  ;
wire [PK_REG_W-1:0] reg_op   ;
wire [PK_REG_W-1:0] reg_br   ;
wire [PK_REG_W-1:0] reg_jal  ;
wire [PK_REG_W-1:0] reg_jalr ;
wire [PK_REG_W-1:0] reg_auipc;
wire [PK_REG_W-1:0] reg_lui  ;
wire [PK_REG_W-1:0] reg_load ;
wire [PK_REG_W-1:0] reg_store;
//ALU           
wire [PK_ALU_W-1:0] alu_imm  ;
wire [PK_ALU_W-1:0] alu_op   ;
wire [PK_ALU_W-1:0] alu_br   ;
wire [PK_ALU_W-1:0] alu_jal  ;
wire [PK_ALU_W-1:0] alu_jalr ;
wire [PK_ALU_W-1:0] alu_auipc;
wire [PK_ALU_W-1:0] alu_lui  ;
wire [PK_ALU_W-1:0] alu_load ;
wire [PK_ALU_W-1:0] alu_store;
//Branch        
wire [PK_BR_W-1:0]  br_imm   ;
wire [PK_BR_W-1:0]  br_op    ;
wire [PK_BR_W-1:0]  br_br    ;
wire [PK_BR_W-1:0]  br_jal   ;
wire [PK_BR_W-1:0]  br_jalr  ;
wire [PK_BR_W-1:0]  br_auipc ;
wire [PK_BR_W-1:0]  br_lui   ;
wire [PK_BR_W-1:0]  br_load  ;
wire [PK_BR_W-1:0]  br_store ;
//Memory  
wire [PK_MEM_W-1:0] mem_imm  ;
wire [PK_MEM_W-1:0] mem_op   ;
wire [PK_MEM_W-1:0] mem_br   ;
wire [PK_MEM_W-1:0] mem_jal  ;
wire [PK_MEM_W-1:0] mem_jalr ;
wire [PK_MEM_W-1:0] mem_lui  ;
wire [PK_MEM_W-1:0] mem_load ;
wire [PK_MEM_W-1:0] mem_store;

//Illegal instruction decoded
wire                illegal_imm  ;
wire                illegal_op   ;
wire                illegal_br   ;
wire                illegal_jal  ;
wire                illegal_jalr ;
wire                illegal_lui  ;
wire                illegal_load ;
wire                illegal_store;

wire [PK_DATA_W-1:0]  decoded_packed_imm  ;
wire [PK_DATA_W-1:0]  decoded_packed_lui  ;
wire [PK_DATA_W-1:0]  decoded_packed_auipc;
wire [PK_DATA_W-1:0]  decoded_packed_op   ;
wire [PK_DATA_W-1:0]  decoded_packed_jal  ;
wire [PK_DATA_W-1:0]  decoded_packed_jalr ;
wire [PK_DATA_W-1:0]  decoded_packed_br   ;
wire [PK_DATA_W-1:0]  decoded_packed_load ;
wire [PK_DATA_W-1:0]  decoded_packed_store;

reg [PK_DATA_W-1:0]   decoded_packed;

reg  [`ALU_FUNCT_W-1:0] alu_funct3_imm;
wire [`ALU_FUNCT_W-1:0] alu_funct_imm;
reg  [`ALU_FUNCT_W-1:0] alu_funct_op;

reg [`BR_FUNCT_W-1 :0] br_funct_branch;
reg [`MEM_FUNCT_W-1:0] mem_funct_load;
reg [`MEM_FUNCT_W-1:0] mem_funct_store;

wire                 illegal_instruction;
wire [PK_REG_W-1:0]  reg_unpk;
wire [PK_ALU_W-1:0]  alu_unpk;
wire [PK_BR_W-1:0]   br_unpk ;
wire [PK_MEM_W-1:0]  mem_unpk;

wire                sign;
wire [6:0]          funct7;
wire [2:0]          funct3;
wire [6:0]          opcode;
wire [9:0]          funct10;

wire [31:0]         i_im;
wire [31:0]         s_im;
wire [31:0]         b_im;
wire [31:0]         u_im;
wire [31:0]         j_im;

assign sign     = instr[31];
assign funct7   = instr[31:25];
assign funct3   = instr[14:12];
assign opcode   = instr[6:0];
assign funct10  = {funct7, funct3};

assign i_im = {{20{sign}}, instr[30:20]};
assign s_im = {{20{sign}}, instr[30:25], instr[11:7]};
assign b_im = {{19{sign}}, instr[7], instr[30:25], instr[11:8], 1'b0};
assign u_im = {sign, instr[30:12], 12'b0};
assign j_im = {{11{sign}}, instr[19:12], instr[20], instr[30:21], 1'b0};

//Packed data is packed {MEM, BR, ALU, REG};
//                    Valids          Lockout on RSD
//Register settings rsj   rsk   rsd   rsd 
assign reg_imm   = {1'b1, 1'b0, 1'b1, `ALU_LOCKOUT };
assign reg_op    = {1'b1, 1'b1, 1'b1, `ALU_LOCKOUT };
assign reg_br    = {1'b1, 1'b1, 1'b0, `NO_LOCKOUT  };
assign reg_jal   = {1'b0, 1'b0, 1'b1, `ALU_LOCKOUT };
assign reg_jalr  = {1'b1, 1'b0, 1'b1, `ALU_LOCKOUT };
assign reg_auipc = {1'b0, 1'b0, 1'b1, `ALU_LOCKOUT };
assign reg_lui   = {1'b0, 1'b0, 1'b1, `ALU_LOCKOUT };
assign reg_load  = {1'b1, 1'b0, 1'b1, `LOAD_LOCKOUT};
assign reg_store = {1'b1, 1'b1, 1'b0, `NO_LOCKOUT  };
//ALU               alu_funct  sel_a    sel_b    immed_a immed_b
assign alu_imm   = {alu_funct_imm, `SEL_REG, `SEL_IM,  32'b0,  i_im};
assign alu_op    = {alu_funct_op,  `SEL_REG, `SEL_REG, 32'b0,  32'b0};
assign alu_br    = {`ALU_NOP,      `SEL_IM,  `SEL_IM,  32'b0,  32'b0};
assign alu_jal   = {`ALU_ADD,      `SEL_IM,  `SEL_IM,  pc_in,  32'h4};
assign alu_jalr  = {`ALU_ADD,      `SEL_IM,  `SEL_IM,  pc_in,  32'h4};
assign alu_auipc = {`ALU_ADD,      `SEL_IM,  `SEL_IM,  pc_in,  u_im};
assign alu_lui   = {`ALU_ADD,      `SEL_IM,  `SEL_IM,  32'b0,  u_im};
assign alu_load  = {`ALU_ADD,      `SEL_REG, `SEL_IM,  32'b0,  i_im};
assign alu_store = {`ALU_ADD,      `SEL_REG, `SEL_IM,  32'b0,  s_im};
//Branch           br_funct   sel_a    im_a im_b
assign br_imm    = {`BR_NOP,          `SEL_IM,  32'b0,  32'b0};
assign br_op     = {`BR_NOP,          `SEL_IM,  32'b0,  32'b0};
assign br_br     = {br_funct_branch,  `SEL_IM,  pc_in,  b_im};
assign br_jal    = {`BR_JUMP,         `SEL_IM,  pc_in,  j_im};
assign br_jalr   = {`BR_JUMP,         `SEL_REG, 32'b0,  j_im};
assign br_auipc  = {`BR_NOP,          `SEL_IM,  32'b0,  32'b0};
assign br_lui    = {`BR_NOP,          `SEL_IM,  32'b0,  32'b0};
assign br_load   = {`BR_NOP,          `SEL_IM,  32'b0,  32'b0};
assign br_store  = {`BR_NOP,          `SEL_IM,  32'b0,  32'b0};
//Memory 
assign mem_imm   = `MEM_NOP;
assign mem_op    = `MEM_NOP;
assign mem_br    = `MEM_NOP;
assign mem_jal   = `MEM_NOP;
assign mem_jalr  = `MEM_NOP;
assign mem_lui   = `MEM_NOP;
assign mem_load  = mem_funct_load;
assign mem_store = mem_funct_store;


//Decode IMM
always @ (*) begin
    case (funct3) 
        INSTR_ADD : alu_funct3_imm = `ALU_ADD ;
        INSTR_OR  : alu_funct3_imm = `ALU_OR  ;
        INSTR_XOR : alu_funct3_imm = `ALU_XOR ;
        INSTR_AND : alu_funct3_imm = `ALU_AND ;
        INSTR_SLT : alu_funct3_imm = `ALU_SLT ;
        INSTR_SLTU: alu_funct3_imm = `ALU_SLTU;
        INSTR_SLL : alu_funct3_imm = `ALU_SLL ;
        INSTR_SRL : alu_funct3_imm = `ALU_SRL ;
        default   : alu_funct3_imm = `ALU_NOP ;
    endcase
end
assign illegal_imm = (alu_funct3_imm == `ALU_NOP) ? 1'b1 : 1'b0;

//Decode OP
always @ (*) begin
    case (funct10) 
        INSTR_ADD : alu_funct_op = `ALU_ADD ;
        INSTR_SUB : alu_funct_op = `ALU_SUB ;
        INSTR_OR  : alu_funct_op = `ALU_OR  ;
        INSTR_XOR : alu_funct_op = `ALU_XOR ;
        INSTR_AND : alu_funct_op = `ALU_AND ;
        INSTR_SLT : alu_funct_op = `ALU_SLT ;
        INSTR_SLTU: alu_funct_op = `ALU_SLTU;
        INSTR_SLL : alu_funct_op = `ALU_SLL ;
        INSTR_SRL : alu_funct_op = `ALU_SRL ;
        INSTR_SRA : alu_funct_op = `ALU_SRA ;
        default   : alu_funct_op = `ALU_NOP ;
    endcase
end
assign illegal_op = (alu_funct_op == `ALU_NOP) ? 1'b1 : 1'b0;

//Special case handle SRA Immediate as immediate field is overloaded
assign alu_funct_imm = (alu_funct_op == `ALU_SRA) ? alu_funct_op : alu_funct3_imm;

//Decode branch
always @ (*) begin
    case (funct3) 
        INSTR_BEQ  : br_funct_branch = `BR_BEQ;
        INSTR_BNE  : br_funct_branch = `BR_BNE;
        INSTR_BLT  : br_funct_branch = `BR_BLT;
        INSTR_BGE  : br_funct_branch = `BR_BGE;
        INSTR_BLTU : br_funct_branch = `BR_BLTU;
        INSTR_BGEU : br_funct_branch = `BR_BGEU;
        default    : br_funct_branch = `BR_NOP;
    endcase
end
assign illegal_br = (br_funct_branch == `BR_NOP) ? 1'b1 : 1'b0;

//Decode JALR
assign illegal_jalr = (funct3 != INSTR_JALR) ? 1'b1 : 1'b0;

//These cannot be illegal for now
assign illegal_jal   = 1'b0;
assign illegal_auipc = 1'b0;
assign illegal_lui   = 1'b0;

//Decode LOAD
always @ (*) begin
    case (funct3)
        INSTR_LB : mem_funct_load = `MEM_LB;
        INSTR_LH : mem_funct_load = `MEM_LH;
        INSTR_LW : mem_funct_load = `MEM_LW;
        INSTR_LBU: mem_funct_load = `MEM_LBU;
        INSTR_LHU: mem_funct_load = `MEM_LHU;
        default  : mem_funct_load = `MEM_NOP;
    endcase
end
assign illegal_load = (mem_funct_load == `MEM_NOP) ? 1'b1 : 1'b0;

always @ (*) begin
    case (funct3)
        INSTR_SB : mem_funct_store = `MEM_SB;
        INSTR_SH : mem_funct_store = `MEM_SH;
        INSTR_SW : mem_funct_store = `MEM_SW;
        default  : mem_funct_store = `MEM_NOP;
    endcase
end
assign illegal_store = (mem_funct_store == `MEM_NOP) ? 1'b1 : 1'b0;

assign decoded_packed_imm   = {illegal_imm,   reg_imm,   alu_imm,   br_imm,   mem_imm   };
assign decoded_packed_lui   = {illegal_lui,   reg_lui,   alu_lui,   br_lui,   mem_lui   };
assign decoded_packed_auipc = {illegal_auipc, reg_auipc, alu_auipc, br_auipc, mem_auipc };
assign decoded_packed_op    = {illegal_op,    reg_op,    alu_op,    br_op,    mem_op    };
assign decoded_packed_jal   = {illegal_jal,   reg_jal,   alu_jal,   br_jal,   mem_jal   };
assign decoded_packed_jalr  = {illegal_jalr,  reg_jalr,  alu_jalr,  br_jalr,  mem_jalr  };
assign decoded_packed_br    = {illegal_br,    reg_br,    alu_br,    br_br,    mem_br    };
assign decoded_packed_load  = {illegal_load,  reg_load,  alu_load,  br_load,  mem_load  };
assign decoded_packed_store = {illegal_store, reg_store, alu_store, br_store, mem_store };

always @ (*) begin
    case (opcode)
        OPCODE_IMM   : decoded_packed = decoded_packed_imm;
        OPCODE_LUI   : decoded_packed = decoded_packed_lui;
        OPCODE_AUIPC : decoded_packed = decoded_packed_auipc;
        OPCODE_OP    : decoded_packed = decoded_packed_op;
        OPCODE_JAL   : decoded_packed = decoded_packed_jal;
        OPCODE_JALR  : decoded_packed = decoded_packed_jalr;
        OPCODE_BRANCH: decoded_packed = decoded_packed_br;
        OPCODE_LOAD  : decoded_packed = decoded_packed_load;
        OPCODE_STORE : decoded_packed = decoded_packed_store;
        default      : decoded_packed = {1'b1, {PK_DATA_W-1{1'b0}}};
    endcase
end

//unpack and assign outputs 
assign illegal_instruction = decoded_packed[ILLEGAL_OFFSET];
assign reg_unpk = decoded_packed[(PK_REG_W-1)+PK_REG_OFFSET:PK_REG_OFFSET];
assign alu_unpk = decoded_packed[(PK_ALU_W-1)+PK_ALU_OFFSET:PK_ALU_OFFSET];
assign br_unpk  = decoded_packed[(PK_BR_W -1)+PK_BR_OFFSET :PK_BR_OFFSET];
assign mem_unpk = decoded_packed[(PK_MEM_W-1)+PK_MEM_OFFSET:PK_MEM_OFFSET];

//Register settings rsj   rsk   rsd   rsd 
assign use_rsj     = reg_unpk[4];
assign use_rsk     = reg_unpk[3];
assign use_rsd     = reg_unpk[2];
assign rsd_lockout = reg_unpk[1:0];

//ALU               alu_funct  sel_a    sel_b    immed_a immed_b
assign alu_funct   = alu_unpk[75:66];
assign alu_sel_a   = alu_unpk[65];
assign alu_sel_b   = alu_unpk[64];
assign alu_immed_a = alu_unpk[63:32];
assign alu_immed_b = alu_unpk[31:0];

//Branch           br_funct   sel_a    immed_a immed_b
assign br_funct   = br_unpk[71:65];
assign br_sel_a   = br_unpk[64];
assign br_immed_a = br_unpk[63:32];
assign br_immed_b = br_unpk[31:0];

//MEM
assign mem_funct  = mem_unpk[7:0];

endmodule
