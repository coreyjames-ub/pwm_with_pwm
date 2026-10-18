	.data
; DATA SECTION
; VARS
red_duty:						.word 0x00
green_duty:						.word 0x00
blue_duty:						.word 0x00
int_spd:						.word 0x003D0900
usr_input:						.byte 0x00
color_flag:						.byte 0x00
wheel_flag:						.byte 0x00
; INSTRUCTION STRINGS
blinky_or_color:	.string "***** PRESS <b> TO ENTER BLINK_MODE, PRESS <c> TO ENTER COLOR_MODE, OR PRESS <q> TO QUIT *****",0x0D, 0x0A,0
exit_blinky_mode:	.string	"***** PRESS <m> TO RETURN TO THE MAIN MENU *****",0x0D, 0x0A,0
instruct_1: 		.string "***** INPUT A 3 DIGIT INTEGER VALUE FOR RED, PRESS <spacebar> TO CONTINUE *****",0x0D, 0x0A,0
instruct_2: 		.string "***** INPUT A 3 DIGIT INTEGER VALUE FOR GREEN, PRESS <spacebar> TO CONTINUE *****",0x0D, 0x0A,0
instruct_3: 		.string "***** INPUT A 3 DIGIT INTEGER VALUE FOR BLUE, PRESS <spacebar> TO CONTINUE *****",0x0D, 0x0A,0
exit_color_mode:	.string "***** PRESS <c> TO ENTER A NEW RGB VALUE, OR PRESS <m> TO RETURN TO THE MAIN MENU *****",0x0D, 0x0A,0
usr_in_val:			.string "     ", 0
line_feed: 			.string "", 0x0D, 0x0A, 0
;delete_char:		.string 27, "[1D ", 27, "[1D",0
delete_char:		.string 27, "[1D", 27, "[J", 0
curs_home:			.string 27, "[0;0;H",0
clr_screen: 		.string 27, "[2J", 0
red_str:			.string "000",0
blue_str:			.string "000",0
green_str:			.string "000",0

	.text
; TEXT SECTION

	.global UART0_Handler
	.global uart_interrupt_init
	.global uart_init
	.global pwm_with_pwm_init
	.global pwm_with_pwm_project
	.global output_string
	.global output_character
	.global fpu_init
	.global str2float
	.global init_pwm_rgb
	.global enable_pwm_out
	.global connect_pwm_out
	.global set_pwm_load
	.global set_pwm_compare
	.global mod
	.global config_pwm_clock_div
	.global config_pwm_gen
	.global Timer_Handler
	.global timer_interrupt_init

; PTRS

ptr_blinky_or_color:		.word blinky_or_color
ptr_exit_blinky_mode:	.word exit_blinky_mode
ptr_exit_color_mode:		.word exit_color_mode
ptr_usr_input:			.word usr_input
ptr_instruct_1:			.word instruct_1
ptr_instruct_2:			.word instruct_2
ptr_instruct_3:			.word instruct_3
ptr_usr_in_val:			.word usr_in_val
ptr_line_feed:			.word line_feed
ptr_color_flag:			.word color_flag
ptr_delete_char:		.word delete_char
ptr_curs_home:			.word curs_home
ptr_clr_screen: 		.word clr_screen
ptr_red_duty:			.word red_duty
ptr_green_duty:			.word green_duty
ptr_blue_duty:			.word blue_duty
ptr_red_str:			.word red_str
ptr_blue_str:			.word blue_str
ptr_green_str:			.word green_str
ptr_wheel_flag:			.word wheel_flag
ptr_int_spd:			.word int_spd

; BASE ADDR
base_UART0:						.word 0x4000C000
base_gpio_F: 					.word 0x40025000
base_timer_0:					.word 0x40030000


