`timescale 1ns / 1ps
// 111550006

/* checkout FIGURE C.5.10 (Top) */
module bit_alu (
    input            a,          // 1 bit, a
    input            b,          // 1 bit, b
    input            less,       // 1 bit, Less
    input            a_invert,   // 1 bit, Ainvert
    input            b_invert,   // 1 bit, Binvert
    input            carry_in,   // 1 bit, CarryIn
    input      [1:0] operation,  // 2 bit, Operation
    output reg       result,     // 1 bit, Result (Must it be a reg?)
    output           carry_out   // 1 bit, CarryOut
);

    /* [step 1] invert input on demand */
    wire ai, bi;  // what's the difference between wire and reg ?
    assign ai = (a_invert == 0) ? a : ~a ;  // remember `?` operator in C/C++?
    assign bi = ( ~b_invert & b ) | ( b_invert & ~b );  // you can use logical expression too!

    /* [step 2] implement a 1-bit full adder */
    /**
     * Full adder should take ai, bi, carry_in as input, and carry_out, sum as output.
     * What is the logical expression of each output? (Checkout C.5.1)
     * Is there another easier way to implement by `+` operator?
     * https://www.chipverify.com/verilog/verilog-combinational-logic-assign
     * https://www.chipverify.com/verilog/verilog-full-adder
     */
    
    // The easy way: {carry_out, sum} = carry_in + ai + bi;
    wire sum;
    assign carry_out = ( ai & bi ) | ( (ai ^ bi) & carry_in );
    assign sum       = (ai ^ bi) ^ carry_in;

    /* [step 3] using a mux to assign result */
    //assign result = ( operation == 2'b00 ) ? ( ai & bi ) : ( operation == 2'b01 ) ? ( ai | bi ) : ( operation == 2'b10 ) ?  (sum) : ( operation == 2'b11 ) ?  (less) : 0 ;
    always @(*) begin
        case(operation)
            2'b00: result = ai & bi;
            2'b01: result = ai | bi;
            2'b10: result = sum;
            2'b11: result = less;
            default: result = 1'b0; // Default case to avoid synthesis issues
        endcase
    end
    /**
     * In fact, mux is combinational logic.
     * Can you implement the mux above without using always block?
     * Hint: `?` operator and remove reg in font of `result`.
     * https://www.chipverify.com/verilog/verilog-4to1-mux
     * [Note] Try to understand the difference between blocking `=` & non-blocking `<=` assignment.
     * https://zhuanlan.zhihu.com/p/58614706
     */

endmodule