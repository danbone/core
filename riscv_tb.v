module riscv_tb ();

parameter    ADDI  = 1;
parameter    ORI   = 2;  
parameter    XORI  = 3;
parameter    ANDI  = 4;
parameter    SLTI  = 5;
parameter    SLTUI = 6;
parameter    SLLI  = 7;
parameter    SRLI  = 8;
parameter    SRAI  = 9;
parameter    LUI   = 10;
parameter    AUIPC = 11;
parameter    ADD   = 12;
parameter    SUB   = 13;
parameter    OR    = 14;
parameter    XOR   = 15;
parameter    AND   = 16;
parameter    SLT   = 17;
parameter    SLTU  = 18;
parameter    SLL   = 19;
parameter    SRL   = 20;
parameter    SRA   = 21;
parameter    JALR  = 22;
parameter    JAL   = 23;
parameter    SB    = 24;
parameter    SH    = 25;
parameter    SW    = 26;
parameter    LB    = 27;
parameter    LH    = 28;
parameter    LW    = 29;
parameter    LBU   = 30;
parameter    LHU   = 31;
parameter    BEQ   = 32;
parameter    BNE   = 33;
parameter    BLT   = 34;
parameter    BLTU  = 35;
parameter    BGE   = 36;
parameter    BGEU  = 37;

random_pool #(3, 32) instr_pool  ();

reg success;
reg [31:0] instr;
initial begin
/*

 */
    encoding_add(
    instr_pool.add_to_pool(SLTU, success);
    instr_pool.add_to_pool(SRA,  success);
    instr_pool.add_to_pool(JALR, success);

    instr_pool.shuffle(success);
    instr_pool.get_top(instr);
    instr_pool.get_top(instr);
    instr_pool.get_top(instr);
    instr_pool.get_top(instr);
end

endmodule 

module random_pool();
    parameter DEPTH = 3;
    parameter DATA_W = 16;
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    integer head;
    integer tail;
    integer top;
    integer fullness;
    integer i;

    initial begin
        head = 0;
        top  = 0;
        fullness = 0;
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = {DATA_W{1'b0}};
        end
    end

    task add_to_pool (input [DATA_W-1:0] data, output success);
    begin
        if (fullness == DEPTH) begin
            success = 1'b0;
        end
        else begin
            success = 1'b1;
            mem[head] = data;
            head = head + 1;
            fullness = fullness + 1;
        end
    end
    endtask

    task shuffle (output success);
    begin
        top = $random % DEPTH;
        success = 1'b1;
    end
    endtask

    task get_top (output [DATA_W-1:0] data);
    begin
        if (fullness == 0) begin
            $display("top on an empty fifo");
            $finish;
        end
        else begin
            data = mem[top];
            $display("Returning %x from pool", data);
            top = top + 1;
            if (top == fullness) begin
                top = 0;
            end
        end
    end
    endtask

    task shuffle_and_top(output [DATA_W-1:0] data);
    reg success;
    begin
        shuffle(success);
        get_top(data);
    end
    endtask

endmodule

module cam ();
parameter DEPTH = 100;
parameter KEY_W = 8;
parameter DATA_W = 16;

reg [DATA_W-1:0] data_mem [0:DEPTH-1];
reg [KEY_W-1:0]  key_mem  [0:DEPTH-1];
reg              valids   [0:DEPTH-1];
integer          initial_idx;

task invalidate (input x);
integer i = 0;
begin
    for (i = 0; i < DEPTH; i = i + 1) begin
        data_mem[i] = 0;
        key_mem [i] = 0;
        valids  [i] = 0;
    end
end
endtask

initial begin
    invalidate(1);
end


    task add_pair (input [KEY_W-1:0] key, input [DATA_W-1:0] data);
    reg exists = 0;
    integer key_idx = 0;
    integer insert_idx = 0;
    integer i = 0;
    begin
        for (i = 0; i < DEPTH; i = i+1) begin
            if (key_mem[i] == key && valid[i]) begin
                exists = 1;
                key_idx = i;
            end
        end
        if (exists) begin
            $display("WARNING: Key %x exists with data : %x", key, data_mem[key_idx]);
        end
        else begin
            for (insert_idx = 0; insert_idx < DEPTH; insert_idx = insert_idx + 1) begin : FIND_INSERT_IDX
                if (!valids[insert_idx]) 
                    disable FIND_INSERT_IDX;
            end
            //Does the for loop increment the idx after the condition evaluates false? if yes then
            if (insert_idx == DEPTH) begin
            //else
            //if (valids[insert_idx]) begin
                $display("CAM IS FULL");
            end
            else begin
                $display("Add key pair %x : %x at index %d", key, data, head);
                key_mem[insert_idx] = key;
                data_mem[insert_idx] = data;
                valids[insert_idx] = 1'b1;
            end
            
        end
    end
    endtask
    
    task find_value_by_key (input [KEY_W-1:0] key, output [DATA_W-1:0] data, output found);
    integer i = 0;
    begin
        found = 1'b0;
        for (i = 0; i < DEPTH; i = i+1) begin : FIND_BLOCK
            if (key_mem[i] == key && valids[i]) begin
                found = 1;
                data = data_mem[i];
                disable FIND_BLOCK;
            end
        end
    end
    endtask
    
    task next (inout integer index, output valid);
    begin
        valid = 1'b0;
        while (index < DEPTH) begin : LOOP
            if (valids[index]) begin
                valid = 1'b1;
                disable LOOP;
            end
            else begin
                index = index + 1;
            end
        end
    end
    endtask
    
    task get_pair_by_index (input integer index, output [KEY_W-1:0] key, output [DATA_W-1:0], output success);
    integer i = 0;
    integer idx = 0;
    reg valid = 1;
    begin
        success = 1'b0;
        while (valid) begin : SEARCH_LOOP
            next(i, valid);
            if (idx == index) begin
                key = key_mem[i];
                data = key_mem[i];
                success = 1'b1;
                disable SEARCH_LOOP;
            end
            else begin
                idx = idx + 1;
            end
        end
        success = 1'b0;
    end
    endtask
    
    /*
    task get_index_by_key (input [KEY_W-1:0] key, output integer index, output success);
    
    endtask
    */

endmodule
