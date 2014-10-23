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

reg               id_ex_rdy_raw;
wire              id_ex_ack_raw;
reg  [31:0]       id_ex_data_raw;


initial begin
        count = 0;
        clk  = 1'b0;
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
    if (rstn == 1) begin
        if (count < 10) begin
            id_ex_rdy <= 1'b1;
            count <= count + 1;
            if (id_ex_rdy_raw && id_ex_ack_raw) begin
                id_ex_data_raw <= $urandom;
                id_ex_rdy_raw <= 1'b1;
            end
            else if (!id_ex_rdy_raw) begin
                id_ex_rdy_raw  <= 1'b1;
                id_ex_data_raw <= $urandom;
            end
            //Else stalled
        end
        else begin
            $finish;
        end
    end
end

rand_staller i_frontend_staller (
    .clk            (clk),
    .rstn           (rstn),
    .rdy_in         (id_ex_rdy_raw),
    .ack_in         (id_ex_ack_raw),
    .data_in        (id_ex_data_raw),
    .rdy_out        (id_ex_rdy),
    .ack_out        (id_ex_ack),
    .data_out       (id_ex_data)
);

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
    input [DATA_W-1:0] data_in,
    output  rdy_out,
    input   ack_out,
    output [DATA_W-1:0] data_out
);
parameter ENABLED   = 1;
parameter DATA_W    = 32;
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
            
            if (STALL_MIN < 0) begin
                $display("ERROR: STALL_MIN < 0");
                $finish;
            end
            
            if (BURST_MIN < 0) begin
                $display("ERROR: BURST_MIN < 0");
                $finish;
            end
            
            if (BURST_MAX < BURST_MIN) begin
                $display("ERROR: BURST_MAX is less than BURST_MIN");
                $finish;
            end
            if (STALL_MAX < STALL_MIN) begin
                $display("ERROR: STALL_MAX is less than STALL_MIN");
                $finish;
            end
            
            $display("INFO: Staller enabled - stall %d:%d burst %d:%d", 
                STALL_MIN, STALL_MAX, BURST_MIN, BURST_MAX);
        end
        
        reg              ack_in;
        reg              rdy_out;
        //Treat data_out as a latch as its only sampled on handshake
        reg [DATA_W-1:0] data_out;
        
        //Bypass ack and rdy if stall count is up and burst count > 0
        always @ (*) begin
            if (stall == 0 && burst > 0) begin
                ack_in = ack_out;
                rdy_out = rdy_in;
                data_out = data_in;
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
        wire              ack_in;
        wire              rdy_out;
        wire [DATA_W-1:0] data_out;
        //Bypass
        assign ack_in = ack_out;
        assign rdy_out = rdy_in;
        assign data_out = data_in;
    end
endgenerate

endmodule
