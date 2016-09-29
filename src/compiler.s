.include "file_reader.s"
.include "robot_actions.s"

.equ LED, 0xFF200000

.data
TOKEN_INDEX : .word 0x0
TOKEN_START : .word 0x0
TOKEN_END   : .word 0x0

LINE_INDEX  : .word 0x0

OPCODE_INDEX: .word 0x0
OPCODE_START: .word 0x0

# /////////////////////////////////////////////////
# /////////////////////////////////////////////////
# ///////// START OF OPCODES AND //////////////////
# /////////        SYNTAX        //////////////////
# /////////////////////////////////////////////////
# /////////////////////////////////////////////////

START_SYNTAX: .asciz "BroBot, you are under my command!"
    .align 2
END_SYNTAX: .asciz "BroBot, I release you!"
    .align 2
MOVE_SYNTAX: .asciz "move"
    .align 2
    MOVE_OPCODE: .word 0x00000000
    
SLEEP_SYNTAX: .asciz "sleep"
    .align 2
    SLEEP_OPCODE: .word 0x00000001
    
TURN_LEFT_SYNTAX: .asciz "turn->left"
    .align 2
    TURN_LEFT_OPCODE: .word 0x00000002
    
TURN_RIGHT_SYNTAX: .asciz "turn->right"
    .align 2
    TURN_RIGHT_OPCODE: .word 0x00000003
    
TAUNT_SYNTAX: .asciz "taunt"
    .align 2
    TAUNT_OPCODE: .word 0x00000004
    
LED_1_ON_SYNTAX: .asciz "LED[1]->ON"
    .align 2
    LED_1_ON_OPCODE: .word 0x00000005
    
LED_1_OFF_SYNTAX: .asciz "LED[1]->OFF"
    .align 2
    LED_1_OFF_OPCODE: .word 0x00000006
    
LED_2_ON_SYNTAX: .asciz "LED[2]->ON"
    .align 2
    LED_2_ON_OPCODE: .word 0x00000007
    
LED_2_OFF_SYNTAX: .asciz "LED[2]->OFF"
    .align 2
    LED_2_OFF_OPCODE: .word 0x00000008
    
ERROR_MESSAGE: .asciz "Fatal error on line "
    .align 2

# /////////////////////////////////////////////////
# /////////////////////////////////////////////////
# /////////  END OF OPCODES AND  //////////////////
# /////////        SYNTAX        //////////////////
# /////////////////////////////////////////////////
# /////////////////////////////////////////////////

.global main
.text

main:
    call start_over
    
    # Get the address where we have to put the opcodes.
    call get_end_of_file_address
    addi r2, r2, 0x4
    movia r8, OPCODE_START
    stw r2, 0(r8)
    movia r8, OPCODE_INDEX
    stw r2, 0(r8)

    call parse_file
    # If the file could not be parsed print an error.
    beq r2, r0, print_error
    call perform_instructions
    
done:
    br done
    
/**
 * Walks through the file, and encodes instructions.
 * It stops if there are any illegal instructions in the file.
 */
