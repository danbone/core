module riscv_ex_pipe_tb ();
localparam ALU_OP   = 'h0;
localparam LOAD_OP  = 'h1;
localparam STORE_OP = 'h2;

localparam NUM_ALU_FUNCTS   = 10;
localparam NUM_LOAD_FUNCTS  = 5;
localparam NUM_STORE_FUCNTS = 3;

reg                       clk;
reg                       rstn;
reg [1:0]                 operation;


reg [`EX_FUNCT_W-1:0]     alu_functions   [0:NUM_ALU_FUNCTS-1];
reg [`MEM_FUNCT_W-1:0]    load_functions  [0:NUM_LOAD_FUNCTS-1];
reg [`MEM_FUNCT_W-1:0]    store_functions [0:NUM_STORE_FUNCTS-1];

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

function [`EX_FUNCT_W-1:0] generate_alu_function();
integer rand_var;
begin
    rand_var = $urandom % NUM_ALU_FUNCTS;
    return alu_functions[rand_var];
end
endfunction

function [`MEM_FUNCT_W-1:0] generate_load_function();
integer rand_var;
begin
    rand_var = $urandom % NUM_LOAD_FUNCTS;
    return load_functions[rand_var];
end
endfunction

function [`MEM_FUNCT_W-1:0] generate_load_function();
integer rand_var;
begin
    rand_var = $urandom % NUM_STORE_FUNCTS;
    return store_functions[rand_var];
end
endfunction

task stim_generation ();
begin
    //ALU or MEM instruction
    id_ex_mem_data = $urandom;
    id_ex_wb_rsd   = $urandom & 'h1f;
    operation      = $urandom % 3;
    case (operation) 
        ALU_OP: begin
            id_ex_funct = generate_alu_function();
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
            id_ex_mem_funct = generate_load_function();
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
            id_ex_mem_funct = generate_store_function();
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

wire [31:0] alu_result;
wire [31:0] load_data;
wire [31:0] store_data;


always @ (*) begin
    //Default assignments
    reg_check_fifo_push      = 1'b0;
    load_check_fifo_push     = 1'b0;
    store_check_fifo_push    = 1'b0;
    next_load_check_fifo_pop = 1'b0;
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
                //Check address alignment
                if ((id_ex_mem_funct == `MEM_LH || id_ex_mem_funct == `MEM_LHU) && 
                        mem_address[0]) begin
                    $display(
                        "STIM ERROR Misaligned memory address for half word load: %x", 
                        mem_address);
                    $finish;
                end
                else if (id_ex_mem_funct == `MEM_LW && |(mem_address[1:0])) begin
                    $display("
                        STIM ERROR Misaligned memory address for word load: %x", 
                        mem_address);
                    $finish;
                end
                //Figure out rdata
                case (id_ex_mem_funct) 
                    `MEM_LB, 
                    `MEM_LBU : load_data = (next_load_check_fifo_data_out 
                                            >> (8*mem_address[1:0])) & 'hf;
                    `MEM_LH, 
                    `MEM_LHU : load_data = (next_load_check_fifo_data_out 
                                            >> (8*mem_address[1:0])) & 'hff;
                    `MEM_LW  : load_data = next_load_check_fifo_data_out;
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
                next_load_check_fifo_pop = 1'b1;
                //Store expected load address
                load_check_fifo_data_in = {mem_address[31:2], 2'b0};
                load_check_fifo_push    = 1'b1;
                end
            //STORE_OP
            STORE_OP: begin
                mem_address = id_ex_op1 + id_ex_op2;
                //Check address alignment
                if (id_ex_mem_funct == `MEM_SH || && mem_address[0]) begin
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
                    `MEM_SB: store_wmask = 'h1; store_data = {4{id_ex_mem_data[7:0]}};
                    `MEM_SH: store_wmask = 'h3; store_data = {2{id_ex_mem_data[15:0]}};
                    //STORE WORD
                    default: store_wmask = 'hF; store_data = id_ex_mem_data;
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
        data_bif_rdata <= 32'h0;
        data_bif_ack <= 1'b0;
        data_bif_rvalid <= 1'b0;
        next_load_fifo_pop <= 1'b0;
    end
    else begin
        data_bif_ack <= 1'b1;
        if (data_bif_req && data_bif_rnw) begin
            data_bif_rdata     <= next_load_fifo_data_out;
            data_bif_rvalid    <= 1'b1;
            next_load_fifo_pop <= 1'b1;
        end
        else begin
            data_bif_rvalid <= 1'b0; 
            next_load_fifo_pop <= 1'b0;
        end
    end
end

reg check_load;
reg check_store;
reg check_reg;

//Data bif checker
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
            store_check_fifo_pop 1'b1;
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


id_ex_rdy,
id_ex_funct,
id_ex_op1,
id_ex_op2,
id_ex_mem_funct,
id_ex_mem_data,
id_ex_wb_rsd,




riscv_ex_pipe_tb i_riscv_ex_pipe_tb (
    input                      clk,
    input                      rstn,
    input                      id_ex_rdy,
    input  [`EX_FUNCT_W-1:0]   id_ex_funct,
    input  [31:0]              id_ex_op1,
    input  [31:0]              id_ex_op2,
    input  [`MEM_FUNCT_W-1:0]  id_ex_mem_funct,
    input  [31:0]              id_ex_mem_data,
    input  [4:0]               id_ex_wb_rsd,
    input  [31:0]              data_bif_rdata,
    input                      data_bif_ack,
    output [31:0]              data_bif_addr,
    output                     data_bif_req,
    output                     data_bif_rnw,
    input                      data_bif_rvalid,
    output [3:0]               data_bif_wmask,
    output [31:0]              data_bif_wdata,
    output [31:0]              wb_rf_data,
    output [4:0]               wb_rf_rsd,
    output                     wb_rf_write
);

endmodule
