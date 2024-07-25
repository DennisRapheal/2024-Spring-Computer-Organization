`timescale 1ns / 1ps
// 111550006

/** [Reading] 4.4 p.316-318
 * "The ALU Control"
 */
/**
 * This module is the ALU control in FIGURE 4.17
 * You can implement it by any style you want.
 * There's a more hardware efficient design in Appendix D.
 */

/* checkout FIGURE 4.12/13 */
module alu_control (
    input  [1:0] alu_op,    // ALUOp
    input  [5:0] funct,     // Funct field
    output [3:0] operation  // Operation
);

    /* implement "combinational" logic satisfying requirements in FIGURE 4.12 */
    // add sub slt or and nop lw sw beq j li lui ori nop
    assign operation = (alu_op == 2'b01) ? 4'b0110 : 
                       (alu_op == 2'b10 & funct[3:0] == 4'b0000) ? 4'b0010 : // add
                       (alu_op == 2'b10 & funct[3:0] == 4'b0010) ? 4'b0110 : //sub
                       (alu_op == 2'b10 & funct[3:0] == 4'b0100) ? 4'b0000 : //and
                       (alu_op == 2'b10 & funct[3:0] == 4'b0101) ? 4'b0001 : //or
                       (alu_op == 2'b10 & funct[3:0] == 4'b1010) ? 4'b0111 : //slt
                        4'b0010;
endmodule
