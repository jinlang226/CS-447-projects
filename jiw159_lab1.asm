# Jinlang Wang jiw159

.data
hello_message: .asciiz "Hello, world!"
.text

.globl main
main:
	li   t0, 1
	li   t1, 2
	li   t2, 3
	

	move a0, t0
	move v0, t1
	move t2, zero

	li   a0, 97
	li   v0, 1
	syscall
	
	li   a0, 97
    li   v0, 11
    syscall
	#Prints ASCII character corresponding to contents of low-order byte.

	la   a0, hello_message
	li   v0, 4
	syscall

	li   v0, 10
	syscall
