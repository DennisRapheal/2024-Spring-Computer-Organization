`timescale 1ns / 1ps
// 111550006

/* checkout FIGURE 4.7 */
module reg_file (
    input         clk,          // clock
    input         rstn,         // negative reset
    input  [ 4:0] read_reg_1,   // Read Register 1 (address)
    input  [ 4:0] read_reg_2,   // Read Register 2 (address)
    input         reg_write,    // RegWrite: write data when posedge clk
    input  [ 4:0] write_reg,    // Write Register (address)
    input  [31:0] write_data,   // Write Data
    output reg [31:0] read_data_1,  // Read Data 1
    output reg [31:0] read_data_2   // Read Data 2
);

    /* [step 1] How many bits per register? How many registers does MIPS have? */
    reg [31:0] registers[0:31];  // do not change its name

    /* [step 2] Read Registers */
    /* Remember to check whether register number is zero */
    initial begin
        read_data_1 = 5'b0;
        read_data_2 = 5'b0;
    end
    always @(*) begin
        if(read_reg_1 != 0)
             read_data_1 = registers[read_reg_1];
        if(read_reg_2 != 0)
             read_data_2 = registers[read_reg_2];
    end

    /** Sequential Logic
     * `posedge clk` means that this block will execute when clk changes from 0 to 1 (positive edge trigger).
     * `negedge rstn` vice versa.
     * https://www.chipverify.com/verilog/verilog-always-block
     */
    /* [step 3] Write Registers */
    always @(posedge clk)
        if (rstn) begin  // make sure to check reset!
            if (reg_write) begin
                registers[write_reg] <= write_data ;
            end
        end

    /* [step 4] Reset Registers (wordy in Verilog, how about System Verilog?) */
    integer i;
    always @(negedge rstn) begin
        for ( i=0 ; i<32 ; i= i + 1 ) begin
            registers[i] <= 0 ;
        end
    end

endmodule