typedef enum opcode_e {
   OPCODE_IMM       = 0b0010011,
   OPCODE_LUI       = 0b0110111,
   OPCODE_AUIPC     = 0b0010111,
   OPCODE_OP        = 0b0110011,
   OPCODE_JAL       = 0b1101111,
   OPCODE_JALR      = 0b1100111,
   OPCODE_BRANCH    = 0b1100011,
   OPCODE_LOAD      = 0b0000011,
   OPCODE_STORE     = 0b0100011,
   OPCODE_MISC_MEM  = 0b0001111,
   OPCODE_SYSTEM    = 0b1110011
} opcode_t;

typedef enum alu_op_e {
   ALU_NOP     = 0b0000000000,
   ALU_ADD     = 0b0000000001,
   ALU_SUB     = 0b0000000010,
   ALU_OR      = 0b0000000100,
   ALU_XOR     = 0b0000001000,
   ALU_AND     = 0b0000010000,
   ALU_STL     = 0b0000100000,
   ALU_STLU    = 0b0001000000,
   ALU_SLL     = 0b0010000000,
   ALU_SRL     = 0b0100000000,
   ALU_SRA     = 0b1000000000
} alu_op_t;

typedef enum mem_op_e {
   MEM_NOP = 0b00000000,
   MEM_LB  = 0b00000001,
   MEM_LH  = 0b00000010,
   MEM_LW  = 0b00000100,
   MEM_LBU = 0b00001000,
   MEM_LHU = 0b00010000,
   MEM_SB  = 0b00100000,
   MEM_SH  = 0b01000000,
   MEM_SW  = 0b10000000
} mem_op_t;

typedef enum br_op_e {
   BR_NOP  = 0b0000000,
   BR_BEQ  = 0b0000001,
   BR_BNE  = 0b0000010,
   BR_BLT  = 0b0000100,
   BR_BGE  = 0b0001000,
   BR_BLTU = 0b0010000,
   BR_BGEU = 0b0100000,
   BR_JUMP = 0b1000000
} br_op_t;

uint32_t extract_from_32b (uint32_t val, uint32_t high, uint32_t low) {
   uint32_t mask = (2**((high+1)-low))-1;
   return ((val >> low) & mask);
}

uint32_t extract_register_d(uint32_t val) {
   return extract_from_32b(val, 11, 7);
}

uint32_t extract_register_j(uint32_t val) {
   return extract_from_32b(val, 19, 15);
}

uint32_t extract_register_k(uint32_t val) {
   return extract_from_32b(val, 24, 20);
}

uint32_t sign_extend (uint32_t sign, uint32_t val, uint32_t width) {
   for (uint32_t i = width; i < 32; i++) {
      val |= (sign << i);
   }
   return val;
}

uint32_t extract_immediate_type_I (uint32_t data) {
   uint32_t sign;
   uint32_t ret;
   sign = (data >> 31) & 0x1;
   ret = extract_from_32b(data, 30, 20);
   ret = sign_extend(sign, ret, 11);
   return ret;
}

uint32_t extract_immediate_type_S (uint32_t data) {
   uint32_t sign;
   uint32_t ret;
   sign = (data >> 31) & 0x1;
   ret = (extract_from_32b(data, 30, 25) << 5) +
      (extract_from_32b(data, 11,  7));
   ret = sign_extend(sign, ret, 11);
   return ret;
}

uint32_t extract_immediate_type_B (uint32_t data) {
   uint32_t sign;
   uint32_t ret;
   sign = (data >> 31) & 0x1;
   ret = (extract_from_32b(data,  7,  7)  << 11) +
      (extract_from_32b(data, 30, 25)  <<  5) +
      (extract_from_32b(data, 11,  8)  <<  1);
   ret = sign_extend(sign, ret, 12);
   return ret;
}

uint32_t extract_immediate_type_U (uint32_t data) {
   uint32_t sign;
   uint32_t ret;
   sign = (data >> 31) & 0x1;
   ret = (extract_from_32b(data, 30, 12)  << 12);
   ret = sign_extend(sign, ret, 31);
   return ret;
}

uint32_t extract_immediate_type_J (uint32_t data) {
   uint32_t sign;
   uint32_t ret;
   sign = (data >> 31) & 0x1;
   ret = (extract_from_32b(data, 19, 12))  << 12) +
      (extract_from_32b(data, 20, 20)   << 11) +
      (extract_from_32b(data, 30, 21)   <<  1);
   ret = sign_extend(sign, ret, 20);
   return ret;
}

typedef struct {
   uint32_t pc;
   opcode_t opcode;
   alu_op_t alu_op;
   mem_op_t mem_op;
   br_op_t br_op;
   uint32_t sel_rsj;
   uint32_t sel_rsj;
   uint32_t sel_rsk;
   uint32_t sel_rsd;
   uint32_t immediate;
   uint32_t result;
} instruction_t;

void print_immediate (uint32_t instr) {
   uint32_t immediate;
   uint32_t register_dest;
   uint32_t funct3;
   uint32_t funct7;
   uint32_t funct10;
   uint32_t register_op;

   char     register_dest_s[4];
   char     register_op_s  [4];
   char     function_s     [6];

   funct3        = extract_from_32b(instr, 14, 12);
   funct7        = extract_from_32b(instr, 31, 25);
   funct10       = (funct7 << 3) + funct3;

   immediate     = extract_immediate_type_I(instr);
   register_dest = extract_register_d(instr);
   register_op   = extract_register_j(instr);

   register_dest_s = REG2STRING(register_dest);
   register_op_s   = REG2STRING(register_op);

   switch (funct3) {
      FUNCT_ADD_RAW:
         function_s = "ADDI";
         break;
      FUNCT_OR_RAW:
         function_s = "ORI";
         break;
      FUNCT_XOR_RAW:
         function_s = "XORI";
         break;
      FUNCT_AND_RAW:
         function_s = "ANDI";
         break;
      FUNCT_STL_RAW:
         function_s = "STLI";
         break;
      FUNCT_STLU_RAW:
         function_s = "STLUI";
         break;
      default:
         //Only 5 bits are relevant now
         immediate &= 0x1F;
         switch (funct10) {
            FUNCT_SLL_RAW:
               function_s = "SLL";
               break;
            FUNCT_SRL_RAW:
               function_s = "SRL";
               break;
            FUNCT_SRA_RAW:
               function_s = "SRL";
               break;
            default:
               printf("Illegal instruction\n");
               exit (1);
         }
   }
   printf("%s %s, %s, %d", function_s, register_dest_s, register_op_s, immediate);

}
void print_instruction (uint32_t instr) {
   uint32_t opcode;
   opcode = extract_from_32b(instr, 6, 0);
   switch (opcode) {
      OPCODE_IMM:
         print_immediate(instr);
         break;
      default: //Error
      break;
   }
}
