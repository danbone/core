
`define CLOG2(x)          \
    (x <= 2)    ? 1  : \
    (x <= 4)    ? 2  : \
    (x <= 8)    ? 3  : \
    (x <= 16)   ? 4  : \
    (x <= 32)   ? 5  : \
    (x <= 64)   ? 6  : \
    (x <= 128)  ? 7  : \
    (x <= 256)  ? 8  : \
                 -1   

module sync_fifo #(
        parameter   DEPTH            = 3,
        parameter   DATA_W           = 32,
        parameter   ASSERT_OVERFLOW  = 1,
        parameter   ASSERT_UNDERFLOW = 1,
        parameter   ENABLE_BYPASS    = 0
    )
    (
        input                   clk,
        input                   rstn,
        input  [DATA_W-1:0]     fifo_data_in,
        input                   fifo_push,
        output [DATA_W-1:0]     fifo_data_out,
        input                   fifo_pop,
        output                  fifo_full,
        output                  fifo_empty,
        input                   fifo_flush
);

localparam DEPTH_LOG2 = `CLOG2(DEPTH);

reg [DATA_W-1:0]     mem [0:DEPTH-1];
reg [DEPTH_LOG2-1:0] head, n_head;
reg [DEPTH_LOG2-1:0] tail, n_tail;
wire                 empty;
wire                 full;
reg                  push_last;

assign fifo_data_out = mem[tail];

assign fifo_full = full;
assign fifo_empty = empty;

always @ (*) begin
    if (head < DEPTH-1) begin
        n_head = head + 'h1;
    end
    else begin
        n_head = 'h0;
    end
end

always @ (*) begin
    if (tail < DEPTH-1) begin
        n_tail = tail + 'h1;
    end
    else begin
        n_tail = 'h0;
    end
end

generate 
if (ENABLE_BYPASS) begin
    assign full  = (push_last  && (head == tail) && !fifo_pop)  ? 1'b1 : 1'b0;
    assign empty = (!push_last && (head == tail) && !fifo_push) ? 1'b1 : 1'b0;
end
else begin
    assign full  = (push_last  && (head == tail))  ? 1'b1 : 1'b0;
    assign empty = (!push_last && (head == tail))  ? 1'b1 : 1'b0;
end
endgenerate

generate
if (ASSERT_OVERFLOW) begin
    always @ (posedge clk) begin
        if (clk && !fifo_flush && fifo_push && full) begin
            $display("ERROR: FIFO OVERFLOW");
            $finish;
        end
    end
end
if (ASSERT_UNDERFLOW) begin
    always @ (posedge clk) begin
        if (clk && !fifo_flush && fifo_pop && empty) begin
            $display("ERROR: FIFO UNDERFLOW");
            $finish;
        end
    end
end
endgenerate

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        head      <= 'h0;
        tail      <= 'h0;
        push_last <= 'h0;
    end
    else begin
        if (fifo_flush) begin
            tail      <= 'h0;
            head      <= 'h0;
            push_last <= 'h0;
        end
        else if (!((full && fifo_push) || (empty && fifo_pop))) begin
            if (fifo_push) begin
                mem[head] <= fifo_data_in;
                head      <= n_head;
            end
            if (fifo_pop) begin
                tail      <= n_tail;
            end
            if (fifo_push && !fifo_pop) begin
                push_last = 'h1;
            end
            else if (!fifo_push && fifo_pop) begin
                push_last = 'h0;
            end
        end
    end
end

endmodule
