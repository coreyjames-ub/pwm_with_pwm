	.data
; DATA SECTION

; Hertz
clock_Hz: 						.word 0x00F42400 	; 16,000,000
hundred_Hz:						.word 0x00000640 	; 1,600
red_duty:						.word 0x00
green_duty:						.word 0x00
blue_duty:						.word 0x00
big_count:						.word 0x00
half_sec:						.word 0x00001388

; VARS
cycle_count:		.byte 0x00
usr_input:			.byte 0x00
color_flag:			.byte 0x00
blink_flag:			.byte 0x00

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
	.global output_string
	.global pwm_with_pwm_init
	.global pwm_with_pwm_project
	.global output_string
	.global output_character
	.global RGB_init
	.global illuminate_RGB_LED
	.global timer_interrupt_init
	.global Timer_Handler
	.global fpu_init
	.global str2float
	.global init_pwm_rgp

; PTRS
ptr_hundred_Hz:			.word hundred_Hz
ptr_cycle_count:		.word cycle_count
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
ptr_clock_Hz: 			.word clock_Hz
ptr_red_duty:			.word red_duty
ptr_green_duty:			.word green_duty
ptr_blue_duty:			.word blue_duty
ptr_red_str:			.word red_str
ptr_blue_str:			.word blue_str
ptr_green_str:			.word green_str
ptr_big_count:			.word big_count
ptr_blink_flag:			.word blink_flag
ptr_half_sec:			.word half_sec

; BASE ADDR
base_UART0:						.word 0x4000C000
base_timer_0:					.word 0x40030000
base_gpio_F: 					.word 0x40025000


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




; PWM INIT
pwm_with_pwm_init:
	PUSH {r4-r6, lr}

	BL uart_init
	BL uart_interrupt_init
	BL init_pwm_rgp

	MOV r5, #0
my_loop:
	CMP r5, #1
	BNE my_loop




	BL fpu_init
	; set interrupt timer to 1600
	LDR r0, ptr_hundred_Hz
	LDR r0, [r0]
	BL timer_interrupt_init 	; initialize timer

	POP {r4-r6, lr}
	MOV pc, lr


; PWM PROJ
pwm_with_pwm_project:
	PUSH {r4-r12, lr}

	; BASE ADDRESS FOR USER INPUT IS IN R4
	LDR r4, ptr_usr_input					; base address to user input in R4
	MOV r5, #0								; Mutable Data
	MOV r6, #0								; keep zero in r6
	LDR r7, ptr_big_count					; base addres to BIG COUNT
	MOV r8, #0								; base address for color strings
	LDR r9, ptr_color_flag					; color count flag
	LDR r10, ptr_half_sec
	LDR r10, [r10]							; half sec VALUE
	LDR r11, ptr_blink_flag					; ptr to blink flag
	LDR r12, ptr_cycle_count				; pointer to cycle count

main_menu:

	; TURN OFF RGB LED
	MOV r0, #0x0			; clear the rgb led
	BL illuminate_RGB_LED	; turn it off

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
	B wait_main					; LOOP

blinky:

	; Clear user input and screen
	STRB r6, [r4]				; store the user input
	BL clear_screen				; clear the screen

	; CLEAR BIG COUNT ... SET BLINK FLAG ... TURN ON LED
	STR r6, [r7]				; store zero in big count
	MOV r0, #1					; move 1 into r0
	STRB r0, [r11]				; store 1 into blink flag
	MOV r0, #2					; turn rgb led to red
	BL illuminate_RGB_LED

	; SHOW THE BLINKY PROMPT
	LDR r0, ptr_exit_blinky_mode
	BL output_string

wait_blinky:
	LDRB r5, [r4]				; load user input
	CMP r5, #LETTER_M			; compare it to the letter m
	BEQ main_menu				; go back to main menu if equal
	LDR r5, [r7]				; load the big count
	CMP r5, r10			; compare big count to half a sec
	BGE blink_light				; if equal branch to blink light
	B wait_blinky				; else loop blinky again

blink_light:
	LDRB r5, [r11]				; look at blink flag
	CMP r5, #0
	BEQ blink_on
	MOV r0, #0
	BL illuminate_RGB_LED
	STRB r6, [r11]				; clear the Blink flag
	STR r6, [r7]				; clear big count
	B wait_blinky

blink_on:
	MOV r0, #2					; turn the led red
	BL illuminate_RGB_LED
	MOV r0, #1					; set blink flag to a 1
	STRB r0, [r11]
	STR r6, [r7]				; clear big count
	B wait_blinky

