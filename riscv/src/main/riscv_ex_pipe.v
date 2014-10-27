`include "riscv_functions.vh"
module riscv_ex_pipe (
    input                       clk,
    input                       rstn,
    //ID to EX inputs
    input                       id_ex_rdy,
    output                      id_ex_ack,
    input  [31:0]               id_ex_op1,
    input  [31:0]               id_ex_op2,
    input  [`EX_FUNCT_W-1:0]    id_ex_funct,
    //ID to MEM inputs
    input  [31:0]               id_ex_mem_st_data,
    input  [`ST_FUNCT_W-1:0]    id_ex_mem_st_funct,
    input  [`LD_FUNCT_W-1:0]    id_ex_mem_ld_funct,
    //Data bif
    output [31:0]               data_bif_addr,
    output                      data_bif_rnw,
    output                      data_bif_rdy,
    input                       data_bif_ack,
    input  [31:0]               data_bif_rdata,
    output [31:0]               data_bif_wdata,
    output [3:0]                data_bif_wmask,
    //RF output
    output                      mem_rf_rdy,
    output [31:0]               mem_rf_data
);

wire                      clk;
wire                      rstn;
wire                      id_ex_rdy;
wire                      id_ex_ack;
wire  [31:0]              id_ex_op1;
wire  [31:0]              id_ex_op2;
wire  [`EX_FUNCT_W-1:0]   id_ex_funct;
wire  [31:0]              id_ex_mem_st_data;
wire  [`ST_FUNCT_W-1:0]   id_ex_mem_st_funct;
wire  [`LD_FUNCT_W-1:0]   id_ex_mem_ld_funct;
wire                      ex_mem_rdy;
wire                      ex_mem_ack;
wire                      ex_mem_alu_op;
wire  [31:0]              ex_mem_st_data;
wire  [`LD_FUNCT_W-1:0]   ex_mem_ld_funct;
wire  [`ST_FUNCT_W-1:0]   ex_mem_st_funct;
wire  [31:0]              ex_mem_data;
wire  [31:0]              data_bif_addr;
wire                      data_bif_rnw;
wire                      data_bif_rdy;
wire                      data_bif_ack;
wire [31:0]               data_bif_rdata;
wire [31:0]               data_bif_wdata;
wire [3:0]                data_bif_wmask;
wire                      mem_rf_rdy;
wire [31:0]               mem_rf_data;

riscv_ex i_riscv_ex (
    .clk                (clk),
    .rstn               (rstn),
    .id_ex_rdy          (id_ex_rdy),
    .id_ex_ack          (id_ex_ack),
    .id_ex_op1          (id_ex_op1),
    .id_ex_op2          (id_ex_op2),
    .id_ex_funct        (id_ex_funct),
    .id_ex_mem_st_data  (id_ex_mem_st_data),
    .id_ex_mem_st_funct (id_ex_mem_st_funct),
    .id_ex_mem_ld_funct (id_ex_mem_ld_funct),
    .ex_mem_rdy         (ex_mem_rdy),
    .ex_mem_ack         (ex_mem_ack),
    .ex_mem_alu_op      (ex_mem_alu_op),
    .ex_mem_st_data     (ex_mem_st_data),
    .ex_mem_ld_funct    (ex_mem_ld_funct),
    .ex_mem_st_funct    (ex_mem_st_funct),
    .ex_mem_data        (ex_mem_data)
);

riscv_mem i_riscv_mem (
    .clk                (clk),
    .rstn               (rstn),
    .ex_mem_rdy         (ex_mem_rdy),
    .ex_mem_ack         (ex_mem_ack),
    .ex_mem_alu_op      (ex_mem_alu_op),
    .ex_mem_st_data     (ex_mem_st_data),
    .ex_mem_ld_funct    (ex_mem_ld_funct),
    .ex_mem_st_funct    (ex_mem_st_funct),
    .ex_mem_data        (ex_mem_data),
    .data_bif_addr      (data_bif_addr),
    .data_bif_rnw       (data_bif_rnw),
    .data_bif_rdy       (data_bif_rdy),
    .data_bif_ack       (data_bif_ack),
    .data_bif_rdata     (data_bif_rdata),
    .data_bif_wdata     (data_bif_wdata),
    .data_bif_wmask     (data_bif_wmask),
    .mem_rf_rdy         (mem_rf_rdy),
    .mem_rf_data        (mem_rf_data)
);

endmodule
