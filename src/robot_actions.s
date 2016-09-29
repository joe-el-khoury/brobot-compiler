.equ JP1,   0xFF200060
.equ TIMER, 0xFF202000

# The unit of time our robot will use.
.equ TIME_UNIT, 10000000

/**
 * Kills the robot.
 */
KILL_ROBOT:
	addi sp, sp, -0x8
	stw r8, 0(sp)
	stw r9, 4(sp)
	
	movia r8, JP1
	movia r9, 0xFFFFFFFF
	stwio r9, 0(r8)
	
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0x8
	ret

/**
 * Puts the robot to sleep for a certain amount of time.
 */
ROBOT_DELAY: # ROBOT_DELAY(int time)
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw r10, 8(sp)
	
	movia r8, TIMER
	
	# Set the timeout bit to 0.
	stwio r0, 0(r8)
	
	movia r10, TIME_UNIT
	
	# Multiply the parameter by the time unit.
	mul r4, r4, r10
	
	# Just so we don't lose the value of r5
	mov r9, r4
	
	# Extract bits 0 - 15 of r5.
	andi r9, r9, 0xFFFF
	stwio r9, 8(r8)
	
	# Just so we don't lose the value of r5.
	mov r9, r4
	
	# Extract bits 16 - 31 of r5.
	srli r9, r9, 16
	andi r9, r9, 0xFFFF
	stwio r9, 12(r8)
	
	# Start the timer.
	movui r9, 0b0100
	stwio r9, 4(r8)
	
# Keep polling the clock until the delay is done.
ROBOT_DELAY_POLL:
	ldwio r9, 0(r8)
	# Get the timeout bit.
	andi r9, r9, 0x1
	beq r9, r0, ROBOT_DELAY_POLL
	
	# End of function.
	ldw r10, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret

MOVE_FORWARDS: # MOVE_FORWARDS(int time)
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw ra, 8(sp)
	
	/* SET ALL MOTORS TO OUTPUT */
	movia r8, JP1
	movia r9, 0x07F557FF
	stwio r9, 4(r8)
	
	/**
	 * Move motors 0 and 1 forwards.
	 */
	movia r9, 0xFFFFFFF0
	stwio r9, 0(r8)
	
	call ROBOT_DELAY
	
	ldw ra, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret
	
MOVE_BACKWARDS: # MOVE_BACKWARDS(int time)
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw ra, 8(sp)
	
	/* Set all motors to output */
	movia r8, JP1
	movia r9, 0x07F557FF
	stwio r9, 4(r8)
	
	/**
	 * Move motors 0 and 1 backwards.
	 */
	movia r9, 0xFFFFFFFA
	stwio r9, 0(r8)
	
	call ROBOT_DELAY
	
	ldw ra, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret
	
TURN_RIGHT: # TURN_RIGHT()
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw ra, 8(sp)
	
	/* Set all motors to output */
	movia r8, JP1
	movia r9, 0x07F557FF
	stwio r9, 4(r8)
	
	/**
	 * Turn motor 0 backwards and motor 1 forwards.
	 */
	movia r9, 0xFFFFFFF8
	stwio r9, 0(r8)
	
	movi r4, 1
	call ROBOT_DELAY
	
	ldw ra, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret
	
TURN_LEFT: # TURN_LEFT()
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw ra, 8(sp)
	
	/* Set all motors to output */
	movia r8, JP1
	movia r9, 0x07F557FF
	stwio r9, 4(r8)
	
	/**
	 * Turn motor 0 forwards and motor 1 backwards.
	 */
	movia r9, 0xFFFFFFF2
	stwio r9, 0(r8)
	
	movi r4, 1
	call ROBOT_DELAY
	
	ldw ra, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret
	
TAUNT: # TAUNT(int time)
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw ra, 8(sp)
	
	/* Set all motors to output */
	movia r8, JP1
	movia r9, 0x07F557FF
	stwio r9, 4(r8)
	
	/**
	 * Set motor 2 to on.
	 */
	movia r9, 0xFFFFFFCF
	stwio r9, 0(r8)
	
	call ROBOT_DELAY
		
	ldw ra, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret
	
LED_ON: # LED_ON(bool lr, int time)
	addi sp, sp, -0xC
	stw r8, 0(sp)
	stw r9, 4(sp)
	stw ra, 8(sp)
	
	/* Set all motors to output */
	movia r8, JP1
	movia r9, 0x07F557FF
	stwio r9, 4(r8)
	
	/**
	 * If r4 is 1, we need to turn on the left LED.
	 * If r4 is 0, we need to turn on the right LED.
	 */
	beq r4, r0, 0f
1:
	# Turn on Motor 3
	movia r9, 0xFFFFFFBF
	stwio r9, 0(r8)
	br DONE_LED
0:
	# Turn on Motor 4
	movia r9, 0xFFFFF2FF
	stwio r9, 0(r8)
DONE_LED:
	mov r4, r5
	call ROBOT_DELAY
	
	ldw ra, 8(sp)
	ldw r9, 4(sp)
	ldw r8, 0(sp)
	addi sp, sp, 0xC
	ret
	