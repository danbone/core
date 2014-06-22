module riscv_ex_pipe_tb ();

reg               clk;
reg               rstn;
reg               id_ex_rdy;
wire              id_ex_ack;
reg  [31:0]       id_ex_data;
wire              mem_wb_rdy;
reg               mem_wb_ack;
wire [31:0]       mem_wb_data;
integer           count;

initial begin
        count = 0;
        clk = 1'b0;
        rstn = 1'b1;
    #5  rstn = 1'b0;
    #5  rstn = 1'b1;
end
always #5 clk = ~clk;

initial begin
    id_ex_rdy   = 1'b0;
    id_ex_data  = 32'b0;
    mem_wb_ack  = 1'b1;
end

always @ (posedge clk) begin
    if (count < 10) begin
        count <= count + 1;
        if (id_ex_ack) begin
            id_ex_data <= $urandom;
            id_ex_rdy <= 1'b1;
        end
        else begin
            id_ex_rdy <= 1'b0;
        end
    end
    else begin
        $finish;
    end
end


initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, i_riscv_ex_pipe);
end

riscv_ex_pipe i_riscv_ex_pipe (
    .clk               (clk),
    .rstn              (rstn),
    .id_ex_rdy         (id_ex_rdy),
    .id_ex_ack         (id_ex_ack),
    .id_ex_data        (id_ex_data),
    .mem_wb_rdy        (mem_wb_rdy),
    .mem_wb_ack        (mem_wb_ack),
    .mem_wb_data       (mem_wb_data)
);

endmodule

module rand_staller (
    input   clk,
    input   rstn,
    input   rdy_in,
    output  ack_in,
    output  rdy_out,
    input   ack_out
);
parameter BURST_MIN = 0;
parameter BURST_MAX = 3;
parameter STALL_MIN = 1;
parameter STALL_MAX = 5;

reg  ack_in;
reg  rdy_out;
reg rdy_hold;

integer burst;
integer stall;

function integer randomize(integer MIN, integer MAX);
integer range;
begin
    range = MAX - MIN;
    randomize = $urandom % range;
    randomize = randomize + MIN;
end
endfunction


assign ack_in = (rdy_out && ack_out) ? 1'b1 : 1'b0;

always @ (*) begin
    if (
end

//NEED to buffer rdy incase we end a burst and rdy_in isn't active

always @ (posedge clk, negedge rstn) begin
    if (!rstn) begin
        rdy_out <= 0;
    end
    else if (clk) begin
        if (rdy_hld == 1'b0) 
        if (rdy_out) begin
            //Wait for ack
            if (ack_out) begin
                if (burst > 0) begin
                    burst <= burst - 1;
                    rdy_out <= rdy_in;
                end
                else begin
                    stall = randomize(STALL_MIN, STALL_MAX);
                    burst = randomize(BURST_MIN, BURST_MAX);
                    rdy_out <= 1'b0;
                end
            end
        end
        //Wait for stall delay to finish
        else if (stall > 0) begin
            stall <= stall -1;
        end
        //Propagate rdy
        else begin
            rdy_out <= rdy_in;
        end
    end
end

endmodule
