# Jinlang Wang
# jiw159

.include "macros.asm"

.eqv INPUT_SIZE 3

.data
recorded_notes: .byte  -1:1024
recorded_times: .word 250:1024
input: .space INPUT_SIZE

instrument: .word 0

# maps from ASCII to MIDI note numbers, or -1 if invalid.
key_to_note_table: .byte
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 60 -1 -1 -1
	75 -1 61 63 -1 66 68 70 -1 73 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 55 52 51 64 -1 54 56 72 58 -1 -1 59 57 74
	76 60 65 49 67 71 53 62 50 69 48 -1 -1 -1 -1 -1

demo_notes: .byte
	67 67 64 67 69 67 64 64 62 64 62
	67 67 64 67 69 67 64 62 62 64 62 60
	60 60 64 67 72 69 69 72 69 67
	67 67 64 67 69 67 64 62 64 65 64 62 60
	-1

demo_times: .word
	250 250 250 250 250 250 500 250 750 250 750
	250 250 250 250 250 250 500 375 125 250 250 1000
	375 125 250 250 1000 375 125 250 250 1000
	250 250 250 250 250 250 500 250 125 125 250 250 1000
	0
.text

# -----------------------------------------------

.globl main
main:
	
	_main_loop:


		print_str "[k]eyboard, [d]emo, [r]ecord, [p]lay, [q]uit: \n"

		li a1, INPUT_SIZE  # inuput size

		la a0, input #put string read from user into input  location
			   	#give it the address of the input array

		li v0, 8
		syscall
	
		lb t0, input 
		

		beq t0, 'k', _keyboard
		beq t0, 'd', _demo
		beq t0, 'r', _record
		beq t0, 'p', _play
		beq t0, 'q', _quit
		print_str "Not a valid command! \n"
		j _main_loop


		_keyboard:
			jal key
			j _main_loop
                                                         
		_demo:
			#call play_song using demo_notes and demo_times as its arguments.
			la  a0, demo_notes	#a0 = a notes (&demo_notes)
   			la  a1, demo_times	#a1 = a times
			jal play_song
			j _main_loop

		_record:
			jal record_song
			j _main_loop

		#play the recorded song
		_play:
			la  a0, recorded_notes	#a0 = a notes (&demo_notes)
   			la  a1, recorded_times	#a1 = a times
			jal play_song
			j _main_loop

		_quit:
			print_str "bye!"
			li v0, 10
   			syscall

# --------------------------------------------------------------------------------------------
#recording
#recorded_notes: .byte  -1:1024
#recorded_times: .word 250:1024
		record_song:
			push ra
			push s0
			push s1
			push s2

			la s0, recorded_notes
			la s1, recorded_times
	
			print_str "play when ready, and hit enter to finish. \n"
			

   			_record_loop:
  				li v0, 12
				syscall

				#exit the loop
				beq v0, '\n', _record_loop_break

				move a0, v0  #a0 = t0
				jal  translate_note # takes ascii character, returns note number
				bne v0, -1, _jal_record_note
				j _record_loop

			_jal_record_note:
				move s2, v0 # now the note is saved in s2!

				move a0, v0 # pass translate_note return value to play_note
				jal  play_note

				#Store that note at the note pointer
				sb s2, (s0)   # store the note at the note pointer
				add s0, s0, 1 # move to next value in the note array
				
				# store the time at the time pointer
				li v0, 30
				syscall

				sw v0, (s1)   # store the time at the time pointer
				add s1, s1, 4 # move to the next value in the time array

			j _record_loop
			# end of record_loop
			_record_loop_break:

				# store -1 at the note pointer
				li t0, -1
				sb t0, (s0)

				# store the current time!!! at the time pointer
				li v0, 30
				syscall
				sw v0, (s1)
				
				# restart at beginning
				la s0, recorded_notes
				la s1, recorded_times

			# for(s0 = recorded_notes, s1 = recorded_times; *s0 != -1; s0++, s1 += 4)
			rec_for_loop:

				lw t0, (s1)  #first time

				add s1, s1, 4

				#li t1, 4(s1)
				# four byte after s1

				lw t1, (s1)

				sub t1, t1, t0
				sub s1, s1, 4

				sw t1, (s1)
				add s1, s1, 4

				lb t3, (s0)

				beq t3, -1, _record_exit
				add s0, s0, 1
				
				j rec_for_loop

	   		_record_exit:
	   			print_str "done!\n"
	   			pop s2
				pop s1
				pop s0
				pop ra
				jr ra