parse_file:
    addi sp, sp, -0x4
    stw ra, 0x0(sp)
    
    # Checks if we start the file legally.
    call get_next_line
    movia r4, START_SYNTAX
    call compare_tokens
    
    beq r2, r0, ERROR
    
    # Now we know that the file is legal.
    
    parse_loop:
        call get_next_token
        
        MOVE_INSTR:
            movia r4, MOVE_SYNTAX
            call compare_tokens
            beq r2, r0, SLEEP_INSTR
            ENCODE_MOVE:
                movia r4, MOVE_OPCODE
                call encode_instruction
                br parse_loop
                
        SLEEP_INSTR:
            movia r4, SLEEP_SYNTAX
            call compare_tokens
            beq r2, r0, TURN_LEFT_INSTR
            ENCODE_SLEEP:
                movia r4, SLEEP_OPCODE
                call encode_instruction
                br parse_loop
                
        TURN_LEFT_INSTR:
            movia r4, TURN_LEFT_SYNTAX
            call compare_tokens
            beq r2, r0, TURN_RIGHT_INSTR
            ENCODE_TURN_LEFT:
                movia r4, TURN_LEFT_OPCODE
                call encode_instruction
                br parse_loop
                
        TURN_RIGHT_INSTR:
            movia r4, TURN_RIGHT_SYNTAX
            call compare_tokens
            beq r2, r0, TAUNT_INSTR
            ENCODE_TURN_RIGHT:
                movia r4, TURN_RIGHT_OPCODE
                call encode_instruction
                br parse_loop
                
        TAUNT_INSTR:
            movia r4, TAUNT_SYNTAX
            call compare_tokens
            beq r2, r0, LED_1_ON_INSTR
            ENCODE_TAUNT:
                movia r4, TAUNT_OPCODE
                call encode_instruction
                br parse_loop
                
        LED_1_ON_INSTR:
            movia r4, LED_1_ON_SYNTAX
            call compare_tokens
            beq r2, r0, LED_1_OFF_INSTR
            ENCODE_LED_1_ON:
                movia r4, LED_1_ON_OPCODE
                call encode_instruction
                br parse_loop
                
        LED_1_OFF_INSTR:
            movia r4, LED_1_OFF_SYNTAX
            call compare_tokens
            beq r2, r0, LED_2_ON_INSTR
            ENCODE_LED_1_OFF:
                movia r4, LED_1_OFF_OPCODE
                call encode_instruction
                br parse_loop
                
        LED_2_ON_INSTR:
            movia r4, LED_2_ON_SYNTAX
            call compare_tokens
            beq r2, r0, LED_2_OFF_INSTR
            ENCODE_LED_2_ON:
                movia r4, LED_2_ON_OPCODE
                call encode_instruction
                br parse_loop
                
        LED_2_OFF_INSTR:
            movia r4, LED_2_OFF_SYNTAX
            call compare_tokens
            beq r2, r0, END_INSTR
            ENCODE_LED_2_OFF:
                movia r4, LED_2_OFF_OPCODE
                call encode_instruction
                br parse_loop
        
        END_INSTR:
            movia r4, END_SYNTAX
            call compare_tokens
            beq r2, r0, ERROR
            br DONE_PARSE
    
    ERROR:
        # The file could not be parsed.
        movi r2, 0x0
        br 1f
    
    DONE_PARSE:
        # The parse was a success! Good job, team!
        movi r2, 0x1
        
    1:
        ldw ra, 0x0(sp)
        addi sp, sp, 0x4
        ret

/**
 * Encodes an instruction to its corresponding op code.
 */
encode_instruction:
    addi sp, sp, -0x8
    stw ra, 0x0(sp)
    stw r8, 0x4(sp)
    
    # These opcodes expect an argument.
    movia r8, MOVE_OPCODE
    beq r4, r8, 0f
    movia r8, SLEEP_OPCODE
    beq r4, r8, 0f
    
    # Get the real opcode from the address.
    ldw r4, 0(r4)
    br 1f
    
    0:
        # Get the real opcode from the address.
        ldw r8, 0(r4)
        call get_argument
        slli r2, r2, 16
        or r4, r8, r2
    
    1:
        # Write the op code at the opcode index!
        call get_opcode_index
        stw r4, 0(r2)
        
        call increment_opcode_index
        
        ldw r8, 0x4(sp)
        ldw ra, 0x0(sp)
        addi sp, sp, 0x8
        ret

/**
 * Gets the parameter included in the token.
 * Example: move!128  returns 128
 *          move!-247 returns -247
 */
