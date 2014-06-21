`include "riscv_functions.vh"

module riscv_ex_pipe_tb ();

localparam NUM_INSTRUCTIONS = 10;
localparam LOCKUP_COUNT = 100;
localparam ALU_OP   = 'h0;
localparam LOAD_OP  = 'h1;
localparam STORE_OP = 'h2;

localparam NUM_ALU_FUNCTS   = 10;
localparam NUM_LOAD_FUNCTS  = 5;
localparam NUM_STORE_FUNCTS = 3;

localparam REG_CHECK_FIFO_W   = 32 + 5;
localparam LOAD_CHECK_FIFO_W  = 32;
localparam STORE_CHECK_FIFO_W = 4+32+32;
localparam NEXT_LOAD_FIFO_W   = 32;

reg                       clk;
reg                       rstn;
reg [1:0]                 operation;

reg [`EX_FUNCT_W-1:0]     alu_functions   [0:NUM_ALU_FUNCTS-1];
reg [`MEM_FUNCT_W-1:0]    load_functions  [0:NUM_LOAD_FUNCTS-1];
reg [`MEM_FUNCT_W-1:0]    store_functions [0:NUM_STORE_FUNCTS-1];

reg                      id_ex_rdy;
reg  [`EX_FUNCT_W-1:0]   id_ex_funct;
reg  [31:0]              id_ex_op1;
reg  [31:0]              id_ex_op2;
reg  [`MEM_FUNCT_W-1:0]  id_ex_mem_funct;
reg  [31:0]              id_ex_mem_data;
reg  [4:0]               id_ex_wb_rsd;
reg  [31:0]              data_bif_rdata;
reg                      data_bif_ack;

wire [31:0] alu_result;
wire [31:0] load_data;
wire [31:0] store_data;

wire        reg_check_fifo_empty;
wire        load_check_fifo_empty;
wire        store_check_fifo_empty;

reg  [REG_CHECK_FIFO_W-1:0]     reg_check_fifo_data_in;
reg                             reg_check_fifo_push;
wire [REG_CHECK_FIFO_W-1:0]     reg_check_fifo_data_in;

reg  [LOAD_CHECK_FIFO_W-1:0]    load_check_fifo_data_in;
reg                             load_check_fifo_push;
wire [LOAD_CHECK_FIFO_W-1:0]    load_check_fifo_data_in;

reg  [STORE_CHECK_FIFO_W-1:0]   store_check_fifo_data_in;
reg                             store_check_fifo_push;
wire [STORE_CHECK_FIFO_W-1:0]   store_check_fifo_data_in;

reg  [NEXT_LOAD_FIFO_W-1:0]     next_load_fifo_data_in;
reg                             next_load_fifo_push;
wire [NEXT_LOAD_FIFO_W-1:0]     next_load_fifo_data_in;

always clk = #5 ~clk;

initial begin
    clk  = 1'b1;
    rstn = 1'b1;
    //Reset cycle
 #5 rstn = 1'b0;
 #5 rstn = 1'b1;
end

initial begin
    alu_functions[0] = `EX_ADD ;
    alu_functions[1] = `EX_SUB ;
    alu_functions[2] = `EX_OR  ;
    alu_functions[3] = `EX_XOR ;
    alu_functions[4] = `EX_AND ;
    alu_functions[5] = `EX_STL ;
    alu_functions[6] = `EX_STLU;
    alu_functions[7] = `EX_SLL ;
    alu_functions[8] = `EX_SRL ;
    alu_functions[9] = `EX_SRA ;

    load_functions[0] = `MEM_LB ;
    load_functions[1] = `MEM_LH ;
    load_functions[2] = `MEM_LW ;
    load_functions[3] = `MEM_LBU;
    load_functions[4] = `MEM_LHU;

    store_functions[0] = `MEM_SB;
    store_functions[1] = `MEM_SH;
    store_functions[2] = `MEM_SW;
end

task generate_alu_function (output [`EX_FUNCT_W-1:0] funct);
integer rand_var;
begin
    rand_var = $urandom % NUM_ALU_FUNCTS;
    funct = alu_functions[rand_var];
end
endtask

task generate_load_function (output [`MEM_FUNCT_W-1:0] funct);
integer rand_var;
begin
    rand_var = $urandom % NUM_LOAD_FUNCTS;
    funct = load_functions[rand_var];
