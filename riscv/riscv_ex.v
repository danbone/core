module riscv_ex (
    input               clk,
    input               rstn,
    input               id_ex_rdy,
    output              id_ex_ack,
    input  [31:0]       id_ex_data,
    output              ex_mem_rdy,
    input               ex_mem_ack,
    output [31:0]       ex_mem_data
);

reg         ex_mem_rdy;
reg [31:0]  ex_mem_data;
reg         id_ex_ack;

always @ (*) begin
    if (ex_mem_rdy && !ex_mem_ack) begin
        id_ex_ack = 1'b0;
    end
    else begin
        id_ex_ack = 1'b1;
    end
end

always @ (posedge clk, negedge rstn) begin
    if (!rstn) begin
        ex_mem_rdy <= 1'b0;
        ex_mem_data <= 32'b0;
    end
    else if (clk) begin
        if (ex_mem_ack) begin
            ex_mem_rdy <= id_ex_rdy;
            ex_mem_data <= id_ex_data;
        end
    end
end

endmodule