get_argument:
    addi sp, sp, -0x18
    stw ra,  0(sp)
    stw r8,  4(sp)
    stw r9,  8(sp)
    stw r10, 12(sp)
    stw r11, 16(sp)
    stw r12, 20(sp)
    
    # ! = 0x21
    movi r8, 0x21
    # 0 = 0x30
    movi r9, 0x30
    # 9 = 0x39
    movi r10, 0x39
    # - = 0x2D
    movi r11, 0x2D
    
    # Set r11 to zero. This will store the argument.
    mov r6, r0
    
    call get_token_end
    mov r5, r2
    addi r5, r5, -0x1
    
    extract_arg:
        mov r4, r5
        call get_char
        
        beq r2, r8, 5f
        beq r2, r11, 4f
        
        # If it's not a number then leave the function.
        blt r2, r9, THROW_ERROR
        bgt r2, r10, THROW_ERROR
        
        addi sp, sp, -0x4
        stw r2, 0(sp)
        
        call get_token_end
        sub r7, r2, r5
        
        ldw r2, 0(sp)
        addi sp, sp, 0x4
        
        movi r12, 0x1
        beq r7, r12, 0f
        movi r12, 0x2
        beq r7, r12, 1f
        movi r12, 0x3
        beq r7, r12, 2f
        br THROW_ERROR
        
        0:
            # Get the digit from the ASCII character.
            sub r2, r2, r9
            muli r2, r2, 0x1
            add r6, r6, r2
            br 3f
            
        1:
            # Get the digit from the ASCII character.
            sub r2, r2, r9
            muli r2, r2, 0xA
            add r6, r6, r2
            br 3f
            
        2:
            # Get the digit from the ASCII character.
            sub r2, r2, r9
            muli r2, r2, 0x64
            add r6, r6, r2
            br 3f
            
        3:
            addi r5, r5, -0x1
            br extract_arg

    4:
        muli r6, r6, -0x1
        addi r4, r4, -0x1
        call get_char
        # If it's not a ! then we throw an error.
        bne r2, r8, THROW_ERROR
    5:
        mov r2, r6
        ldw r12, 20(sp)
        ldw r11, 16(sp)
        ldw r10, 12(sp)
        ldw r9,  8(sp)
        ldw r8,  4(sp)
        ldw ra,  0(sp)
        addi sp, sp, 0x18
        ret
        
    THROW_ERROR:
        ldw r12, 20(sp)
        ldw r11, 16(sp)
        ldw r10, 12(sp)
        ldw r9,  8(sp)
        ldw r8,  4(sp)
        ldw ra,  0(sp)
        addi sp, sp, 0x18
        
        # THROW AN ERROR HERE!!!!
        call print_error

/**
 * Goes through the op codes and performs them, one by one.
 */