; OFFSETS
GPTMICR:			.equ 0x024
UARTICR: 			.equ 0x044
SPACE:				.equ 0x20
DELETE:				.equ 0x7F
ZERO_CHAR:			.equ 0x30
NINE_CHAR:			.equ 0x39
BACKSPACE:			.equ 0x8
LETTER_B:			.equ 0x62
LETTER_C:			.equ 0x63
LETTER_Q:			.equ 0x71
LETTER_M:			.equ 0x6D
enable_GPIO: 		.equ 0x608
port_f:				.equ 0x20
pwmenablegen2:		.equ 0x0C0
pwmenablegen3:		.equ 0x100
pwm2load:			.equ 0x0D0
pwm3load:			.equ 0x110
pwm2cmpb:			.equ 0x0DC
pwm3cmpb:			.equ 0x11C
pwm3cmpa:			.equ 0x118
pwm5en:				.equ 0x008
pwm2genb:			.equ 0xE4
pwm3gena:			.equ 0x120
pwm3genb:			.equ 0x124

hundred:			.equ 0xFFFF
fifty:				.equ 0x7FFF

LETTER_W:			.equ 0x77




; PWM INIT
pwm_with_pwm_init:
	PUSH {r4-r6, lr}

	BL uart_init
	BL uart_interrupt_init
	BL init_pwm_rgb

	BL fpu_init

	POP {r4-r6, lr}
	MOV pc, lr


; PWM PROJ
pwm_with_pwm_project:
	PUSH {r4-r12, lr}

	; BASE ADDRESS FOR USER INPUT IS IN R4
	LDR r4, ptr_usr_input					; base address to user input in R4
	MOV r5, #0								; Mutable Data
	MOV r6, #0								; keep zero in r6
	MOV r8, #0								; base address for color strings
	LDR r9, ptr_color_flag					; color count flag


main_menu:

	; TURN OFF RGB LED
	BL reg_red
	BL reg_green
	BL reg_blue

	; disconnect pwm output ... configure disabel
	MOV r0, #pwm5en
	MOV r1, #0x0								; red: #0x1		green: #0x2		blue: #0x4 ... all 3 is 7
	BL connect_pwm_out

	MOV r0, #pwmenablegen2
	MOV r1, #0
	BL enable_pwm_out

	MOV r0, #pwmenablegen3
	MOV r1, #0
	BL enable_pwm_out

	; CLEAR THE USER INPUT AND SCREEN
	STRB r6, [r4]				; clear and store the user input ... zero
	BL clear_screen

	; Show main menu prompt:
	LDR r0, ptr_blinky_or_color
	BL output_string

wait_main:
	LDRB r5, [r4]				; LOAD USER INPUT
	CMP r5, #LETTER_B			; COMPARE TO B
	BEQ blinky					; IF B BREAK TO BLINKY
	CMP r5, #LETTER_C			; COMPARE TO C
	BEQ advanced_rgb_led		; IF C BREAK TO ADV RGB
	CMP r5, #LETTER_Q			; COMPARE TO Q
	BEQ done_proj				; IF Q BREAK TO DONE
	CMP r5, #LETTER_W			; compare to w
	BEQ color_wheel
	B wait_main					; LOOP

blinky:

	; Clear user input and screen
	STRB r6, [r4]				; clear and store the user input ... zero
	BL clear_screen				; clear the screen

	; set clock divisor to divide by 64
	MOV r0, #7
	BL config_pwm_clock_div

	; set the load value
	; PWM GEN 2
	MOV r0, #pwm2load
	MOV r1, #hundred
	BL set_pwm_load
	; PWM GEN 3
	MOV r0, #pwm3load
	MOV r1, #hundred
	BL set_pwm_load

	; set the compare value
	; PWM GEN 2 B
	MOV r0, #pwm2cmpb
	MOV r1, #fifty
	BL set_pwm_compare
	; PWM GEN 3 B
	MOV r0, #pwm3cmpb
	MOV r1, #fifty
	BL set_pwm_compare
	; PWM GEN 3 A
	MOV r0, #pwm3cmpa
	MOV r1, #fifty
	BL set_pwm_compare

	; connect pwm output ... configure enable
	MOV r0, #pwm5en
	MOV r1, #0x1								; red: #0x1		blue: #0x2		green: #0x4 ... all 3 is 7
	BL connect_pwm_out

	MOV r0, #pwmenablegen2
	MOV r1, #1
	BL enable_pwm_out

	; Gen 3
	MOV r0, #pwmenablegen3
	MOV r1, #0
	BL enable_pwm_out

	; SHOW THE BLINKY PROMPT
	LDR r0, ptr_exit_blinky_mode
	BL output_string

