`include "riscv_functions.vh"
module riscv_ex_pipe_tb ();

/*
`define ASSERT_MATCH(A, B)                              \
    if (A != B) begin                                   \
        $display("ERROR: Mismatch %s != %s - %X vs %X", \
                    `"A`", `"B`", A, B);                \
        $finish;
*/


localparam        INSTR_COUNT = 100;

localparam        ID_EX_BUNDLED_W = (32+32+`EX_FUNCT_W);

reg                         clk;
reg                         rstn;

reg                         id_ex_rdy;
wire                        id_ex_ack;
reg [`EX_FUNCT_W-1:0]       id_ex_funct;
reg [31:0]                  id_ex_op1;
reg [31:0]                  id_ex_op2;

wire                        mem_wb_rdy;
wire                        mem_wb_ack;
wire [31:0]                 mem_wb_data;

reg  [31:0]                 check_fifo_data_in;
reg                         check_fifo_push;
wire [31:0]                 check_fifo_data_out;
reg                         check_fifo_pop;
wire                        check_fifo_full;
wire                        check_fifo_empty;
reg                         check_fifo_flush;

wire                        id_ex_rdy_rstl;
wire                        id_ex_ack_rstl;
reg [`EX_FUNCT_W-1:0]       id_ex_funct_rstl;
reg [31:0]                  id_ex_op1_rstl;
reg [31:0]                  id_ex_op2_rstl;

reg  [ID_EX_BUNDLED_W-1:0]  id_ex_bundled_in;
wire [ID_EX_BUNDLED_W-1:0]  id_ex_bundled_out;
integer                     count;

`ifdef WAVES
initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, riscv_ex_pipe_tb);
end
`endif

/////////////////////////////////////////////////////////////////////////////////////////
//Clock and initial assignments 
/////////////////////////////////////////////////////////////////////////////////////////
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
end

