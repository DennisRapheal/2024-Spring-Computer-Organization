`timescale 1ns / 1ps
// 111550006

/** [Prerequisite] pipelined (Lab 3), forwarding, hazard_detection
 * This module is the pipelined MIPS processor "similar to" FIGURE 4.60 (control hazard is not solved).
 * You can implement it by any style you want, as long as it passes testbench.
 */

module pipelined #(
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
) (
    input clk,  // clock
    input rstn  // negative reset
);

    /** [step 0] Copy from Lab 3
     * You should modify your pipelined processor from Lab 3, so copy to here first.
     */
    wire [31:0] instr_mem_address, instr_mem_instr;
    instr_mem #(
        .BYTES(TEXT_BYTES),
        .START(TEXT_START)
    ) instr_mem (
        .address(instr_mem_address),
        .instr  (instr_mem_instr)
    );

    /* Register Rile */
    wire [4:0] reg_file_read_reg_1, reg_file_read_reg_2, reg_file_write_reg;
    wire reg_file_reg_write;
    wire [31:0] reg_file_write_data, reg_file_read_data_1, reg_file_read_data_2;
    reg_file reg_file (
        .clk        (~clk),                  // only write when negative edge
        .rstn       (rstn),
        .read_reg_1 (reg_file_read_reg_1),
        .read_reg_2 (reg_file_read_reg_2),
        .reg_write  (reg_file_reg_write),
        .write_reg  (reg_file_write_reg),
        .write_data (reg_file_write_data),
        .read_data_1(reg_file_read_data_1),
        .read_data_2(reg_file_read_data_2)
    );

    /* ALU */
    wire [31:0] alu_a, alu_b, alu_result;
    wire [3:0] alu_ALU_ctl;
    wire alu_zero, alu_overflow;
    alu alu (
        .a       (alu_a),
        .b       (alu_b),
        .ALU_ctl (alu_ALU_ctl),
        .result  (alu_result),
        .zero    (alu_zero),
        .overflow(alu_overflow)
    );

    /* Data Memory */
    wire data_mem_mem_read, data_mem_mem_write;
    wire [31:0] data_mem_address, data_mem_write_data, data_mem_read_data;
    data_mem #(
        .BYTES(DATA_BYTES),
        .START(DATA_START)
    ) data_mem (
        .clk       (~clk),                 // only write when negative edge
        .mem_read  (data_mem_mem_read),
        .mem_write (data_mem_mem_write),
        .address   (data_mem_address),
        .write_data(data_mem_write_data),
        .read_data (data_mem_read_data)
    );

    /* ALU Control */
    wire [1:0] alu_control_alu_op;
    wire [5:0] alu_control_funct;
    wire [3:0] alu_control_operation;
    alu_control alu_control (
        .alu_op   (alu_control_alu_op),
        .funct    (alu_control_funct),
        .operation(alu_control_operation)
    );

    /* (Main) Control */
    wire [5:0] control_opcode;
    // Execution/address calculation stage control lines
    wire control_reg_dst, control_alu_src;
    wire [1:0] control_alu_op;
    // Memory access stage control lines
    wire control_branch, control_mem_read, control_mem_write;
    // Wire-back stage control lines
    wire control_reg_write, control_mem_to_reg;
    control control (
        .opcode    (control_opcode),
        .reg_dst   (control_reg_dst),
        .alu_src   (control_alu_src),
        .mem_to_reg(control_mem_to_reg),
        .reg_write (control_reg_write),
        .mem_read  (control_mem_read),
        .mem_write (control_mem_write),
        .branch    (control_branch),
        .alu_op    (control_alu_op)
    );

    //IF Stage
    reg [31:0] pc;  // DO NOT change this line
    // 2.
    assign instr_mem_address = pc;
    // 3.
    wire [31:0] pc_4 = pc + 4;
    // 4.
    reg [31:0] IF_ID_instr, IF_ID_pc_4;
    always @(posedge clk)
        if (rstn && IF_ID_write) begin
            IF_ID_instr <= instr_mem_instr;  // a.
            IF_ID_pc_4  <= pc_4;  // b.
        end
    always @(negedge rstn) begin
        IF_ID_instr <= 0;  // a.
        IF_ID_pc_4  <= 0;  // b.
    end

    //IF Stage
    wire [4:0]  IF_ID_rt, IF_ID_rd, IF_ID_rs;
    assign IF_ID_rt = IF_ID_instr[20:16];
    assign IF_ID_rd = IF_ID_instr[15:11];
    assign IF_ID_rs = IF_ID_instr[25:21];

    //ID Stage
    reg [31:0] ID_EX_read_data_1, ID_EX_read_data_2, ID_EX_pc_4, ID_EX_sign_extend; 
    reg [4:0]  ID_EX_rs, ID_EX_rt, ID_EX_rd;
    reg [5:0]  ID_EX_opcode; 
    reg [1:0]  ID_EX_WB; //mem to reg, regwrite
    reg [2:0]  ID_EX_M;  //mem read, memwrite, branch
    reg [3:0]  ID_EX_EX; //regdst, aluop, alusrc
    assign control_opcode = IF_ID_instr[31:26];
    assign reg_file_read_reg_1 = IF_ID_instr[25:21];
    assign reg_file_read_reg_2 = IF_ID_instr[20:16];
    always @(posedge clk) begin
        if(stall) begin
            ID_EX_WB <= 0;
            ID_EX_M  <= 0;
            ID_EX_EX <= 0;
        end
        else begin
            // 1. Generate control signals // 2 1 0!!!
            ID_EX_WB <=  {control_mem_to_reg, control_reg_write};
            ID_EX_M  <=  {control_mem_read  , control_mem_write, control_branch};
            ID_EX_EX <=  {control_reg_dst   , control_alu_op, control_alu_src};
        end
        
        if (rstn) begin
            // 2. Read desired registers
            ID_EX_read_data_1 <= reg_file_read_data_1;
            ID_EX_read_data_2 <= reg_file_read_data_2;
            
            // 3. Calculate sign-extended immediate from ID stage
            ID_EX_sign_extend <= {{16{IF_ID_instr[15]}}, IF_ID_instr[15:0]};

            // 4. Update ID/EX pipeline registers, and reset them @(negedge rstn)
            ID_EX_rs  <= IF_ID_instr[25:21];
            ID_EX_rt  <= IF_ID_instr[20:16];
            ID_EX_rd  <= IF_ID_instr[15:11];
            ID_EX_opcode <= control_opcode; 
            ID_EX_pc_4 <= IF_ID_pc_4;
        end
    end
    

    always @(negedge rstn) begin
        ID_EX_pc_4 <= 0;
        ID_EX_read_data_1 <= 0;
        ID_EX_read_data_2 <= 0;
        ID_EX_sign_extend <= 0; 
        ID_EX_rt <= 0;
        ID_EX_rd <= 0;
        ID_EX_WB <= 0;
        ID_EX_M  <= 0;
        ID_EX_EX <= 0;
        ID_EX_opcode <= 0;
    end

    //EX Stage
    reg       EX_MEM_zero;
    reg [1:0] EX_MEM_WB; //mem to reg, regwrite
    reg [2:0] EX_MEM_M;  //mem read, memwrite, branch
    reg [4:0] EX_MEM_rd;
    reg [31:0] EX_MEM_alu_result, EX_MEM_write_data; //, EX_MEM_branch_target;
    always @(posedge clk)
        if (rstn) begin
            // 1. Calculate branch target address
            EX_MEM_alu_result <= alu_result;
            EX_MEM_zero <= alu_zero;
            // EX_MEM_branch_target <= (ID_EX_pc_4 + (ID_EX_sign_extend << 2));
            EX_MEM_WB <= ID_EX_WB;
            EX_MEM_M  <= ID_EX_M;
            EX_MEM_write_data <= ID_EX_read_data_2;
            if (ID_EX_EX[3]) EX_MEM_rd <= ID_EX_rd;
            else EX_MEM_rd <= ID_EX_rt;
        end
    always @(negedge rstn) begin
        EX_MEM_alu_result <= 0;
        // EX_MEM_branch_target <= 0;
        EX_MEM_M <= 0;
        EX_MEM_WB <= 0;
        EX_MEM_zero <= 0;
        EX_MEM_rd <= 0;
        EX_MEM_write_data <= 0 ;
    end

    // assign alu_a = ID_EX_read_data_1;
    // assign alu_b = (ID_EX_EX[0]) ? (ID_EX_sign_extend) : ID_EX_read_data_2;
    assign alu_control_alu_op = ID_EX_EX[2:1];
    assign alu_ALU_ctl = alu_control_operation; 
    assign alu_control_funct = ID_EX_sign_extend[5:0]; // 改成ID_sign_extend

     // MEM Stage
    reg [31:0] MEM_WB_address, MEM_WB_read_data;
    reg [4:0] MEM_WB_rd;
    reg [1:0] MEM_WB_WB;
    wire PCSrc;
    assign data_mem_mem_read   = EX_MEM_M[2];
    assign data_mem_mem_write  = EX_MEM_M[1];
    assign data_mem_address    = EX_MEM_alu_result;
    assign data_mem_write_data = EX_MEM_write_data;
    // assign PCSrc = EX_MEM_M[0] & EX_MEM_zero;
    

    always @(posedge clk)
        if (rstn) begin
            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_WB <= EX_MEM_WB;
            MEM_WB_address <= EX_MEM_alu_result;
            MEM_WB_read_data <= data_mem_read_data;
            // 1. Decide whether to branch or not
        end
    // always @(posedge clk) begin
    //     if(pc_write) begin
    //         pc <= (PCSrc) ? EX_MEM_branch_target : pc_4;
    //     end
    // end
    always @(negedge rstn) begin
        pc <= 32'h00400000;
        MEM_WB_address    <= 0;
        MEM_WB_read_data  <= 0;
        MEM_WB_WB         <= 0;
        MEM_WB_rd         <= 0; 
    end

    // WB Stage
    assign reg_file_reg_write = MEM_WB_WB[0];
    assign reg_file_write_reg = MEM_WB_rd;
    assign reg_file_write_data = MEM_WB_WB[1] ?  MEM_WB_read_data : MEM_WB_address;  

    /** [step 2] Connect Forwarding unit
     * 1. add ID_EX_rs into ID/EX stage registers
     * 2. Use a mux to select correct ALU operands according to forward_A/B
     *    Hint don't forget that alu_b might be sign-extended immediate!
     */
    wire [1:0] forward_A, forward_B;
    forwarding forwarding (
        .ID_EX_rs        (ID_EX_rs),
        .ID_EX_rt        (ID_EX_rt),
        .EX_MEM_reg_write(EX_MEM_WB[0]),
        .EX_MEM_rd       (EX_MEM_rd),
        .MEM_WB_reg_write(MEM_WB_WB[0]),
        .MEM_WB_rd       (MEM_WB_rd),
        .PCSrc           (PCSrc),
        .ID_EX_mem_read  (ID_EX_M[2]),
        .IF_ID_write     (IF_ID_write),
        .IF_ID_rs        (IF_ID_instr[25:21]),
        .IF_ID_rt        (IF_ID_instr[20:16]),
        .forward_A       (forward_A),
        .forward_B       (forward_B)
    );
    

    /** [step 4] Connect Hazard Detection unit
     * 1. use pc_write when updating PC
     * 2. use IF_ID_write when updating IF/ID stage registers -> line 115
     * 3. use stall when updating ID/EX stage registers       -> line 136
     */

wire stall, pc_write, IF_ID_write;
hazard_detection hazard_detection (
        .ID_EX_mem_read (ID_EX_M[2]),
        .ID_EX_rt       (ID_EX_rt),
        .IF_ID_rs       (IF_ID_instr[25:21]),
        .IF_ID_rt       (IF_ID_instr[20:16]),
        .IF_ID_rd       (IF_ID_instr[15:11]),
        .ID_EX_reg_write(ID_EX_WB[0]),
        .EX_MEM_rd      (EX_MEM_rd),
        .ID_EX_rs       (ID_EX_rs),
        .EX_MEM_mem_read(EX_MEM_M[2]),
        .EX_MEM_rt      (EX_MEM_rd),
        .ID_EX_opcode   (ID_EX_opcode),
        .clk            (clk),
        .rstn           (rstn),
        .branch_control (control_branch),
        .pc_write       (pc_write),            // implicitly declared
        .IF_ID_write    (IF_ID_write),         // implicitly declared
        .stall          (stall)                // implicitly declared
    );

    //step4
    always @(posedge clk) begin
        if(pc_write) begin
            // pc <= (PCSrc) ? EX_MEM_branch_target : pc_4;
            pc <= (PCSrc) ? ID_branch_target : pc_4;
        end
    end

    /** [step 5] Control Hazard
     * This is the most difficult part since the textbook does not provide enough information.
     * By reading p.377-379 "Reducing the Delay of Branches",
     * we can disassemble this into the following steps:
     * 1. Move branch target address calculation & taken or not from EX to ID
     * 2. Move branch decision from MEM to ID
     * 3. Add forwarding for registers used in branch decision from EX/MEM (MEM stage)
        * since branch might read register which are not written yet, forwarding to ID stage is needed. 
        * Is forwarding from MEM/WB to ID needed?
     * 4. Add stalling:
          branch read registers right after an ALU instruction writes it -> 1 stall
          branch read registers right after a load instruction writes it -> 2 stalls
     */
    // 1. Move branch target address calculation & taken or not from EX to ID
    wire [31:0] ID_branch_target, ID_sign_extend; // address
    
    assign ID_sign_extend   = {{16{IF_ID_instr[15]}}, IF_ID_instr[15:0]};
    assign ID_branch_target = ( ID_sign_extend << 2 ) + IF_ID_pc_4; 
    // taken or not depends on control_branch directly

    //3. Add forwarding for registers used in branch decision from EX/MEM (MEM stage)
    wire[31:0] branch_data_1, branch_data_2;
    assign branch_data_1 =  (control_branch && (EX_MEM_WB[0] && (EX_MEM_rd != 0) && (IF_ID_instr[20:16] == EX_MEM_rd))) ? EX_MEM_alu_result : 
                            (control_branch && (MEM_WB_WB[1] && (MEM_WB_rd != 0) && (IF_ID_instr[20:16] == MEM_WB_rd))) ? reg_file_write_data : 
                            reg_file_read_data_1;
    assign branch_data_2 =  (control_branch && (EX_MEM_WB[0] && (EX_MEM_rd != 0) && (IF_ID_instr[15:11] == EX_MEM_rd))) ? EX_MEM_alu_result : 
                            (control_branch && (MEM_WB_WB[1] && (MEM_WB_rd != 0) && (IF_ID_instr[15:11] == MEM_WB_rd))) ? reg_file_write_data : 
                            reg_file_read_data_2;
    // 2. Move branch decision from MEM to ID
    assign PCSrc = (control_branch && (branch_data_1 == branch_data_2));
    //4.->hazard_detection 3.->forwarding

    // step 2
    // branch will still get maybe unassigned value from regfile even if it won't change pc
    assign alu_a = (control_branch)      ? branch_data_1 : 
                   (forward_A == 2'b10)  ? EX_MEM_alu_result :
                   (forward_A == 2'b01)  ? reg_file_write_data: 
                    ID_EX_read_data_1 ;  // forward 1st operand
    assign alu_b = (control_branch)      ? branch_data_2 : 
                   (forward_B == 2'b10)  ? EX_MEM_alu_result :
                   (forward_B == 2'b01)  ? reg_file_write_data :
                   (ID_EX_EX[0]) ? ID_EX_sign_extend : 
                    ID_EX_read_data_2;  // forward 2nd operand

endmodule  // pipelined
