`include "riscv_functions.vh"
module riscv_ex (
    input                       clk,
    input                       rstn,
    input                       id_ex_rdy,
    output                      id_ex_ack,
    input  [31:0]               id_ex_op1,
    input  [31:0]               id_ex_op2,
    input  [`EX_FUNCT_W-1:0]    id_ex_funct,
    output                      ex_mem_rdy,
    input                       ex_mem_ack,
    output [31:0]               ex_mem_data
);

reg                             id_ex_ack;
reg                             ex_mem_rdy;
reg  [31:0]                     ex_mem_data;

wire [31:0]                     neg_op2;
wire [5:0]                      shft_amnt;
reg  [31:0]                     result;

assign neg_op2   = (~id_ex_op2) + 1;
assign shft_amnt = id_ex_op2 & 'h1f;

always @ (*) begin
    case (id_ex_funct) 
        `EX_ADD : result = id_ex_op1 + id_ex_op2;
        `EX_SUB : result = id_ex_op1 - id_ex_op2;
        `EX_OR  : result = id_ex_op1 | id_ex_op2;
        `EX_XOR : result = id_ex_op1 ^ id_ex_op2;
        `EX_AND : result = id_ex_op1 & id_ex_op2;
        `EX_STL : result = ($signed(id_ex_op1) < $signed(id_ex_op2)) ?  1'b1 : 1'b0;
        `EX_STLU: result = (id_ex_op1 < id_ex_op2) ? 1'b1 : 1'b0;
        `EX_SLL : result = id_ex_op1 << shft_amnt;
        `EX_SRL : result = id_ex_op1 >> shft_amnt;
        `EX_SRA : result = id_ex_op1 >>> shft_amnt;
        default : result = 32'b0;
    endcase
end

always @ (*) begin
    if (ex_mem_rdy && !ex_mem_ack) begin
        id_ex_ack = 1'b0;
    end
    else begin
        id_ex_ack = 1'b1;
    end
end

always @ (posedge clk, negedge rstn) begin
    if (!rstn) begin
        ex_mem_rdy <= 1'b0;
        ex_mem_data <= 32'b0;
    end
    else if (clk) begin
        if (!ex_mem_rdy || ex_mem_ack) begin
            ex_mem_rdy <= id_ex_rdy;
            ex_mem_data <= result;
        end
    end
end

endmodule
