#jiw159
#Jinlang Wang

.include "lab6_include.asm"

.eqv GAME_TICK_MS 16    # how long to wait for each frame.

.eqv GRAVITY     0x000C # (24.8) 0.046875 (I just played with the number)
.eqv RESTITUTION 0x00C0 # (24.8) 0.75 (this is fun to play with...)

.eqv THRUST_X    0x000C # (24.8) 0.046875
.eqv THRUST_Y    0x001C # (24.8) 0.109375 (have to overcome gravity)
.eqv XVEL_MIN   -0x0300 # (24.8) -3.0
.eqv XVEL_MAX    0x0300 # (24.8) +3.0
.eqv YVEL_MIN   -0x0300 # (24.8) -3.0
.eqv YVEL_MAX    0x0300 # (24.8) +3.0
.eqv X_MIN       0      # (24.8) 0.0
.eqv X_MAX       0x3B00 # (24.8) 59.0
.eqv Y_MIN       0      # (24.8) 0.0
.eqv Y_MAX       0x3B00 # (24.8) 59.0

# The struct member variable offsets, to be used with lw/sw.
.eqv Ball_x      0      # (24.8) x position [X_MIN .. X_MAX]
.eqv Ball_y      4      # (24.8) y position [Y_MIN .. Y_MAX]
.eqv Ball_vx     8      # (24.8) x velocity [XVEL_MIN .. XVEL_MAX]
.eqv Ball_vy     12     # (24.8) y velocity [YVEL_MIN .. YVEL_MAX]

.eqv Ball_sizeof 16     # size of one Ball instance.

.data
prev_input:   .word 0 # will be used for detecting the frame a key is pressed.
num_balls:    .word 5 # how many balls are in the array. change this if you want.
current_ball: .word 0 # which ball is being controlled by the user.

# the array of Ball instances! each one is one 4 words.
balls:
#        x      y      vx      vy
.word 0x1D00 0x1D00  0x0000  0x0000
.word 0x2400 0x1D00  0x0100 -0x00C0
.word 0x2000 0x1000  0x0200 -0x0080
.word 0x0800 0x1800 -0x0100 -0x0180
.word 0x1B00 0x2500 -0x0200 -0x0200

.text

# -------------------------------------------------------------------------------------------------

.globl main
main:

_main_loop:
	# check for input,
	jal check_input

	# update everything,
	jal ball_motion
	jal ball_collision

	# then draw everything.
	jal draw_balls
	jal display_update_and_clear

	# wait for next frame and loop.
	li  a0, GAME_TICK_MS
	jal wait_for_next_frame
	j   _main_loop

# -------------------------------------------------------------------------------------------------
# clamp(val: a0, lo: a1, hi: a2)
#   returns val clamped to range [lo, hi] (INCLUSIVE both ends)
clamp:
enter
	# if(value < lo) return lo
	# else if(value > hi) return hi
	# else return value
	move v0, a0
	bge  a0, a1, _clamp_check_hi
	move v0, a1
	j    _clamp_exit
_clamp_check_hi:
	ble  a0, a2, _clamp_exit
	move v0, a2
_clamp_exit:
leave

# -------------------------------------------------------------------------------------------------

check_input:
enter
	jal  input_get_keys
	
	#balls[current_ball]
	lw t1, current_ball
	la t2, balls
	mul t1, t1, Ball_sizeof
	add t2, t2, t1
	# t2 is your pointer to the current ball.

	and t0, v0, KEY_U
	beq t0, 0, _not_U

	lw t4, Ball_vy(t2) # t4 = t2.vy
	sub t4, t4, THRUST_Y
	sw t4, Ball_vy(t2)

	_not_U:
		and t0, v0, KEY_R
		beq t0, 0, _not_R
		#add THRUST_X to the ball’s X velocity (Ball_vx).
		lw t4, Ball_vx(t2)
		add t4, t4, THRUST_X
		sw t4, Ball_vx(t2)

	_not_R:
		and t0, v0, KEY_L
		beq t0, 0, _not_L

		lw t4, Ball_vx(t2)
		sub t4, t4, THRUST_X
		sw t4, Ball_vx(t2)


	_not_L:

	# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< here is where you'll add more.
	
		# if((~prev_input & input) & KEY_B)
		# (so, when B was NOT pressed last frame AND it was pressed this frame...)
		lw   t0, prev_input
		not  t0, t0
		and  t0, t0, v0
		and  t0, t0, KEY_B
		beqz t0, _check_input_exit

			# current_ball = (current_ball + 1) % num_balls
			lw  t0, current_ball
			lw  t1, num_balls
			add t0, t0, 1
			rem t0, t0, t1
			sw  t0, current_ball

