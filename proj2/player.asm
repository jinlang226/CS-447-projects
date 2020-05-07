.include "constants.asm"
.include "macros.asm"

# =================================================================================================
# Player
# =================================================================================================

.globl player_init
.eqv TEMP 
player_init:
enter
	# NOTE: this is unique to the player object. All other objects are made using
	# Object_new. it's just a special object.

	la t0, player
	# player.type = TYPE_PLAYER
	li t1, TYPE_PLAYER
	sw t1, Object_type(t0)

	# player.hw = PLAYER_HW, player.hh = PLAYER_HH
	li t1, PLAYER_HW
	sw t1, Object_hw(t0)
	li t1, PLAYER_HH
	sw t1, Object_hh(t0)

	# reset lives
	li t1, PLAYER_INIT_LIVES
	sw t1, player_lives

	# reset the rest
	jal player_respawn
leave

# ------------------------------------------------------------------------------
player_respawn:
enter
	la t0, player

	# player.x = player.y = 32.0
	li t1, 0x2000
	sw t1, Object_x(t0)
	sw t1, Object_y(t0)

	# player.vx = player.vy = 0
	sw zero, Object_vx(t0)
	sw zero, Object_vy(t0)

	# reset the other variables
	sw zero, player_iframes
	sw zero, player_fire_time
	sw zero, player_deadframes
	sw zero, player_angle
	sw zero, player_accel
	li t1, PLAYER_MAX_HEALTH
	sw t1, player_health
leave

# ------------------------------------------------------------------------------
.globl player_update
player_update:
enter 

	lw t0, player_deadframes
	beq t0, 0, _update_as_normal
		#not 0:
		lw t1, player_deadframes
		sub t1, t1, 1
		sw t1, player_deadframes

		#If player_deadframes is not 0, just return from player_update.
		bne t1, 0, _exit_player_update
			#if the player_deadframes is zero
			#frame timer is up, and it’s time to respawn the player
			lw t2, player_lives
			ble t2, 0, _call_lose_game
				#If player_lives > 0
				jal player_respawn
				li t3, PLAYER_RESPAWN_IFRAMES
				sw t3, player_iframes
				j _exit_player_update

	_call_lose_game:
		jal lose_game
		j _exit_player_update


	_update_as_normal:
		lw t0, player_iframes
		#????
		beq t0, 0, _next_player_update
			sub t0, t0, 1
			sw t0, player_iframes

		_next_player_update:
			jal player_check_input
			jal player_update_thrust

			la a0, player
			li a1, PLAYER_DRAG
			jal Object_damp_velocity

			la a0, player
			jal Object_accumulate_velocity

			la a0, player
			li a1, PLAYER_MAX_POS
			li a2, PLAYER_MAX_POS
			jal Object_wrap_position

_exit_player_update:
leave

# ------------------------------------------------------------------------------
.globl player_draw
player_draw:
enter
	# don't draw the player if they're dead.
	lw   t0, player_deadframes
	bnez t0, _player_draw_return

	# if they're invulnerable, draw them 4 frames on, 4 frames off.
	lw   t0, player_iframes
	beqz t0, _player_draw_doit
	lw   t0, frame_counter
	and  t0, t0, 4
	beqz t0, _player_draw_return

	_player_draw_doit:
		# there are 16 different directions in the rotation animation.
		# this chooses which frame to use based on the player's angle (0 = up, 90 = right)
		# a1 = spr_player[((player_angle + 11) % 360) / 23]
		lw  t0, player_angle
		add t0, t0, 11
		blt t0, 360, _player_draw_a_nowrap
			sub t0, t0, 360
		_player_draw_a_nowrap:
		div t0, t0, 23
		sll t0, t0, 2
		la  a1, spr_player
		add a1, a1, t0
		lw  a1, (a1)
		jal Object_blit_5x5_trans

	_player_draw_return:
leave