wait_blinky:
	LDRB r5, [r4]				; load user input
	CMP r5, #LETTER_M			; compare it to the letter m
	BEQ main_menu				; go back to main menu if equal
	B wait_blinky				; else loop blinky again

advanced_rgb_led:

	; Clear user input, color flag, and screen
	STRB r6, [r4]				; store the user input
	STRB r6, [r9]					; clear color flag
	BL clear_screen				; clear the screen

	; Clear rgb duty
	LDR r0, ptr_red_duty
	STR r6, [r0]
	LDR r0, ptr_green_duty
	STR r6, [r0]
	LDR r0, ptr_blue_duty
	STR r6, [r0]

	; Show 1st Instruction
	LDR r0, ptr_instruct_1
	BL output_string

red_wait:
	LDRB r5, [r4]					; load user input
	CMP r5, #SPACE					; compare to space
	BEQ green_prep					; if it is space then branch to green loop
	CMP r5, #0x0					; compare user input to zero
	ITTT GT							; if it is greater than zero
	MOVGT r0, r5			; set arg1 to user input				1
	MOVGT r1, #1			; set arg2 to color flag to red			2
	BLGT show_keys			; use show_keys sub_routine				3
	B red_wait				; start loop again

green_prep:
	STRB r6, [r4]				; clear the user input
	BL clear_screen
	LDR r8, ptr_red_str
	LDRB r0, [r9]					; load color flag count into r0
	STRB r6, [r8, r0]				; null terminate red str
	STRB r6, [r9]					; clear color flag
	LDR r0, ptr_instruct_2		; load green instruction
	BL output_string				; show the instruction

green_wait:
	LDRB r5, [r4]					; load user input
	CMP r5, #SPACE					; compare to space
	BEQ blue_prep					; branch to green loop
	CMP r5, #0x0					; compare user input to zero
	ITTT GT							; if it is greater than zero
	MOVGT r0, r5			; set arg1 to user input				1
	MOVGT r1, #2			; set arg2 to color flag to green		2
	BLGT show_keys			; use show_keys sub_routine				3
	B green_wait				; start loop again

blue_prep:
	STRB r6, [r4]				; clear the user input
	BL clear_screen
	LDR r8, ptr_green_str
	LDRB r0, [r9]					; load color flag count into r0
	STRB r6, [r8, r0]				; null terminate green str
	STRB r6, [r9]					; clear color flag
	LDR r0, ptr_instruct_3		; load green instruction
	BL output_string				; show the instruction

blue_wait:
	LDRB r5, [r4]					; load user input
	CMP r5, #SPACE					; compare to space
	BEQ adv_rgb_prep					; branch to adv_rgb prep		4
	CMP r5, #0x0					; compare user input to zero
	ITTT GT							; if it is greater than zero
	MOVGT r0, r5			; set arg1 to user input				1
	MOVGT r1, #3			; set arg2 to color flag to blue		2
	BLGT show_keys			; use show_keys sub_routine				3
	B blue_wait				; start loop again

