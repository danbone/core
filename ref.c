#include "ref.h"

uint32_t sign_extend (uint32_t sign, uint32_t val, uint32_t width) {
    uint32_t i;
   for (i = width; i < 32; i++) {
      val |= (sign << i);
   }
   return val;
}

uint32_t extract_from_32b (uint32_t val, uint32_t high, uint32_t low) {
   //uint32_t mask = (2**((high+1)-low))-1;
   uint32_t mask = (1<<((high+1)-low))-1;
   return ((val >> low) & mask);
}

const char * REG2STRING (uint32_t val) {
   switch (val) {
      case 0:  return "r0";
      case 1:  return "r1";
      case 2:  return "r2";
      case 3:  return "r3";
      case 4:  return "r4";
      case 5:  return "r5";
      case 6:  return "r6";
      case 7:  return "r7";
      case 8:  return "r8";
      case 9:  return "r9";
      case 10: return "r10";
      case 11: return "r11";
      case 12: return "r12";
      case 13: return "r13";
      case 14: return "r14";
      case 15: return "r15";
      case 16: return "r16";
      case 17: return "r17";
      case 18: return "r18";
      case 19: return "r19";
      case 20: return "r20";
      case 21: return "r21";
      case 22: return "r22";
      case 23: return "r23";
      case 24: return "r24";
      case 25: return "r25";
      case 26: return "r26";
      case 27: return "r27";
      case 28: return "r28";
      case 29: return "r29";
      case 30: return "r30";
      case 31: return "r31";
   }
}
const char * INSTR2STRING (instr_e val) {
    switch (val) {
        case ADDI: return "ADDI"; 
        case ORI: return "ORI"; 
        case XORI: return "XORI"; 
        case ANDI: return "ANDI"; 
        case SLTI: return "SLTI"; 
        case SLTUI: return "SLTUI"; 
        case SLLI: return "SLLI"; 
        case SRLI: return "SRLI"; 
        case SRAI: return "SRAI"; 
        case LUI: return "LUI"; 
        case AUIPC: return "AUIPC"; 
        case ADD: return "ADD"; 
        case SUB: return "SUB"; 
        case OR: return "OR"; 
        case XOR: return "XOR"; 
        case AND: return "AND"; 
        case SLT: return "SLT"; 
        case SLTU: return "SLTU"; 
        case SLL: return "SLL"; 
        case SRL: return "SRL"; 
        case SRA: return "SRA"; 
        case JALR: return "JALR"; 
        case JAL: return "JAL"; 
        case SB: return "SB"; 
        case SH: return "SH"; 
        case SW: return "SW"; 
        case LB: return "LB"; 
        case LH: return "LH"; 
        case LW: return "LW"; 
        case LBU: return "LBU"; 
        case LHU: return "LHU"; 
        case BEQ: return "BEQ"; 
        case BNE: return "BNE"; 
        case BLT: return "BLT"; 
        case BLTU: return "BLTU"; 
        case BGE: return "BGE"; 
        case BGEU: return "BGEU"; 
        default: exit(1);
    }
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
   ret = (extract_from_32b(data, 19, 12)  << 12) +
      (extract_from_32b(data, 20, 20)   << 11) +
      (extract_from_32b(data, 30, 21)   <<  1);
   ret = sign_extend(sign, ret, 20);
   return ret;
}


//Opcodes:
//OPCODE_IMM     
//OPCODE_LUI     
//OPCODE_AUIPC   
//OPCODE_OP      
//OPCODE_JAL     
//OPCODE_JALR    
//OPCODE_BRANCH  
//OPCODE_LOAD    
//OPCODE_STORE   
//OPCODE_MISC_MEM
//OPCODE_SYSTEM  

void print_imm (instr_t * instr) {
    printf("%s %s, %s, %d\n", INSTR2STRING(instr->instruction),
                              REG2STRING(instr->rsd), 
                              REG2STRING(instr->rsj),
                              instr->immediate);
}
void print_lui (instr_t * instr) {
    printf("%s %s, %d\n", INSTR2STRING(instr->instruction),
                           REG2STRING(instr->rsd), 
                           instr->immediate);
}
void print_auipc (instr_t * instr) {
    printf("%s %s, %d\n", INSTR2STRING(instr->instruction),
                          REG2STRING(instr->rsd), 
                          instr->immediate);
}
void print_op (instr_t * instr) {
    printf("%s %s, %s, %s\n", INSTR2STRING(instr->instruction),
                              REG2STRING(instr->rsd), 
                              REG2STRING(instr->rsj),
                              REG2STRING(instr->rsk));    
}
void print_jalr (instr_t * instr) {
    printf("%s %s, %s, %d\n", INSTR2STRING(instr->instruction), 
                             REG2STRING(instr->rsd), 
                             REG2STRING(instr->rsj), 
                             instr->immediate);
}
void print_jal (instr_t * instr) {
    printf("%s %s, %d\n",      INSTR2STRING(instr->instruction),
                               REG2STRING(instr->rsd), 
                               instr->immediate);    
}
void print_store (instr_t * instr) {
    printf ("%s %s, %s, %d\n", INSTR2STRING(instr->instruction),
                               REG2STRING(instr->rsj),
                               REG2STRING(instr->rsk),
                               instr->immediate);
}
void print_load (instr_t * instr) {
    printf ("%s %s, %s, %d\n", INSTR2STRING(instr->instruction),
                               REG2STRING(instr->rsd),
                               REG2STRING(instr->rsj),
                               instr->immediate);    
}
void print_branch (instr_t * instr) {
    printf("%s %s, %s, %d\n",  INSTR2STRING(instr->instruction),
                               REG2STRING(instr->rsj), 
                               REG2STRING(instr->rsk), 
                               instr->immediate);

}

