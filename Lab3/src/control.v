`timescale 1ns / 1ps
// 111550006

/** [Reading] 4.4 p.318-321
 * "Designing the Main Control Unit"
 */
/** [Prerequisite] alu_control.v
 * This module is the Control unit in FIGURE 4.17
 * You can implement it by any style you want.
 */

/* checkout FIGURE 4.16/18 to understand each definition of control signals */
module control (
    input  [5:0] opcode,      // the opcode field of a instruction is [5:4]
    output       reg_dst,     // select register destination: rt(0), rd(1)
    output       alu_src,     // select 2nd operand of ALU: rt(0), sign-extended(1)
    output       mem_to_reg,  // select data write to register: ALU(0), memory(1)
    output       reg_write,   // enable write to register file
    output       mem_read,    // enable read form data memory
    output       mem_write,   // enable write to data memory
    output       branch,      // this is a branch instruction or not (work with alu.zero)

    output       jump,
    output       lui, 
    output       ori,
    output [1:0] alu_op       // ALUOp passed to ALU Control unit
);

    /* implement "combinational" logic satisfying requirements in FIGURE 4.18 */
    /* You can check the "Green Card" to get the opcode/funct for each instruction. */
    // R   000000
    // lw  100011
    // sw  101011
    // lui 001111
    // ori 001101
    // j   000010
    // addi 001000 
    assign reg_dst    = ( opcode == 6'b000000 ) ? 1 : 0;              // R-format
    assign alu_src    = ( opcode == 6'b100011 | opcode == 6'b101011 |  opcode == 6'b001111 | opcode == 6'b001101 | opcode == 6'b001000) ? 1 : 0;  // lw, sw, lui, ori addi
    assign mem_to_reg = ( opcode == 6'b100011) ? 1 : 0;  // lw
    // lw and lui need to be 1 since it may search for non-exist memory
    assign reg_write  = ( opcode == 6'b000000 | opcode == 6'b100011 | opcode == 6'b001111 | opcode == 6'b001101 | opcode == 6'b001000 ) ? 1 : 0; // R-type, lw, lui, ori addi 
    assign mem_read   = ( opcode == 6'b100011 ) ? 1 : 0;              // lw
    assign mem_write  = ( opcode == 6'b101011 ) ? 1 : 0;              // sw
    assign branch     = ( opcode == 6'b000100 ) ? 1 : 0;              // beq
    assign jump       = ( opcode == 6'b000010 ) ? 1 : 0;
    assign lui        = ( opcode == 6'b001111 ) ? 1 : 0;  
    assign ori        = ( opcode == 6'b001101 ) ? 1 : 0;  
    assign alu_op[1]  = ( opcode == 6'b000000 ) ? 1 : 0;              // R-format
    assign alu_op[0]  = ( opcode == 6'b000100 ) ? 1 : 0;              // beq
endmodule
