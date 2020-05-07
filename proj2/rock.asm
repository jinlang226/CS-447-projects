.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Rocks
# =================================================================================================

.globl rocks_count
rocks_count:
enter
	la t0, objects
	li t1, 0
	li v0, 0

	_rocks_count_loop:
		lw t2, Object_type(t0)
		beq t2, TYPE_ROCK_L, _rocks_count_yes
		beq t2, TYPE_ROCK_M, _rocks_count_yes
		bne t2, TYPE_ROCK_S, _rocks_count_continue
		_rocks_count_yes:
			inc v0
	_rocks_count_continue:
	add t0, t0, Object_sizeof
	inc t1
	blt t1, MAX_OBJECTS, _rocks_count_loop
leave

# ------------------------------------------------------------------------------

# void rocks_init(int num_rocks)
.globl rocks_init
rocks_init:
enter s0, s1, s2, s3
	
	li s2, 0
	move s3, a0

	_loop:
		li a0, 0x2000
		jal random
		move t1, v0
		add t1, t1, 0x3000
		rem s0, t1, 0x4000

		li a0, 0x2000
		jal random
		move t1, v0
		add t1, t1, 0x3000
		rem s1, t1, 0x4000

		move a0, s0
		move a1, s1
		li a2, TYPE_ROCK_L
		jal rock_new
		
		add s2, s2, 1
		blt s2, s3, _loop

leave s0, s1, s2, s3

# ------------------------------------------------------------------------------

# void rock_new(x, y, type)
.globl rock_new
rock_new:
enter s0, s1, s2, s3, s4 
#s0 is the new project
	move s1, a0
	move s2, a1
	move s3, a2 # s3 = type

	move a0, a2
	jal Object_new
	
	beq v0, 0, _no_new_rock
		move s0, v0 #s0 is the new project

		# position
		sw s1, Object_x(s0)
		sw s2, Object_y(s0)

		li t0, TYPE_ROCK_L
		li t1, TYPE_ROCK_M
		li t2, TYPE_ROCK_S
		beq t0, s3, _rock_L
		beq t1, s3, _rock_M
		beq t2, s3, _rock_S

		_rock_L:
			# bounding box
			li t0, ROCK_L_HW
			li t1, ROCK_L_HH

			sw t0, Object_hw(s0)
			sw t1, Object_hh(s0)

			#get a0
			li a0, ROCK_VEL
			j _next_step

		_rock_M:
			li t0, ROCK_M_HW
			li t1, ROCK_M_HH

			sw t0, Object_hw(s0)
			sw t1, Object_hh(s0)

			li t2, ROCK_VEL
			mul a0, t2, 4
			j _next_step

		_rock_S:
			li t0, ROCK_S_HW
			li t1, ROCK_S_HH

			sw t0, Object_hw(s0)
			sw t1, Object_hh(s0)

			li t2, ROCK_VEL
			mul a0, t2, 12
			j _next_step


		_next_step:
			move s4, a0
			#get a0 in previous function
			#li a0, ROCK_VEL

			#get a1
			li a0, 360
			jal random
			move a1, v0

			move a0, s4
			
			jal to_cartesian

			sw v0, Object_vx(s0)
			sw v1, Object_vy(s0)

	_no_new_rock:
leave s0, s1, s2, s3, s4 

# ------------------------------------------------------------------------------

.globl rock_update
rock_update:
enter s0
	move s0, a0
	jal Object_accumulate_velocity
	
	#Wrap the position
	move a0, s0
	jal Object_wrap_position

	move a0, s0
	jal rock_collide_with_bullets
leave s0

# ------------------------------------------------------------------------------
#???????
rock_collide_with_bullets:
enter s0, s1, s2
	#loop over all the objects in the objects array
	la s0, objects
	li s1, 0
	move s2, a0 #s2 is the rock
	_loop_rock_collide_with_bullets:
		lw t0, Object_type(s0)
		li t1, TYPE_BULLET
		bne t0, t1, _next_block

			#Object_contains_point(obj, x, y)
			#returns a boolean saying whether the point (x, y)
			# is within the object’s bounding box.
			move a0, s2
			lw a1, Object_x(s0)
			lw a2, Object_y(s0)
			jal Object_contains_point

			beq v0, 0, _next_block
				move a0, s2
				jal rock_get_hit
				move a0, s0
				jal Object_delete
				j _Object_delete_exit

	_next_block:
		add s0, s0, Object_sizeof
		inc s1
		blt s1, MAX_OBJECTS, _loop_rock_collide_with_bullets

_Object_delete_exit:
leave s0, s1, s2

# ------------------------------------------------------------------------------

rock_get_hit:
enter s0, s1, s2, s3
	move s0, a0 # s0 = old object
	#println_str "rock got hit"
	lw t4, Object_type(s0)
	
	li t0, TYPE_ROCK_L
	li t1, TYPE_ROCK_M
	li t2, TYPE_ROCK_S
	beq t0, t4, _rock_L_hit
	beq t1, t4, _rock_M_hit
	beq t2, t4, _rock_S_hit

	_rock_L_hit:
		# void rock_new(x, y, type)
		lw a0, Object_x(s0)
		lw a1, Object_y(s0)
		li a2, TYPE_ROCK_M
		move s1, a0
		move s2, a1
		move s3, a2
		jal rock_new
		move a0, s1
		move a1, s2
		move a2, s3
		jal rock_new
		j _rock_S_hit

	_rock_M_hit:
		lw a0, Object_x(s0)
		lw a1, Object_y(s0)
		li a2, TYPE_ROCK_S
		move s1, a0
		move s2, a1
		move s3, a2
		jal rock_new
		move a0, s1
		move a1, s2
		move a2, s3
		jal rock_new
		j _rock_S_hit

	_rock_S_hit:
		lw a0, Object_x(s0)
		lw a1, Object_y(s0)
		jal explosion_new

		move a0, s0
		jal Object_delete
leave s0, s1, s2, s3

# ------------------------------------------------------------------------------

.globl rock_collide_l
rock_collide_l:
enter
	jal rock_get_hit
	li a0, 3
	jal player_damage
leave

# ------------------------------------------------------------------------------

.globl rock_collide_m
rock_collide_m:
enter
	jal rock_get_hit
	li a0, 2
	jal player_damage
leave
leave

# ------------------------------------------------------------------------------

.globl rock_collide_s
rock_collide_s:
enter
	jal rock_get_hit
	li a0, 1
	jal player_damage
leave
leave

# ------------------------------------------------------------------------------

.globl rock_draw_l
rock_draw_l:
enter s0
move s0, a0
	la a1, spr_rock_l
	jal Object_blit_5x5_trans
leave s0

# ------------------------------------------------------------------------------

.globl rock_draw_m
rock_draw_m:
enter
move s0, a0
	la a1, spr_rock_m
	jal Object_blit_5x5_trans
leave

# ------------------------------------------------------------------------------

.globl rock_draw_s
rock_draw_s:
enter
move s0, a0
	la a1, spr_rock_s
	jal Object_blit_5x5_trans
leave