bool decode_imm (uint32_t instr_in, instr_t * instr_out) {
   uint32_t funct3;
   uint32_t funct7;
   uint32_t funct10;
   bool     legal_instr = true;

    //assert(instr_out != NULL) 

   funct3        = extract_from_32b(instr_in, 14, 12);
   funct7        = extract_from_32b(instr_in, 31, 25);
   funct10       = (funct7 << 3) + funct3;
   instr_out->rsd = extract_from_32b(instr_in, 11, 7);
   instr_out->rsj = extract_from_32b(instr_in, 19, 15);
   instr_out->immediate = extract_immediate_type_I(instr_in);

   switch (funct3) {
      case FUNCT_ADD_RAW:  instr_out->instruction = ADDI; break;
      case FUNCT_OR_RAW:   instr_out->instruction = ORI; break;
      case FUNCT_XOR_RAW:  instr_out->instruction = XORI; break;
      case FUNCT_AND_RAW:  instr_out->instruction = ANDI; break;
      case FUNCT_SLT_RAW:  instr_out->instruction = SLTI; break;
      case FUNCT_SLTU_RAW: instr_out->instruction = SLTUI; break;
      default: {
         instr_out->immediate &= 0x1F;
         switch (funct10) {
            case FUNCT_SLL_RAW: instr_out->instruction = SLLI; break;
            case FUNCT_SRL_RAW: instr_out->instruction = SRLI; break;
            case FUNCT_SRA_RAW: instr_out->instruction = SRAI; break;
            default: {
                legal_instr = false;
            }
         }
      }
   }
   print_imm(instr_out);
   return legal_instr;
}
bool decode_lui (uint32_t instr_in, instr_t * instr_out) {
   bool     legal_instr = true;

    //assert(instr_out != NULL) 
   instr_out->immediate = extract_immediate_type_U(instr_in);
   instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
   instr_out->instruction = LUI;
   print_lui(instr_out);
   return legal_instr;
}
bool decode_auipc (uint32_t instr_in, instr_t * instr_out) {
   bool     legal_instr = true;

    //assert(instr_out != NULL) 
   instr_out->immediate = extract_immediate_type_U(instr_in);
   instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
   instr_out->instruction = AUIPC;
   print_auipc(instr_out);
   return legal_instr;
}
bool decode_op (uint32_t instr_in, instr_t * instr_out) {
   uint32_t funct3;
   uint32_t funct7;
   uint32_t funct10;
   bool     legal_instr = true;

    //assert(instr_out != NULL) 

   funct3        = extract_from_32b(instr_in, 14, 12);
   funct7        = extract_from_32b(instr_in, 31, 25);
   funct10       = (funct7 << 3) + funct3;

   instr_out->rsd = extract_from_32b(instr_in, 11, 7);
   instr_out->rsj = extract_from_32b(instr_in, 19, 15);
   instr_out->rsk = extract_from_32b(instr_in, 24, 20);

   switch (funct10) {
      case FUNCT_ADD_RAW:  instr_out->instruction = ADD; break;
      case FUNCT_SUB_RAW:  instr_out->instruction = SUB; break;
      case FUNCT_OR_RAW:   instr_out->instruction = OR; break;
      case FUNCT_XOR_RAW:  instr_out->instruction = XOR; break;
      case FUNCT_AND_RAW:  instr_out->instruction = AND; break;
      case FUNCT_SLT_RAW:  instr_out->instruction = SLT; break;
      case FUNCT_SLTU_RAW: instr_out->instruction = SLTU; break;
      case FUNCT_SLL_RAW:  instr_out->instruction = SLL; break;
      case FUNCT_SRL_RAW:  instr_out->instruction = SRL; break;
      case FUNCT_SRA_RAW:  instr_out->instruction = SRA; break;
      default: {
         legal_instr = false;
      }
   }
   print_op(instr_out);
   return legal_instr;
}
bool decode_jalr (uint32_t instr_in, instr_t * instr_out) {
    bool legal_instr = true;
    uint32_t funct3;

    instr_out->immediate = extract_immediate_type_I(instr_in);
    instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
    instr_out->rsj       = extract_from_32b(instr_in, 19, 15);
    funct3              = extract_from_32b(instr_in, 14, 12);

   switch (funct3) {
      case FUNCT_JALR_RAW: instr_out->instruction = JALR; break;
      default: {
         legal_instr = false;
      }
   }
   print_jalr(instr_out);
   return legal_instr;
}
bool decode_jal (uint32_t instr_in, instr_t * instr_out) {
    bool legal_instr = true;
    instr_out->immediate = extract_immediate_type_J(instr_in);
    instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
    instr_out->instruction = JAL;
    print_jal(instr_out);
   return legal_instr;
}
bool decode_store (uint32_t instr_in, instr_t * instr_out) {
    bool legal_instr = true;
    uint32_t funct3;

    funct3              = extract_from_32b(instr_in, 14, 12);
    instr_out->immediate = extract_immediate_type_S(instr_in);
    instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
    instr_out->rsj       = extract_from_32b(instr_in, 19, 15);
    instr_out->rsk       = extract_from_32b(instr_in, 24, 20);

   switch (funct3) {
      case FUNCT_SB_RAW: instr_out->instruction = SB; break;
      case FUNCT_SH_RAW: instr_out->instruction = SH; break;
      case FUNCT_SW_RAW: instr_out->instruction = SW; break;
      default: {
         legal_instr = false;
      }
   }
   print_store(instr_out);
   return legal_instr;
}
bool decode_load (uint32_t instr_in, instr_t * instr_out) {
    bool legal_instr = true;
    uint32_t funct3;

    funct3              = extract_from_32b(instr_in, 14, 12);
    instr_out->immediate = extract_immediate_type_I(instr_in);
    instr_out->rsj       = extract_from_32b(instr_in, 19, 15);
    instr_out->rsk       = extract_from_32b(instr_in, 24, 20);

   switch (funct3) {
      case FUNCT_LB_RAW:  instr_out->instruction = LB; break;
      case FUNCT_LH_RAW:  instr_out->instruction = LH; break;
      case FUNCT_LW_RAW:  instr_out->instruction = LW; break;
      case FUNCT_LBU_RAW: instr_out->instruction = LBU; break;
      case FUNCT_LHU_RAW: instr_out->instruction = LHU; break;
      default: {
         legal_instr = false;
      }
   }
   print_load(instr_out);
   return legal_instr;
}
bool decode_branch (uint32_t instr_in, instr_t * instr_out) {
    bool legal_instr = true;
    uint32_t funct3;

    funct3              = extract_from_32b(instr_in, 14, 12);
    instr_out->immediate = extract_immediate_type_B(instr_in);
    instr_out->rsj       = extract_from_32b(instr_in, 19, 15);
    instr_out->rsk       = extract_from_32b(instr_in, 24, 20);

   switch (funct3) {
      case FUNCT_BEQ_RAW:   instr_out->instruction = BEQ; break;
      case FUNCT_BNE_RAW:   instr_out->instruction = BNE; break;
      case FUNCT_BLT_RAW:   instr_out->instruction = BLT; break;
      case FUNCT_BLTU_RAW:  instr_out->instruction = BLTU; break;
      case FUNCT_BGE_RAW:   instr_out->instruction = BGE; break;
      case FUNCT_BGEU_RAW:  instr_out->instruction = BGEU; break;
      default: {
         legal_instr = false;
      }
   }
   print_branch(instr_out);
   return legal_instr;
}

