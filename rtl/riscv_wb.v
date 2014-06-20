`include "riscv_functions.vh"

module riscv_mem (
    input                       clk,
    input                       rstn,
    //Downstream
    input                       ds_rdy,
    output                      ds_ack,
    //Upstream 
    input                       us_rdy,
    output                      us_ack,
    //Mem bus input
    input  [31:0]               data_bif_rdata,
    input                       data_bif_ack,
    //MEM input
    input  [`LD_FUNCT_W-1:0]    mem_wb_funct,
    input  [31:0]               mem_wb_data,
    input  [4:0]                mem_wb_rsd,
    //RF output
    output [31:0]               wb_rf_data,
    output [4:0]                wb_rf_rsd,
    output                      wb_rf_write
);

reg                     us_rdy_reg;

wire [31:0]             rdata_lsht;
wire [23:0]             sign_ext_byte;
wire [15:0]             sign_ext_half;
wire [23:0]             zero_ext_byte;
wire [15:0]             zero_ext_half;
wire                    load_pending;

assign load_pending     = (mem_wb_funct == `LD_NOP || data_bif_ack) ? 1'b0 : 1'b1;
assign rdata_lsht       = data_bif_rdata >> baddr;
assign sign_ext_byte    = {24{rdata_lsht[7]}};
assign sign_ext_half    = {16{rdata_lsht[15]}};
assign zero_ext_byte    = {24{1'b0}};
assign zero_ext_half    = {16{1'b0}};

assign ds_ack           = ~load_pending;

always @ (*) begin
    case (mem_wb_funct) 
        LD_NOP : data = mem_wb_data;
        LD_LB  : data = {sign_ext_byte, rdata_lsht[7:0]};
        LD_LH  : data = {sign_ext_half, rdata_lsht[15:0]};
        LD_LW  : data = rdata_lsht;
        LD_LBU : data = {zero_ext_byte, rdata_lsht[7:0]};
        LD_LBH : data = {zero_ext_half, rdata_lsht[15:0]};
        default: begin
            $display("ERROR mem_wb: unknown function: %x", mem_wb_funct);
            $finish;
        end
    endcase
end

/*
 * Pulse wb_rf_write?
 */

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        wb_rf_data  <= 'h0;
        wb_rf_rsd   <= 'h0;
        wb_rf_write <= 'h0;
    end
    else begin
        if (ds_rdy && ds_ack) begin
            wb_rf_data  <= mem_wb_data;
            wb_rf_rsd   <= mem_wb_rsd;
            wb_rf_write <= 1'b1;
        end
        else begin
            wb_rf_data  <= 'h0;
            wb_rf_rsd   <= 'h0;
            wb_rf_write <= 'h0;
        end
    end
end

endmodule
