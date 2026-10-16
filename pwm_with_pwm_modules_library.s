	.text
	.global uart_init
	.global ALICE_KEYPAD_init
	.global gpio_interrupt_init
	.global output_string
	.global uart_interrupt_init
	.global output_character
	.global RGB_init
	.global illuminate_RGB_LED
	.global timer_interrupt_init
	.global fpu_init
	.global str2float
	.global init_pwm_rgp
	.global enable_pwm_out
	.global connect_pwm_out
	.global set_pwm_load
	.global set_pwm_compare

;BASE
base_clock: 		.word 0x400FE000
base_gpio_D: 		.word 0x40007000
base_gpio_A: 		.word 0x40004000
base_EN0:			.word 0xE000E000
base_UART0: 		.word 0x4000C000
base_gpio_F: 		.word 0x40025000
base_fpu:			.word 0xE000E000
base_timer_0: 		.word 0x40030000
base_rcgcpwm:					.word 0x400FE000
base_pwm_1:						.word 0x40029000

;OFFSETS
enable_UART:		.equ 0x618
PRUART: 			.equ 0xA18
enable_GPIO: 		.equ 0x608
PRGPIO: 			.equ 0xA08
GPIODIR: 			.equ 0x400
GPIODEN: 			.equ 0x51C
GPIOIS: 			.equ 0x404
GPIOIBE:			.equ 0x408
GPIOIV:				.equ 0x40C
GPIOIM:				.equ 0x410
EN0: 				.equ 0x100
U0FR: 				.equ 0x018
UARTCTL:			.equ 0x030
UARTIBRD:			.equ 0x024
UARTFBRD:			.equ 0x028
UARTLCRH: 			.equ 0x02C
UARTCC:				.equ 0xFC8
GPIOPCTL:			.equ 0x52C
UARTIM: 			.equ 0x038
GPIODATA:   		.equ 0x3FC
enable_timer: 		.equ 0x604
PRTIMER: 			.equ 0xA04
GPTMCTL: 			.equ 0x00C
GPTMCFG: 			.equ 0x000
GPTMTAMR: 			.equ 0x004
GPTMTAILR:			.equ 0x028
GPTMIMR: 			.equ 0x018
GPTMICR: 			.equ 0x024
CPACR:				.equ 0xD88
GPIOAFSEL:			.equ 0x420
pwm_clock_gating:	.equ 0x640
pwm2genb:			.equ 0xE4
pwm3gena:			.equ 0x120
pwm3genb:			.equ 0x124
pwm2load:			.equ 0x0D0
pwm3load:			.equ 0x110
pwm2cmpb:			.equ 0x0DC
pwm3cmpb:			.equ 0x11C
pwm3cmpa:			.equ 0x118
pwm5en:				.equ 0x8
pwmenablegen2:		.equ 0x0C0
pwmenablegen3:		.equ 0x100
rcc_offset:			.equ 0x60

hundred:			.equ 0xFFFF
fifty:				.equ 0x7FFF

; ****************************************************** INIT PWM FOR RGB *************************************************************

