#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <stdbool.h>

#define OPCODE_IMM      0b0010011
#define OPCODE_LUI      0b0110111
#define OPCODE_AUIPC    0b0010111
#define OPCODE_OP       0b0110011
#define OPCODE_JAL      0b1101111
#define OPCODE_JALR     0b1100111
#define OPCODE_BRANCH   0b1100011
#define OPCODE_LOAD     0b0000011
#define OPCODE_STORE    0b0100011
#define OPCODE_MISC_MEM 0b0001111
#define OPCODE_SYSTEM   0b1110011

#define FUNCT_JALR_RAW  0b0000000000
#define FUNCT_SB_RAW    0b0000000000
#define FUNCT_SH_RAW    0b0000000001
#define FUNCT_SW_RAW    0b0000000010
#define FUNCT_LB_RAW    0b0000000000
#define FUNCT_LH_RAW    0b0000000001
#define FUNCT_LW_RAW    0b0000000010
#define FUNCT_LBU_RAW   0b0000000100
#define FUNCT_LHU_RAW   0b0000000101
#define FUNCT_BEQ_RAW   0b0000000000
#define FUNCT_BNE_RAW   0b0000000001
#define FUNCT_BLT_RAW   0b0000000100
#define FUNCT_BGE_RAW   0b0000000101
#define FUNCT_BLTU_RAW  0b0000000110
#define FUNCT_BGEU_RAW  0b0000000111
#define FUNCT_ADD_RAW   0b0000000000
#define FUNCT_SUB_RAW   0b0100000000
#define FUNCT_SLL_RAW   0b0000000001
#define FUNCT_SLT_RAW   0b0000000010
#define FUNCT_SLTU_RAW  0b0000000011
#define FUNCT_XOR_RAW   0b0000000100
#define FUNCT_SRL_RAW   0b0000000101
#define FUNCT_SRA_RAW   0b0100000101
#define FUNCT_OR_RAW    0b0000000110
#define FUNCT_AND_RAW   0b0000000111

typedef enum {
    ADDI,
    ORI,
    XORI,
    ANDI,
    SLTI,
    SLTUI,
    SLLI,
    SRLI,
    SRAI,
    LUI,
    AUIPC,
    ADD,
    SUB,
    OR,
    XOR,
    AND,
    SLT,
    SLTU,
    SLL,
    SRL,
    SRA,
    JALR,
    JAL,
    SB,
    SH,
    SW,
    LB,
    LH,
    LW,
    LBU,
    LHU,
    BEQ,
    BNE,
    BLT,
    BLTU,
    BGE,
    BGEU
} instr_e;

typedef struct {
    uint32_t pc;
    uint32_t    rsd;
    uint32_t    rsj;
    uint32_t    rsk;
    uint32_t immediate;
    instr_e  instruction;
    char     instr_string[30];
} instr_t;

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

void print_imm (instr_t * instr) {
}
void print_lui (instr_t * instr) {
}
void print_auipc (instr_t * instr) {
}
void print_op (instr_t * instr) {
}
void print_jalr (instr_t * instr) {
   printf("%s %s, %s, %d\n", INSTR2STRING(instr->instruction), 
                             REG2STRING(instr->rsd), 
                             REG2STRING(instr->rsj), 
                             instr->immediate);
}
void print_jal (instr_t * instr) {
}
void print_store (instr_t * instr) {
}
void print_load (instr_t * instr) {
}
void print_branch (instr_t * instr) {
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
   return legal_instr;
}

bool decode_lui (uint32_t instr_in, instr_t * instr_out) {
   bool     legal_instr = true;

    //assert(instr_out != NULL) 
   instr_out->immediate = extract_immediate_type_U(instr_in);
   instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
   instr_out->instruction = LUI;

   return legal_instr;
}

bool decode_auipc (uint32_t instr_in, instr_t * instr_out) {
   bool     legal_instr = true;

    //assert(instr_out != NULL) 
   instr_out->immediate = extract_immediate_type_U(instr_in);
   instr_out->rsd       = extract_from_32b(instr_in, 11, 7);
   instr_out->instruction = AUIPC;

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
   return legal_instr;
}



