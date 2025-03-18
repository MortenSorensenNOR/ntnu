.globl main

.data

n_rows: .quad 12
n_cols: .quad 12
space_for_numbers: .quad 4

space: .string " "
newline: .string "\n"

integer_slot: .string "%ld"

.text
/*
    Main "function" - program starts here!

    It works as a regular function, but is called at when running the program instead of by other code.

    We allow main to use the callee-save/"global" registers:
    %rbx, %rbp, and %r12-r15

    Our program should probably use loops to iterate through the table.
    Thus, we will probably use variables/counters tracking the current loop.
    It might also be a good idea to use another variable to store the modulo result.

    How you handle this is up to you,
    but you may assign certain registers that *always* represent certain variables.
    E.g.:
        r12 = i
        r13 = j
        r14 = modulo_result
        etc...

    Note that we do have a finite amount of "global" registers.
    We use these as we *know* they cannot (or at least *should not*) be overwritten by other functions.

    We recommend that you keep a AT&T Assembly cheat sheet like this nearby:
    https://cs.brown.edu/courses/cs033/docs/guides/x64_cheatsheet.pdf
*/
main:
    pushq %rbp
    movq %rsp, %rbp

    # TODO 2.A
    # Use a register to track what row we are at
    # (Recommended) Use a global register
    # (Recommended) Use 1-indexing / start at 1
    movq $1, %r12

    # TODO 2.B
    # Prepare the outer loop
    # OUTER LOOP START
    main_outer_loop_start:

        # TODO 2.C
        # Reset the register tracking what column we are at
        # (Recommended) Use a global register
        # (Recommended) Use 1-indexing / start at 1
        movq $1, %r13

        # TODO 2.D
        # Check if we are done with all rows (and thus the entire table),
        # and should break the loop
        # If so, move out of the loop
        # (Hint) The number of rows is stored in `n_rows` - how can we read this value?
        movq n_rows(%rip), %r8
        cmp %r8, %r12
        jg main_outer_loop_end

        # If not, we should repeat the inner loop

        # TODO 2.E
        # Prepare the inner loop
        # INNER LOOP START
        main_inner_loop_start:

            # TODO 2.F
            # Check if we are done with all e.g. columns and should break the loop
            # If so, move out of the inner loop
            # (Hint) See 2.D, and do respective changes
            movq n_cols(%rip), %r9
            cmp %r9, %r13
            jg main_inner_loop_end

            # TODO 2.G
            # *Ready special registers* for our modulo check
            # Put correct values in all registers
            # (Hint) Set %rdx to 0
            # (Hint) We want to calulate M[row, col] = row % col

            movq $0, %rdx
            movq %r12, %rax
            movq %r13, %rcx

            # TODO 2.H
            # Perform the modulo math
            # (Optional, Recommended) Afterwards, move the result somewhere safe so the next functions won't accidently alter it
            # (Hint) In what register will the result appear?

            divq %rcx
            movq %rdx, %r14

            # TODO 2.I
            # Get the number of digits of the result
            # (Hint) You shouldn't have to write a lot of code for this one (unless you want to)

            movq %r14, %rdi
            pushq %r8
            pushq %r9
            pushq %r10
            call get_digits
            popq %r10
            popq %r9
            popq %r8

            movq %rax, %r15

            # TODO 2.J
            # Calculate the amount of padding for the number
            # (Hint) If we allocate 3 spaces for every number, then e.g. "5" should have 2 spaces of padding
            # (Hint) You may use `subq S, D` here: "D = D - S"
            
            movq space_for_numbers(%rip), %r8
            subq %r15, %r8

            # TODO 2.K
            # Print the padded number using `print_padded_number` using the modulo result AND number of padding spaces
            # Afterwards, print an additional space to sepeate this number from the next

            movq %r14, %rdi
            movq %r8, %rsi
            pushq %r8
            pushq %r9
            pushq %r10
            call print_padded_number
            popq %r10
            popq %r9
            popq %r8

            # We are now done with a single number

            # TODO 2.L
            # Increment the inner loop count, and repeat the loop

            inc %r13
            jmp main_inner_loop_start

        # INNER LOOP END
        main_inner_loop_end:

        # TODO 2.M
        # First, print a newline ('\n') indicating that we are done with a row
        # Then, increment the outer loop counter
        # Finally, repeat the outer loop

        leaq newline(%rip), %rdi
        pushq %r8
        pushq %r9
        pushq %r10
        call safe_printf
        popq %r10
        popq %r9
        popq %r8

        inc %r12
        jmp main_outer_loop_start

    # OUTER LOOP END
    main_outer_loop_end:
        # After completing the outer loop we should be done with the table
    
    movq $0, %rax
    leave
    ret


