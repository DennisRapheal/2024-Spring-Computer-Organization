`timescale 1ns / 1ps
// <your student id>

/** [Reading] 4.7 p.372-375
 * Understand when and how to detect stalling caused by data hazards.
 * When read a reg right after it was load from memory,
 * it is impossible to solve the hazard just by forwarding.
 */

/* checkout FIGURE 4.59 to understand why a stall is needed */
/* checkout FIGURE 4.60 for how this unit should be connected */
module hazard_detection (
    input        ID_EX_mem_read,
    input  [4:0] ID_EX_rt,
    input  [4:0] IF_ID_rs,
    input  [4:0] IF_ID_rt,
    input  [4:0] IF_ID_rd,
    input  [4:0] ID_EX_opcode, 

    input        ID_EX_reg_write,
    input  [4:0] EX_MEM_rd,
    input  [4:0] ID_EX_rs,
    input  [4:0] EX_MEM_rt,
    input        EX_MEM_mem_read,

    input        clk,
    input        rstn,
    input        branch_control,
    output       pc_write,        // only update PC when this is set
    output       IF_ID_write,     // only update IF/ID stage registers when this is set
    output       stall            // insert a stall (bubble) in ID/EX when this is set
);

    /** [step 3] Stalling
     * 1. calculate stall by equation from textbook.
     * 2. Should pc be written when stall? no
     * 3. Should IF/ID stage registers be updated when stall? no 
     */
    // 4. Add stalling
    wire branch_read_reg_after_load, branch_read_reg_after_ALU, branch_read_reg_after2_load; 
    reg[2:0] nxt_stall;
    
    // branch read registers right after an ALU instruction writes it -> 1 stall
    // branch read registers right after a load instruction writes it -> 2 stalls
    assign branch_read_reg_after2_load= (branch_control && (EX_MEM_mem_read && ((EX_MEM_rt == IF_ID_rs) || (EX_MEM_rt == IF_ID_rt))));// load before before branch
    assign branch_read_reg_after_load = (branch_control && (ID_EX_mem_read  && ((ID_EX_rt  == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)))); // load
    assign branch_read_reg_after_ALU  = (branch_control && (ID_EX_reg_write && ((ID_EX_rt  == IF_ID_rs) || (ID_EX_rt == IF_ID_rd)))); // R-format
    
    wire   stall_condition;
    assign stall_condition = (ID_EX_mem_read && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt))); // load use
    wire addi_condition;
    assign addi_condition =  (branch_control && ((ID_EX_opcode == 6'b001000) && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt))));

    assign stall = (nxt_stall > 0);
    assign pc_write    = ~stall;
    assign IF_ID_write = ~stall;

    always @(*)begin
        if (branch_read_reg_after_load)begin
            nxt_stall <= 2;
        end 
        else if (branch_read_reg_after_ALU || 
                    stall_condition || 
                        branch_read_reg_after2_load ||
                            addi_condition)begin
            nxt_stall <= 1;
        end
    end

    always @(posedge clk && rstn)begin
        if(nxt_stall > 0)begin
            nxt_stall <= nxt_stall - 1; 
        end
        else begin
            nxt_stall <= 0;
        end
    end

    always @(negedge rstn) begin
        nxt_stall <= 0;
    end

endmodule