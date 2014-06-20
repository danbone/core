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
    output [`LD_FUNCT_W-1:0]    mem_wb_funct,
    output [1:0]                mem_wb_baddr,
    output [31:0]               mem_wb_data,
    output [4:0]                mem_wb_rsd
);

reg                     us_rdy_reg;
reg  [3:0]              waddr_wmask;
wire [1:0]              baddr;

wire [31:0]             waddr;
wire                    data_req;


assign baddr          = ex_mem_result[1:0];
assign waddr          = {ex_mem_result[31:2], 2'b0};
assign data_req       = (ex_mem_funct == `MEM_NOP) ? 1'b0 : 1'b1;
/*
assign load_op        = |(ex_mem_funct[`LD_FUNCT_W-1:0]);
*/

assign data_bif_addr  = waddr;
assign data_bif_rnw   = |(ex_mem_funct[`LD_FUNCT_W-1:0]);
assign data_bif_req   = data_req;
assign data_bif_wmask = waddr_mask << baddr_addr;
assign data_bif_wdata = ex_mem_data;
//This module cannot stall
assign ds_ack         = us_rdy;
assign us_rdy         = us_rdy_reg;

always @ (*) begin
    case (ex_mem_funct) 
        LD_LB  : waddr_mask = 4'b0001;
        LD_LH  : waddr_mask = 4'b0011;
        LD_LW  : waddr_mask = 4'b1111;
        LD_LBU : waddr_mask = 4'b0001;
        LD_LBH : waddr_mask = 4'b0011;
        default: waddr_mask = 4'b0000;
    endcase
end

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        us_rdy_reg     <= 1'b0;
        mem_wb_funct   <= `LD_NOP;
        mem_wb_data    <= 'h0;
        mem_wb_rsd     <= 'h0;
    end
    else begin
        if (us_rdy_reg && us_ack) begin
            us_rdy_reg     <= ds_rdy;
            mem_wb_funct   <= ex_mem_funct[`LD_FUNCT_W-1:0];
            mem_wb_data    <= ex_mem_data;
            mem_wb_rsd     <= ex_mem_rsd;
        end
    end
end

endmodule
