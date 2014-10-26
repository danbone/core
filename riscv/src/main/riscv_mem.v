module riscv_mem (
    input               clk,
    input               rstn,
    input               ex_mem_rdy,
    output              ex_mem_ack,
    input  [31:0]       ex_mem_data,
    output              mem_wb_rdy,
    input               mem_wb_ack,
    output [31:0]       mem_wb_data
);

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
