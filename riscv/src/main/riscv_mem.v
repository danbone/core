`include "riscv_functions.vh"
module riscv_mem (
    input                       clk,
    input                       rstn,
    //EX input
    input                       ex_mem_rdy,
    output                      ex_mem_ack,
    input                       ex_mem_alu_op,
    input  [31:0]               ex_mem_st_data,
    input  [`LD_FUNCT_W-1:0]    ex_mem_ld_funct,
    input  [`ST_FUNCT_W-1:0]    ex_mem_st_funct,
    input  [31:0]               ex_mem_data,
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

//Outputs
reg         ex_mem_ack;
reg         data_bif_rdy;
reg         data_bif_rnw;
reg [31:0]  data_bif_addr;
reg [3:0]   data_bif_wmask;
reg [31:0]  data_bif_wdata;
reg [31:0]  mem_rf_data_n;
reg         mem_rf_rdy_n;
reg [31:0]  mem_rf_data;
reg         mem_rf_rdy;

reg         ld_op;
reg         st_op;

//Set data bif controls 
always @ (*) begin
    if (ex_mem_ld_funct != `LD_NOP) begin
        ld_op        = 1'b1;
        st_op        = 1'b0;
        data_bif_rdy = 1'b1;
        data_bif_rnw = 1'b1;
    end
    else if (ex_mem_st_funct != `ST_NOP) begin
        ld_op        = 1'b0;
        st_op        = 1'b1;
        data_bif_rdy = 1'b1;
        data_bif_rnw = 1'b0;
    end
    else begin
        ld_op        = 1'b0;
        st_op        = 1'b0;
        data_bif_rnw = 1'b1;
        data_bif_rdy = 1'b0;
    end
end

//Assign wmask
always @ (*) begin
    case (ex_mem_st_funct) 
        `ST_B  : data_bif_wmask = 4'b0001;            
        `ST_H  : data_bif_wmask = 4'b0011;            
        `ST_W  : data_bif_wmask = 4'b1111;            
        default: data_bif_wmask = 4'b0000;
    endcase
end

//Assign read data
always @ (*) begin
    case (ex_mem_ld_funct)
        `LD_B  : mem_rf_data_n = {{24{data_bif_rdata[7]}} ,  data_bif_rdata[7:0]};
        `LD_H  : mem_rf_data_n = {{16{data_bif_rdata[15]}},  data_bif_rdata[15:0]};
        `LD_W  : mem_rf_data_n = data_bif_rdata;
        `LD_BU : mem_rf_data_n = {24'b0,  data_bif_rdata[7:0]};
        `LD_HU : mem_rf_data_n = {16'b0,  data_bif_rdata[15:0]};
        default: mem_rf_data_n = ex_mem_data;
    endcase
end

//Ack the incoming rdy
always @ (*) begin
    if (data_bif_rdy) begin
        //Only ack if are bus transfer is accepted
        ex_mem_ack = data_bif_ack;
    end
    else begin
        ex_mem_ack = 1'b1;
    end
end

//Do we have write data going to the RF
always @ (*) begin
    mem_rf_rdy_n = 1'b0;
    if (ex_mem_rdy && ex_mem_ack) begin
        if (ld_op || !st_op) begin
            //Must be an ALU op
            mem_rf_rdy_n = ex_mem_alu_op;
        end
    end
end

always @ (posedge clk, negedge rstn) begin
    if (!rstn) begin
        mem_rf_rdy  <= 1'b0;
        mem_rf_data <= 1'b0;
    end
    else begin
        mem_rf_rdy  <= mem_rf_rdy_n;
        mem_rf_data <= mem_rf_data_n;
    end
end

endmodule
