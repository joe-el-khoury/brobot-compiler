.equ TERMINAL, 0xFF201000

.data
# The address of the start of the file
BASE_FILE: .word 0x30000000

/**
 * Resets the start address of the file.
 */
reset_base_file:
    addi sp, sp, -0x8
    stw r10, 0x0(sp)
    stw r11, 0x4(sp)
    
    # Set the new base file address to the old one.
    movia r10, 0x30000000
    movia r11, BASE_FILE
    stw r10, 0(r11)
    
    ldw r11, 0x4(sp)
    ldw r10, 0x0(sp)
    addi sp, sp, 0x8
    ret

/**
 * Get the address of the end of the file.
 */
get_end_of_file_address:
    movia r2, BASE_FILE
    ldw r2, 0(r2)
    
    loop_to_end:
        ldw r3, 0(r2)
        0:
            srli r3, r3, 0
            andi r3, r3, 0xFF
            beq r3, r0, 4f
        
        ldw r3, 0(r2)
        1:
            srli r3, r3, 8
            andi r3, r3, 0xFF
            beq r3, r0, 4f
        
        ldw r3, 0(r2)
        2:
            srli r3, r3, 16
            andi r3, r3, 0xFF
            beq r3, r0, 4f
        
        ldw r3, 0(r2)
        3:
            srli r3, r3, 24
            andi r3, r3, 0xFF
            beq r3, r0, 4f
            
        addi r2, r2, 0x4
        br loop_to_end
    
    4: ret
    
/**
 * Get a character at a certain position in the file.
 */
get_char:
    addi sp, sp, -0x14
    stw r11, 0x00(sp)
    stw r12, 0x04(sp)
    stw r13, 0x08(sp)
    stw r14, 0x0C(sp)
    stw ra,  0x10(sp)
    
    # Every 4 characters, we increment the address by 4.
    movi r12, 0x4
    
    # This computes r4 % 4 and stores the result in r13.
    divu r11, r4, r12
    mul r13, r11, r12
    sub r13, r4, r13
    
    mov r14, r4
    
    # r14 = r14 - (r4 % 4)
    sub r14, r14, r13
    
    movia r11, BASE_FILE
    ldw r11, 0(r11)
    add r11, r11, r14
    movia r12, BASE_FILE
    stw r11, 0(r12)
    
    1:
        # We now know that r4 % 4 != 0, so we can now get the character.
        # We will now use r13 as the index, because it stores the modulus
        # of r4 and 4.
        
        # Get the address of the base of the file.
        movia r11, BASE_FILE
        ldw r11, 0(r11)
        
        # Get the contents at that address.
        ldw r2, 0(r11)
        mov r16, r2
        
        movi r12, 0
        beq r13, r12, 0f
        movi r12, 1
        beq r13, r12, 1f
        movi r12, 2
        beq r13, r12, 2f
        movi r12, 3
        beq r13, r12, 3f
        
    0:
        srli r2, r2, 0
        andi r2, r2, 0xFF
        br 4f
    1:
        srli r2, r2, 8
        andi r2, r2, 0xFF
        br 4f
    2:
        srli r2, r2, 16
        andi r2, r2, 0xFF
        br 4f
    3:
        srli r2, r2, 24
        andi r2, r2, 0xFF
        br 4f
    4:
        call reset_base_file
        
        # Pop all saved registers from the stack.
        ldw ra,  0x10(sp)
        ldw r14, 0x0C(sp)
        ldw r13, 0x08(sp)
        ldw r12, 0x04(sp)
        ldw r11, 0x00(sp)
        addi sp, sp, 0x14
        
        ret