/*
    Functions are defined here.
    These will be executed when we call them using the `call` keyword.
*/

/*
    Function: print_padded_number

    Prepends PADDING spaces before NUMBER, and prints it to output

    Args:
        (%rdi) NUMBER (quad)  - Number to print
        (%rsi) PADDING (quad) - Number of padding spaces before number 
*/
print_padded_number:
    pushq %rbp
    movq %rsp, %rbp

    # TODO 1.A:
    # (Optional, recommended) 
    # Move the arguments NUMBER and PADDING to two other register to better keep track of them.
    movq %rdi, %r8  # number
    movq %rsi, %r9  # padding

    # TODO 1.B
    # Keep track of the amount of spaces printet for this number
    # Assign count to a register (starting at 0)
    movq $0, %r10

    # TODO 1.C
    # Create a loop printing PADDING spaces
    # Print Space Loop START
    padding_print_loop_start:
        # TODO 1.C.1
        # Check if we are done printing spaces using the count from 1.B
        # If we are done, jump out of the loop
        cmp %r9, %r10
        jge padding_print_loop_end
        
    
        # TODO 1.C.2
        # Print a single space
        # You are free to use the `print_space` function here, or do it your own way
        # HOWEVER, note that if you call ANY function, you should PUSH all caller-save registers that you currently use
        # When done, POP the values in reverse order to their respective registers
        # (Hint) If using `print_space`, use `pushq` *before* the function call and `popq` afterwards
        pushq %r8
        pushq %r9
        pushq %r10
        call print_space
        popq %r10
        popq %r9
        popq %r8

        # TODO 1.C.3
        # Incement the "number of spaces printed" counter
        # and continue the loop
        inc %r10
        jmp padding_print_loop_start

    # Print Space Loop END
        # TODO 1.C.1*
        # Jump here from 1.C.1
    padding_print_loop_end:

    # TODO 1.D
    # We are now done printing all the spaces
    # Print the number
    # (Hint) You may use the `integer_slot` here
    # (Hint) You may use the `safe_printf` function here
    pushq %r8
    pushq %r9
    pushq %r10
    leaq integer_slot(%rip), %rdi
    movq %r8, %rsi
    call safe_printf
    popq %r10
    popq %r9
    popq %r8

    # Done
    leave
    ret

/*
    Function: print_space

    Simply prints a space.
*/
print_space:
    pushq %rbp
    movq %rsp, %rbp

    leaq space(%rip), %rdi
    call safe_printf

    leave
    ret

/*
    Function: get_digits

    Calculates the digits of NUMBER, and returns it as N_DIGITS

    Args:
        (%rdi) NUMBER (quad)  - Number to print

    Returns:
        (%rax) N_DIGITS (quad) - Number of digits in NUMBER 
*/
get_digits:
    pushq %rbp
    movq %rsp, %rbp

    movq $1, %r11           # r11 = counter = 1

    # Ready argument for division
    movq %rdi, %rax
    
gd_loop:
    # Divide NUMBER by 10
    movq $10, %r8

    # Ensure that %rdx = 0; divq will use it as upper bits...
    movq $0, %rdx
    # %rax = %rax / 10
    divq %r8

    # If quotient == 0, exit the loop
    movq $0, %r8

    cmp %rax, %r8
    je gd_loop_end

    # Else, increment digit counter, and repeat
    # Note, result from division is already in the correct register
    inc %r11
    jmp gd_loop

gd_loop_end:
    # Our counter contains number of digits; move it to return register %rax
    movq %r11, %rax

    leave
    ret


/*
    Function: safe_printf

    Prints to output - like printf - but makes sure that stack is alligned before calling printf
    Convinience function that avoids a lot of crashes caused by printf

    Args:
        (all) any value, but always a string pointer in (%rdi)
*/
safe_printf:
	pushq %rbp
	movq %rsp, %rbp

	andq $-16, %rsp
	call printf
    
	leave
	ret

// Workaround for macOS prefixing symbols with _
#ifdef __APPLE__
    .set printf, _printf
    .set putchar, _putchar
    .set _main, main
    .global _main
#endif
