module riscv_ex_pipe (
    input               clk,
    input               rstn,
    input               id_ex_rdy,
    output              id_ex_ack,
    input  [31:0]       id_ex_data,
    output              mem_wb_rdy,
    input               mem_wb_ack,
    output [31:0]       mem_wb_data
);

wire               clk;
wire               rstn;
wire               id_ex_rdy;
wire               id_ex_ack;
wire  [31:0]       id_ex_data;
wire               mem_wb_rdy;
wire               mem_wb_ack;
wire [31:0]        mem_wb_data;

wire               ex_mem_rdy;
wire               ex_mem_ack;
wire [31:0]        ex_mem_data;

riscv_ex i_riscv_ex (
    .clk               (clk),
    .rstn              (rstn),
    .id_ex_rdy         (id_ex_rdy),
    .id_ex_ack         (id_ex_ack),
    .id_ex_data        (id_ex_data),
    .ex_mem_rdy        (ex_mem_rdy),
    .ex_mem_ack        (ex_mem_ack),
    .ex_mem_data       (ex_mem_data)
);

riscv_mem i_riscv_mem (
    .clk               (clk),
    .rstn              (rstn),
    .ex_mem_rdy        (ex_mem_rdy),
    .ex_mem_ack        (ex_mem_ack),
    .ex_mem_data       (ex_mem_data),
    .mem_wb_rdy        (mem_wb_rdy),
    .mem_wb_ack        (mem_wb_ack),
    .mem_wb_data       (mem_wb_data)
);

endmodule