adv_rgb_prep:
	STRB r6, [r4]				; clear the user input
	BL clear_screen
	LDR r8, ptr_blue_str
	LDRB r0, [r9]					; load color flag count into r0
	STRB r6, [r8, r0]				; null terminate green str
	STRB r6, [r9]					; clear color flag					???

	; prep 255 in s7
	MOV r0, #255
	VMOV s7, r0
	VCVT.F32.S32 s7, s7			; converts from integer to float

	; I need 100 in s5
	MOV r0, #100				; move 100 into r0
	VMOV s5, r0					; move 100 into s5 ... float!
	VCVT.F32.S32 s5, s5		; converts from integer to float

	; red string value to float
	LDR r0, ptr_red_str
	BL str2float
	VMOV s6, r0						; move red float val into s6
	VDIV.F32 s6, s6, s7			; divide red val in s6 by 255 in s7

	VMUL.F32 s6, s6, s5					; multiply the decimal by 100
	VCVTR.S32.F32 s6, s6				; convert from float to int
	VMOV r0, s6							; move from float reg to core reg

	LDR r1, ptr_red_duty
	STR r0, [r1]						; store the int val into mem

	; green string value to float
	LDR r0, ptr_green_str
	BL str2float
	VMOV s6, r0						; move green float val into s6
	VDIV.F32 s6, s6, s7			; divide green val in s6 by 255 in s7

	VMUL.F32 s6, s6, s5					; multiply by 100
	VCVTR.S32.F32 s6, s6				; convert from float to int
	VMOV r0, s6							; move from float reg to core reg

	LDR r1, ptr_green_duty
	STR r0, [r1]						; store the int val into mem

	; blue string value to float
	LDR r0, ptr_blue_str
	BL str2float
	VMOV s6, r0						; move blue float val into s6
	VDIV.F32 s6, s6, s7			; divide blue val in s6 by 255 in s7

	VMUL.F32 s6, s6, s5
	VCVTR.S32.F32 s6, s6				; convert from float to int
	VMOV r0, s6							; move from float reg to core reg

	LDR r1, ptr_blue_duty
	STR r0, [r1]						; store the int val into mem

	LDR r0, ptr_exit_color_mode		; load green instruction	2
	BL output_string				; show the instruction		3

set_adv_rgb_with_pwm:
	; disable the pwm generators
	MOV r0, #pwmenablegen2
	MOV r1, #0
	BL enable_pwm_out
	MOV r0, #pwmenablegen3
	MOV r1, #0
	BL enable_pwm_out

	; reset the clock divisor ... need to do this with blinky too
	; divide by 16
	MOV r0, #3
	BL config_pwm_clock_div

	; reset the load ... need to do this with blinky too
	; load is 100
	; set the load value
	; PWM GEN 2
	MOV r0, #pwm2load
	MOV r1, #0x64
	BL set_pwm_load
	; PWM GEN 3
	MOV r0, #pwm3load
	MOV r1, #0x64
	BL set_pwm_load

	; set the compares ... set this up with blinky too
	; account for on and off channels
	; compares are the respective duty cycle
	; set the compare value
	; PWM GEN 2 B
	MOV r5, #0

	MOV r0, #pwm2cmpb
	LDR r1, ptr_red_duty
	LDR r1, [r1]
	CMP r1, #0
	IT NE
	ADDNE r5, r5, #1
	CMP r1, #100
	IT GE
	MOVGE r1, #99					; if its 100 offset the compare and load by a little bit
	BL set_pwm_compare
	; we have to check if its on 100%
	LDR r1, ptr_red_duty
	LDR r1, [r1]
	CMP r1, #0x64
	ITE GE
	BLGE always_red
	BLLT reg_red
	; PWM GEN 3 B
	MOV r0, #pwm3cmpb
	LDR r1, ptr_green_duty
	LDR r1, [r1]
	CMP r1, #0
	IT NE
	ADDNE r5, r5, #4
	CMP r1, #100
	IT GE
	MOVGE r1, #99					; if its 100 offset the compare and load by a little bit
	BL set_pwm_compare
	LDR r1, ptr_green_duty
	LDR r1, [r1]
	CMP r1, #0x64
	ITE GE
	BLGE always_green
	BLLT reg_green
	; PWM GEN 3 A
	MOV r0, #pwm3cmpa
	LDR r1, ptr_blue_duty
	LDR r1, [r1]
	CMP r1, #0
	IT NE
	ADDNE r5, r5, #2
	CMP r1, #100
	IT GE
	MOVGE r1, #99 			; if its 100 offset the compare and load by a little bit
	BL set_pwm_compare
	LDR r1, ptr_blue_duty
	LDR r1, [r1]
	CMP r1, #0x64
	ITE GE
	BLGE always_blue
	BLLT reg_blue

	; check if the duty cycle is greater than zero and then enable output
	; connect pwm output ... configure enable
	MOV r0, #pwm5en
	MOV r1, r5
	BL connect_pwm_out

	; check if duty cycle is greater than zero and enable the generator ... use mod
	MOV r1, r5
	MOV r0, #2
	BL mod
	CMP r0, #1
	ITE EQ
	MOVEQ r1, #1
	MOVNE r1, #0
	MOV r0, #pwmenablegen2
	BL enable_pwm_out

	CMP r5, #1
	ITE GT
	MOVGT r1, #1
	MOVLE r1, #0
	MOV r0, #pwmenablegen3
	BL enable_pwm_out


	; do str to float for each color
	; do math for each color and set them value / 255 * 100 = round it ... integer it ... store it
	; now loop