# ------------------------------------------------------------------------------
.globl player_check_input
player_check_input:
enter s0, s1

	jal input_get_keys
	move s1, v0
	lw s0, player_angle

	and t0, v0, KEY_B
	beq t0, 0, _check_U
		jal player_fire

	_check_U:
		li t2, 1
		li t3, 0

		and t0, s1, KEY_U
		sw t3, player_accel
		beq t0, 0, _rotate_left #result not 0, left
			sw t2, player_accel  # player_accel = 1

	_rotate_left:
	and t0, s1, KEY_L
	beq t0, 0, _rotate_right

		sub s0, s0, PLAYER_ANG_VEL
		bge s0, 0, _rotate_right
			add s0, s0, 360

	_rotate_right:
	and t0, s1, KEY_R
	beq t0, 0, _exit

		add s0, s0, PLAYER_ANG_VEL
		blt s0, 360, _exit
			sub s0, s0, 360

	_exit:
	sw s0, player_angle
leave s0, s1

# ------------------------------------------------------------------------------
.globl player_fire
player_fire:
enter
	lw t1, player_fire_time
	bne t1, 0, _exit_player_fire
		#player_fire_time == 0
		# player_fire_time = PLAYER_FIRE_DELAY;
		li t2, PLAYER_FIRE_DELAY
		sw t2, player_fire_time

		#player.x, player.y, player_angle
		la t0, player
		lw a0, Object_x(t0) # t1 = player.x
		lw a1, Object_y(t0) # t1 = player.x
		lw a2, player_angle
		jal bullet_new
	
	_exit_player_fire:
leave

# ------------------------------------------------------------------------------
.globl player_update_thrust
player_update_thrust:
enter

	lw t2, player_fire_time
	ble t2, 0, _time_le_zero
		#player_fire_time > 0
		sub t2, t2, 1
		sw t2, player_fire_time

	_time_le_zero: 
		lw t0, player_accel
		bne t0, 1, _exit_in_player_update_thrust

		li a0, PLAYER_THRUST
		lw a1, player_angle
		jal to_cartesian


		la a0, player
		move a1, v0
		move a2, v1
		jal Object_apply_acceleration

	_exit_in_player_update_thrust:
leave

# ------------------------------------------------------------------------------
# void player_damage(int dmg)
#   can be called by other objects (like rocks) to damage the player.
#   the argument is how many points of damage to do.
.globl player_damage
player_damage:
enter 
	#syscall_print_int
	#println_str " damage"
	lw t2, player_iframes
	bne t2, 0, _exit_player_damage

		lw t0, player_health
		sub t0, t0, a0
		maxi t0, t0, 0  # t0 = max(t0, 0)
		sw t0, player_health

		bne t0, 0, _change_player_iframes
			#player_health is 0
			lw t1, player_lives
			sub  t1, t1, 1
	  		maxi t1, t1, 0
	  		sw t1, player_lives
	  		li t4, PLAYER_RESPAWN_TIME
	  		sw t4, player_deadframes

	  		la t0, player
	  		lw a0, Object_x(t0)
			lw a1, Object_y(t0)
	  		jal explosion_new

	  	_change_player_iframes:
	  		li t3, PLAYER_HURT_IFRAMES
	  		sw t3, player_iframes

  	_exit_player_damage:
leave

# ------------------------------------------------------------------------------
# player_collide_all()
# checks if the player collides with anything.
# call the appropriate player-collision function on all active objects that have one.
.globl player_collide_all
player_collide_all:
enter s0, s1, s2
	# s0 = obj
	# s1 = i
	# s2 = collision function

	# start at objects[1]
	la s0, objects
	add s0, s0, Object_sizeof
	li s1, 1
_player_collide_all_loop:
		# don't collide if the player is invulnerable or dead.
		lw   t0, player_deadframes
		bnez t0, _player_collide_all_return
		lw   t0, player_iframes
		bnez t0, _player_collide_all_return

		# s2 = player_collide_funcs[obj.type]
		lw  s2, Object_type(s0)
		sll s2, s2, 2
		la  t0, player_collide_funcs
		add s2, s2, t0
		lw  s2, (s2)

		# skip objects without a collision function
		beq s2, 0, _player_collide_all_continue

		# if Objects_overlap(obj, player)
		move a0, s0
		la   a1, player
		jal  Objects_overlap
		beq  v0, 0, _player_collide_all_continue

			# OKAY, we hit the player
			# call the function (in s2) with the object as the argument
			move a0, s0
			jalr s2

_player_collide_all_continue:
	add s0, s0, Object_sizeof
	inc s1
	blt s1, MAX_OBJECTS, _player_collide_all_loop

_player_collide_all_return:
leave s0, s1, s2