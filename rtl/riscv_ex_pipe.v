`include "riscv_functions.vh"
module riscv_ex_pipe (
    input                      clk,
    input                      rstn,
    input                      id_ex_rdy,
    input  [`EX_FUNCT_W-1:0]   id_ex_funct,
    input  [31:0]              id_ex_op1,
    input  [31:0]              id_ex_op2,
    input  [`MEM_FUNCT_W-1:0]  id_ex_mem_funct,
    input  [31:0]              id_ex_mem_data,
    input  [4:0]               id_ex_wb_rsd,
    input  [31:0]              data_bif_rdata,
    input                      data_bif_ack,
    output [31:0]              data_bif_addr,
    output                     data_bif_req,
    output                     data_bif_rnw,
    output [3:0]               data_bif_wmask,
    output [31:0]              data_bif_wdata,
    output [31:0]              wb_rf_data,
    output [4:0]               wb_rf_rsd,
    output                     wb_rf_write
);
    //Wires for pipeline
    wire                       id_ex_ack;
    wire                       ex_mem_rdy;
    wire                       ex_mem_ack;
    wire  [31:0]               ex_mem_result;
    wire  [`MEM_FUNCT_W-1:0]   ex_mem_funct;
    wire  [31:0]               ex_mem_data;
    wire  [4:0]                ex_mem_wb_rsd;
    wire                       mem_wb_rdy;
    wire                       mem_wb_ack;
    wire  [`LD_FUNCT_W-1:0]    mem_wb_funct;
    wire  [1:0]                mem_wb_baddr;
    wire  [31:0]               mem_wb_data;
    wire  [4:0]                mem_wb_rsd;

riscv_ex i_riscv_ex (
    .clk                (clk),
    .rstn               (rstn),
    .id_ex_rdy          (id_ex_rdy),
    .id_ex_ack          (id_ex_ack),
    .id_ex_funct        (id_ex_funct),
    .id_ex_op1          (id_ex_op1),
    .id_ex_op2          (id_ex_op2),
    .id_ex_mem_funct    (id_ex_mem_funct),
    .id_ex_mem_data     (id_ex_mem_data),
    .id_ex_wb_rsd       (id_ex_wb_rsd),
    .ex_mem_rdy         (ex_mem_rdy),
    .ex_mem_ack         (ex_mem_ack),
    .ex_mem_result      (ex_mem_result),
    .ex_mem_funct       (ex_mem_funct),
    .ex_mem_data        (ex_mem_data),
    .ex_mem_wb_rsd      (ex_mem_wb_rsd)
);

riscv_mem i_riscv_mem (
    .clk                (clk),
    .rstn               (rstn),
    .ex_mem_rdy         (ex_mem_rdy),
    .ex_mem_ack         (ex_mem_ack),
    .ex_mem_result      (ex_mem_result),
    .ex_mem_funct       (ex_mem_funct),
    .ex_mem_data        (ex_mem_data),
    .ex_mem_wb_rsd      (ex_mem_wb_rsd),
    .mem_wb_rdy         (mem_wb_rdy),
    .mem_wb_ack         (mem_wb_ack),
    .data_bif_addr      (data_bif_addr),
    .data_bif_req       (data_bif_req),
    .data_bif_rnw       (data_bif_rnw),
    .data_bif_wmask     (data_bif_wmask),
    .data_bif_wdata     (data_bif_wdata),
    .mem_wb_funct       (mem_wb_funct),
    .mem_wb_baddr       (mem_wb_baddr),
    .mem_wb_data        (mem_wb_data),
    .mem_wb_rsd         (mem_wb_rsd)
);

riscv_wb i_riscv_wb (
    .clk                (clk),
    .rstn               (rstn),
    .mem_wb_rdy         (mem_wb_rdy),
    .mem_wb_ack         (mem_wb_ack),
    .data_bif_rdata     (data_bif_rdata),
    .data_bif_ack       (data_bif_ack),
    .mem_wb_funct       (mem_wb_funct),
    .mem_wb_data        (mem_wb_data),
    .mem_wb_rsd         (mem_wb_rsd),
    .wb_rf_data         (wb_rf_data),
    .wb_rf_rsd          (wb_rf_rsd),
    .wb_rf_write        (wb_rf_write)
);

endmodule