adv_rgb_loop:
	LDRB r5, [r4]					; load user input
	CMP r5, #LETTER_C					; compare to space
	BEQ advanced_rgb_led
	CMP r5, #LETTER_M
	BEQ main_menu
	B adv_rgb_loop

done_proj:
	POP {r4-r12,lr}
	MOV pc, lr

; ******************************************* ALWAYS RED ****************************************************
; ARGS:			N/A
; RETURN:		N/A
always_red:
	PUSH {r4-r8, lr}

	; PF1 ... 	M1PWM5 ... PWM2GENB
	MOV r0, #pwm2genb
	MOV r1, #0xC00
	MOV r2, #3
	BL config_pwm_gen

	POP {r4-r8,lr}
	MOV pc, lr

; ******************************************* REG RED ****************************************************
; ARGS:			N/A
; RETURN:		N/A
reg_red:
	PUSH {r4-r8, lr}

	; PF1 ... 	M1PWM5 ... PWM2GENB
	MOV r0, #pwm2genb
	MOV r1, #0xC00
	MOV r2, #2
	BL config_pwm_gen

	POP {r4-r8,lr}
	MOV pc, lr

; ******************************************* ALWAYS GREEN ****************************************************
; ARGS:			N/A
; RETURN:		N/A
always_green:
	PUSH {r4-r8, lr}

	; PF3 ... M1PWM7 ... PWM3GENB
	MOV r0, #pwm3genb
	MOV r1, #0xC00
	MOV r2, #3
	BL config_pwm_gen

	POP {r4-r8,lr}
	MOV pc, lr

; ******************************************* REG GREEN ****************************************************
; ARGS:			N/A
; RETURN:		N/A
reg_green:
	PUSH {r4-r8, lr}

	; PF3 ... M1PWM7 ... PWM3GENB
	MOV r0, #pwm3genb
	MOV r1, #0xC00
	MOV r2, #2
	BL config_pwm_gen

	POP {r4-r8,lr}
	MOV pc, lr

; ******************************************* ALWAYS BLUE ****************************************************
; ARGS:			N/A
; RETURN:		N/A
always_blue:
	PUSH {r4-r8, lr}

	; PF2 ... M1PWM6 ... PWM3GENA
	MOV r0, #pwm3gena
	MOV r1, #0xC0
	MOV r2, #3
	BL config_pwm_gen

	POP {r4-r8,lr}
	MOV pc, lr

; ******************************************* REG BLUE ****************************************************
; ARGS:			N/A
; RETURN:		N/A
reg_blue:
	PUSH {r4-r8, lr}

	; PF2 ... M1PWM6 ... PWM3GENA
	MOV r0, #pwm3gena
	MOV r1, #0xC0
	MOV r2, #2
	BL config_pwm_gen

	POP {r4-r8,lr}
	MOV pc, lr