//TODO: Move print statements out of decode and into the calling function
uint32_t alu_function (alu_funct_e function, uint32_t op1, uint32_t op2) {
    uint32_t result; 
    //Signed versions of the ops
    int32_t s_op1 = (int32_t) op1;
    int32_t s_op2 = (int32_t) op2;
    switch (function) {
        case ALU_ADD : result = op1 + s_op2;  break;
        case ALU_SUB : result = op1 - op2;    break;
        case ALU_AND : result = op1 & op2;    break;
        case ALU_OR  : result = op1 | op2;    break;
        case ALU_XOR : result = op1 ^ op2;    break;
        case ALU_SLT : result = (s_op1 < s_op2) ? 1 : 0; break;
        case ALU_SLTU: result = (op1 < op2) ? 1 : 0; break;
        case ALU_SLL : result = op1 << op2 ;  break;
        case ALU_SRL : result = op1 >> op2;   break;
        case ALU_SRA : result = s_op1 >> op2; break;
    }
    printf ("ALU_FUNCT: %4x %8x %8x %8x\n", (uint32_t) function, 
                                          op1, op2, result);
    return result;
}

bool branch_function (branch_funct_e function, uint32_t op1, uint32_t op2) {
  bool result;
  //Signed versions of the ops
  int32_t s_op1 = (int32_t) op1;
  int32_t s_op2 = (int32_t) op2;

  switch (function) {
      case BR_BEQ:  result = (op1 == op2)     ? true : false; break;
      case BR_BNE:  result = (op1 != op2)     ? true : false; break;
      case BR_BLT:  result = (s_op1 < s_op2)  ? true : false; break;
      case BR_BGE:  result = (s_op1 >= s_op2) ? true : false; break;
      case BR_BLTU: result = (op1 < op2)      ? true : false; break;
      case BR_BGEU: result = (op1 >= op2)     ? true : false; break;
      case BR_JUMP: result = true;                            break;
  }
  printf ("BR_FUNCT: %4x %8x %8x %1x\n", (uint32_t) function,
                                     op1, op2, (uint32_t) result);
  return result;
}

