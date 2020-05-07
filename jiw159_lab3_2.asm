# Jinlang Wang
# jiw159

.eqv DISPLAY_CTRL  0xFFFF0000
.eqv DISPLAY_KEYS  0xFFFF0004
.eqv DISPLAY_BASE  0xFFFF0008
.eqv COLOR_BLACK   0
.eqv COLOR_RED     1
.eqv COLOR_ORANGE  2
.eqv COLOR_YELLOW  3
.eqv COLOR_GREEN   4
.eqv COLOR_BLUE    5
.eqv COLOR_MAGENTA 6
.eqv COLOR_WHITE   7



.globl main
main:
	#clear the display whenever we run our program
	sw zero, DISPLAY_CTRL

	#prove that we can draw something on the display
	li t0, 0x06050401
	sw t0, DISPLAY_BASE
	sw zero, DISPLAY_CTRL


	#call the function
	jal draw_horiz_line
	sw zero, DISPLAY_CTRL

	#call the function
	jal draw_vert_line
	sw zero, DISPLAY_CTRL

	#call the function
	li	a0, 30 # x1
	li	a1, 15 # y1
	li	a2, 50 # x2
	li	a3, 25 # y2
	jal draw_rectangle
	sw zero, DISPLAY_CTRL
	
	# exit
	li v0, 10
	syscall


	 # -----------------------------------------

	
	
	#void draw_horiz_line() {
   	# for(int i = 0; i < 10; i++)
    #    DISPLAY_BASE[i + 10] = COLOR_BLUE;
	draw_horiz_line:
		#for loop
		#msg1: .asciiz"A program in MIPS to test for loop. "

		li t0, 10

		for_loop:
			blt t0, 1, _exit

			li t1, DISPLAY_BASE

			add t1, t1, t0
			add t1, t1, 10

			li t2, COLOR_BLUE

			# the (t_) register holds the calculated address
			sb t2, (t1)

			sub t0, t0, 1

			j for_loop
	  
	   	_exit:
	    	jr ra

	 # -----------------------------------------

	draw_vert_line:
		li t1, DISPLAY_BASE  #a registor holding memory adress
		add t1, t1, 20   #p = DISPLAY_BASE + 20

		li t0, 0 # t2 = 0

		for_loop_second:
			# store byte into address in p
			li t2, COLOR_ORANGE
			sb t2, (t1)   	#store byte, take byte form t2 and writes memory adress t1
						
							#la 	storing memory adress into register

			#la t3, t1
			#mul t4, 4, t0
			#add t3, t4, t3

			add t1, t1, 64



			add t0, t0, 1
			bgt t0, 15, _exit_sec

				j for_loop_second
		
		_exit_sec:
	 		jr ra


	 #---------------------------------------------
draw_rectangle:

	 	move t0, a0   #x1
	 	move t2, a2   #x2
	 	
	 	li t5,COLOR_WHITE

	 	nested_for_loop_outer:

	 		#inner for loop 
	 		#-----------------------------------

	 	 	move t1, a1   #y1
	 		move t3, a3   #y2
	 	
	 		nest_for_loop_inner:
	 			
	 			li  t6, DISPLAY_BASE # DISPLAY_BASE
	 			mul t7, t1, 64      # y * 64
	 			add t6, t6, t7      # DISPLAY_BASE + y * 64
	 			add t6, t6, t0      # DISPLAY_BASE + y * 64 + x
	 			sb  t5, (t6)

				add t1, t1, 1				
				blt t1, t3, nest_for_loop_inner
	 		
	 		#-----------------------------------
	 		add t0, t0, 1
	 		blt t0, t2, nested_for_loop_outer
	jr ra