; *****************************************
; ARGS:			R0: ASCII CHARACTER				R1: COLOR FLAG: 1 = RED, 2 = GREEN, 3 = BLUE
show_keys:
	PUSH {r4-r12, lr}
	MOV r4, r0			; move the ascii char into r4
	CMP r1, #1			; compare to 1 for red
	IT EQ
	LDREQ r7, ptr_red_str
	CMP r1, #2			; compare to 2 for green
	IT EQ
	LDREQ r7, ptr_green_str
	CMP r1, #3
	IT EQ
	LDREQ r7, ptr_blue_str


	LDR r5, ptr_color_flag	; load the color count
	LDRB r6, [r5]

	CMP r6, #0				; compare color count to zero
	BEQ good_keys

	CMP r4, #DELETE
	ITTTT EQ
	LDREQ r0, ptr_delete_char
	BLEQ output_string
	SUBEQ r6, r6, #1			; sub 1 from color count
	BEQ done_keys

	CMP r4, #BACKSPACE
	ITTTT EQ
	LDREQ r0, ptr_delete_char
	BLEQ output_string
	SUBEQ r6, r6, #1			; sub 1 from color count
	BEQ done_keys

good_keys:
	CMP r6, #3
	BEQ done_keys

	CMP r4, #ZERO_CHAR
	IT LT
	BLT done_keys

	CMP r4, #NINE_CHAR
	IT GT
	BGT done_keys

	STRB r4, [r7, r6] 		; store the user input string with the count offset

	MOV r0, r4				; show the user input string
	BL output_character

	ADD r6, r6, #1				; add one to color count

done_keys:
	STRB r6, [r5]				; store color count to mem
	MOV r4, #0x0				; clear user input
	LDR r5, ptr_usr_input
	STRB r4, [r5]
	POP {r4-r12, lr}
	MOV pc, lr


; *****************************************
	; 	CLEAR SCREEN						; testing this
clear_screen:
	PUSH {r4, lr}   						; Preserve registers to adhere to the AAPCS

	LDR r0, ptr_curs_home
	BL output_string
	LDR r0, ptr_clr_screen
    BL output_string

    POP {r4, lr}
	MOV pc, lr

; **************** COLOR WHEEL
color_wheel:
	PUSH {r4-r8, lr}

	LDR r0, ptr_int_spd
	LDR r0, [r0]
	BL timer_interrupt_init 	; initialize timer *** VERIFY THIS ... TESTING

	; Vars
	LDR r4, ptr_usr_input
	MOV r5, #0
	LDR r6, ptr_wheel_flag

	; Clear user input and screen
	STRB r5, [r4]				; clear and store the user input ... zero
	BL clear_screen				; clear the screen

	; set up the pwms
	; disable the pwm generators
	MOV r0, #pwmenablegen2
	MOV r1, #0
	BL enable_pwm_out
	MOV r0, #pwmenablegen3
	MOV r1, #0
	BL enable_pwm_out

	; reset the clock divisor ... need to do this with blinky too
	; divide by 16
	MOV r0, #3
	BL config_pwm_clock_div

	; reset the load ... need to do this with blinky too
	; load is 100
	; set the load value
	; PWM GEN 2
	MOV r0, #pwm2load
	MOV r1, #0x64
	BL set_pwm_load
	; PWM GEN 3
	MOV r0, #pwm3load
	MOV r1, #0x64
	BL set_pwm_load

	MOV r4, #99
	LDR r5, ptr_red_duty
	STR r4, [r5]

	MOV r4, #0
	LDR r5, ptr_green_duty
	STR r4, [r5]

	MOV r4, #0
	LDR r5, ptr_blue_duty
	STR r4, [r5]

	; start:	 			red: 100%		green: 0%		blue: 0%
red_start:
	; now load the red duty
	MOV r1, #99
	MOV r0, #pwm2cmpb
	LDR r2, ptr_red_duty
	STR r1, [r2]
	BL set_pwm_compare
