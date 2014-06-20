`include "riscv_functions.vh"

module riscv_ex (
    input                       clk,
    input                       rstn,
    //Downstream
    input                       ds_rdy,
    output                      ds_ack,
    //ID input
    input  [`EX_FUNCT_W-1:0]    id_ex_funct,
    input  [31:0]               id_ex_op1,
    input  [31:0]               id_ex_op2,
    input  [`MEM_FUNCT_W-1:0]   id_ex_mem_funct,
    input  [31:0]               id_ex_mem_data,
    input  [4:0]                id_ex_wb_rsd,
    //Upstream 
    input                       us_rdy,
    output                      us_ack,
    //MEM output
    output [31:0]               ex_mem_result,
    output [`MEM_FUNCT_W-1:0]   ex_mem_funct,
    output [31:0]               ex_mem_data,
    output [4:0]                ex_mem_wb_rsd
);

//Outputs
reg                      us_rdy_reg;
reg  [31:0]              ex_mem_result;
reg  [`MEM_FUNCT_W-1:0]  ex_mem_funct;
reg  [31:0]              ex_mem_data;
reg  [4:0]               ex_mem_wb_rsd;


wire                     flip_op2;
wire [31:0]              neg_op2;
wire [5:0]               shft_amnt;

wire [31:0]              op2;

reg  [31:0]              result;

assign neg_op2   = (~id_ex_op2) + 1;
assign shft_amnt = id_ex_op2 & 'h1f;
assign op2       = (flip_op2) ? neg_op2 : id_ex_op2;

always @ (*) begin
    case (id_ex_funct) 
        `EX_ADD ,
        `EX_SUB : result = id_ex_op1 + id_ex_op2;
        `EX_OR  : result = id_ex_op1 | id_ex_op2;
        `EX_XOR : result = id_ex_op1 ^ id_ex_op2;
        `EX_AND : result = id_ex_op1 & id_ex_op2;
        `EX_STL : result = ($signed(id_ex_op1) < $signed(id_ex_op2)) ?  1'b1 : 1'b0;
        `EX_STLU: result = (id_ex_op1 < id_ex_op2) ? 1'b1 : 1'b0;
        `EX_SLL : result = id_ex_op1 << shft_amnt;
        `EX_SRL : result = id_ex_op1 >> shft_amnt;
        `EX_SRA : result = id_ex_op1 >>> shft_amnt;
        default : result = 32'b0;
    endcase
end

//This module cannot stall
assign ds_ack = us_rdy;
assign us_rdy = us_rdy_reg;

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        us_rdy_reg     <= 1'b0;
        ex_mem_result  <= 'h0;
        ex_mem_funct   <= `MEM_NOP;
        ex_mem_data    <= 'h0;
        ex_mem_wb_rsd  <= 'h0;
    end
    else begin
        if (us_rdy_reg && us_ack) begin
            us_rdy_reg     <= ds_rdy;
            ex_mem_result  <= result;
            ex_mem_funct   <= id_ex_mem_funct;
            ex_mem_data    <= id_ex_mem_data;
            ex_mem_wb_rsd  <= id_ex_wb_rsd;
        end
    end
end

endmodule

`ifdef EX_TB
module tb ();

reg tb_clk  = 1'b0;
reg tb_rstn = 1'b0;

//Generate stimulus
always @ (posedge clk) begin
end

//Check process
always @ (posedge clk) begin
    if (~tb_rstn) begin
        check_fifo_flush <= 1'b1;
    end
    else begin
        check_fifo_flush <= 1'b0;
        check_fifo_read  <= 1'b0;
        if (us_rdy && us_ack) begin
            if (check_fifo_empty) begin
                $display("ERROR: DUT output rdy but no data in check fifo");
                $finish();
            end
            else begin
                check_fifo_mem_funct  = check_fifo_rdata[`CHECK_FIFO_MEM_FUNCT_RANGE];
                check_fifo_mem_data   = check_fifo_rdata[`CHECK_FIFO_MEM_DATA_RANGE ];
                check_fifo_mem_result = check_fifo_rdata[`CHECK_FIFO_RESULT_RANGE   ];
                check_fifo_wb_rsd     = check_fifo_rdata[`CHECK_FIFO_WB_RSD_RANGE   ];
                check_fifo_trans_cnt  = check_fifo_rdata[`CHECK_FIFO_TRANS_CNT_RANGE];

                if (check_fifo_mem_funct != dut_mem_funct) begin
                    $display("ERROR: dut_mem_funct mismatch for trans : %0d", 
                        check_fifo_trans_cnt);
                    check_fifo_mismatch |= 1;
                end
                if (check_fifo_mem_data != dut_mem_data) begin
                    $display("ERROR: dut_mem_data mismatch for trans : %0d", 
                        check_fifo_trans_cnt);
                    check_fifo_mismatch |= 1;
                end
                if (check_fifo_mem_result != dut_mem_result) begin
                    $display("ERROR: dut_mem_result mismatch for trans : %0d", 
                        check_fifo_trans_cnt);
                    check_fifo_mismatch |= 1;
                end
                if (check_fifo_wb_rsd != dut_wb_rsd) begin
                    $display("ERROR: dut_wb_rsd mismatch for trans : %0d", 
                        check_fifo_trans_cnt);
                    check_fifo_mismatch |= 1;
                end
                if (check_fifo_mismatch) begin
                    $display("Test ending due to mismatches");
                    $finish();
                end
                else begin
                    $display("Match for trans : %0d", check_fifo_trans_cnt);
                    check_fifo_read <= 1'b1;
                end
            end
        end
    end
end

endmodule
`endif