/*
//Print instruction functions
void print_jump_register_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t dest;
   uint32_t base;
   uint32_t funct3;
   char *   function_s;

   immediate = extract_immediate_type_I(instr);
   dest      = extract_from_32b(instr, 11, 7);
   base      = extract_from_32b(instr, 19, 15);
   funct3    = extract_from_32b(instr, 14, 12);
   switch (funct3) {
      case FUNCT_JALR_RAW:
         function_s = "JALR";
          break;
      default:
         printf("Illegal jump instruction\n");
         exit(1);
   }
   printf("%s %s, %s, %d\n", function_s, REG2STRING(dest), REG2STRING(base), immediate);
}

void print_lui_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t dest;
   immediate = extract_immediate_type_U(instr);
   dest      = extract_from_32b(instr, 11, 7);
   printf("LUI %s, %d\n", REG2STRING(dest), immediate);
}
void print_auipc_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t dest;
   immediate = extract_immediate_type_U(instr);
   dest      = extract_from_32b(instr, 11, 7);
   printf("AUIPC %s, %d\n", REG2STRING(dest), immediate);
}

void print_store_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t base;
   uint32_t src;
   uint32_t funct3;
   char * function_s;

   immediate = extract_immediate_type_S(instr);
   funct3    = extract_from_32b(instr, 14, 12);
   base      = extract_from_32b(instr, 19, 15);
   src       = extract_from_32b(instr, 24, 20);

   switch (funct3) {
      case FUNCT_SB_RAW:
            function_s = "SB";
            break;
      case FUNCT_SH_RAW:
            function_s = "SH";
            break;
      case FUNCT_SW_RAW:
            function_s = "SW";
            break;
      default:
         printf("Illegal store instruction\n");
         exit(1);
   }

   printf ("%s %s, %s, %d", function_s, REG2STRING(base), REG2STRING(src), immediate);
}

void print_load_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t base;
   uint32_t dest;
   uint32_t funct3;
   char * function_s;

   immediate = extract_immediate_type_I(instr);
   dest      = extract_from_32b(instr, 11, 7);
   funct3    = extract_from_32b(instr, 14, 12);
   base      = extract_from_32b(instr, 19, 15);

   switch (funct3) {
      case FUNCT_LB_RAW:
            function_s = "LB";
            break;
      case FUNCT_LH_RAW:
            function_s = "LH";
            break;
      case FUNCT_LW_RAW:
            function_s = "LW";
            break;
      case FUNCT_LBU_RAW:
            function_s = "LBU";
            break;
      case FUNCT_LHU_RAW:
            function_s = "LHU";
            break;
      default:
         printf("Illegal load instruction\n");
         exit(1);
   }
   printf("%s %s, %s, %d\n\n", function_s, REG2STRING(dest), REG2STRING(base), immediate);
}

void print_jump_direct_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t dest;
   immediate = extract_immediate_type_J(instr);
   dest      = extract_from_32b(instr, 11, 7);
   printf("JAL %s, %d\n", REG2STRING(dest), immediate);
}

void print_branch_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t src1;
   uint32_t src2;
   uint32_t funct3;

   char * function_s;

   immediate = extract_immediate_type_B(instr);
   funct3    = extract_from_32b(instr, 14, 12);
   src1      = extract_from_32b(instr, 19, 15);
   src2      = extract_from_32b(instr, 24, 20);

   switch(funct3) {
      case FUNCT_BEQ_RAW:
            function_s = "BEQ";
            break;
      case FUNCT_BNE_RAW:
            function_s = "BNE";
            break;
      case FUNCT_BLT_RAW:
            function_s = "BLT";
            break;
      case FUNCT_BTLU_RAW:
            function_s = "BTLU";
            break;
      case FUNCT_BGT_RAW:
            function_s = "BGT";
            break;
      case FUNCT_BGTU_RAW:
            function_s = "BGTU";
            break;
      default:
         printf("Illegal branch instruction\n");
         exit(1);
   }
   printf("%s %s, %s, %d\n", function_s,
                           REG2STRING(src1),
                           REG2STRING(src2),
                           immediate);
}

void print_immediate_instruction (uint32_t instr) {
   uint32_t immediate;
   uint32_t dest;
   uint32_t funct3;
   uint32_t funct7;
   uint32_t funct10;
   uint32_t op;

   char * function_s;

   funct3        = extract_from_32b(instr, 14, 12);
   funct7        = extract_from_32b(instr, 31, 25);
   funct10       = (funct7 << 3) + funct3;

   immediate     = extract_immediate_type_I(instr);
   dest          = extract_from_32b(instr, 11, 7);
   op            = extract_from_32b(instr, 19, 15);

   switch (funct3) {
      case FUNCT_ADD_RAW:
         function_s = "ADDI";
         break;
      case FUNCT_OR_RAW:
         function_s = "ORI";
         break;
      case FUNCT_XOR_RAW:
         function_s = "XORI";
         break;
      case FUNCT_AND_RAW:
         function_s = "ANDI";
         break;
      case FUNCT_SLT_RAW:
         function_s = "STLI";
         break;
      case FUNCT_SLTU_RAW:
         function_s = "STLUI";
         break;
      default:
         //Only 5 bits are relevant now
         immediate &= 0x1F;
         switch (funct10) {
            case FUNCT_SLL_RAW:
               function_s = "SLL";
               break;
            case FUNCT_SRL_RAW:
               function_s = "SRL";
               break;
            case FUNCT_SRA_RAW:
               function_s = "SRL";
               break;
            default:
               printf("Illegal instruction\n");
               exit (1);
         }
   }
   printf("%s %s, %s, %d\n", function_s, REG2STRING(dest), REG2STRING(op), immediate);
}

void print_register_instruction (uint32_t instr) {
   uint32_t dest;
   uint32_t funct3;
   uint32_t funct7;
   uint32_t funct10;
   uint32_t op1;
   uint32_t op2;

   char * function_s;

   funct3        = extract_from_32b(instr, 14, 12);
   funct7        = extract_from_32b(instr, 31, 25);
   funct10       = (funct7 << 3) + funct3;

   dest  = extract_from_32b(instr, 11, 7);
   op1   = extract_from_32b(instr, 19, 15);
   op2   = extract_from_32b(instr, 24, 20);


   switch (funct10) {
      case FUNCT_ADD_RAW:
            function_s = "ADD";
            break;
      case FUNCT_SUB_RAW:
            function_s = "SUB";
            break;
      case FUNCT_SLT_RAW:
            function_s = "SLT";
            break;
      case FUNCT_SLTU_RAW:
            function_s = "STLU";
            break;
      case FUNCT_OR_RAW:
            function_s = "OR";
            break;
      case FUNCT_XOR_RAW:
            function_s = "XOR";
            break;
      case FUNCT_AND_RAW:
            function_s = "AND";
            break;
      case FUNCT_SLL_RAW:
            function_s = "SLL";
            break;
      case FUNCT_SRL_RAW:
            function_s = "SRL";
            break;
      case FUNCT_SRA_RAW:
            function_s = "SRA";
            break;
      default:
            printf("Illegal register instruction\n");
            exit(1);
   }
   printf("%s %s, %s, %s\n", function_s, REG2STRING(dest), REG2STRING(op1), REG2STRING(op2));
}

void print_instruction (uint32_t instr) {
   uint32_t opcode;
   opcode = extract_from_32b(instr, 6, 0);
   switch (opcode) {
      case OPCODE_IMM:
         print_immediate_instruction(instr);
         break;
      case OPCODE_LUI:
         print_lui_instruction(instr);
         break;
      case OPCODE_AUIPC:
         print_auipc_instruction(instr);
         break;
      case OPCODE_OP:
         print_register_instruction(instr);
         break;
      case OPCODE_JAL:
         print_jump_direct_instruction(instr);
         break;
      case OPCODE_JALR:
         print_jump_register_instruction(instr);
         break;
      case OPCODE_BRANCH:
         print_branch_instruction(instr);
         break;
      case OPCODE_LOAD:
         print_load_instruction(instr);
         break;
      case OPCODE_STORE:
         print_store_instruction(instr);
         break;
      //case OPCODE_MISC_MEM:
      //case OPCODE_SYSTEM:
      default: //Error
      break;
   }
}
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