red_yellow:
	; first load the green duty vale and compare to 99
	LDR r3, ptr_green_duty
	LDR r1, [r3]
	CMP r1, #99
	BEQ yellow_green			; if 100 then branch to next segment
	; else load the green compare value here
	ADD r2, r1, #1
	STR r2, [r3]
	MOV r0, #pwm3cmpb
	BL set_pwm_compare
	; connect PWM2
	MOV r0, #pwm5en
	MOV r1, #5					; we want to connect red (1) and green (4)
	BL connect_pwm_out
	; enable red gen
	MOV r1, #1
	MOV r0, #pwmenablegen2
	BL enable_pwm_out
	; enable green gen
	MOV r1, #1
	MOV r0, #pwmenablegen3
	BL enable_pwm_out
wait_red_yellow:
	; use a flag and the interrupt timer
	LDRB r7, [r6]
	CMP r7, #1
	ITTT EQ
	MOVEQ r7, #0
	STRBEQ r7, [r6]
	BEQ red_yellow
	B wait_red_yellow

	; transition to:	 	red: 100%		green: 100%		blue: 0%
yellow_green:
	; first load the red duty vale and compare to 1
	LDR r3, ptr_red_duty
	LDR r1, [r3]
	CMP r1, #1
	BEQ green_cyan			; if 0 then branch to next segment
	; else load the red compare value here
	SUB r2, r1, #1
	STR r2, [r3]
	MOV r0, #pwm2cmpb
	BL set_pwm_compare
	; connect PWM2
	MOV r0, #pwm5en
	MOV r1, #5					; we want to connect red (1) and green (4)
	BL connect_pwm_out
	; enable red gen
	MOV r1, #1
	MOV r0, #pwmenablegen2
	BL enable_pwm_out
	; enable green gen
	MOV r1, #1
	MOV r0, #pwmenablegen3
	BL enable_pwm_out
wait_yellow_green:
	; use a flag and the interrupt timer
	LDRB r7, [r6]
	CMP r7, #1
	ITTT EQ
	MOVEQ r7, #0
	STRBEQ r7, [r6]
	BEQ yellow_green
	B wait_yellow_green

	; transition to:	 	red: 0%			green: 100%		blue: 0%
green_cyan:
	; first load the blue duty vale and compare to 99
	LDR r3, ptr_blue_duty
	LDR r1, [r3]
	CMP r1, #99
	BEQ cyan_blue			; if 100 then branch to next segment
	; else load the blue compare value here
	ADD r2, r1, #1
	STR r2, [r3]
	MOV r0, #pwm3cmpa
	BL set_pwm_compare
	; connect PWM2
	MOV r0, #pwm5en
	MOV r1, #6					; we want to connect blue (2) and green (4)
	BL connect_pwm_out
	; enable red gen
	MOV r1, #0
	MOV r0, #pwmenablegen2
	BL enable_pwm_out
	; enable green gen
	MOV r1, #1
	MOV r0, #pwmenablegen3
	BL enable_pwm_out
wait_green_cyan:
	; use a flag and the interrupt timer
	LDRB r7, [r6]
	CMP r7, #1
	ITTT EQ
	MOVEQ r7, #0
	STRBEQ r7, [r6]
	BEQ green_cyan
	B wait_green_cyan
	; transition to:	 	red: 0%			green: 100%		blue: 100%
cyan_blue:
	; first load the blue duty vale and compare to 1
	LDR r3, ptr_green_duty
	LDR r1, [r3]
	CMP r1, #1
	BEQ blue_purple			; if 100 then branch to next segment
	; else load the blue compare value here
	SUB r2, r1, #1
	STR r2, [r3]
	MOV r0, #pwm3cmpb
	BL set_pwm_compare
	; connect PWM2
	MOV r0, #pwm5en
	MOV r1, #6					; we want to connect blue (2) and green (4)
	BL connect_pwm_out
	; enable red gen
	MOV r1, #0
	MOV r0, #pwmenablegen2
	BL enable_pwm_out
	; enable green gen
	MOV r1, #1
	MOV r0, #pwmenablegen3
	BL enable_pwm_out
