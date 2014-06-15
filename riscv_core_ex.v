module riscv_core_ex (
    input                                       clk,
    input                                       rstn,
    //CT interface
    input  [31:0]                               ct_ex_op1_st2,
    input  [31:0]                               ct_ex_op2_st2,
    //ID interface
    input  [9:0]                                id_ex_funct,
    input                                       id_ex_mux1_cntl,
    input  [31:0]                               id_ex_pc,
    input                                       id_ex_mux2_cntl,
    input  [31:0]                               id_ex_immed,
    //MEM interface
    output                                      ex_mem_result
);

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


wire [31:0] op1_st1;
wire [31:0] op2_st1;

wire [31:0] op1_st2;
wire [31:0] op2_st2;

wire [31:0] result_nxt;

wire        flip_op2_st2;
wire [31:0] neg_op2_st2;
wire [5:0]  shft_amnt;

assign op1_st1 = (id_ex_op1_cntl) ? id_ex_pc    : ct_ex_op1;
assign op2_st1 = (id_ex_op2_cntl) ? id_ex_immed : ct_ex_op2;

assign op1_st2 = op1_st1;
assign op2_st2 = (flip_op2) ? neg_op2 : op2_st1;


assign flip_op2 == (id_ex_funct == FUNCT_SUB_OH) ? 1'b1 : 1'b0;

assign neg_op2 = (~op2_st1)+1;
assign shft_amnt = op2_st1 & 'h1f;


assign ex_mem_result = result_ff;

always @ (*) begin
    case (id_ex_funct) 
        FUNCT_ADD_OH ,
        FUNCT_SUB_OH : result = op1_st2 + op2_st2;
        FUNCT_OR_OH  : result = op1_st2 | op2_st2;
        FUNCT_XOR_OH : result = op1_st2 ^ op2_st2;
        FUNCT_AND_OH : result = op1_st2 & op2_st2;
        FUNCT_STL_OH : result = ($signed(op1_st2) < $signed(op2_st2)) ? 1'b1 : 1'b0;
        FUNCT_STLU_OH: result = (op1_st2 < op2_st2) ? 1'b1 : 1'b0;
        FUNCT_SLL_OH : result = op1_st2 << shft_amnt;
        FUNCT_SRL_OH : result = op1_st2 >> shft_amnt;
        FUNCT_SRA_OH : result = op1_st2 >>> shft_amnt;
        default      : result = 32'b0;
    endcase
end

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        result_ff <= 0;
    end
    else begin
        result_ff <= result_nxt;
    end
end


endmodule