perform_instructions:
    addi sp, sp, -0xC
    stw ra, 0x0(sp)
    stw r8, 0x4(sp)
    stw r9, 0x8(sp)
    
    call get_opcode_index
    mov r5, r2
    
    call get_opcode_start
    mov r6, r2
    
    perform_loop:
        # In between each op code, add a small delay.
        #call KILL_ROBOT
        movi r4, 1
        #call ROBOT_DELAY
        
        bgt r6, r5, 0f
        
        MOVE_PERF:
            movia r8, MOVE_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            
            andi r9, r7, 0xFFFF
            bne r9, r8, 1f
            
            # Check if the argument is negative.
            blt r7, r0, NEG_MOVE
            
            # Get the argument from the opcode.
            srli r7, r7, 16
            andi r9, r7, 0xFFFF
            
            mov r4, r9
            
            call MOVE_FORWARDS
            br 1f
            
            NEG_MOVE:
                # If the argument is negative then make it positive using 
                # complex mathematical algorithms.
                srli r7, r7, 16
                orhi r7, r7, 0xFFFF
                muli r4, r7, -0x1
                call MOVE_BACKWARDS
            1: br SLEEP_PERF
        
        SLEEP_PERF:
            movia r8, SLEEP_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            
            andi r9, r7, 0xFFFF
            bne r9, r8, 1f
            
            # Check if the argument is negative.
            blt r7, r0, NEG_SLEEP
            
            # Get the argument from the opcode.
            srli r7, r7, 0x16
            andi r9, r7, 0xFFFF
            
            mov r4, r9
            
            call ROBOT_DELAY
            br 1f
            
            NEG_SLEEP:
                # If the argument is negative then make it positive using 
                # complex mathematical algorithms.
                srli r7, r7, 16
                orhi r7, r7, 0xFFFF
                muli r4, r7, -0x1
                call ROBOT_DELAY
            1: br TURN_LEFT_PERF
        
        TURN_LEFT_PERF:
            movia r8, TURN_LEFT_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            bne r7, r8, 1f
            call TURN_LEFT
            1: br TURN_RIGHT_PERF
        
        TURN_RIGHT_PERF:
            movia r8, TURN_RIGHT_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            bne r7, r8, 1f
            call TURN_RIGHT
            1: br TAUNT_PERF

        TAUNT_PERF:
            movia r8, TAUNT_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            bne r7, r8, 1f
            movi r4, 0x3
            call TAUNT
            1: br LED_1_ON_PERF
            
        LED_1_ON_PERF:
            movia r8, LED_1_ON_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            bne r7, r8, 1f
            
            addi sp, sp, -0x4
            stw r5, 0(sp)
            
            movi r4, 0x1
            movi r5, 0x3
            
            call LED_ON
            
            ldw r5, 0(sp)
            addi sp, sp, 0x4
            
            1: br LED_2_ON_PERF
            
        LED_2_ON_PERF:
            movia r8, LED_2_ON_OPCODE
            ldw r8, 0(r8)
            ldw r7, 0(r6)
            bne r7, r8, 1f
            
            addi sp, sp, -0x4
            stw r5, 0(sp)
            
            movi r4, 0x0
            movi r5, 0x3
            
            call LED_ON
            
            ldw r5, 0(sp)
            addi sp, sp, 0x4
            
            1: # nothing!
        
        addi r6, r6, 0x1
        
        br perform_loop
    
    0:
        movia r8, LED
        movi r9, 0b1111111111
        stwio r9, 0(r8)
        
        call KILL_ROBOT
        
        ldw r9, 0x8(sp)
        ldw r8, 0x4(sp)
        ldw ra, 0x0(sp)
        addi sp, sp, 0xC
        ret
    
/**
 * Gets a line from the file. This is done by repeatedly calling get_next_token
 * until the line index increments.
 */
get_next_line:
    addi sp, sp, -0x10
    stw ra,  0x0(sp)
    stw r8,  0x4(sp)
    stw r9,  0x8(sp)
    stw r10, 0xC(sp)
    
    call get_token_start
    mov r8, r2
    
    call get_line_index
    mov r9, r2
    
    # r10 holds the new line character.
    movi r10, 0x0D
    
    0:
        # Check if the token's end is a new line and leave the function
        # if it is.
        call get_token_end
        mov r4, r2
        call get_char
        beq r2, r10, 1f
    
        # Keep getting the next token.
        call get_next_token
        
        # If the line index changes during the loop, then leave it.
        call get_line_index
        bne r2, r9, 1f
        
        br 0b
    
    1:
        # Set token start to the beginning of the line.
        mov r4, r8
        call set_token_start
        
        ldw r10, 0xC(sp)
        ldw r9,  0x8(sp)
        ldw r8,  0x4(sp)
        ldw ra,  0x0(sp)
        addi sp, sp, 0x10
        ret
    
/**
 * Compares two tokens, given the start and end address of the first token.
 * Returns a 1 if the tokens match, and a 0 if they do not.
 */