wait_cyan_blue:
	; use a flag and the interrupt timer
	LDRB r7, [r6]
	CMP r7, #1
	ITTT EQ
	MOVEQ r7, #0
	STRBEQ r7, [r6]
	BEQ cyan_blue
	B wait_cyan_blue
	; transition to:	 	red: 0%			green: 0%		blue: 100%
blue_purple:
	; first load the red duty vale and compare to 99
	LDR r3, ptr_red_duty
	LDR r1, [r3]
	CMP r1, #99
	BEQ purple_red			; if 100 then branch to next segment
	; else load the blue compare value here
	ADD r2, r1, #1
	STR r2, [r3]
	MOV r0, #pwm2cmpb
	BL set_pwm_compare
	; connect PWM2
	MOV r0, #pwm5en
	MOV r1, #3					; we want to connect red (1) and blue (2)
	BL connect_pwm_out
	; enable red gen
	MOV r1, #1
	MOV r0, #pwmenablegen2
	BL enable_pwm_out
	; enable green gen
	MOV r1, #1
	MOV r0, #pwmenablegen3
	BL enable_pwm_out
wait_blue_purple:
	; use a flag and the interrupt timer
	LDRB r7, [r6]
	CMP r7, #1
	ITTT EQ
	MOVEQ r7, #0
	STRBEQ r7, [r6]
	BEQ blue_purple
	B wait_blue_purple

	; transition to:	 	red: 100%		green: 0%		blue: 100%

	; back to:	 			red: 100%		green: 0%		blue: 0%
purple_red:
	; first load the blue duty vale and compare to 1
	LDR r3, ptr_blue_duty
	LDR r1, [r3]
	CMP r1, #1
	BEQ red_yellow			; if 100 then branch to next segment
	; else load the blue compare value here
	SUB r2, r1, #1
	STR r2, [r3]
	MOV r0, #pwm3cmpa
	BL set_pwm_compare
	; connect PWM2
	MOV r0, #pwm5en
	MOV r1, #3					; we want to connect red (1) and blue (2)
	BL connect_pwm_out
	; enable red gen
	MOV r1, #1
	MOV r0, #pwmenablegen2
	BL enable_pwm_out
	; enable green gen
	MOV r1, #1
	MOV r0, #pwmenablegen3
	BL enable_pwm_out
wait_purple_red:
	; use a flag and the interrupt timer
	LDRB r7, [r6]
	CMP r7, #1
	ITTT EQ
	MOVEQ r7, #0
	STRBEQ r7, [r6]
	BEQ purple_red
	B wait_purple_red
	POP {r4-r8, lr}
	MOV pc, lr

; *********** UART0 HANDLER ************ ;

UART0_Handler:

; lecture says r0-r3, r12, pc and lr are all preserved automatically within handler
	PUSH {r4-r7}

; clear interrupt
	LDR r4, base_UART0						; store base address for UART0 into r0
	LDR r5, [r4, #UARTICR] 					; load what's in uarticr
	ORR r5, r5, #0x10 						; set pin 4 to clear interrupt
	STR r5, [r4, #UARTICR]					; set the pins in memory

	; Load User Input Address
	LDR r6, ptr_usr_input					; load the ptr to user input into r6

; r0: contains char that user entered
; r4: contains base address for UART0
	;LDR r1, base_UART0
	LDRB r0, [r4] 							; grab the char from UART0 and place into r0 (?)

; Set User Input
	STRB r0, [r6]							; store the char into address at ptr_usr_in

done_UART:
	POP {r4-r7}
	BX lr       	; Return

; ****************************** TIMER HANDLER *******************************;
Timer_Handler:
	PUSH {r4-r11}

	; clear interrupt
	LDR r4, base_timer_0					; store base address for UART0 into r0
	LDR r5, [r4, #GPTMICR] 					; load what's in uarticr
	ORR r5, r5, #0x1 						; set pin 0 to clear interrupt
	STR r5, [r4, #GPTMICR]					; set the pins in memory

	LDR r4, ptr_wheel_flag
	MOV r5, #1
	STRB r5, [r4]

	POP {r4-r11}
	BX lr       	; Return

	.end
