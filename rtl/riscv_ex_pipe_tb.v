module riscv_ex_pipe_tb ();

reg                       clk;
reg                       rstn;

always clk = #5 ~clk;

initial begin
    clk  = 1'b1;
    rstn = 1'b1;
    //Reset cycle
 #5 rstn = 1'b0;
 #5 rstn = 1'b1;
end

task stim_generation ();
begin
    //ALU or MEM instruction
    id_ex_mem_data = $urandom;
    id_ex_wb_rsd   = $urandom & 'h1f;
    alu_not_mem    = $urandom & 'h1;
    if (alu_not_mem) begin
        alu_funct = $urandom % `EX_FUNCT_W;
        id_ex_funct = 'h0;
        for (i = 0 ; i < `EX_FUNCT_W; i=i+1) begin
            id_ex_funct[i] = (alu_funct == i) ? 1'b1 : 1'b0;
        end
        id_ex_op2 = $urandom;
        if (    id_ex_funct == `EX_SLL || 
                id_ex_funct == `EX_SRL || 
                id_ex_funct == `EX_SRA) begin
            id_ex_op1 = $urandom & 'h1f;
        end
        else begin
            id_ex_op1 = $urandom;
        end
        id_ex_mem_funct = `MEM_NOP;
    end
    else begin
        mem_funct = $urandom % `MEM_FUNCT_W;
        id_ex_mem_funct = 'h0;
        for (i = 0; i < `MEM_FUNCT_W; i=i+1) begin
            id_ex_mem_funct[i] = (mem_funct == i) ? 1'b1 : 1'b0;
        end
        id_ex_funct = `EX_ADD;
        id_ex_op1 = $urandom;
        id_ex_op2 = $urandom;
    end
end
endtask

wire [31:0] alu_result;
wire [31:0] load_data;
wire [31:0] store_data;

wire alu_op;
wire load_op;
wire store_op;


always @ (*) begin
    if (rstn == 0) begin
        reg_check_fifo_flush = 1'b1;
        mem_check_fifo_flush = 1'b1;
    end
    else begin
        //Default assignments
        reg_check_fifo_flush = 1'b0;
        mem_check_fifo_flush = 1'b0;
        reg_check_fifo_push = 1'b0;
        load_check_fifo_push = 1'b0;
        store_check_fifo_push = 1'b0;
        //Modeling logic
        if (id_ex_rdy && id_ex_ack) begin
            case ({store_op, load_op, alu_op}) 
                //ALU_OP
                3'b001: begin 
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
                3'b010: begin 
                    mem_address = id_ex_op1 + id_ex_op2;
                    //This is wrong, fix it
                    //Figure out rdata
                    case (id_ex_mem_funct) 
                        `MEM_LB, 
                        `MEM_LBU : load_data = (next_load_check_fifo_data_out 
                                                    >> mem_address[1:0]) & 'hf;
                        `MEM_LH, 
                        `MEM_LHU : load_data = (next_load_check_fifo_data_out 
                                                    >> mem_address[1:0]) & 'hff;
                        `MEM_LW  : load_data = next_load_check_fifo_data_out;
                    endcase
                    next_load_check_fifo_pop = 1'b1;
                    load_check_fifo_data_in = {mem_address[31:2], 2'b0};
                    load_check_fifo_push    = 1'b1;
                    reg_check_fifo_data_in = load_data;
                    reg_check_fifo_push    = 1'b1;
                end
                //STORE_OP
                3'b100: begin
                    
                    store_check_fifo_data_in = {store_wmask, store_data, alu_result};
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
    output [3:0]               data_bif_wmask,
    output [31:0]              data_bif_wdata,
    output [31:0]              wb_rf_data,
    output [4:0]               wb_rf_rsd,
    output                     wb_rf_write
);

endmodule