init_pwm_rgp:
	PUSH {r4-r10,lr}			; Spill registers to stack

	; enable gpio port f with pwm
	; connect clock to GPIO
	MOV r0, #enable_GPIO				; module offset
	MOV r1, #0x20						; port bit is Port F
	BL enable_module_clock

	; check prgpio to see if gpio ports are ready
	MOV r0, #PRGPIO
	MOV r1, #0x20
	BL check_peripheral_ready

	; select gpio port for alt func
	LDR r0, base_gpio_F			; setting up r0 with base address for gpio f
	MOV r1, #0xE				; pins 1-3
	BL enable_gpioafsel

	; set pwm as alt func via GPIO Port Control
	LDR r0, base_gpio_F
	MOVW r1, #0x5550			; funtion is 5 for pwm
	BL select_alt_func

	; set gpio pins 1-3 as digital
	LDR r0, base_gpio_F			; store base address for port F into r0
	MOV r1, #0xE  			; 0xE = 1110, masking for bits 1-3
	BL set_gpio_pins_digital

	; connect clock to pwm
	MOV r0, #0x2					; or it with 2 to enable PWM MODULE 1
	BL enable_pwm_clock_gpio

	; use the pwm clock divisor ... set both the usepwmdiv and the pwmdiv amount
	MOV r0, #1
	BL set_pwm_clock_div
	MOV r0, #7
	BL config_pwm_clock_div

	; configure pwm generator
	; set action for when counter reaches zero ....drive low for compare ... drive high for zero
	; PF1 ... 	M1PWM5 ... PWM2GENB
	MOV r0, #pwm2genb
	MOV r1, #0x800
	MOV r2, #3
	BL config_pwm_gen
	; PF2 ... M1PWM6 ... PWM3GENA
	MOV r0, #pwm3gena
	MOV r1, #0x80
	MOV r2, #3
	BL config_pwm_gen
	; PF3 ... M1PWM7 ... PWM3GENB
	MOV r0, #pwm3genb
	MOV r1, #0x800
	MOV r2, #3
	BL config_pwm_gen

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
	MOV r1, #0x7
	BL connect_pwm_out

	; pwm enable enable
	; Gen 2
	MOV r0, #pwmenablegen2
	MOV r1, #0
	BL enable_pwm_out
	; Gen 3
	MOV r0, #pwmenablegen3
	MOV r1, #0
	BL enable_pwm_out

	POP {r4-r10,lr}  			; Restore registers from stack
	MOV pc, lr

; ******************************************************   STR2FLOAT   ********************************************************************************
; args		r0: str_addr
; return	r0: float_num		r1: str_addr
; comments	args: r0 str_addr	 return r0: float_num / r1: str_addr
; ******************************************************************************************************************************************************

str2float:
	PUSH {r4-r10,lr}			; Spill registers to stack

; r0: base address of string version of number
; r4: copy of r0

; r6: divde by num
; r7: whole number
; r8: decimal number
; r9: temp num
; r10: i need 10
; s2 will be whole num val
; s3 will be decimal num val
; s4 will be power of 10 to divide by

	MOV r4, r0					; copy base addr of num str to r4
	MOV r5, #0					; clear r5, it will hold the str
	MOV r6, #1					; divde by num
	MOV r7, #0					; clear whole num r7
	MOV r8, #0					; clear decimal num r8
	MOV r9, #0					; temp num
	MOV r10, #10				; i need a ten

	VMOV s2, r7					; s2 will be whole num val
	VMOV s3, r7					; s3 will be decimal num val
	VMOV s4, r7					; s4 will be power of 10 to divide by

float_whole_loop:
	LDRB r5, [r4], #1			; load char at r4 into r2 and post increment
	CMP r5, #0x2E				; is r2 a decimal sign (.)?
	BEQ make_decimal_loop 		; make decimal loop
	CMP r5, #0x30				; if its less than 30 then its not a number
	BLT float_done				; we are done
	CMP r5, #0x39				; if its greater than 39 then its not a number
	BGT float_done				; we are done
	SUB r9, r5, #0x30				; get the num val into r9 (temp num)
	MUL r7, r7, r10 			; mult whole number by 10
	ADD r7, r7, r9  			; add temp num to whole number
	B float_whole_loop

make_decimal_loop:
	LDRB r5, [r4], #1			; load char from r4 into r2 and post increment
	CMP r5, #0x30				; if its less than 30 then its not a number
	BLT decimal_done			; we are done with decimal bit
	CMP r5, #0x39				; if its greater than 39 then its not a number
	BGT decimal_done			; we are done with decimal bit
	SUB r9, r5, #0x30				; get the num val into r9 (temp num)
	MUL r8, r8, r10				; mult whole number by 10
	ADD r8, r8, r9				; add temp num to whole number
	MUL r6, r6, r10				; multiply power of 10 by 10 (starting at 1)
	B make_decimal_loop