advanced_rgb_led:

	; Clear user input, color flag, and screen
	STRB r6, [r4]				; store the user input
	STRB r6, [r9]					; clear color flag
	BL clear_screen				; clear the screen

	; Turn off RGB
	MOV r0, #0x0			; clear the rgb led
	BL illuminate_RGB_LED	; turn it off

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
	BGT show_keys			; use show_keys sub_routine				3
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
	BGT show_keys			; use show_keys sub_routine				3
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
	BGT show_keys			; use show_keys sub_routine				3
	B blue_wait				; start loop again

adv_rgb_prep:
	STRB r6, [r4]				; clear the user input
	BL clear_screen
	LDR r8, ptr_blue_str
	LDRB r0, [r9]					; load color flag count into r0
	STRB r6, [r8, r0]				; null terminate green str
	STRB r6, [r9]					; clear color flag

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

	; prep everything and make sure we are reset and ready to count

	LDR r0, ptr_big_count
	STR r6, [r7]				; clear cycle count


	; do str to float for each color
	; do math for each color and set them value / 255 * 100 = round it ... integer it ... store it
	; now loop
adv_rgb_loop:
	LDRB r5, [r4]					; load user input
	CMP r5, #LETTER_C					; compare to space
	BEQ advanced_rgb_led
	CMP r5, #LETTER_M
	BEQ main_menu
	BL set_adv_rgb
	B adv_rgb_loop

done_proj:
	POP {r4-r12,lr}
	MOV pc, lr

; ************************* ADV RGB SUB ROUTINE *************************
; ARGS:				N/A
; RETURN VAL:		N/A
; ***********************************************************************
set_adv_rgb:
	PUSH {r4-r12, lr}

	MOV r6, #0

	LDR r4, ptr_big_count
	LDR r5, [r4]				; load cyle count into r5
	ADD r5, r5, #1				; add 1 to cycle count
	CMP r5, #100				; compare to 100
	IT EQ						; if its equal store zero to cycle count
	STRBEQ r6, [r4]

	LDR r7, ptr_red_duty
	LDRB r8, [r7]				; get the red duty val in r8
	CMP r8, r5
	IT GE
	ADDGE r6, r6, #2

	LDR r7, ptr_green_duty
	LDR r8, [r7]				; get the green duty val in r8
	CMP r8, r5
	IT GE
	ADDGE r6, r6, #8

	LDR r7, ptr_blue_duty
	LDR r8, [r7]				; get the blue duty val in r11
	CMP r8, r5
	IT GE
	ADDGE r6, r6, #4

	MOV r0, r6
	BL illuminate_RGB_LED

	POP {r4-r12, lr}
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

; *********** TIMER HANDLER ************                                           ************* COREY ***********

Timer_Handler:
; lecture says r0-r3, r12, pc and lr are all preserved automatically within handler
	PUSH {r4-r11}

; clear interrupt
	LDR r4, base_timer_0					; Load the base address to general purpose timer
	MOV r5, #0x1 						; set pin 0 to clear interrupt
	STR r5, [r4, #GPTMICR]					; set the pins in memory

	; load big count and increment
	LDR r6, ptr_big_count
	LDR r7, [r6]
	ADD r7, r7, #1
	STR r7, [r6]

exit_timer:
	POP {r4-r11}
	BX lr       	; Return


	.end


	; cool math that i dont need anymore
	; get clock hz ... 16MHz per second ... s3 as a float
	;LDR r0, ptr_clock_Hz			; load pointer to clock HZ
	;LDR r0, [r0]				; load actual 16MHz
	;VMOV s3, r0					; move the clock hz into s3
	;VCVT.F32.S32 s3, s3			; converts from integer to float
	; I need 100 in s1
;	MOV r1, #100				; move 100 into r1
;	VMOV s1, r1					; move 100 into s1 ... float!
;	VCVT.F32.S32 s1, s1			; converts from integer to float
;	; I need the percent value in s0
;	MOV r0, #50					; move 50 into r0 ... bc we want red 50 % of the time ... 1/2 a second
;	VMOV s0, r0					; move 50 into s0 ... float!
;	VCVT.F32.S32 s0, s0			; converts from integer to float
;	VDIV.F32 s0, s0, s1			; divide percent in s0 by 100 in s1
;	; Multiply the percent now as decimal by the clock hz ... then convert to 32 bit int ... then vmov it into core reg
;	VMUL.F32 s0, s0, s3
;	VCVTR.S32.F32 s0, s0				; convert from float to int
;	VMOV r0, s0							; move from float reg to core reg
;
;	BL timer_interrupt_init 	; initialize timer
