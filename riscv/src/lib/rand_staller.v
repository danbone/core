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

function integer randomize(input integer MIN, MAX);
integer range;
begin
    range = MAX - MIN;
    randomize = $urandom % range;
    randomize = randomize + MIN;
end
endfunction

wire              ack_in;
wire              rdy_out;
wire [DATA_W-1:0] data_out;

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
        
        assign rdy_out = (stall == 0 && burst > 0) ? rdy_in : 1'b0;
        assign data_out = (stall == 0 && burst > 0) ? data_in : 1'b0;
        assign ack_in = (stall == 0 && burst > 0) ? ack_out : 1'b0;
        
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
        assign data_out = data_in;
    end
endgenerate

endmodule
