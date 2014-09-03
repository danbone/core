module riscv_core_ref (
input clk,
input rstn,
//Instruction memory interface, combinational
output [31:0] instr_mem_addr,
input  [31:0] instr_mem_rdata,
//output        branch_taken,
//output        illegal_instruction,
//Data memory interface, read data expected combinational
output [31:0] data_mem_addr,
output        data_mem_write,
output [31:0] data_mem_wdata,
input  [31:0] data_mem_rdata
);

localparam BEQ   = 6'h00;
localparam BNE   = 6'h01;
localparam BLT   = 6'h02;
localparam BGE   = 6'h03;
localparam BLTU  = 6'h04;
localparam BGEU  = 6'h05;
localparam JALR  = 6'h06;
localparam JAL   = 6'h07;
localparam LUI   = 6'h08;
localparam AUIPC = 6'h09;
localparam ADDI  = 6'h0A;
localparam SLTI  = 6'h0B;
localparam SLTIU = 6'h0C;
localparam XORI  = 6'h0D;
localparam ORI   = 6'h0E;
localparam ANDI  = 6'h0F;
localparam SLLI  = 6'h10;
localparam SRLI  = 6'h11;
localparam SRAI  = 6'h12;
localparam ADD   = 6'h13;
localparam SUB   = 6'h14;
localparam OR    = 6'h15;
localparam XOR   = 6'h16;
localparam AND   = 6'h17;
localparam SLT   = 6'h18;
localparam SLTU  = 6'h19;
localparam SLL   = 6'h1A;
localparam SRL   = 6'h1B;
localparam SRA   = 6'h1C;
localparam LB    = 6'h1D;
localparam LH    = 6'h1E;
localparam LW    = 6'h1F;
localparam LBU   = 6'h20;
localparam LHU   = 6'h21;
localparam SB    = 6'h22;
localparam SH    = 6'h23;
localparam SW    = 6'h24;

reg [31:0] rf [0:31];
reg [31:0] pc_ff;
reg [31:0] data_mem_wdata_l;

wire [31:0] instr_raw;
reg  [5:0] instr_e;
reg        illegal_instr;

wire [31:0] i_im;
wire [31:0] s_im;
wire [31:0] b_im;
wire [31:0] u_im;
wire [31:0] j_im;
wire        sign;
wire [4:0]  rsj_sel;
wire [4:0]  rsk_sel;
wire [4:0]  rsd_sel;
wire [31:0] rsj; 
wire [31:0] rsk;

reg  [31:0] pc_nxt;
reg  [31:0] rf_wdata;

reg  [31:0] d_addr;
reg  [31:0] d_wdata;
reg  [3:0]  d_wmask;
reg         d_write;
reg         take_branch;
reg         alu_op;
reg         load_op;

assign rsd_sel = instr_raw[11:7];
assign rsj_sel = instr_raw[19:15];
assign rsk_sel = instr_raw[24:20];
assign sign    = instr_raw[31];