end
endtask

task generate_store_function (output [`MEM_FUNCT_W-1:0] funct);
integer rand_var;
begin
    rand_var = $urandom % NUM_STORE_FUNCTS;
    funct = store_functions[rand_var];
end
endtask

task stim_generation;
begin
    //ALU or MEM instruction
    id_ex_mem_data = $urandom;
    id_ex_wb_rsd   = $urandom & 'h1f;
    operation      = $urandom % 3;
    case (operation) 
        ALU_OP: begin
            generate_alu_function(id_ex_funct);
            id_ex_op2 = $urandom;
            if (    id_ex_funct == `EX_SLL || 
                    id_ex_funct == `EX_SRL || 
                    id_ex_funct == `EX_SRA   ) begin
                id_ex_op1 = $urandom & 'h1f;
            end
            else begin
                id_ex_op1 = $urandom;
            end
            id_ex_mem_funct = `MEM_NOP;
        end
        LOAD_OP: begin
            generate_load_function(id_ex_mem_funct);
            id_ex_funct = `EX_ADD;
            id_ex_op1 = $urandom;
            id_ex_op2 = $urandom;
            //Ensure they are aligned to their boundary correctly
            if (id_ex_mem_funct == `MEM_LW) begin
                id_ex_op1[1:0] = 2'b00;
                id_ex_op2[1:0] = 2'b00;
            end
            else if (id_ex_mem_funct == `MEM_LH || id_ex_mem_funct == `MEM_LHU) begin
                id_ex_op1[0] = 1'b0;
                id_ex_op2[0] = 1'b0;
            end
        end
        STORE_OP: begin
            generate_store_function(id_ex_mem_funct);
            id_ex_funct = `EX_ADD;
            id_ex_op1 = $urandom;
            id_ex_op2 = $urandom;
            //Ensure they are aligned to their boundary correctly
            if (id_ex_mem_funct == `MEM_SW) begin
                id_ex_op1[1:0] = 2'b00;
                id_ex_op2[1:0] = 2'b00;
            end
            else if (id_ex_mem_funct == `MEM_SH) begin
                id_ex_op1[0] = 1'b0;
                id_ex_op2[0] = 1'b0;
            end
        end
    endcase
end
endtask

always @ (posedge clk) begin
    if (~rstn) begin
        //Reset inputs
        id_ex_rdy       <= 'h0;
        id_ex_funct     <= 'h0;
        id_ex_op1       <= 'h0;
        id_ex_op2       <= 'h0;
        id_ex_mem_funct <= 'h0;
        id_ex_mem_data  <= 'h0;
        id_ex_wb_rsd    <= 'h0;
        //Simulation controls
        stall_count     <= 0;
    end
    else begin
        if (id_ex_rdy) begin
            stall_count <= 0;
            if (instruction_count < NUM_INSTRUCTIONS) begin
                instruction_count <= instruction_count + 1;
                stim_generation();
            end
            else begin 
                stim_finished <= 1'b1;
            end
        end
        else begin
            stall_count <= stall_count + 1;
        end
    end
end

always @ (*) begin
    if (stall_count >= LOCKUP_COUNT) begin
        $display("FAIL: Lock up detected");
        $finish;
    end
end

initial begin
    @ (stim_finished && reg_check_fifo_empty && load_check_fifo_empty && 
            store_check_fifo_empty);
    $display("PASS: Simulation finished");
    $finish;
end


//Checks register writes
riscv_fifo #( 
        .DEPTH             (5),
        .DATA_W            (32 + 5),
        .ASSERT_OVERFLOW   (1),
        .ASSERT_UNDERFLOW  (1),
        .ENABLE_BYPASS     (0)
    )
    reg_check_fifo (
        .clk                (clk),
        .rstn               (rstn),
        .fifo_data_in       (reg_check_fifo_data_in),
        .fifo_push          (reg_check_fifo_push),
        .fifo_data_out      (reg_check_fifo_data_out),
        .fifo_pop           (check_reg),
        //.fifo_full          (),
        .fifo_empty         (reg_check_fifo_empty),
        .fifo_flush         (1'b0)
);

//Checks load addresses
riscv_fifo #( 
        .DEPTH             (5),
        .DATA_W            (32),
        .ASSERT_OVERFLOW   (1),
        .ASSERT_UNDERFLOW  (1),
        .ENABLE_BYPASS     (0)
    )
    load_check_fifo (
        .clk                (clk),
        .rstn               (rstn),
        .fifo_data_in       (load_check_fifo_data_in),
        .fifo_push          (load_check_fifo_push),
        .fifo_data_out      (load_check_fifo_data_out),
        .fifo_pop           (check_reg),
        //.fifo_full          (),
        .fifo_empty         (load_check_fifo_empty),
        .fifo_flush         (1'b0)
);

//Store check fifo
riscv_fifo #( 
        .DEPTH             (5),
        .DATA_W            (4+32+32),
        .ASSERT_OVERFLOW   (1),
        .ASSERT_UNDERFLOW  (1),
        .ENABLE_BYPASS     (0)
    )
    store_check_fifo (
        .clk                (clk),
        .rstn               (rstn),
        .fifo_data_in       (store_check_fifo_data_in),
        .fifo_push          (store_check_fifo_push),
        .fifo_data_out      (store_check_fifo_data_out),
        .fifo_pop           (check_store),
        //.fifo_full          (),
        .fifo_empty         (store_check_fifo_empty),
        .fifo_flush         (1'b0)
);

//Next load data, holds rdata for pending loads
riscv_fifo #( 
        .DEPTH             (5),
        .DATA_W            (32),
        .ASSERT_OVERFLOW   (1),
        .ASSERT_UNDERFLOW  (1),
        .ENABLE_BYPASS     (0)
    )
    next_load_fifo (
        .clk                (clk),
        .rstn               (rstn),
        .fifo_data_in       (next_load_fifo_data_in),
        .fifo_push          (next_load_fifo_push),
        .fifo_data_out      (next_load_fifo_data_out),
        .fifo_pop           (next_load_fifo_pop),
        //.fifo_full          (),
        //.fifo_empty         (),
        .fifo_flush         (1'b0)
);

always @ (*) begin
    //Default assignments
    reg_check_fifo_push      = 1'b0;
    load_check_fifo_push     = 1'b0;
    store_check_fifo_push    = 1'b0;
    next_load_fifo_push      = 1'b0;
    //Modeling logic
    if (id_ex_rdy && id_ex_ack) begin
        case (operation) 
            //ALU_OP
            ALU_OP: begin 
                case (id_ex_funct) 
                    `EX_ADD : alu_result = id_ex_op1 + id_ex_op2;
                    `EX_SUB : alu_result = id_ex_op1 - id_ex_op2;
                    `EX_OR  : alu_result = id_ex_op1 | id_ex_op2;
                    `EX_XOR : alu_result = id_ex_op1 ^ id_ex_op2;
                    `EX_AND : alu_result = id_ex_op1 & id_ex_op2;
                    `EX_STL : alu_result = ($signed(id_ex_op1) < $signed(id_ex_op2)) 
                                            ?  1'b1 : 1'b0;
                    `EX_STLU: alu_result = (id_ex_op1 < id_ex_op2) ? 1'b1 : 1'b0;
                    `EX_SLL : alu_result = id_ex_op1 << id_ex_op2;
                    `EX_SRL : alu_result = id_ex_op1 >> id_ex_op2;
                    `EX_SRA : alu_result = id_ex_op1 >>> id_ex_op2;
                    default : alu_result = 32'b0;
                endcase
                reg_check_fifo_data_in = {id_ex_wb_rsd, alu_result};
                reg_check_fifo_push    = 1'b1;
            end
            //LOAD_OP
            LOAD_OP: begin 
                mem_address = id_ex_op1 + id_ex_op2;
                next_load_data = $urandom;
                //Check address alignment
                if ((id_ex_mem_funct == `MEM_LH || id_ex_mem_funct == `MEM_LHU) && 
                        mem_address[0]) begin
                    $display(
                        "STIM ERROR Misaligned memory address for half word load: %x", 
                        mem_address);
                    $finish;
                end
                else if (id_ex_mem_funct == `MEM_LW && |(mem_address[1:0])) begin
                    $display(
                        "STIM ERROR Misaligned memory address for word load: %x", 
                        mem_address);
                    $finish;
                end
                //Figure out rdata
                case (id_ex_mem_funct) 
                    `MEM_LB, 
                    `MEM_LBU : load_data = (next_load_data 
                                            >> (8*mem_address[1:0])) & 'hf;
                    `MEM_LH, 
                    `MEM_LHU : load_data = (next_load_data 
                                            >> (8*mem_address[1:0])) & 'hff;
                    `MEM_LW  : load_data = next_load_data;
                endcase
                //Store expected write data
                reg_check_fifo_push     = 1'b1;
            //Sign extend
                if (id_ex_mem_funct == `MEM_LB) begin
                    reg_check_fifo_data_in  = {{24{load_data[7]}}, load_data[7:0]};
                end
                else if (id_ex_mem_funct == `MEM_LH) begin
                    reg_check_fifo_data_in  = {{16{load_data[15]}}, load_data[15:0]};
                end
                else begin
                    reg_check_fifo_data_in  = load_data;
                end
                next_load_fifo_data_in = next_load_data;
                next_load_fifo_push    = 1'b1;
                //Store expected load address
                load_check_fifo_data_in = {mem_address[31:2], 2'b0};
                load_check_fifo_push    = 1'b1;
                end
            //STORE_OP
            STORE_OP: begin
                mem_address = id_ex_op1 + id_ex_op2;
                //Check address alignment
                if (id_ex_mem_funct == `MEM_SH && mem_address[0]) begin
                    $display(
                        "STIM ERROR Misaligned memory address for half word store: %x",
                        mem_address);
                    $finish;
                end
                else if (id_ex_mem_funct == `MEM_SW && |(mem_address[1:0])) begin
                    $display(
                        "STIM ERROR Misaligned memory address for word store: %x", 
                        mem_address);
                $finish;
                end
                case (id_ex_mem_funct) 
                    `MEM_SB: begin 
                        store_wmask = 'h1; 
                        store_data = {4{id_ex_mem_data[7:0]}};
                    end
                    `MEM_SH: begin
                        store_wmask = 'h3; 
                        store_data = {2{id_ex_mem_data[15:0]}};
                    end
                    //STORE WORD
                    default: begin
                        store_wmask = 'hF; 
                        store_data = id_ex_mem_data;
                    end
                endcase
                store_check_fifo_data_in = {(store_wmask << mem_address[1:0]), 
                                                store_data, mem_address};
                store_check_fifo_push    = 1'b1;
            end
            //Illegal input
            default: begin
                $display("FATAL: Input is illegal:");
                $display("    id_ex_rdy: %x",       id_ex_rdy);
                $display("    id_ex_funct: %x",     id_ex_funct);
                $display("    id_ex_op1: %x",       id_ex_op1);
                $display("    id_ex_op2: %x",       id_ex_op2);
                $display("    id_ex_mem_funct: %x", id_ex_mem_funct);
                $display("    id_ex_mem_data: %x",  id_ex_mem_data);
                $display("    id_ex_wb_rsd: %x",    id_ex_wb_rsd);
                $finish;
            end
        endcase
    end
end

//BIF BFM
always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        data_bif_rdata      <= 32'h0;
        data_bif_ack        <= 1'b0;
        data_bif_rvalid     <= 1'b0;
        next_load_fifo_pop  <= 1'b0;
    end
    else begin
        data_bif_ack        <= 1'b1;
        if (data_bif_req && data_bif_rnw) begin
            data_bif_rdata     <= next_load_fifo_data_out;
            data_bif_rvalid    <= 1'b1;
            next_load_fifo_pop <= 1'b1;
        end
        else begin
            data_bif_rvalid    <= 1'b0; 
            next_load_fifo_pop <= 1'b0;
        end
    end
end

reg check_load;
reg check_store;
reg check_reg;

//Checker comb
always @ (*) begin
    check_load  = 1'b0;
    check_store = 1'b0;
    check_reg   = 1'b0;
    if (data_bif_req && data_bif_ack) begin
        if (data_bif_rnw) begin
            check_load = 1'b1;
            load_check_fifo_pop = 1'b1;
            sim_load_addr = load_check_fifo_data_out;
            rtl_load_addr = data_bif_addr;
        end
        else begin
            check_store = 1'b1;
            store_check_fifo_pop = 1'b1;
            sim_store_addr  = store_check_fifo_data_out[31:0];
            sim_store_wdata = store_check_fifo_data_out[63:32];
            sim_store_wmask = store_check_fifo_data_out[67:64];
            rtl_store_addr  = data_bif_addr;
            rtl_store_wdata = data_bif_wdata;
            rtl_store_wmask = data_bif_wmask;
        end
    end
    if (wb_rf_write) begin
        check_reg = 1'b1;
        sim_reg_wdata = reg_check_fifo_data_out[31:0];
        sim_reg_rsd   = reg_check_fifo_data_out[36:32];
        rtl_reg_wdata = wb_rf_data;
        rtl_reg_rsd   = wb_rf_rsd;
    end
end

reg mismatch_load;
reg mismatch_store;
reg mismatch_reg;

//Checker 
always @ (posedge clk) begin
    if (~rstn) begin
        mismatch_load  = 1'b0;
        mismatch_store = 1'b0;
        mismatch_reg   = 1'b0;
    end
    else begin
        if (check_load) begin
            if (sim_load_addr != rtl_load_addr) begin
                mismatch_load = 1'b1;
                $display("sim_load_addr != rtl_load_addr : %x != %x", 
                    sim_load_addr, rtl_load_addr);
            end
        end
        else if (check_store) begin
            if (    sim_store_wmask != rtl_store_wmask ||
                    sim_store_wdata != rtl_store_wdata ||
                    sim_store_addr  != rtl_store_addr    ) begin
                mismatch_store = 1'b1;
                $display("sim_store_wmask != rtl_store_wmask : %x != %x", 
                    sim_store_wmask, rtl_store_wmask);
                $display("sim_store_wdata != rtl_store_wdata : %x != %x", 
                    sim_store_wdata, rtl_store_wdata);
                $display("sim_store_addr  != rtl_store_addr : %x != %x", 
                    sim_store_addr, rtl_store_addr); 
            end
        end
        else if (check_reg) begin
            if (     sim_reg_wdata != rtl_reg_wdata ||
                     sim_reg_rsd   != rtl_reg_rsd     ) begin
                mismatch_reg = 1'b1;
                $display("sim_reg_wdata != rtl_reg_wdata : %x != %x", 
                    sim_reg_wdata, rtl_reg_wdata);
                $display("sim_reg_rsd   != rtl_reg_rsd : %x != %x", 
                    sim_reg_rsd, rtl_reg_rsd);  
             end
        end
        if (mismatch_load || mismatch_store || mismatch_reg) begin
            $display("ERROR: mismatches load (%0b) store (%0b) reg (%0b)", 
                mismatch_load, mismatch_store, mismatch_reg);
            $finish;
        end
    end
end

//DUT
riscv_ex_pipe i_riscv_ex_pipe (
    .clk             (clk),
    .rstn            (rstn),
    .id_ex_rdy       (id_ex_rdy),
    .id_ex_funct     (id_ex_funct),
    .id_ex_op1       (id_ex_op1),
    .id_ex_op2       (id_ex_op2),
    .id_ex_mem_funct (id_ex_mem_funct),
    .id_ex_mem_data  (id_ex_mem_data),
    .id_ex_wb_rsd    (id_ex_wb_rsd),
    .data_bif_rdata  (data_bif_rdata),
    .data_bif_ack    (data_bif_ack),
    .data_bif_addr   (data_bif_addr),
    .data_bif_req    (data_bif_req),
    .data_bif_rnw    (data_bif_rnw),
    .data_bif_rvalid (data_bif_rvalid),
    .data_bif_wmask  (data_bif_wmask),
    .data_bif_wdata  (data_bif_wdata),
    .wb_rf_data      (wb_rf_data),
    .wb_rf_rsd       (wb_rf_rsd),
    .wb_rf_write     (wb_rf_write)
);

endmodule