compare_tokens:
    addi sp, sp, -0xC
    stw ra,  0(sp)
    stw r8,  4(sp)
    stw r9,  8(sp)
    
    # Get the pointers to the start and end addresses of the token.
    call get_token_start
    mov r5, r2
    call get_token_end
    mov r6, r2
    
    # ! = 0x21
    movi r8, 0x21
    # Space = 0x20
    movi r9, 0x20
    
    0:
        # Check if we reached the end of the token.
        beq r5, r6, 2f
    
        addi sp, sp, -0x4
        stw r4, 0(sp)
        
        # Get the next character.
        mov r4, r5
        call get_char
        
        ldw r4, 0(sp)
        addi sp, sp, 0x4
        
        # Get the character of the token being compared.
        ldb r7, 0(r4)
        
        # Check if we reached the end of the token being compared.
        # Check if we reached the end of the token being compared.
        beq r7, r0, 1f
        
        # Check if they're equal.
        cmpeq r2, r2, r7
        
        # If they're not, exit the loop.
        beq r2, r0, 2f
        
        # Increment the pointers.
        addi r4, r4, 0x1
        addi r5, r5, 0x1
        
        br 0b
    
    1:
        # Check if we reached the end of the token.
        beq r5, r6, 2f
        
        # Get the next character.
        mov r4, r5
        call get_char
        
        addi sp, sp, -0x4
        stw r2, 0(sp)
        
        # Check if the current character is a hashtag. This means that the rest of the line
        # is a comment and is irrelevant.
        cmpeq r2, r2, r8
        bne r2, r0, 3f
        
        ldw r2, 0(sp)
        addi sp, sp, 0x4
        
        # If the current character is a space then keep looping.
        cmpeq r2, r2, r9
        beq r2, r0, 2f
        
        # Increment the counter.
        addi r5, r5, 0x1
        br 1b
    
    2:
        ldw r9,  8(sp)
        ldw r8,  4(sp)
        ldw ra,  0(sp)
        addi sp, sp, 0xC
        ret
        
    3:
        addi sp, sp, 0x4
        br 2b
    
/**
 * Prints the token, given the start and end index of it.
 */
print_token:
    addi sp, sp, -0x8
    stw r8, 0x0(sp)
    stw ra, 0x4(sp)
    
    movia r8, TERMINAL
    
    call get_token_start
    mov r4, r2
    
    call get_token_end
    mov r5, r2
    
    print:
        beq r4, r5, 1f
        call get_char
        stwio r2, 0(r8)
        addi r4, r4, 0x1
        br print
    
    1:
        ldw ra, 0x4(sp)
        ldw r8, 0x0(sp)
        addi sp, sp, 0x8
        ret
    
/**
 * Gets a token from the file, given the index of the token.
 * This function modifies the pointers TOKEN_START and TOKEN_END.
 * It also increments TOKEN_INDEX if we need to.
 *
 * If there are no more tokens because we passed the end of the file,
 * then set TOKEN_START to be equal to TOKEN_END.
 */
get_next_token:
    addi sp, sp, -0x8
    stw r8, 0(sp)
    stw ra, 4(sp)
    
    # Set the start pointer to the end pointer.
    call get_token_end
    mov r4, r2
    call set_token_start
    
    # Space = 0x20
    movi r5, 0x20
    # New line = 0x0D
    movi r8, 0x0D
    
    # Set the start pointer to the first non space character.
    # r4 contains the start pointer.
    set_start_to_nonspace_char:
        call get_char
        
        # If the current character is a new line, then increment the line index.
        beq r2, r8, 0f
        # If the current character is not a space, then we can break out of the loop.
        bne r2, r5, 1f
        
        # Increment the loop counter.
        addi r4, r4, 0x1
        
        br set_start_to_nonspace_char
    0:
        # Increment r4 by 2, in order to skip the 0xD and 0xA.
        # 0xD and 0xA is the new line.
        addi r4, r4, 0x2
        br set_start_to_nonspace_char
    1:
        # End of loop
    
    # Push r2 on the stack to preserve it.
    addi sp, sp, -0x4
    stw r2, 0(sp)
    
    # Set the token start to the first nonspace.
    call set_token_start
    
    # Get r2 back from the stack.
    ldw r2, 0(sp)
    addi sp, sp, 0x4
    
    # If the start character is equal to the null character, then
    # set the start index to be equal to the end index.
    beq r2, r0, end_of_token_stream
    
    # Set the end pointer to the first space character.
    set_end_to_space_char:
        call get_char
        # Increment the loop counter.
        addi r4, r4, 0x1
        
        # If the current character is a new line, then break out of the loop.
        beq r2, r8, 0f
        # If the current character is a space, then break out of the loop.
        beq r2, r5, 1f
        
        br set_end_to_space_char
    0:
        # Push r2 on the stack to preserve it.
        addi sp, sp, -0x4
        stw r2, 0(sp)
        
        call increment_line_index
        
        # Get r2 back from the stack.
        ldw r2, 0(sp)
        addi sp, sp, 0x4
    1:
        addi r4, r4, -0x1
        # Set token end to the first space.
        call set_token_end
        
    1:
        call increment_token_index
        # Restore the registers from the stack.
        ldw ra, 4(sp)
        ldw r8, 0(sp)
        addi sp, sp, 0x8
        ret
        
    end_of_token_stream:
        movia r4, 0xFFFFFFFF
        call set_token_start
        call set_token_end
        br 1b
    
