# Jinlang Wang
# jiw159

.include "lab5_include.asm"



.macro print_str %str
	.data
	print_str_message: .asciiz %str
	.text
	la	a0, print_str_message
	li	v0, 4
	syscall
.end_macro

.data
frame_counter:    .word 0
last_frame_time:  .word 0

dot_x: .word  32 40 20

dot_y: .word  32 20 50

current_dot: .word  0 

current_input: .word  0 

pre_dot: .word 0

.text

.globl main
main:
    # here is where you would put any initialization stuff that
    # needs to happen *before* the game begins.
    

_main_loop:

    lw a0, frame_counter
    div a0, a0, 60
    li v0, 1
    syscall

    print_str "\n"

    # check_input()
    jal check_input
    jal draw_dots
    # display_update_and_clear()
    #copies the display RAM onto the display, and then clears the display RAM.
    jal display_update_and_clear

    # wait_for_next_frame(16)
    # wait for at most 16 milliseconds - 1/60th of a second
    li a0, 16
    jal wait_for_next_frame

    j _main_loop





check_input:
    push ra

    jal input_get_keys
    
    sw v0, current_input
    and t4, v0, KEY_B
    lw t7, pre_dot

    #getting adress of dot_x & y
    la t1, dot_x
    la t2, dot_y

    lw t6, current_dot
    mul t6, t6, 4
    add t1, t1, t6
    add t2, t2, t6

    #checking===============
    beq t4, 0, _not_B
    beq t7, v0, _not_B
    #checking===============

    lw t6, current_dot
    add t6, t6, 1
    rem t6, t6, 3 # current_dot in t6
    sw t6, current_dot

    mul t6, t6, 4

    add t1, t1, t6
    add t2, t2, t6

    _not_B:
        and t0, v0, KEY_L
        beq t0, 0, _not_L
        #_x_min
        lw t0, (t1)
        sub t0, t0, 1
        sw t0, (t1)

        _not_L:
            and t0, v0, KEY_R
            beq t0, 0, _not_R
            #x addition
            lw t0, (t1)
            add t0, t0, 1
            sw t0, (t1)

            _not_R:
                and t0, v0, KEY_U
                beq t0, 0, _not_U
                #y sub
                lw t0, (t2)
                sub t0, t0, 1
                sw t0, (t2)

                _not_U:
                    and t0, v0, KEY_D
                    beq t0, 0, _not_D
                    #y add
                    lw t0, (t2)
                    add t0, t0, 1
                    sw t0, (t2)

                    _not_D:
                        lw t0, (t1)
                        and t0, t0, 63
                        sw t0, (t1)

                        lw t0, (t2)
                        and t0, t0, 63
                        sw t0, (t2)

                        sw v0, pre_dot
                        
                        pop ra
                        jr ra

#-----------------------

draw_dots:
	push ra
    push s0
    push s1
    push s2
    push s3


    li t0, 0
    la t1, dot_x
    la t2, dot_y
    lw t3, current_dot

    move s0, t0
    move s1, t1
    move s2, t2
    move s3, t3

    _for_loop:
        
        
        lw a0, (s1)
        add s1, s1, 4

        lw a1, (s2)
        add s2, s2, 4

        li a2, COLOR_ORANGE
        bne s3, s0, _change_color
        
        j _last_step

        _change_color:
            li a2, COLOR_WHITE
            j _last_step

        _last_step:
            jal display_set_pixel
            add s0, s0, 1
            bgt s0, 2, _exit
            j _for_loop

    _exit:
        pop s3
        pop s2
        pop s1
        pop s0
        pop ra
        jr ra
	