/*
uint32_t mem_function (mem_funct_e function, uint32_t address) {
    //Caculate the mask
}
*/



bool decode_instruction (uint32_t instr_in, instr_t * instr_out) {
   uint32_t opcode;
   opcode = extract_from_32b(instr_in, 6, 0);
   //assert(instr_out != null)
   switch (opcode) {
      case OPCODE_IMM:
         decode_imm(instr_in, instr_out);
         print_imm(instr_out);
         break;
      case OPCODE_LUI:
         decode_lui(instr_in, instr_out);
         print_lui(instr_out);
         break;
      case OPCODE_AUIPC:
         decode_auipc(instr_in, instr_out);
         print_auipc(instr_out);
         break;
      case OPCODE_OP:
         decode_op(instr_in, instr_out);
         print_op(instr_out);
         break;
      case OPCODE_JAL:
         decode_jal(instr_in, instr_out);
         print_jal(instr_out);
         break;
      case OPCODE_JALR:
         decode_jalr(instr_in, instr_out);
         print_jalr(instr_out);
         break;
      case OPCODE_BRANCH:
         decode_branch(instr_in, instr_out);
         print_branch(instr_out);
         break;
      case OPCODE_LOAD:
         decode_load(instr_in, instr_out);
         print_load(instr_out);
         break;
      case OPCODE_STORE:
         decode_store(instr_in, instr_out);
         print_store(instr_out);
         break;
      //case OPCODE_MISC_MEM:
      //case OPCODE_SYSTEM:
      default: //Error
        printf("Unsupported opcode : %x extracted from %x\n", opcode, instr_in);
        exit(1);
      break;
   }
   return true;
}

/*
//Main loop
clear(instr);
instr->pc = current_pc
//Fetch
instr->instr_in = read_memory(instr->pc);
//Decode and branch
decode(instr->instr_in, instr);
branch(instr);
//Do an ALU operation
execute(instr);
//Access memory
mem_access(instr);
//Write result back to register file
write_back(instr);
current_pc = instr->pc_next;
*/


uint32_t randomise_immediate_instr () {
   uint32_t dest_rand;
   uint32_t src_rand;
   uint32_t imm_rand;
   uint32_t fun_rand;
   uint32_t instruction;

   uint32_t funct3 = 0;

   dest_rand = rand() % 32;
   src_rand  = rand() % 32;
   //12 bits wide
   imm_rand  = rand() % (1<<13);
   fun_rand  = rand() % 9;

   switch (fun_rand) {
      case 0:
         funct3  = FUNCT_ADD_RAW;
         break;
      case 1:
         funct3  = FUNCT_OR_RAW;
         break;
      case 2:
         funct3  = FUNCT_XOR_RAW;
         break;
      case 3:
         funct3  = FUNCT_AND_RAW;
         break;
      case 4:
         funct3  = FUNCT_SLT_RAW;
         break;
      case 5:
         funct3  = FUNCT_SLTU_RAW;
         break;
      case 6:
         imm_rand &= 0x1F;
         funct3  = FUNCT_SLL_RAW;
         break;
      case 7:
         imm_rand &= 0x1F;
         funct3  = FUNCT_SRL_RAW;
         break;
      case 8:
         imm_rand &= 0x1F;
         //Set the shift modifier
         //12 - 7 bits
         //0100000
         imm_rand |= 0x800;
         funct3  = FUNCT_SRA_RAW;
         break;
   }
   //Build the instruction
   instruction |= OPCODE_IMM;
   instruction |= dest_rand << 7;
   instruction |= funct3    << 12;
   instruction |= src_rand  << 15;
   instruction |= imm_rand  << 20;

   return instruction;
}

int main (char argc, char ** argv) {
   uint32_t i = 0;
   uint32_t instr;
   for (i = 0 ; i < 10; i++) {
      instr = randomise_immediate_instr();
      //print_instruction(instr);
   }
   return 1;
}