increment_opcode_index:
    movia r3, OPCODE_INDEX
    ldw r2, 0(r3)
    addi r2, r2, 0x4
    stw r2, 0(r3)
    ret
    
get_opcode_index:
    movia r3, OPCODE_INDEX
    ldw r2, 0(r3)
    ret
    
get_opcode_start:
    movia r3, OPCODE_START
    ldw r2, 0(r3)
    ret
    
increment_line_index:
    movia r3, LINE_INDEX
    ldw r2, 0(r3)
    addi r2, r2, 0x1
    stw r2, 0(r3)
    ret
    
get_line_index:
    movia r3, LINE_INDEX
    ldw r2, 0(r3)
    ret
    
increment_token_index:
    movia r3, TOKEN_INDEX
    ldw r2, 0(r3)
    addi r2, r2, 0x1
    stw r2, 0(r3)
    ret
    
get_token_index:
    movia r3, TOKEN_INDEX
    ldw r2, 0(r3)
    ret
    
get_token_start:
    movia r3, TOKEN_START
    ldw r2, 0(r3)
    ret
    
get_token_end:
    movia r3, TOKEN_END
    ldw r2, 0(r3)
    ret
    
set_token_start:
    movia r2, TOKEN_START
    stw r4, 0(r2)
    ret
    
set_token_end:
    movia r2, TOKEN_END
    stw r4, 0(r2)
    ret

/**
 * Resets everything. A brand new start!
 */ 
start_over:
    addi sp, sp, -0xC
    stw r8, 0(sp)
    stw r9, 4(sp)
    stw ra, 8(sp)
    
    movia r8, LED
    movi r9, 0b0000000000
    stwio r9, 0(r8)
    
    movi r4, 0x0
    call set_token_start
    call set_token_end
    
    movia r8, TOKEN_INDEX
    stw r4, 0(r8)
    
    movia r8, LINE_INDEX
    stw r4, 0(r8)
    
    ldw ra, 8(sp)
    ldw r9, 4(sp)
    ldw r8, 0(sp)
    addi sp, sp, 0xC
    ret
    
/**
 * Print an error. You dun goofed, son.
 */
print_error:
    movia r8, TERMINAL
    movia r9, ERROR_MESSAGE
    
    call get_line_index
    0:
        ldb r10, 0(r9)
        beq r10, r0, 1f
        stwio r10, 0(r8)
        addi r9, r9, 0x1
        br 0b
    1:
        movi r17, 10
        div r16, r2, r17
        mul r18, r16, r17
        sub r18, r2, r18
        
        addi r16, r16, 48
        addi r18, r18, 48
        
        movi r9, 0x30
        beq r16, r9, 0f
        stwio r16, 0(r8)
        0:
            stwio r18, 0(r8)
        movi r9, 0x2E
        stwio r9, 0(r8)
    br done
    ret