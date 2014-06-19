module riscv_ex (
    input                   clk,
    input                   rstn,
    //ID input
    input                   id_mem_funct,
    input                   id_mem_sb,
    //MEM output
    output                  mem_result,
    output                  mem_funct,
    output                  mem_sb,
    //Downstream
    input                   ds_rdy,
    output                  ds_ack,
    //Upstream 
    input                   us_rdy,
    output                  us_ack
);

reg                         us_rdy_reg;

//This module cannot stall
assign ds_ack = us_rdy;
assign us_rdy = us_rdy_reg;

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        us_rdy_reg     <= 1'b0;
        mem_result_reg <= 'h0;
        mem_funct_reg  <= 'h0;
        mem_sb_reg     <= 'h0;
    end
    else begin
        if (us_rdy_reg && us_ack) begin
            us_rdy_reg     <= ds_rdy;
            mem_result_reg <= mem_result_nxt;
            mem_funct_reg  <= mem_funct_nxt;
            mem_sb_reg     <= mem_sb_nxt;
        end
    end
end

assign ex_mem_result = result_ff;

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

endmodule