_check_input_exit:
	# prev_input = input
	sw  v0, prev_input
leave

# -------------------------------------------------------------------------------------------------

ball_motion:
enter s0, s1
		
		#lw t1, current_ball
		li s0, 0

		_for_loop_motion:
			#balls[current_ball]
			

			la t2, balls
			mul t1, s0, Ball_sizeof
			add s1, t2, t1
			# t2 is your pointer to the current ball.
			lw t1, Ball_vy(s1)
			add t1, t1, GRAVITY
			sw t1, Ball_vy(s1)

			# clamp(val: a0, lo: a1, hi: a2)

			lw a0, Ball_vx(s1)
			li a1, XVEL_MIN
			li a2, XVEL_MAX
			jal clamp

			#ball.x += ball.vx
			lw t3, Ball_x(s1)
			lw t4, Ball_vx(s1)
			add t3, t3, v0
			sw t3, Ball_x(s1)


			lw a0, Ball_vy(s1)
			li a1, YVEL_MIN
			li a2, YVEL_MAX
			jal clamp


			lw t3, Ball_y(s1)
			add t3, t3, v0
			sw t3, Ball_y(s1)


			lw t5, num_balls

			add s0, s0, 1
			blt s0, t5, _for_loop_motion

	
	 
leave s0, s1

# -------------------------------------------------------------------------------------------------

ball_collision:
enter s0, s1, s2
	
	#counter
	li s0, 0

	_for_loop:
		#lw t1, current_ball
		la t2, balls
		mul t1, s0, Ball_sizeof
		add s1, t2, t1

		li t2, X_MIN
		li t3, X_MAX

		#if( <= X_MIN or >= X_MAX)
		#var <= X_MIN, block A
		#var < X_MAX, block B
		#Ball_x
		lw t4, Ball_x(s1)
		ble t4, t2, _call_clamp
		blt t4, t3, _block_B

		_call_clamp:
			# clamp(val: a0, lo: a1, hi: a2)

			lw a0, Ball_x(s1)
			
			li a1, X_MIN
			li a2, X_MAX
			jal clamp

			sw v0, Ball_x(s1)

			lw t5, Ball_vx(s1)
			neg t6, t5
			li t5, RESTITUTION
			mul t6, t6, t5
			sra t6, t6, 8
			sw t6, Ball_vx(s1)
			

		_block_B:

			lw t4, Ball_y(s1)
			
			ble t4, t2, _call_clamp_two
			blt t4, t3, _block_C

		_call_clamp_two:

			lw a0, Ball_y(s1)
			li a1, Y_MIN
			li a2, Y_MAX
			jal clamp

			sw v0, Ball_y(s1)


			lw t5, Ball_vy(s1)
			neg t6, t5
			li t5, RESTITUTION
			mul t6, t6, t5
			sra t6, t6, 8
			sw t6, Ball_vy(s1)
			


		_block_C:
			
			add s0, s0, 1
			lw s2, num_balls
			blt s0, s2, _for_loop
			leave s0, s1, s2

# -------------------------------------------------------------------------------------------------

.data
ball_pattern:
	.byte -1 7 7 7 -1
	.byte 7 7 7 7 7
	.byte 7 7 7 7 7
	.byte 7 7 7 7 7
	.byte -1 7 7 7 -1

ball_pattern_red:
	.byte -1 1 1 1 -1
	.byte 1 1 1 1 1
	.byte 1 1 1 1 1
	.byte 1 1 1 1 1
	.byte -1 1 1 1 -1

.text
draw_balls:
enter s0, s1
	la  s0, balls # s0 = walking pointer
	li  s1, 0     # s1 = i

_draw_balls_loop:
		# get integer part of ball.x and ball.y
		lw  a0, Ball_x(s0)
		sra a0, a0, 8
		lw  a1, Ball_y(s0)
		sra a1, a1, 8

		# a2 = (i == current_ball) ? ball_pattern_red : ball_pattern
		la  a2, ball_pattern
		lw  t0, current_ball
		bne s1, t0, _draw_balls_white
			la  a2, ball_pattern_red
	_draw_balls_white:
		# draw it!
		jal display_blit_5x5_trans

	add  s0, s0, Ball_sizeof # walk the pointer...
	add  s1, s1, 1           # i++...
	lw   t0, num_balls       # and loop while i < num_balls.
	blt  s1, t0, _draw_balls_loop
leave s0, s1

