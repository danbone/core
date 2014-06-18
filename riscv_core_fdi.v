module riscv_fid (
    clk,
    resetn,
    //Instruction bif
    instr_bif_addr,
    instr_bif_rdata,
    instr_bif_req,
    instr_bif_ack,
    //bypass
    wdata_bypass,
    //STall
    stall_back,
    //RF write channel
    rf_wdata,
    rf_wr_req,
    rf_wr_ack
);

reg [31:0] pc;

assign instr_bif_addr = pc;

always @ (*) begin
    if (stalled) begin
        pc_nxt = pc;
    end
    else if (branch_taken) begin
        pc_nxt = target;
    end
    else begin
        pc_nxt = pc + 4;
    end
end

assign br_immed_b_muxed = (br_sel_b == `SEL_REG) ? rsk_val : br_immed_b;
assign target = br_immed_a + br_immed_b_muxed;

        case (br_funct) 
            BR_BNE  :
            BR_BEQ  :
            BR_BLT  :
            BR_BLTU :
            BR_BGE  :
            BR_BGEU :
            BR_JUMP :
        default :



module instr_decoder (
input  [31:0]              instr,
input  [31:0]              pc_in       ,
output                     use_rsj     ,
output                     use_rsk     ,
output                     use_rsd     ,
output [1:0]               rsd_lockout ,
output [`ALU_FUNCT_W-1:0]  alu_funct   ,
output                     alu_sel_a   ,
output                     alu_sel_b   ,
output [31:0]              alu_immed_a ,
output [31:0]              alu_immed_b ,
output [`BR_FUNCT_W-1:0]   br_funct    ,
output                     br_sel_a    ,
output  [31:0]             br_immed_a  ,
output  [31:0]             br_immed_b  ,
output  [`MEM_FUNCT_W-1:0] mem_funct  
);

