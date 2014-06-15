module riscv_core_id (
    input                                       clk,
    input                                       rstn,
    output [31:0]                               icache_addr;
    output                                      if_branch_taken;
    output                                      
    output [31:0]                               if_id_pc;
    //IF interface
    input  [5:0]                                id_if_branch_funct,
    input  [31:0]                               id_if_target,
    input  [1:0]                                id_if_mux_cntl,
    //RF interface
    input [31:0]                                rf_if_src1,
    input [31:0]                                rf_if_src2
);

localparam BR_FUNCT_NOP_OH  = 7'b0000000;
localparam BR_FUNCT_BEQ_OH  = 7'b0000001;
localparam BR_FUNCT_BNE_OH  = 7'b0000010;
localparam BR_FUNCT_BLT_OH  = 7'b0000100;
localparam BR_FUNCT_BGE_OH  = 7'b0001000;
localparam BR_FUNCT_BLTU_OH = 7'b0010000;
localparam BR_FUNCT_BGEU_OH = 7'b0100000;
//Handles JALR and JAL
localparam BR_FUNCT_JUMP_OH = 7'b1000000;


reg branch_taken_nxt;
reg branch_taken_ff;
reg [31:0] pc_ff;

wire [31:0] pc_nxt;

always @ (*) begin
    case (id_if_branch_funct) begin
        BR_FUNCT_BEQ_OH  : branch_taken_nxt = (rf_if_src1 == rf_if_src2) ? 1'b1 : 1'b0;
        BR_FUNCT_BNE_OH  : branch_taken_nxt = (rf_if_src1 != rf_if_src2) ? 1'b1 : 1'b0;
        BR_FUNCT_BLT_OH  : 
            branch_taken_nxt = ($signed(rf_if_src1) < $signed(rf_if_src2)) ? 1'b1 : 1'b0;
        BR_FUNCT_BGE_OH  : 
            branch_taken_nxt = ($signed(rf_if_src1) > $signed(rf_if_src2)) ? 1'b1 : 1'b0;
        BR_FUNCT_BLTU_OH : branch_taken_nxt = (rf_if_src1 < rf_if_src2) ? 1'b1 : 1'b0;
        BR_FUNCT_BGEU_OH : branch_taken_nxt = (rf_if_src1 > rf_if_src2) ? 1'b1 : 1'b0;
        BR_FUNCT_JUMP_OH : branch_taken_nxt = 1'b1;
        // BR_FUNCT_NOP_OH
        default          : branch_taken_nxt = 1'b0;;
    endcase
end

assign pc_nxt = (branch_taken_nxt) ? id_if_target : pc + 4;

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        pc_ff           <= 'h0;
        branch_taken_ff <= 1'b0;
    end
    else begin
        pc_ff           <= pc_nxt;
        branch_taken_ff <= branch_taken_nxt;
    end
end

assign if_branch_taken = branch_taken_ff;
assign if_id_pc = pc_ff;
assign icache_addr = pc_ff;

endmodule

