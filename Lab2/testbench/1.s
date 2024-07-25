        .data   0x10008000      # start of Dynamic Data (pointed by $gp)
hun:    .word   0x00114514      # 0($gp)
hah:    .word   0xf1919810
        .word   0x1
        .word   0x2
        .word   0x3             # 16($gp)

        .text   0x00400000      # start of Text (pointed by PC), 
                                # Be careful there might be some other instructions in JsSPIM.
                                # Recommend at least 9 instructions to cover out those other instructions.
main:
    lui $t0, 0x1000                 # Load upper immediate to set upper 16 bits of $t0 to 0x1000
    lw $t1,  hun                    # Load word from memory at address hun into $t1
    ori $t2, $t1, 0xFF              # Bitwise OR immediate to set $t2 with value of $t1 OR 0xFF
    slt $t3, $t1, $t2               # Set less than to compare $t1 and $t2, result stored in $t3
    j loop                          # Jump to the loop label

loop:
    lw $t4, hah                     
    sw $t4, 8($gp)                  # Store word from $t4 into memory at address $gp + 8
    or $t7, $zero, $gp              # should not execute
    lw $t6, 0($gp)                  # should not execute