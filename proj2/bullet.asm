.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Bullet
# =================================================================================================

# void bullet_new(x: a0, y: a1, angle: a2)
.globl bullet_new
bullet_new:
enter s0, s1, s2
	move s0, a0
	move s1, a1
	move s2, a2 #s2 = angle

	li a0, TYPE_BULLET
	jal Object_new

	beq v0, 0, _no_new_bullet
		#set obj.x and obj.y to the arguments
		sw s0, Object_x(v0)
		sw s1, Object_y(v0) #new_object.y

		li t0, BULLET_LIFE
 		sw t0, Bullet_frame(v0)

 		move s0, v0 # now object is in s0

 		# call to_cartesian(BULLET_THRUST, s2)
 		# store v0 into vx
 		# store v1 into vy
 		li a0, BULLET_THRUST
 		move a1, s2
		jal to_cartesian

 		sw v0, Object_vx(s0)
 		sw v1, Object_vy(s0)
		
	_no_new_bullet:
leave s0, s1, s2

# ------------------------------------------------------------------------------

.globl bullet_update
bullet_update:
enter s0, s1

	#s0: bullet
	#s1: bullet life time
	move s0, a0
	lw s1, Bullet_frame(s0)
	sub s1, s1, 1
 	sw s1, Bullet_frame(s0)

 	bne s1, 0, _not_delete
 		#delete:
 		move a0, s0
 		jal Object_delete

 	_not_delete:
		#Object_accumulate_velocity(bullet);
		move a0, s0
		jal Object_accumulate_velocity

		#Object_wrap_position(bullet);
		move a0, s0
	    jal Object_wrap_position

leave s0, s1

# ------------------------------------------------------------------------------

.globl bullet_draw
bullet_draw:
enter
	#display_set_pixel(bullet.x >> 8, bullet.y >> 8, COLOR_RED);

	move t0, a0
	lw a0, Object_x(t0)
	sra a0, a0, 8

	lw a1, Object_y(t0)
	sra a1, a1, 8

	li a2, COLOR_RED

	jal display_set_pixel
leave