decimal_done:
	VMOV s4, r6					; move int from core reg to fpu reg for power of 10
	VCVT.F32.S32 s4, s4			; converts from integer to float
	VMOV s3, r8					; move int from core reg to fpu reg for decimal num
	VCVT.F32.S32 s3, s3			; converts from integer to float
	VDIV.F32 s3, s3, s4			; divide decimal num / by power of 10

float_done:
	VMOV s2, r7					; move int from core reg to fpu reg for whole num
	VCVT.F32.S32 s2, s2			; converts from integer to float
	VADD.F32 s2, s2, s3			; add whole number to decimal number
	VMOV r0, s2					; move float into r0

	MOV r1, r4
	SUB r1, r1, #1 				; move base address back one
	POP {r4-r10,lr}  			; Restore registers from stack
	MOV pc, lr
; ****************************************************************** ;


; ************************* FPU_INIT ***************************** ;
fpu_init:
	PUSH {r4-r12,lr}			; Spill registers to stack

	LDR r0, base_fpu			; Load base fpu into r0
	LDR r1, [r0, #CPACR]		; Load CPACR offset

	MOV r2, #0xF				; Load 0xF into r2
	ORR r1, r1, r2, LSL #20		; Set bits 20-23 to enable CP10 and CP11 coprocessors

	STR r1, [r0, #CPACR]		; store the enabled cp10 and cp11 coprocessors back to cpacr

	DSB							; ensures that outstanding memory transactions complete before subsequent instructions execute
	ISB							;ensures that the effect of all completed memory transactions is recognizable by subsequent instructions

	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr
; **************************************************************** ;

; ************************* TIMER_INTERRUPT_INIT ***************************** ;
; ARG - r0: interval
timer_interrupt_init:
	PUSH {r4-r12, lr}

	MOV r4, r0							; take arg and store in unused reg

	; enable clock for Timer
	MOV r0, #enable_timer 				; arg1: module offset
	MOV r1, #0x1						; arg2: port bit
	BL enable_module_clock
	; check prgpio to see if gpio ports are ready
	MOV r0, #PRTIMER
	MOV r1, #0x1
	BL check_peripheral_ready

; disable the general purpose timer control register
	LDR r0, base_timer_0			; load base timer 0 address
	LDR r1, [r0, #GPTMCTL] 			; load offset to control register
	BIC r1, #0x1					; Clear bit 0 to disable
	STR r1, [r0, #GPTMCTL]			; store back

; set timer to 32 bit mode
	LDR r1, [r0, #GPTMCFG] 			; load offset to timer configuration register
	BIC r1, r1, #0x7				; Clear bits 0-2 to set configuration 0
	STR r1, [r0, #GPTMCFG]			; store back

; set timer to periodic mode
	LDR r1, [r0, #GPTMTAMR] 		; load offset to Timer A mode register
	ORR r1, r1, #0x2				; Set bit 2 for periodic
	STR r1, [r0, #GPTMTAMR]			; store back

; set timer interval														********** COREY ****************
	STR r4, [r0, #GPTMTAILR]		; store back

; enable timer to interrupt processor
	LDR r1, [r0, #GPTMIMR] 			; load offset to Timer A mode register
	ORR r1, r1, #0x1				; write 1 to enable interrupt
	STR r1, [r0, #GPTMIMR]			; store back

; set bit 19 to interrupt 0-31 set enable register
	LDR r0, base_EN0				; load base ENO into register
	LDR r1, [r0, #EN0] 				; load offset to general purpose timer configuration register
	MOV r4, #0x1						; load a 1 into r4
	BFI r1, r4, #19, #1				; grab 1 bit from r4, which is #1, and insert it into bit 30 in r1
	STR r1, [r0, #EN0]				; store back

; enable the general purpose timer control register
	LDR r0, base_timer_0			; load base timer 0 address
	LDR r1, [r0, #GPTMCTL] 			; load offset to control register
	ORR r1, r1, #0x1					; Clear bit 0 to disable
	STR r1, [r0, #GPTMCTL]			; store back

	POP {r4-r12, lr}
	MOV pc, lr

; ************ TIVA RGB INIT ************ ;

RGB_init:
	PUSH {r4-r12,lr}			; Spill registers to stack

	; SET UP PORT F fro TIVA RGB ... 0x20

	; enable clock for port F gpio
	MOV r0, #enable_GPIO 				; arg1: module offset
	MOV r1, #0x20						; arg2: port bit
	BL enable_module_clock
	; check prgpio to see if gpio ports are ready
	MOV r0, #PRGPIO
	MOV r1, #0x20
	BL check_peripheral_ready

	; set gpio dir for pins 1-3 as output
    LDR r4, base_gpio_F			; store base address for port F into r0
	LDR r5, [r4, #GPIODIR] 		; load what's in gpiodir
	ORR r5, r5, #0xE 			; set pins 1-3 to output (1)
	STR r5, [r4, #GPIODIR]		; set the pins in memory

; set gpio pins 1-3 as digital
	LDR r5, [r4, #GPIODEN] 		; offset the port F base address with GPIODEN
	ORR r5, r5, #0xE  			; 0xE = 1110, masking for bits 1-3
	STR r5, [r4, #GPIODEN] 		; store activated bits back in gpioden memory

	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr

; ************************* ILLUMINATE_RGB_LED ***************************** ;

illuminate_RGB_LED:
	PUSH {r4-r12,lr}			; Spill registers to stack

    MOV r4, r0 					; keep color in r4

    LDR r5, base_gpio_F			; store port F in r0

	LDR r6, [r5, #GPIODATA] 	; pull in the port F data register
	BIC r6, #0xE 				; clear the data register's bits 1-3
	ORR r6, r6, r4 				; mask register with color
	STR r6, [r5, #GPIODATA] 	; store color into port F

	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr

; ************************* OUTPUT_CHARACTER ***************************** ;
;	Args: 			r0: char
; 	Return Val:		N/A
output_character:
	PUSH {r4-r6,lr}			; Spill registers to stack

	MOV r4, r0				; mov the char from r0 into r7
	LDR r5, base_UART0		; set base address for

; r4: contains value at flag register in memory
; r5: value of TxFF
transmit_loop:
	LDRB r6, [r5, #U0FR] 		; copy the flag register into r4
	AND r6, r6, #0x0020 		; mask out bit 5 of the flag (TxFF)
	CMP r6, #0x0020 			; see if TxFF == 1
	BEQ transmit_loop 			; transmit isn't done yet, reloop
	STRB r4, [r5] 				; send the char in r0 to UART0 (?)

	POP {r4-r6,lr}  			; Restore registers from stack
	MOV pc, lr

; ************************* OUTPUT_STRING ***************************** ;

output_string:
	PUSH {r4,lr}			; Spill registers to stack

    MOV r4, r0					; copy address in r0 into r4
output_string_loop:
	LDRB r0, [r4], #1			; load a character from the address in r4 to r0 and increment r4 pointer
	CMP r0, #0x0 				; does r0 = null?
	BEQ done_output 			; finish sending characters
	BL output_character 		; send the stored character in r0 to putty
	B output_string_loop 		; send the next char

done_output:
	POP {r4,lr}  			; Restore registers from stack
	mov pc, lr

; ************************* GPIO_INTERRUPT_INIT ***************************** ;

gpio_interrupt_init:

	PUSH {r4-r12, lr}

	; Load base address for GPIO Port D into r0
	LDR r4, base_gpio_D		; load base addres for GPIO Port D into r0

	; SET EDGE SENSITIVITY
	LDR r5, [r4, #GPIOIS] 		; use Address Indexing to load GPIOS offset into r1
	BIC r5, #0xF				; Clear bit 3 to set the pin to be Edge Sensitive
	STR r5, [r4, #GPIOIS]		; store GPIOIS back into mermory

	; Select Single Edge Triggering
	LDR r5, [r4, #GPIOIBE]		; use address idx'ing to load GPIOIBE offset into r1
	BIC r5, #0xF				; Clear bit 3 to set the pin to allow GPIOEV reg to control pin
	STR r5, [r4, #GPIOIBE]		; store GPIOIBE back into memory

	; Select Rising Edge for Interrupt
	LDR r5, [r4, #GPIOIV]		; use address idx'ing to load GPIOIV offset into r1
	ORR r5, r5, #0xF			; Set bit 3 to trigger rising edge
	STR r5, [r4, #GPIOIV]		; store GPIOIV back into memory

	; Enable the Interrupt
	LDR r5, [r4, #GPIOIM]		; use address idx'ing to load GPIOIM into r1
	ORR r5, r5, #0xF			; set bit 3 to 1 using or to enable  interrupt
	STR r5, [r4, #GPIOIM]		; store GPIOIM	back into memory

	; Config Processsor to Allow GPIO Port D to interrupt processor
	LDR r4, base_EN0			; store base address for EN0 into r4
	LDR r5, [r4, #EN0] 			; load what's in EN0
	ORR r5, r5, #0x8 			; set pin 3 to initialize enable register
	STR r5, [r4, #EN0]			; set the pins in memory

	POP {r4-r12, lr}
	MOV pc, lr

; ************ ALICE_KEYPAD_INIT ************ ;

ALICE_KEYPAD_init:
	PUSH {r4-r6,lr}					; Spill registers to stack

; SET UP PORT A

	; enable clock for port A gpio
	MOV r0, #enable_GPIO 				; arg1: module offset
	MOV r1, #0x1						; arg2: port bit
	BL enable_module_clock
	; check prgpio to see if gpio ports are ready
	MOV r0, #PRGPIO
	MOV r1, #0x1
	BL check_peripheral_ready

	; CLEARING GPIO PIN DIRECTION AS OUTPUT ... WRITE 1 ... FOR PORT A
	LDR r4, base_gpio_A					; load all 32-bits of base gpio A into r4
	LDR r5, [r4, #GPIODIR]				; LOADING THE GPIO DIR ADDR IN R1
	ORR r5, r5, #0x3C						; NOW IM SETTING BITs 2 - 5, 0011 1100
	STR r5, [r4, #GPIODIR]				; STORING IT BACK INTO MEM

	; Config GPIOAFSEL for PORT A
	LDR r5, [r4, #GPIOAFSEL]
	BIC r5, r5, #0x3C
	STR r5, [r4, #GPIOAFSEL]

	; SETTING GPIO PIN AS DIGITAL for PORT A
	LDR r5, [r4, #GPIODEN]
	ORR r5, r5, #0x3C					; set at bits 2 - 5
	STR r5, [r4, #GPIODEN]				; STORE IT BACK INTO MEM

	; SET GPIO PORT A2:5 AS HIGH ... 1
	MOV r5, #0x3C
	STRB r5, [r4, #0x0F0]

; SET UP PORT D

	; enable clock for port D gpio
	MOV r0, #enable_GPIO 				; arg1: module offset
	MOV r1, #0x8						; arg2: port bit
	BL enable_module_clock
	; check prgpio to see if gpio ports are ready
	MOV r0, #PRGPIO
	MOV r1, #0x8
	BL check_peripheral_ready

	; SETTING GPIO PIN DIRECTION AS INPUT ... WRITE 0 ... FOR PORT D
	LDR r4, base_gpio_D					; load all 32-bits of base gpio D into r4
	LDR r5, [r4, #GPIODIR]				; LOADING THE GPIO DIR ADDR IN R1
	BIC r5, #0xF						; clear pins 0 - 3
	STR r5, [r4, #GPIODIR]				; STORING IT BACK INTO MEM

	; SETTING GPIO PIN AS DIGITAL for PORT D
	LDR r5, [r4, #GPIODEN]
	ORR r5, r5, #0xF 					; set at bits 0 thru 3
	STR r5, [r4, #GPIODEN]				; STORE IT BACK INTO MEM

	POP {r4-r6, lr}  					; Restore registers from stack
	MOV pc, lr

; ************************* GPIO Port for Alt Func ****************** ;
; ARGS: 			r0: Port Base Address		r1: which pin we want to use
; Return:			N/A
enable_gpioafsel:
	PUSH {r4-r8, lr}

	MOV r4, r0								; move port base address into r4
	MOV r6, r1								; move pin we want into r6
	LDR r5, [r4, #GPIOAFSEL]				; load data from base address with gipafsel offeset
	ORR r5, r5, r6							; we are only going to set Pin 1 for the moment. later we will do 1, 2, and 3 for rgb

	STR r5, [r4, #GPIOAFSEL]				; store the data back

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Select Alt Func ************************** ;
; ARGS: 				r0: Port Base Address 		r1: digital function
; Return:				N/A
select_alt_func:
	PUSH {r4-r8, lr}
	MOV r4, r0					; move port address into r4
	MOV r5, r1					; move pin field into r5
	LDR r7, [r4, #GPIOPCTL]			; store the data
	ORR r7, r7, r5
	STR r7, [r4, #GPIOPCTL]

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Select GPIO Pins Digital ************************** ;
; ARGS: 				r0: Port Base Address 		r1: Pins to Set
; Return:				N/A
set_gpio_pins_digital:
	PUSH {r4-r8, lr}
	MOV r4, r0					; move port address into r4
	MOV r5, r1					; move pin field into r5
	LDR r7, [r4, #GPIODEN]			; store the data
	ORR r7, r7, r5
	STR r7, [r4, #GPIODEN]

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Connect Clock to PWM ************************** ;
; ARGS: 				r0: PWM Moduel
; Return:				N/A
enable_pwm_clock_gpio:
	PUSH {r4-r8, lr}
	MOV r6, r0
	LDR r4, base_rcgcpwm
	LDRB r5, [r4, #pwm_clock_gating]
	ORR r5, r5, r6					; or with the arg from r0
	STRB r5, [r4, #pwm_clock_gating]

	POP {r4-r8, lr}
	MOV pc, lr



; ************************ Set PWM Clock Divisor ************************** ;
; ARGS: 				r0: Pick Divisor 	0: System 	1: PWM Clock Divisor
; Return:				N/A
set_pwm_clock_div:
	PUSH {r4-r8, lr}
	MOV r5, r0
	; use the pwm clock divisor ... set both the usepwmdiv and the pwmdiv amount
	LDR r4, base_rcgcpwm
	LDR r6, [r4, #rcc_offset]				; load data from rcc with usepwmdiv offset
	BFI r6, r5, #20, #1
	STR r6, [r4, #rcc_offset]				; store the data back

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Configure PWM Clock Divisor ************************** ;
; ARGS: 				r0: Divisor Value
; Return:				N/A
config_pwm_clock_div:
	PUSH {r4-r8, lr}
	MOV r5, r0
	; use the pwm clock divisor ... set both the usepwmdiv and the pwmdiv amount
	LDR r4, base_rcgcpwm
	LDR r6, [r4, #rcc_offset]				; load data from rcc with usepwmdiv offset
	BFI r6, r5, #17, #3
	STR r6, [r4, #rcc_offset]				; store the data back

	POP {r4-r8, lr}
	MOV pc, lr



; ************************ Configure PWM Generator ************************** ;
; ARGS: 				r0: Offset		r1: action for counter value reaches zero		r2: action for counter value reaches compare
; Return:				N/A
config_pwm_gen:
	PUSH {r4-r8, lr}
	MOV r6, r0				; move offset into r6
	MOV r7, r1				; move zero action into r7
	MOV r8, r2				; move compare action into r8

	; configure pwm generator
	; set action for when counter reaches zero ....drive low for compare ... drive high for zero
	LDR r4, base_pwm_1
	LDR r5, [r4, r6]
	ORR r5, r5, r1				; drive high *** look into ORR
	ORR r5, r5, r2
	STR r5, [r4, r6]

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Set PWM Load Value ************************** ;
; ARGS: 				r0: Offset		r1: load value
; Return:				N/A
set_pwm_load:
	PUSH {r4-r8, lr}
	MOV r6, r0					; move offset val into r6
	MOV r5, r1					; move load val into r5
	; set the load value
	LDR r4, base_pwm_1
	STRH r5, [r4, r6]

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Set PWM Compare Value ************************** ;
; ARGS: 				r0: Offset		r1: compare value
; Return:				N/A
set_pwm_compare:
	PUSH {r4-r8, lr}
	MOV r6, r0					; move offset val into r6
	MOV r5, r1					; move compare val into r5
	; set the load value
	LDR r4, base_pwm_1
	STRH r5, [r4, r6]

	POP {r4-r8, lr}
	MOV pc, lr


; ************************ Connect PWM Output ************************** ;
; ARGS: 				r0: Offset		r1: output enable bit
; Return:				N/A
connect_pwm_out:
	PUSH {r4-r8, lr}
	MOV r6, r0
	MOV r7, r1
	; connect pwm output ... configure enable
	LDR r4, base_pwm_1
	LDR r5, [r4, r6]
	BFI r5, r7, #5, #3
	STR r5, [r4, r6]

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Enable PWM Output ************************** ;
; ARGS: 				r0: Offset		r1: enable bit
; Return:				N/A
enable_pwm_out:
	PUSH {r4-r8, lr}
	MOV r6, r0
	MOV r7, r1
	; pwm enable enable
	LDR r4, base_pwm_1
	LDR r5, [r4, r6]
	CMP r7, #1
	BEQ set_pwm_out
	BNE clear_pwm_out

set_pwm_out:
	ORR r5, r5, r7
	B store_pwm_out

clear_pwm_out:
	AND r5, r5, #0xE
	B store_pwm_out

store_pwm_out:
	STR r5, [r4, r6]

	POP {r4-r8, lr}
	MOV pc, lr


; ************************ Enable Module Clock *************************** ;
; ARGS:		r0: module offset		r1: port bit
; RETURN: 	N/A
enable_module_clock:
	PUSH {r4-r8, lr}

	MOV r6, r0							; module offset
	MOV r7, r1							; port bit
	LDR r4, base_clock					; clock base address
	LDR r5, [r4, r6]					; load data at base clock with module offset
	ORR r5, r5, r7						; set the port bit
	STR r5, [r4, r6]					; store the value back to base clock with module offset

	POP {r4-r8, lr}
	MOV pc, lr

; ************************ Check Peripheral Ready *********************** ;
; ARGS: 	r0: module offset			r1: port bit
; RETURN:	N/A
check_peripheral_ready:
	PUSH {r4-r8, lr}

	MOV r6, r0							; module offset
	MOV r7, r1							; port bit
	LDR r4, base_clock
periph_not_ready:
	LDR r5, [r4, r6]					; load data base clock with module offset
	AND r5, r5, r7						; mask the contents with port bit
	CMP r5, r7						; is the peripheral ready?
	BNE periph_not_ready

	POP {r4-r8, lr}
	MOV pc, lr

; ************************* UART_INTERRUPT_INIT ***************************** ;

uart_interrupt_init:
	PUSH {r4-r12, lr}

; receive interrupt mask initialization
	LDR r0, base_UART0			; store base address for UART0 into r0
	LDR r1, [r0, #UARTIM] 		; load what's in uartim
	ORR r1, r1, #0x10 			; set pin 4 to initialize interrupt
	STR r1, [r0, #UARTIM]		; set the pins in memory

; interrupt set enable register initialization
	LDR r0, base_EN0			; store base address for EN0 into r0
	LDR r1, [r0, #EN0] 			; load what's in EN0
	ORR r1, r1, #0x20 			; set pin 5 to initialize enable register
	STR r1, [r0, #EN0]			; set the pins in memory

	POP {r4-r12, lr}
	MOV pc, lr

; ************************* UART_INIT ***************************** ;

uart_init:
	PUSH {r4-r12,lr}					; Spill registers to stack

; enable clock for UART0 ... Enable the UART module using the RCGCUART register (see page 344).
    MOV r0, #enable_UART   				; module: enable uart
    MOV r1, #0x1						; port: A
    BL enable_module_clock

; read 1 when clock for uart0 is ready
	MOV r0, #PRUART						; module: PRUART
	MOV r1, #0x1						; port bit: UART Module 0
	BL check_peripheral_ready

; Enable the clock to the appropriate GPIO module via the RCGCGPIO register (see page 340). ... PA0 and PA1 refer to Table 23-5 on page 1351.
	MOV r0, #enable_GPIO				; module: GPIO
	MOV r1, #0x1						; port: A
	BL enable_module_clock

; wait for Peripheral A to be ready
	MOV r0, #PRGPIO						; peripheral: PRGPIO
	MOV r1, #0x1						; port bit: A
	BL check_peripheral_ready

; Set the GPIO AFSEL bits for the appropriate pins (see page 671). To determine which GPIOs to configure, see Table 23-4 on page 1344.
	LDR r4, base_gpio_A
	LDR r5, [r4, #GPIOAFSEL]
	ORR r5, r5, #0x3				; set pins PA[1:0]
	STR r5, [r4, #GPIOAFSEL]

; Set the GPIO PA[1:0] to Digital
	LDR r5, [r4, #GPIODEN]
	ORR r5, r5, #0x3				; set pins PA[1:0]
	STR r5, [r4, #GPIODEN]

; Set the GPIOPCTL ... Configure the PMCn fields in the GPIOPCTL register to assign the UART signals to the appropriate pins (see page 688 and Table 23-5 on page 1351).
	LDR r5, [r4, #GPIOPCTL]
	ORR r5, r5, #0x11				; set port mux for pins 0 and 1
	STR r5, [r4, #GPIOPCTL]

; Disable the UART by clearing the UARTEN bit in the UARTCTL register.
	LDR r4, base_UART0
	LDR r5, [r4, #UARTCTL]
	BIC r5, #0x1
	STR r5, [r4, #UARTCTL]

; Write the integer portion of the BRD to the UARTIBRD register.
	MOV r5, #0x8
	STR r5, [r4, #UARTIBRD]

; Write the fractional portion of the BRD to the UARTFBRD register.
	MOV r5, #0x2C			; should be #44
	STR r5, [r4, #UARTFBRD]

; Write the desired serial parameters to the UARTLCRH register (in this case, a value of 0x0000.0060).
; Use 8-bit word length, 1 stop bit, no parity - (*((volatile uint32_t *)(0x4000C02C))) = 0x60; - Lower bits in r4
	MOV r5, #0x60
	STR r5, [r4, #UARTLCRH]

; Configure the UART clock source by writing to the UARTCC register.
	LDR r5, [r4, #UARTCC]
	BIC r5, #0xF			; clear bits 0:3
	STR r5, [r4, #UARTCC]

; Enable the UART by setting the UARTEN bit in the UARTCTL register.
	LDR r4, base_UART0
	LDR r5, [r4, #UARTCTL]
	ORR r5, r5, #0x1
	STR r5, [r4, #UARTCTL]

	POP {r4-r12,lr}  			; Restore registers from stack
	MOV pc, lr

	.end