assign i_im = {{20{sign}}, instr_raw[30:20]};
assign s_im = {{20{sign}}, instr_raw[30:25], instr_raw[11:7]};
assign b_im = {{19{sign}}, instr_raw[7], instr_raw[30:25], instr_raw[11:8], 1'b0};
assign u_im = {sign, instr_raw[30:12], 12'b0};
assign j_im = {{11{sign}}, instr_raw[19:12], instr_raw[20], instr_raw[30:21], 1'b0};

assign rsj = rf[rsj_sel];
assign rsk = rf[rsk_sel];

assign instr_mem_addr = pc_ff;
assign instr_raw = instr_mem_rdata;

always @ (*) begin
    illegal_instr = 1'b0;
    case (instr_raw) 
        32'b?????????????????000?????1100011: instr_e = BEQ;
        32'b?????????????????001?????1100011: instr_e = BNE;
        32'b?????????????????100?????1100011: instr_e = BLT;
        32'b?????????????????101?????1100011: instr_e = BGE;
        32'b?????????????????110?????1100011: instr_e = BLTU;
        32'b?????????????????111?????1100011: instr_e = BGEU;
        32'b?????????????????000?????1100111: instr_e = JALR;
        32'b?????????????????????????1101111: instr_e = JAL;
        32'b?????????????????????????0110111: instr_e = LUI;
        32'b?????????????????????????0010111: instr_e = AUIPC;
        32'b?????????????????000?????0010011: instr_e = ADDI;
        32'b?????????????????010?????0010011: instr_e = SLTI;
        32'b?????????????????011?????0010011: instr_e = SLTIU;
        32'b?????????????????100?????0010011: instr_e = XORI;
        32'b?????????????????110?????0010011: instr_e = ORI;
        32'b?????????????????111?????0010011: instr_e = ANDI;
        32'b000000???????????001?????0010011: instr_e = SLLI;
        32'b000000???????????101?????0010011: instr_e = SRLI;
        32'b010000???????????101?????0010011: instr_e = SRAI;
        32'b0000000??????????000?????0110011: instr_e = ADD;
        32'b0100000??????????000?????0110011: instr_e = SUB;
        32'b0000000??????????110?????0110011: instr_e = OR;
        32'b0000000??????????100?????0110011: instr_e = XOR;
        32'b0000000??????????111?????0110011: instr_e = AND;
        32'b0000000??????????010?????0110011: instr_e = SLT;
        32'b0000000??????????011?????0110011: instr_e = SLTU;
        32'b0000000??????????001?????0110011: instr_e = SLL;
        32'b0000000??????????101?????0110011: instr_e = SRL;
        32'b0100000??????????101?????0110011: instr_e = SRA;
        32'b?????????????????000?????0000011: instr_e = LB;
        32'b?????????????????001?????0000011: instr_e = LH;
        32'b?????????????????010?????0000011: instr_e = LW;
        32'b?????????????????100?????0000011: instr_e = LBU;
        32'b?????????????????101?????0000011: instr_e = LHU;
        32'b?????????????????000?????0100011: instr_e = SB;
        32'b?????????????????001?????0100011: instr_e = SH;
        32'b?????????????????010?????0100011: instr_e = SW;
        default                               illegal_instr = 1'b1;
    endcase
end

//Branch instruction
always @ (*) begin
    case (instr_e) 
        BEQ:     take_branch = (rsj == rsk) ? 1'b1 : 1'b0;
        BNE:     take_branch = (rsj != rsk) ? 1'b1 : 1'b0;
        BLT:     take_branch = ($signed(rsj) < $signed(rsk)) ? 1'b1 : 1'b0;
        BGE:     take_branch = ($signed(rsj) > $signed(rsk)) ? 1'b1 : 1'b0;
        BLTU:    take_branch = (rsj < rsk) ? 1'b1 : 1'b0;
        BGEU:    take_branch = (rsj > rsk) ? 1'b1 : 1'b0;
        JALR,    
        JAL:     take_branch = 1'b1;
        default  take_branch = 1'b0;
    endcase 
end

always @ (*) begin
    if (take_branch) begin
        case (instr_e) 
            BEQ,
            BNE,
            BLT,
            BGE,
            BLTU,
            BGEU:    pc_nxt = pc_ff + b_im;
            JALR,    
            JAL:     pc_nxt = pc_ff + j_im;
            default  pc_nxt = pc_ff + 4;
        endcase
    end
    else begin
        pc_nxt = pc_ff + 4;
    end
end

//ALU instruction
always @ (*) begin
    alu_op = 1'b1;
    case (instr_e) 
        JALR,    
        JAL:   rf_wdata = pc_ff + 4;
        LUI:   rf_wdata = {u_im[31:12], 12'b0};
        AUIPC: rf_wdata = pc_ff + u_im;
        ADDI:  rf_wdata = rsj + i_im;
        SLTI:  rf_wdata = ($signed(rsj) < $signed(i_im)) ? 1 : 0;
        SLTIU: rf_wdata = (rsj < i_im) ? 1 : 0;
        XORI:  rf_wdata = rsj ^ i_im;
        ORI:   rf_wdata = rsj | i_im;
        ANDI:  rf_wdata = rsj & i_im;
        SLLI:  rf_wdata = rsj << (i_im & 'h1F);
        SRLI:  rf_wdata = rsj >> (i_im & 'h1F);
        SRAI:  rf_wdata = rsj >>> (i_im & 'h1F);
        ADD:   rf_wdata = rsj + rsk;
        SUB:   rf_wdata = rsj - rsk;
        OR:    rf_wdata = rsj | rsk;
        XOR:   rf_wdata = rsj ^ rsk;
        AND:   rf_wdata = rsj & rsk;
        SLT:   rf_wdata = ($signed(rsj) < $signed(rsk)) ? 1 : 0;
        SLTU:  rf_wdata = (rsj < rsk) ? 1 : 0;
        SLL:   rf_wdata = rsj << (rsk & 'h1F);
        SRL:   rf_wdata = rsj >> (rsk & 'h1F);
        SRA:   rf_wdata = rsj >>> (rsk & 'h1F);
        default alu_op = 1'b0;
    endcase
end

//MEM operation

assign data_mem_addr = {d_addr[31:2], 2'b00};
assign data_mem_wdata = data_mem_wdata_l;
assign data_mem_write = d_write;

always @ (*) begin
    d_write = 1;
    d_wdata = 0;
    d_wmask = 0;
    d_addr = i_im + rsj;
    case (instr_e) 
        SB: begin
            d_wdata = {4{rsk[7:0]}};
            d_wmask = 'h1 << d_addr[1:0];
        end
        SH: begin
            d_wdata = {2{rsk[15:0]}};
            d_wmask = 'h3 << d_addr[1:0];
        end
        SW: begin
            d_wdata = rsk;
            d_wmask = 'hF << d_addr[1:0];
        end
        default d_write = 0;
    endcase
end

always @ (*) begin
    if (d_write) begin
      data_mem_wdata_l[7:0]   = (d_wmask[0]) ? d_wdata[7:0]   : data_mem_rdata[7:0]; 
      data_mem_wdata_l[15:8]  = (d_wmask[1]) ? d_wdata[15:8]  : data_mem_rdata[15:8];
      data_mem_wdata_l[23:16] = (d_wmask[2]) ? d_wdata[23:16] : data_mem_rdata[23:16];
      data_mem_wdata_l[31:24] = (d_wmask[3]) ? d_wdata[31:24] : data_mem_rdata[31:24];
    end
end

always @ (*) begin
    load_op = 1'b1;
    case (instr_e) 
        LBU : rf_wdata <= 32'h000000FF & data_mem_rdata;
        LHU : rf_wdata <= 32'h0000FFFF & data_mem_rdata;
        LW  : rf_wdata <= data_mem_rdata;
        LB  : rf_wdata <= {{24{data_mem_rdata[7]}},  data_mem_rdata[7:0]};   
        LH  : rf_wdata <= {{16{data_mem_rdata[15]}}, data_mem_rdata[15:8]};  
        default load_op = 1'b0;
    endcase
end

//Assert (!(load_op && alu_op)) else rf_wdata is driven X


integer i;

always @ (posedge clk, negedge rstn) begin
    if (~rstn) begin
        for (i = 0 ; i < 32; i = i + 1) begin
            rf[i] = 0;
        end
        pc_ff = 0;
    end
    else begin
        pc_ff <= pc_nxt;
        if (alu_op || load_op) begin
            rf[rsd_sel] <= rf_wdata;
        end
    end
end


endmodule
