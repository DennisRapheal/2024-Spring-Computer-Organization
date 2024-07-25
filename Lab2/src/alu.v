`timescale 1ns / 1ps
// 111550006

/* checkout FIGURE C.5.12 */
/** [Prerequisite] complete bit_alu.v & msb_alu.v
 * We recommend you to design a 32-bit ALU with 1-bit ALU.
 * However, you can still implement ALU with more advanced feature in Verilog.
 * Feel free to code as long as the I/O ports remain the same shape.
 */
module alu (
    input  [31:0] a,        // 32 bits, source 1 (A)
    input  [31:0] b,        // 32 bits, source 2 (B)
    input  [ 3:0] ALU_ctl,  // 4 bits, ALU control input
    output [31:0] result,   // 32 bits, result
    output        zero,     // 1 bit, set to 1 when the output is 0
    output        overflow  // 1 bit, overflow
);
    /* [step 1] instantiate multiple modules */
    /**
     * First, we need wires to expose the I/O of 32 1-bit ALUs.
     * You might wonder if we can declare operation by wire [31:0][1:0] for better readability.
     * No, that is a feature call "packed array" in "System Verilog" but we are using "Verilog" instead.
     * System Verilog and Verilog are similar to C++ and C by their relationship.
     */
    wire [31:0] less, a_invert, b_invert, carry_in;
    wire [30:0] carry_out;
    wire [63:0] operation;  // flatten vector
    wire        set;        // set of most significant bit
    /**
     * Second, we instantiate the less significant 31 1-bit ALUs
     * How are these modules wried?
     */
    bit_alu lsbs[30:0] (
        .a        (a[30:0]),
        .b        (b[30:0]),
        .less     (less[30:0]),
        .a_invert (a_invert[30:0]),
        .b_invert (b_invert[30:0]),
        .carry_in (carry_in[30:0]),
        .operation(operation[61:0]),

        // output
        .result   (result[30:0]),
        .carry_out(carry_out[30:0])
    );
    /* Third, we instantiate the most significant 1-bit ALU */
    msb_bit_alu msb (
        .a        (a[31]),
        .b        (b[31]),
        .less     (less[31]),
        .a_invert (a_invert[31]),
        .b_invert (b_invert[31]),
        .carry_in (carry_in[31]),
        .operation(operation[63:62]),

        // output
        .result   (result[31]),
        .set      (set),
        .overflow (overflow)
    );
    /** [step 2] wire these ALUs correctly
     * 1. a & b are already wired.
     * 2. About `less`, only the least significant bit should be used when SLT, so the other 31 bits ...?( all 0 )
     *    checkout: https://www.chipverify.com/verilog/verilog-concatenation
     * 3. a_invert should all connect to ?
     * 4. b_invert should all connect to ? (name it b_negate first!)
     * 5. What is the relationship between carry_in[i] & carry_out[i-1] ?
     * 6. carry_in[0] and b_invert appears to be the same when SUB... , right?
     * 7. operation should be wired to which 2 bits in ALU_ctl ?
     * 8. result is already wired.
     * 9. set should be wired to which less bit? MSB
     * 10. overflow is already wired.
     * 11. You need another logic for zero output.
     */
    
    // 2. About `less`, only the least significant bit should be used when SLT, so the other 31 bits ...?
    // 9. set should be wired to which less bit? MSB
    assign less[0] = set;
    assign less[31:1] = 0;
    
    // 3. a_invert should all connect to ?
    // 4. b_invert should all connect to ? (name it b_negate first!)
    wire [1:0] b_negate;
    assign b_negate[1:0] = ALU_ctl[3:2];
    assign a_invert[31:0] = {32{b_negate[1]}};
    assign b_invert[31:0] = {32{b_negate[0]}};

    // 5. What is the relationship between carry_in[i] & carry_out[i-1] ?
    assign carry_in[31:1] = carry_out[30:0];

    // 6. carry_in[0] and b_invert appears to be the same when SUB... , right?
    assign carry_in[0] =  (ALU_ctl[2]) ? b_negate[0] : 0;

    // 7. operation should be wired to which 2 bits in ALU_ctl ?
    assign operation[63:0] = {32{ALU_ctl[1:0]}};

    // 11. You need another logic for zero output.
    assign zero = &( ~result );

endmodule

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

/* checkout FIGURE C.5.10 (Bottom) */
/* [Prerequisite] complete bit_alu.v */
module msb_bit_alu (
    input        a,          // 1 bit, a
    input        b,          // 1 bit, b
    input        less,       // 1 bit, Less
    input        a_invert,   // 1 bit, Ainvert
    input        b_invert,   // 1 bit, Binvert
    input        carry_in,   // 1 bit, CarryIn
    input  [1:0] operation,  // 2 bit, Operation
    output reg   result,     // 1 bit, Result (Must it be a reg?)
    output       set,        // 1 bit, Set
    output       overflow    // 1 bit, Overflow
);

    /* Try to implement the most significant bit ALU by yourself! */
    /* [step 1] invert input on demand */
    wire ai, bi;  // what's the difference between wire and reg ?
    assign ai = ( a_invert == 0 ) ? a : ~a ;  // remember `?` operator in C/C++?
    assign bi = ( ~b_invert & b ) | ( b_invert & ~b );  // you can use logical expression too!

    /* [step 2] implement a 1-bit full adder */
    /**
     * Full adder should take ai, bi, carry_in as input, and carry_out, sum as output.
     * What is the logical expression of each output? (Checkout C.5.1)
     * Is there another easier way to implement by `+` operator?
     * https://www.chipverify.com/verilog/verilog-combinational-logic-assign
     * https://www.chipverify.com/verilog/verilog-full-adder
     */
    // wire sum;
    assign carry_out = ( ai & bi ) | ( (ai ^ bi) & carry_in );
    assign set       = ( ai ^ bi ) ^ carry_in; // sum 
    assign overflow  = (operation == 2'b10 | operation == 2'b11) ? ( carry_in ^ carry_out ) : 0;


    /* [step 3] using a mux to assign result */
    always @(*) begin  // `*` auto captures sensitivity ports, now it's combinational logic
        case (operation)  // case is similar to switch in C
            2'b00:   result <= ai & bi;  // AND
            2'b01:   result <= ai | bi;  // OR
            2'b10:   result <= set;  // ADD
            2'b11:   result <= less;  // slt
            default: result <= 0;  // should not happened
        endcase
    end
    
endmodule