# --------------------------------------------------------------------------------------------------------
   		#play song
   		
   		play_song:
   			push ra
   			push s0 # s0 = notes pointer	in byte move 1
   			push s1 # s1 = times pointer	in words move 4

   			# save arguments to s registers
   			move s0, a0
   			move s1, a1

   			# !!! NEVER USE values from a0 or a1 again!
   			#lb, add1
   			#lb t0, s0
   			#lw t1, s1

   			_while_loop:

   				lb t0, (s0)
   				beq t0, -1, _play_song_return


   				#play note
   				lb t0, (s0)
   				move a0, t0
   				jal play_note
   				# after this jal, a0-a3 and t0-t9 and v0-v1 can have ANY value.


   				#sleep
   				lw a0, (s1)
   				li v0, 32
   				syscall 

   				

   				add s0, s0, 1
   				add s1, s1, 4 

   				j _while_loop


	   		_play_song_return:
	   			pop s1
	   			pop s0
	   			pop ra
	   			jr ra

# --------------------------------------------------------------------------------------------------------
		play_note:
   			
			#li a0, v0   # middle C
			li a1, 500  # duration 0.5s (500)
			lw a2, instrument    # grand piano
			li a3, 100  # normal volume （100）
			
			li v0, 31
			syscall
			
			jr ra

# --------------------------------------------------------------------------------------------------------
   		key:
   			push ra 
	   		print_str "play notes with letters and punctuation.\nchange instrument with ` and then type the number.  \nexit with enter. \n"
	   		print_str "current instrument: "
	   		lw a0, instrument
	   		add a0, a0, 1
	   		li v0, 1
	   		syscall
	   		print_str "\n"
	   		
   			
   			_key_loop:

				li v0, 12
				syscall

				#case 2 
					#let them type a number in the range 1 to 128 to choose an instrument
				beq v0, '`', _change_instrument

				#case 3 
					#exit the loop
				beq v0, '\n', _quit_in_key

				# it wasn't ` or \n, so try to translate it
				j _normal_key

		   		_change_instrument:  
		   			print_str "\nEnter instrument number (1..128): "
		   			
		   			li v0, 5
		   			syscall

		   			bgt, v0, 128, _change_instrument #not greater than 128
		   			blt, v0, 1, _change_instrument   #not less than 1

		   			sub t0, v0, 1

		   			sw t0, instrument # instrument = t0
		   			j _key_loop


		   		#case 1 
						#If they press one of the note keys, 
						#play a MIDI note using the current instrument
		   		_normal_key:

					#save the keyboard
					
					# key is in v0
					# but translate_note expects argument in a0
					move a0, v0  #a0 = t0
					jal  translate_note # takes ascii character, returns note number

 
					# if v0 != -1
					#    play_note(v0)
					
					bne v0, -1, _jal_play_note


					j _key_loop

			_jal_play_note:
				move a0, v0 # pass translate_note return value to play_note
				jal  play_note
				j _key_loop

   		_quit_in_key:
			pop ra
			jr ra
# --------------------------------------------------------------------------------------------------------
		translate_note:
			# ASCII character is in a0
   			blt a0, 0, _set_neg_one
   			bgt a0, 127, _set_neg_one
   			#key_to_note_table[a0]

			# want to return note in v0

			# return key_to_note_table[a0]

			la t1, key_to_note_table # t1 = &a
			mul t2, a0, 1   #Bi
			add t1, t1, t2  #A + Bi
			lb v0, (t1) # t2 = A[a0]
			jr ra

		_set_neg_one:
			# return -1
			li v0, -1
			jr ra


# --------------------------------------------------------------------------------------------------------
