// palin_finder.s, provided with Lab1 in TDT4258 autumn 2024
.global _start

.equ LED_BASE_ADDR, 0xff200000
.equ UART_BASE_ADDR, 0xff201000

// Please keep the _start method and the input strings name ("input") as
// specified below
// For the rest, you are free to add and remove functions as you like,
// just make sure your code is clear, concise and well documented.

_start:
	// Here your execution starts
    ldr r0, =0
	bl check_input          // Get the length of the string, returned into r0
    bl check_palindrom      // Check if the string is a palindrom, r0 is 0 if false, 1 if true
    
    cmp r0, #0
    beq .+12
    bl is_palindrom
	b .+8
    bl is_no_palindrom

	b _exit

	
check_input:
	// You could use this symbol to check for your input length
	// you can assume that your input string is at least 2 characters 
	// long and ends with a null byte
	ldr r0, =0              // Zero out the r1 register; will contain the length
    ldr r1, =input          // The address of the input string

    // Will loop over the string data from the start (=input) and stop when it hits a null-byte, and return the 
    // length of the string stored in register 0

_check_input_loop:
    ldrb r2, [r1], #1           // Load char byte into r2, and increment the r1 pointer by 1
    cmp r2, #0                  // Check if null-byte
    beq _checked_input_length   // If null byte, return
    add r0, r0, #1              // Add 1 to the string length
    b _check_input_loop         // Continue loop

_checked_input_length:
    bx lr                       // Return, where r0 contains the string length
	
	
check_palindrom:
    // Checks if the input is a palindrom
    // r0:      length
    // r1:      i 
    // r2:      j
    // r3:      char_left    
    // r4:      char_right   
    // r5:      is_palindrome
    // r6:      &input

    push {r1, r2, r3, r4, r5, r6}

    ldr r6, =input
    // r0 already conains the length
    ldr r1, =input          // i = &input
    add r2, r0, r6          // j = &input + (length - 1)
    sub r2, r2, #1
    ldr r5, =1              // is_palindrom = true
    
_check_palindrom_loop:
    cmp r1, r2              // while (i < j)
    bge _check_palindrom_loop_finished

    ldrb r3, [r1]           // char_left = string[i]
    ldrb r4, [r2]           // char_right = string[j]

_check_palindrom_skip_space_left:
    cmp r3, #0x20           // char_left == " "
    bne .+16
    add r1, r1, #1          // i += 1
    ldrb r3, [r1]           // char_left = string[i]
    b _check_palindrom_skip_space_left

_check_palindrom_skip_space_right:
    cmp r4, #0x20           // char_right == " "
    bne .+16
    sub r2, r2, #1          // j -= 1
    ldrb r4, [r2]           // char_right = string[j]
    b _check_palindrom_skip_space_right

    cmp r1, r2              // if !(i < j)
    bge _check_palindrom_loop_finished

    add r1, r1, #1          // i += 1
    sub r2, r2, #1          // j -= 1

    // Convert uppercase to lower case
    // if (char_left >= 65 and char_left <= 90) -> char_left is lower case
    cmp r3, #0x41
    blt _check_palindrom_char_left_not_upper

    cmp r3, #0x5A
    bgt _check_palindrom_char_left_not_upper

    add r3, r3, #32          // upper -> lower; char + 32

_check_palindrom_char_left_not_upper:

    // if (char_right >= 65 and char_right <= 90) -> char_right is lower case
    cmp r4, #0x41
    blt _check_palindrom_char_right_not_upper

    cmp r4, #0x5A
    bgt _check_palindrom_char_right_not_upper

    add r4, r4, #32          // upper -> lower; char + 32

_check_palindrom_char_right_not_upper:

    // Wild card check
    cmp r3, #0x3f           // char_left == "?"
    beq _check_palindrom_any_wild_card

    cmp r4, #0x3f           // char_right == "?"
    beq _check_palindrom_any_wild_card

    b .+8
_check_palindrom_any_wild_card:
    b _check_palindrom_loop

    // Check if char_left == char_right
    cmp r3, r4
    beq .+12
    ldr r5, =0              // is_palindrom = false
    b _check_palindrom_loop_finished
    b _check_palindrom_loop

_check_palindrom_loop_finished:
    mov r0, r5              // is_palindrom -> r0
	
	pop {r1, r2, r3, r4, r5, r6}
    bx lr
	
is_palindrom:
	// Switch on only the 5 rightmost LEDs
	// Write 'Palindrom detected' to UART
    ldr r0, =palindrom_text    // Load the address of the palindrom text
    ldr r1, =UART_BASE_ADDR     // Load the uart base register

_is_palindrom_uart_loop:
    ldrb r2, [r0], #1           // Load one byte into the r1 register and increment r0 by 1
    cmp r2, #0
    beq _is_palindrom_uart_loop_finished
    str r2, [r1]
    b _is_palindrom_uart_loop
    
_is_palindrom_uart_loop_finished:
    // Switch on LEDs
    ldr r0, =LED_BASE_ADDR
    ldr r1, =0x1f          // Upper five bits of ten
    str r1, [r0]

    bx lr
	
is_no_palindrom:
	// Switch on only the 5 leftmost LEDs
	// Write 'Not a palindrom' to UART
    ldr r0, =not_palindrom_text    // Load the address of the not palindrom text
    ldr r1, =UART_BASE_ADDR         // Load the uart base register

_is_no_palindrom_uart_loop:
    ldrb r2, [r0], #1               // Load one byte into the r1 register and increment r0 by 1
    cmp r2, #0
    beq _is_no_palindrom_uart_loop_finished
    str r2, [r1]
    b _is_no_palindrom_uart_loop
    
_is_no_palindrom_uart_loop_finished:
    // Switch on LEDs
    ldr r0, =LED_BASE_ADDR
    ldr r1, =0x3e0          // Upper five bits of ten
    str r1, [r0]

    bx lr
	
_exit:
	// Branch here for exit
	b .
	
.data
.align
	// This is the input you are supposed to check for a palindrom
	// You can modify the string during development, however you
	// are not allowed to change the name 'input'!
	input: .asciz "Grav ned den varg"
   
    palindrom_text: .asciz "Palindrome detected"
    not_palindrom_text: .asciz "Not a palindrom"
.end

