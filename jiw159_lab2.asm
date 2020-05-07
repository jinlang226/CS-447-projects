# Jinlang Wang
# jiw159


.eqv INPUT_SIZE 3

# THIS MACRO WILL OVERWRITE WHATEVER IS IN THE a0 AND v0 REGISTERS.
.macro print_str %str
	.data
	print_str_message: .asciiz %str
	.text
	la	a0, print_str_message
	li	v0, 4
	syscall
.end_macro

.data
	display: .word 0
	input: .space INPUT_SIZE
.text

.globl main
main:
	print_str "Hello! Welcome!\n"
	
	
	_main_loop:
	
	lw a0, display #use lw to put its value into a0
	li v0, 1 #print display
	syscall
	
	print_str "\nOperation (=,+,-,*,/,c,q): "
	
	li a1, INPUT_SIZE  # inuput size

	la a0, input #put string read from user into input  location
			   	#give it the address of the input array
	li v0, 8
	syscall
	
	lb t0, input # temoerary, load one byte from input into registor t0
	
	beq t0, 'q', _quit
	beq t0, 'c', _clear
	beq t0, '=', _get_operand
	beq t0, '+', _get_operand
	beq t0, '-', _get_operand
	beq t0, '*', _get_operand
	beq t0, '/', _get_operand

	print_str "Huh?\n"
   	j _main_loop
	
	_quit:
		li v0, 10
   		syscall
   		
   	_clear:
   		li t0, 0
   		sw t0, display
   		j _main_loop
   		
   	_get_operand:
   		
   		# get user value as integer (syscall 5)
   		print_str "Value: "
   		li v0, 5
   		syscall
   		
   		# v0 = the integer input by the user
		
		# now do the requested operation
		# v0 is the second operand
		# t0 is the operator
		beq t0, '+', _add
		beq t0, '-', _sub
		beq t0, '*', _multiply
		beq t0, '/', _divide
		beq t0, '=', _equal
		print_str "Huh?\n"
   		j _main_loop
		
		_add:
			lw t1, display
			add t2, v0, t1
   			sw t2, display
   			j _main_loop
   			
   		_sub:
   			lw t1, display
			sub t2, t1, v0
			sw t2, display
   			j _main_loop
   		
   		_multiply:
   			lw t1, display
			mul t2, t1, v0
			sw t2, display
			j _main_loop
   		
   		_divide:
   			lw t1, display
			beq v0, 0, _zero
			div t2, t1, v0
			sw t2, display
			j _main_loop
			
			_zero:
				print_str "Attempting to divide by 0! \n"
				j _main_loop
   	
		_equal:
   			sw v0, display
   			j _main_loop
		
   		
 		j _main_loop
