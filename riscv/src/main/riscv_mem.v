module riscv_mem (
    input                       clk,
    input                       rstn,
    //EX input
    input                       ex_mem_rdy,
    output                      ex_mem_ack,
    input  [31:0]               ex_mem_st_data,
    input  [`LD_FUNCT_W-1:0]    ex_mem_ld_funct,
    input  [`ST_FUNCT_W-1:0]    ex_mem_st_funct,
    input  [31:0]               ex_mem_addr,
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

reg         ld_op;
reg         st_op;

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

always @ (*) begin
    case (ex_mem_ld_funct)
        LD_LB:   mem_rf_data_n = {{24{data_bif_rdata[7]}} ,  data_bif_rdata[7:0]};
        LD_LH:   mem_rf_data_n = {{16{data_bif_rdata[15]}},  data_bif_rdata[15:0]};
        LD_LW:   mem_rf_data_n = data_bif_rdata;
        LD_LBU:  mem_rf_data_n = {24'b0,  data_bif_rdata[7:0]};
        LD_LHU:  mem_rf_data_n = {16'b0,  data_bif_rdata[15:0]};
        default: mem_rf_data_n = ex_mem_addr;
    endcase
end

always @ (*) begin
    case (ex_mem_st_funct) 
        `ST_SB:  data_bif_wmask = 4'b0001;            
        `ST_SH:  data_bif_wmask = 4'b0011;            
        `ST_SW:  data_bif_wmask = 4'b1111;            
        default: data_bif_wmask = 4'b0000;
    endcase
end

//RF data rdy logic
//If load pending and data_bif_ack or (NOP) then rf write 


reg         mem_wb_rdy;
reg [31:0]  mem_wb_data;
reg         ex_mem_ack;

always @ (*) begin
    if (mem_wb_rdy && !mem_wb_ack) begin
        ex_mem_ack = 1'b0;
    end
    else begin
        ex_mem_ack = 1'b1;
    end
end

always @ (posedge clk, negedge rstn) begin
    if (!rstn) begin
        mem_wb_rdy <= 1'b0;
        mem_wb_data <= 32'b0;
    end
    else if (clk) begin
        if (!mem_wb_rdy || mem_wb_ack) begin
            mem_wb_rdy <= ex_mem_rdy;
            mem_wb_data <= ex_mem_data;
        end
    end
end

endmodule
