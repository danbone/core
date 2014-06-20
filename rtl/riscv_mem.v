`include "riscv_functions.vh"

module riscv_mem (
    input                       clk,
    input                       rstn,
    //Downstream
    input                       ex_mem_rdy,
    output                      ex_mem_ack,
    //MEM input
    input  [31:0]               ex_mem_result,
    input  [`MEM_FUNCT_W-1:0]   ex_mem_funct,
    input  [31:0]               ex_mem_data,
    input  [4:0]                ex_mem_wb_rsd,
    //Upstream 
    output                      mem_wb_rdy,
    input                       mem_wb_ack,
    //Mem bus output
    output [31:0]               data_bif_addr,
    output                      data_bif_req,
    output                      data_bif_rnw,
    output [3:0]                data_bif_wmask,
    output [31:0]               data_bif_wdata,
    input                       data_bif_ack,
    //WB output
    output [`LD_FUNCT_W-1:0]    mem_wb_funct,
    output [1:0]                mem_wb_baddr,
    output [31:0]               mem_wb_data,
    output [4:0]                mem_wb_rsd
);

//Output regs
reg [`LD_FUNCT_W-1:0]    mem_wb_funct;
reg [1:0]                mem_wb_baddr;
reg [31:0]               mem_wb_data;
reg [4:0]                mem_wb_rsd;

reg                     mem_wb_rdy_reg;
reg  [3:0]              waddr_mask;
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
assign data_bif_wmask = waddr_mask << (8*baddr_addr);
assign data_bif_wdata = ex_mem_data;
//This module cannot stall
assign ex_mem_ack         = mem_wb_rdy;
assign mem_wb_rdy         = mem_wb_rdy_reg & (~data_req | data_bif_ack);

always @ (*) begin
    case (ex_mem_funct) 
        `MEM_SB : waddr_mask = 4'b0001;
        `MEM_SH : waddr_mask = 4'b0011;
        `MEM_SW : waddr_mask = 4'b1111;
        default : waddr_mask = 4'b0000;
    endcase
end

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        mem_wb_rdy_reg <= 1'b0;
        mem_wb_funct   <= `LD_NOP;
        mem_wb_data    <= 'h0;
        mem_wb_rsd     <= 'h0;
    end
    else begin
        if (mem_wb_rdy  && mem_wb_ack) begin
            mem_wb_rdy_reg <= ex_mem_rdy;
            mem_wb_funct   <= ex_mem_funct[`LD_FUNCT_W-1:0];
            mem_wb_data    <= ex_mem_data;
            mem_wb_rsd     <= ex_mem_wb_rsd;
        end
    end
end

endmodule
