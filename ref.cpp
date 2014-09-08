class instruction {

public:

private:

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

   virtual void execute (rf_t *rf, mem_t *dmem) {

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
   ret = (extract_from_32b(data, 19, 12))  << 12) +
         (extract_from_32b(data, 20, 20)   << 11) +
         (extract_from_32b(data, 30, 21)   <<  1);
   ret = sign_extend(sign, ret, 20);
   return ret;
}
