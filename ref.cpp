
assign rsd_sel = instr_raw[11:7];
assign rsj_sel = instr_raw[19:15];
assign rsk_sel = instr_raw[24:20];
assign sign    = instr_raw[31];

uint_t rsd_sel;
uint_t rsj_sel;
uint_t rsk_sel;

rsd_sel = (instr_raw >> 7)  & 0x1F;
rsj_sel = (instr_raw >> 15) & 0x1F;
rsk_sel = (instr_raw >> 20) & 0x1F;

uint_t sign_extend (uint_t sign_idx, uint_t data) {
    uint_t sign = 0;
    sign = (data >> sign_idx) & 0x1;
    for (i = sign_idx+1; i < 32; i++) {
        data |= (sign << i);
    }
    return data;
}


uint_t extract_immediate_i (uint data) {
    uint_t immediate_width = 11;

}

uint_t i_im;
uint_t s_im;
uint_t b_im;
uint_t j_im;




assign i_im = {{20{sign}}, instr_raw[30:20]};
assign s_im = {{20{sign}}, instr_raw[30:25], instr_raw[11:7]};
assign b_im = {{19{sign}}, instr_raw[7], instr_raw[30:25], instr_raw[11:8], 1'b0};
assign u_im = {sign, instr_raw[30:12], 12'b0};
assign j_im = {{11{sign}}, instr_raw[19:12], instr_raw[20], instr_raw[30:21], 1'b0};
