.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Explosions
# =================================================================================================

# void explosion_new(x, y)
.globl explosion_new
explosion_new:
enter s0, s1, s3
	move s0, a0 #s0 = a0
	move s1, a1 #s1 = a1

	li a0, TYPE_EXPLOSION
	jal Object_new
	move s3, v0 # now object is in s3

	beq s3, 0, _no_new_explosion
		#set obj.x and obj.y to the arguments
		sw s0, Object_x(s3)
		sw s1, Object_y(s3) #new_object.y

		li t0, EXPLOSION_HW
		li t1, EXPLOSION_HH

		sw t0, Object_hw(s3)
		sw t1, Object_hh(s3)

		li t3, EXPLOSION_ANIM_DELAY
		sw t3, Explosion_timer(s3)
		li t4, 0
		sw t4, Explosion_frame(s3)

	_no_new_explosion:
leave s0, s1, s3

# ------------------------------------------------------------------------------

.globl explosion_update
explosion_update:
enter s0
	move s0, a0

	lw t0, Explosion_timer(s0)
	sub t0, t0, 1
	maxi t0, t0, 0
	sw t0, Explosion_timer(s0)

	bne t0, 0, _exit_explosion_update
		#if it is 0
		li t1, EXPLOSION_ANIM_DELAY
		sw t1, Explosion_timer(s0)

		lw t2, Explosion_frame(s0)
		add t2, t2, 1
		sw t2, Explosion_frame(s0)

		blt t2, 6, _exit_explosion_update
			move a0, s0
			jal Object_delete

	_exit_explosion_update:
leave s0

# ------------------------------------------------------------------------------

.globl explosion_draw
explosion_draw:
enter
	la a1, spr_explosion_frames
	lw t2, Explosion_frame(a0)
	mul t1, t2, 4
	add a1, a1, t1
	lw a1, (a1)
	jal Object_blit_5x5_trans
leave