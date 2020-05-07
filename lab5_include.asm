
# MMIO Registers
.eqv DISPLAY_CTRL 0xFFFF0000
.eqv DISPLAY_KEYS 0xFFFF0004
.eqv DISPLAY_BASE 0xFFFF0008

# Display stuff
.eqv DISPLAY_W         64
.eqv DISPLAY_H         64
.eqv DISPLAY_W_SHIFT   6

# LED Colors
.eqv COLOR_BLACK   0
.eqv COLOR_RED     1
.eqv COLOR_ORANGE  2
.eqv COLOR_YELLOW  3
.eqv COLOR_GREEN   4
.eqv COLOR_BLUE    5
.eqv COLOR_MAGENTA 6
.eqv COLOR_WHITE   7

# Input key flags
.eqv KEY_NONE 0
.eqv KEY_U 0x01
.eqv KEY_D 0x02
.eqv KEY_L 0x04
.eqv KEY_R 0x08
.eqv KEY_B 0x10

# -------------------------------------------------------------------------------------------------
# call once per main loop to keep the game running at a given FPS.
# a0 is the time between frames (typically 16 for 60FPS).
wait_for_next_frame:
	push s0
	lw	s0, last_frame_time
_wait_next_frame_loop:
	# while (sys_time() - last_frame_time) < a0 {}
	li	v0, 30
	syscall
	sub	t1, v0, s0
	bltu	t1, a0, _wait_next_frame_loop

	# save the time
	sw	v0, last_frame_time

	# frame_counter++
	lw	t0, frame_counter
	add	t0, t0, 1
	sw	t0, frame_counter
	pop s0
	jr  ra

# --------------------------------------------------------------------------------------------------
# returns a bitwise OR of the above key constants, indicating which keys are being held down.
input_get_keys:
	lw	v0, DISPLAY_KEYS
	jr	ra

# --------------------------------------------------------------------------------------------------
# copies the color data from display RAM onto the screen.
display_update:
	sw	zero, DISPLAY_CTRL
	jr	ra

# --------------------------------------------------------------------------------------------------
# copies the color data from display RAM onto the screen, and then clears display RAM.
display_update_and_clear:
	li	t0, 1
	sw	t0, DISPLAY_CTRL
	jr	ra

# --------------------------------------------------------------------------------------------------
# sets 1 pixel to a given color.
# (0, 0) is in the top LEFT, and Y increases DOWNWARDS!
# arguments:
#	a0 = x
#	a1 = y
#	a2 = color (use one of the constants above)
display_set_pixel:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	sll	t0, a1, DISPLAY_W_SHIFT
	add	t0, t0, a0
	add	t0, t0, DISPLAY_BASE
	sb	a2, (t0)
	jr	ra

# --------------------------------------------------------------------------------------------------
# fills a rectangle of pixels with a given color.
# there are FIVE arguments, and I was naughty and used 'v1' as a "fifth argument register."
# this is technically bad practice. sue me.
# arguments:
#	a0 = top-left corner x
#	a1 = top-left corner y
#	a2 = width
#	a3 = height
#	v1 = color (use one of the constants above)
display_fill_rect:
	tlti a0, 0
	tgei a0, 64
	tlti a1, 0
	tgei a1, 64

	# turn w/h into x2/y2
	add	a2, a2, a0
	add	a3, a3, a1

	# turn y1/y2 into addresses
	li	t0, DISPLAY_BASE
	sll	a1, a1, DISPLAY_W_SHIFT
	add	a1, a1, t0
	add	a1, a1, a0
	sll	a3, a3, DISPLAY_W_SHIFT
	add	a3, a3, t0

	move	t0, a1
_fill_loop_y:
	move	t1, t0
	move	t2, a0
_fill_loop_x:
	sb	v1, (t1)
	addi	t1, t1, 1
	addi	t2, t2, 1
	blt	t2, a2, _fill_loop_x

	addi	t0, t0, DISPLAY_W
	blt	t0, a3, _fill_loop_y

	jr	ra