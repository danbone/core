`include "riscv_functions.vh"

module riscv_mem (
    input                       clk,
    input                       rstn,
    //Downstream
    input                       ds_rdy,
    output                      ds_ack,
    //MEM input
    input  [31:0]               ex_mem_result,
    input  [`MEM_FUNCT_W-1:0]   ex_mem_funct,
    input  [31:0]               ex_mem_data,
    input  [4:0]                ex_mem_wb_rsd
    //Upstream 
    input                       us_rdy,
    output                      us_ack,
    //Mem bus output
    output [31:0]               data_bif_addr,
    output                      data_bif_req,
    output                      data_bif_rnw,
    output [3:0]                data_bif_wmask,
    output [31:0]               data_bif_wdata,
    //WB output
    output [`MEM_FUNCT_W-1:0]   mem_wb_funct,
    output                      mem_wb_load_req,
    output [31:0]               mem_wb_data,
    output [4:0]                mem_wb_rsd
);

reg                      us_rdy_reg;

//This module cannot stall
assign ds_ack = us_rdy;
assign us_rdy = us_rdy_reg;

reg [3:0] wmask_raw;
reg [3:0] wmask_rotated;

assign data_bif_addr  = ex_mem_result;
assign data_bif_rnw   = store_request;
assign data_bif_req   = (ex_mem_funct == `MEM_NOP) ? 1'b0 : 1'b1;
assign data_bif_wmask = wmask_rotated;

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        us_rdy_reg     <= 1'b0;
    end
    else begin
        if (us_rdy_reg && us_ack) begin
            us_rdy_reg     <= ds_rdy;
        end
    end
end

endmodule
