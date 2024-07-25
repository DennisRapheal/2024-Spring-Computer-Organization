`timescale 1ns / 1ps
// 111550006

/** [Reading] 4.7 p.363-371
 * Understand when and how to forward
 */

/* checkout FIGURE 4.55 for definition of mux control signals */
/* checkout FIGURE 4.56/60 for how this unit should be connected */
module forwarding (
    input      [4:0] ID_EX_rs,          // inputs are pipeline registers relate to forwarding
    input      [4:0] ID_EX_rt,
    input            EX_MEM_reg_write,
    input      [4:0] EX_MEM_rd,
    input            MEM_WB_reg_write,
    input      [4:0] MEM_WB_rd,
    input            PCSrc, 
    input            IF_ID_write,
    input            ID_EX_mem_read,
    input      [4:0] IF_ID_rs,
    input      [4:0] IF_ID_rt,
    output reg [1:0] forward_A,         // ALU operand is from: 00:ID/EX, 10: EX/MEM, 01:MEM/WB
    output reg [1:0] forward_B
);
    /** [step 1] Forwarding
     * 1. EX hazard (p.366)
     * 2. MEM hazard (p.369)
     * 3. Solve potential data hazards between:
          the result of the instruction in the WB stage,
          the result of the instruction in the MEM stage,
          and the source operand of the instruction in the ALU stage.
          Hint: Be careful that the textbook is wrong here!
          Hint: Which of EX & MEM hazard has higher priority?
     */
    initial begin
        forward_A = 2'b00;
        forward_B = 2'b00;
    end

    always @(*) begin
        // Reset the forward signals
        // forward_A = 2'b00;
        // forward_B = 2'b00;
        // 3. Add forwarding for registers used in branch decision from EX/MEM (MEM stage)
        // Check for EX hazard (higher priority)
        if      (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs)) forward_A <= 2'b10;
        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs)) forward_A <= 2'b01;
        else forward_A <= 2'b00;
        // else if (ID_EX_mem_read && IF_ID_rs == ID_EX_rt) begin
        //     // load use hazard
        //     forward_A <= 2'b01;
        // end
        

        ///////////////
        if      (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt)) forward_B <= 2'b10;
        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rt)) forward_B <= 2'b01;
        else forward_B <= 2'b00;
        // else if (ID_EX_mem_read && IF_ID_rt == ID_EX_rt) begin
        //     // load use hazard
        //     forward_B <= 2'b01;
        // end
    end

endmodule
