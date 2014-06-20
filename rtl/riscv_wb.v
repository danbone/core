`include "riscv_functions.vh"

module riscv_wb (
    input                       clk,
    input                       rstn,
    //Downstream
    input                       mem_wb_rdy,
    output                      mem_wb_ack,
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

wire [31:0]             rdata_lsht;
wire [23:0]             sign_ext_byte;
wire [15:0]             sign_ext_half;
wire [23:0]             zero_ext_byte;
wire [15:0]             zero_ext_half;
wire                    load_pending;
wire [1:0]              baddr;

//wb_data = address
assign baddr            = mem_wb_data[1:0];
assign load_pending     = (mem_wb_funct == `LD_NOP || data_bif_ack) ? 1'b0 : 1'b1;
assign rdata_lsht       = data_bif_rdata >> baddr;
assign sign_ext_byte    = {24{rdata_lsht[7]}};
assign sign_ext_half    = {16{rdata_lsht[15]}};
assign zero_ext_byte    = {24{1'b0}};
assign zero_ext_half    = {16{1'b0}};

assign mem_wb_ack           = ~load_pending;

always @ (*) begin
    case (mem_wb_funct) 
        LD_NOP : data = mem_wb_data;
        LD_LB  : data = {sign_ext_byte, rdata_lsht[7:0]};
        LD_LH  : data = {sign_ext_half, rdata_lsht[15:0]};
        LD_LW  : data = rdata_lsht;
        LD_LBU : data = {zero_ext_byte, rdata_lsht[7:0]};
        LD_LHU : data = {zero_ext_half, rdata_lsht[15:0]};
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
        if (mem_wb_rdy && mem_wb_ack) begin
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
