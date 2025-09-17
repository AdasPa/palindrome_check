// palinfinder.s, provided with Lab1 in TDT4258 autumn 2025
.global _start


// Please keep the _start method and the input strings name ("input") as
// specified below
// For the rest, you are free to add and remove functions as you like,
// just make sure your code is clear, concise and well documented.

_start:
	bl transform_input
	// r0 = =input_no_spaces length; =input turned into =input_no_spaces, lowercased, unspaced
	bl check_palindrome 
	// r0 == 0 -> not a palindrome; r0 == 1 -> is a palindrome
	
	cmp r0, #1
	beq palindrome_detected
	
	cmp r0, #0
	beq palindrome_not_detected
	
	b _exit
	
	
	palindrome_detected:
		bl is_palindrome
		b _exit
		
	palindrome_not_detected:
		bl is_not_palindrome
		b _exit

	
transform_input: 
	// deletes spaces from =input into =input_no_spaces
	// =input_no_spaces string length returned in r0
	mov r0, #0
	ldr r1, =input
	ldr r2, =input_no_spaces
	
	transform_loop:
		ldrb r3, [r1], #1
		cmp r3, #0
		beq transformation_done
		cmp r3, #' '
		beq transform_loop  //if space, don't copy to buffer
		
		cmp r3, #'A'
		blt copy_char
		cmp r3, #'Z'
		bgt copy_char
		
		add r3, r3, #32 // transform uppercase into lowercase
		
		copy_char:
		strb r3, [r2], #1 //copy char to buffer
		add r0, r0, #1 // increase real length
		b transform_loop
	
	transformation_done:
		bx lr
	
	
check_palindrome: 
	// takes =input_no_spaces length in r0, 
	// returns in r0 -> 0 if not a palindrome, 1 if a palindrome

	push {r4 - r5}
	ldr r5, =input_no_spaces
	
	mov r1, #0 // offset of first char
	sub r2, r0 , #1 // string length-1 into r1 -> offset of lats char
	mov r0, #1 // bollean, when returned -> 1 if palindrome detected, 0 if not
	
	
	
	check_palindrome_loop:
		ldrb r3, [r5, r1]
		add r1, r1, #1
		
		ldrb r4, [r5, r2]
		sub r2, r2, #1
		
		cmp r3, r4
		bne end_check_not_palindrome // returns 0 if chars differ
		
		cmp r1, r2
		bgt check_done // ends after crossing middle of string
		
		b check_palindrome_loop
		
	end_check_not_palindrome:
		mov r0, #0
		b check_done
	
	check_done:
		pop {r4 - r5}
		bx lr
	
is_palindrome:
	push {lr}
	
	// Switch on only the 5 rightmost LEDs
	mov r0, #0x0000001f
	bl write_led
	
	// Write 'Palindrome detected' to UART
	ldr r0, =detected_message
	bl print_string
	
	pop {lr}
	bx lr
	
is_not_palindrome:
	push {lr}
	
	// Switch on only the 5 leftmost LEDs
	mov r0, #0x000003e0
	bl write_led
	
	// Write 'Not a palindrome' to UART
	ldr r0, =not_detected_message
	bl print_string
	
	pop {lr}
	bx lr
	
write_led: // binary representation of r0 value to LEDs
	ldr r1, =0xff200000    // LEDs address
    str r0, [r1]     // write r0 to LEDs
	bx lr
	
	
print_string: // address of string in r0
	push {r4, lr}
	mov r4, r0
	print_loop:
	ldrb r0, [r4], #1
	cmp r0, #0          // sprawdź, czy to null (koniec stringa)
	beq string_printed  // jeśli tak -> koniec
	bl PUT_JTAG         // wypisz znak
	b print_loop        // pętla dalej

	string_printed:
	pop {r4, lr}
	bx lr

PUT_JTAG: // input param char in R0, assumes call by BL
	LDR R1, =0xFF201000 // JTAG UART base address, assigned to R1
	LDR R2, [R1, #4] // read the JTAG UART control register into R2
	LDR R3, =0xFFFF0000 // mask, top 16 bits of control register holds write-space
	ANDS R2, R2, R3 // Logical AND, R2 becomes zero if no space available, sets status register
	BEQ PUT_JTAG // if no space, try again (Busy-waiting loop)
	STR R0, [R1] // send the character by writing to UART data register
	BX LR  // return from function using the Link Register LR
	
	
_exit:
	// Branch here for exit
	b .
	
.data
.align
	// This is the input you are supposed to check for a palindrom
	// You can modify the string during development, however you
	// are not allowed to change the name 'input'!
	test: .asciz "Test123"
	input: .asciz "Grav ned den varg"
	//input: .asciz "AdAM pZZZac     ek"
	input_no_spaces: .zero 64
	detected_message: .asciz "Palindrome detected\n"
	not_detected_message: .asciz "Not a palindrome\n"
.end