/////////////////////////////////////////////////////////////////////////////////////////
//Stimulus
/////////////////////////////////////////////////////////////////////////////////////////
task gen_stim;
integer funct_rand;
integer op1_rand;
integer op2_rand;
begin
    funct_rand = $urandom % `NUM_EX_FUNCTS;
    case (funct_rand) 
        0:  id_ex_funct = `EX_NOP;
        1:  id_ex_funct = `EX_ADD;
        2:  id_ex_funct = `EX_SUB;
        3:  id_ex_funct = `EX_OR;
        4:  id_ex_funct = `EX_XOR;
        5:  id_ex_funct = `EX_AND;
        6:  id_ex_funct = `EX_STL;
        7:  id_ex_funct = `EX_STLU;
        8:  id_ex_funct = `EX_SLL;
        9:  id_ex_funct = `EX_SRL;
        10: id_ex_funct = `EX_SRA;
        default: begin $display("RAND ERROR"); $finish; end
    endcase
    op1_rand = $urandom;
    if (id_ex_funct == `EX_SRA || id_ex_funct == `EX_SLL || id_ex_funct == `EX_SRL) begin
        op2_rand = $urandom & 'h1f;
    end
    else begin
        op2_rand = $urandom;
    end
    id_ex_op1 = op1_rand;
    id_ex_op2 = op2_rand;
end
endtask

//Sim control
always @ (posedge clk) begin
    if (rstn == 1) begin
        if (count < INSTR_COUNT) begin
            //Gen new instruction
            if (id_ex_ack) begin
                gen_stim;
                id_ex_rdy <= 1'b1;
                count <= count + 1;
            end
        end
        else begin
            @ (check_fifo_empty == 1);
            $finish;
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
//REF PROC
/////////////////////////////////////////////////////////////////////////////////////////
reg [31:0] result;
always @ (posedge clk) begin
    if (rstn == 1) begin
        if (id_ex_ack_rstl && id_ex_rdy_rstl) begin
            case (id_ex_funct_rstl) 
                `EX_ADD : begin
                     result = id_ex_op1_rstl + id_ex_op2_rstl;
                     $display("Driving funct (EX_ADD) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_SUB : begin
                     result = id_ex_op1_rstl - id_ex_op2_rstl;
                     $display("Driving funct (EX_SUB) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_OR  : begin
                     result = id_ex_op1_rstl | id_ex_op2_rstl;
                     $display("Driving funct (EX_OR) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_XOR : begin
                     result = id_ex_op1_rstl ^ id_ex_op2_rstl;
                     $display("Driving funct (EX_XOR) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_AND : begin
                     result = id_ex_op1_rstl & id_ex_op2_rstl;
                     $display("Driving funct (EX_AND) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_STL : begin
                     result = ($signed(id_ex_op1_rstl) < $signed(id_ex_op2_rstl)) ?  1'b1 : 1'b0;
                     $display("Driving funct (EX_STL) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_STLU: begin
                     result = (id_ex_op1_rstl < id_ex_op2_rstl) ? 1'b1 : 1'b0;
                     $display("Driving funct (EX_STLU) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_SLL : begin
                     result = id_ex_op1_rstl << (id_ex_op2_rstl & 'h1f);
                     $display("Driving funct (EX_SLL) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_SRL : begin
                     result = id_ex_op1_rstl >> (id_ex_op2_rstl & 'h1f);
                     $display("Driving funct (EX_SRL) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                `EX_SRA : begin
                     result = id_ex_op1_rstl >>> (id_ex_op2_rstl & 'h1f);
                     $display("Driving funct (EX_SRA) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
                default : begin
                     result = 32'b0;
                     $display("Driving funct (EX_NOP) op1 (%x) op2 (%x) result (%x)",
                         id_ex_op1_rstl, id_ex_op2_rstl, result); 
                end
            endcase
            check_fifo_data_in <= result;
            check_fifo_push <= 1'b1;
        end
        else begin
            check_fifo_push <= 1'b0;
            check_fifo_data_in <= 32'b0;
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
//CHECK PROC
/////////////////////////////////////////////////////////////////////////////////////////
integer match_count = 0;
always @ (posedge clk) begin
    if (rstn == 1) begin
        if (mem_wb_rdy && mem_wb_ack) begin
            if (check_fifo_data_out != mem_wb_data) begin
                /*
                `ASSERT_MATCH(check_fifo_data_out, mem_wb_data)
                */
                $display(
                    "ERROR: Mismatch check_fifo_data_out != mem_wb_data - %8X vs %8X",
                    check_fifo_data_out, mem_wb_data);
                $finish;
            end
            else begin
                match_count = match_count + 1;
                $display("Match: %0d REF: %x DUT: %X", match_count, check_fifo_data_out, mem_wb_data);
            end
        end
    end
end

/////////////////////////////////////////////////////////////////////////////////////////
//Component instantiations
/////////////////////////////////////////////////////////////////////////////////////////
//Bundled proc
always @ (*) begin
    id_ex_bundled_in = {id_ex_op1, id_ex_op2, id_ex_funct};
    {id_ex_op1_rstl, id_ex_op2_rstl, id_ex_funct_rstl} = id_ex_bundled_out;
end

rand_staller #(
        .ENABLED        (1),
        .DATA_W         (ID_EX_BUNDLED_W),
        .BURST_MIN      (1),
        .BURST_MAX      (3),
        .STALL_MIN      (1),
        .STALL_MAX      (5)
    ) 
    i_frontend_staller (
        .clk            (clk),
        .rstn           (rstn),
        .rdy_in         (id_ex_rdy),
        .ack_in         (id_ex_ack),
        .data_in        (id_ex_bundled_in),
        .rdy_out        (id_ex_rdy_rstl),
        .ack_out        (id_ex_ack_rstl),
        .data_out       (id_ex_bundled_out)
);

//Leave outputs unconnected as ack will be stalled
rand_staller #(
        .ENABLED        (1),
        //.DATA_W         (ID_EX_BUNDLED_W)
        .BURST_MIN      (1),
        .BURST_MAX      (3),
        .STALL_MIN      (1),
        .STALL_MAX      (5)
    ) 
    i_backend_staller (
    .clk            (clk),
    .rstn           (rstn),
    .rdy_in         (mem_wb_rdy),
    .ack_in         (mem_wb_ack),
    .data_in        (mem_wb_data),
    .rdy_out        (),
    .ack_out        (1'b1),
    .data_out       ()
);

sync_fifo #(
        .DEPTH            (3),
        .DATA_W           (32),
        .ASSERT_OVERFLOW  (1),
        .ASSERT_UNDERFLOW (1),
        .ENABLE_BYPASS    (1)
    ) 
    i_check_fifo (
        .clk              (clk),
        .rstn             (rstn),
        .fifo_data_in     (check_fifo_data_in),
        .fifo_push        (check_fifo_push),
        .fifo_data_out    (check_fifo_data_out),
        .fifo_pop         (mem_wb_rdy && mem_wb_ack),
        .fifo_full        (check_fifo_full),
        .fifo_empty       (check_fifo_empty),
        .fifo_flush       (1'b0)
/*
        .fifo_data_in     (check_fifo_data_in),
        .fifo_push        (check_fifo_push),
        .fifo_data_out    (check_fifo_data_out),
        .fifo_pop         (check_fifo_pop),
        .fifo_full        (check_fifo_full),
        .fifo_empty       (check_fifo_empty),
        .fifo_flush       (check_fifo_flush)
*/
);

riscv_ex_pipe i_riscv_ex_pipe (
    .clk               (clk),
    .rstn              (rstn),
    .id_ex_rdy         (id_ex_rdy_rstl),
    .id_ex_ack         (id_ex_ack_rstl),
    .id_ex_op1         (id_ex_op1_rstl),
    .id_ex_op2         (id_ex_op2_rstl),
    .id_ex_funct       (id_ex_funct_rstl),
    .mem_wb_rdy        (mem_wb_rdy),
    .mem_wb_ack        (mem_wb_ack),
    .mem_wb_data       (mem_wb_data)
);

endmodule

