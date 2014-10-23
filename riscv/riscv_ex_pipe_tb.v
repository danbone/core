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
parameter ENABLED   = 1;
parameter BURST_MIN = 1;
parameter BURST_MAX = 3;
parameter STALL_MIN = 1;
parameter STALL_MAX = 5;

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

generate
    if (ENABLED) begin
        //Sanity check
        initial begin
            //Start stalled to avoid undefined behaviour at reset
            stall = STALL_MAX;
            burst = BURST_MAX;
            
            if (BURST_MIN < 1) begin
                $display("ERROR: BURST_MIN must be set > 0");
                $finish;
            end
            $display("INFO: Staller enabled - stall %d:%d burst %d:%d", 
                STALL_MIN, STALL_MAX, BURST_MIN, BURST_MAX);
        end
        
        reg  ack_in;
        reg  rdy_out;
        
        //Bypass ack and rdy if stall count is up and burst count > 0
        always @ (*) begin
            if (stall == 0 && burst > 0) begin
                ack_in = ack_out;
                rdy_out = rdy_in;
            end
            else begin
                ack_in = 1'b0;
                rdy_out = 1'b0;
            end
        end
        
        //Control stall/burst in sync proc
        always @ (posedge clk, negedge rstn) begin
            if (!rstn) begin
                stall = randomize(STALL_MIN, STALL_MAX);
                burst = randomize(BURST_MIN, BURST_MAX);
            end
            else if (clk) begin
                if (stall == 0) begin
                    //Reset the delays
                    if (burst == 0) begin
                        stall = randomize(STALL_MIN, STALL_MAX);
                        burst = randomize(BURST_MIN, BURST_MAX);
                    end
                    //Only decrement burst when ack is up
                    else if (rdy_out && ack_out) begin
                        burst = burst - 1;
                    end
                end
                else begin
                    stall = stall - 1;
                end
            end    
        end
    end
    //Staller disabled
    else begin
        //Bypass
        assign ack_in = ack_out;
        assign rdy_out = rdy_in;
    end
endgenerate

endmodule
