; Xe do line su dung cam bien hong ngoai
;
;Written by: HUYNH DANG KHOA	11:11PM		08/06/2022
;=====================================================
		;LCD
BUS_LCD			EQU		P0
EN				BIT		P3.6
RS				BIT		P3.7
;---------------------------
;Ports Used for I2C Communication
SDA			 	BIT 	P3.0
SCL				BIT		P3.1
BELL			BIT		P3.4
;===================================================================
				ORG 	0000H
				lJMP	MAIN
				LJMP	INT0_ISR
				ORG		000BH
				LJMP	T0_ISR
				ORG 	0013H
				LJMP	INT1_ISR
				ORG		001BH
				LJMP	T1_ISR
				ORG 	0023H
				LJMP	SPI_ISR
				ORG		002BH
				LJMP	T2_ISR						  	
;=============================================
				ORG  	0033H
MAIN:		
				MOV 	SP,#5FH
				MOV		TMOD,#11H
				;---------------------
				CALL	INITIAL					;LCD	
				MOV		DPTR,#TAB_LINE1
				CALL	PRINT_LINE

				MOV		A,#0C0H
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT

				MOV		DPTR,#TAB_LINE2
				CALL	PRINT_LINE
				;---------------------

				CALL 	I2C_INIT
				CALL 	STARTC
				MOV 	A,#0D0H
				CALL 	SEND
				MOV 	A,#07H
				CALL 	SEND
				MOV		A,#10H 				;SQWE = 1; 1Hz
				CALL	SEND
				CALL 	STOP
 
				;---------------------
				
				CALL	READ_TIME_DS1307
				CALL	WRITE_SS
				CALL	WRITE_MM
				CALL	WRITE_HH
				CALL	WRITE_JJ
				CALL	WRITE_DD
				CALL	WRITE_MOIS
				CALL	WRITE_YY

				MOV		IP,#01H
				SETB	EA
				SETB	IT0
				SETB	EX0

SLEEP_MODE:		ORL		PCON,#01H						  
				SJMP	SLEEP_MODE

TAB_LINE1:		DB		'DATE:DD/DD/MM/YY'
TAB_LINE2:		DB		'TIME:   HH:MM:SS'
TAB_7JOUR:		DB		'  SuMoTuWeThFrSa'
;============================================
INT0_ISR:	
				PUSH	ACC
				PUSH	PSW				
				;--------------
				MOV		R0,#0
				CALL	READ_REG_DS1307

				MOV		A,30H
				CJNE	A,40H,INT0_ISR_01				
			   	JMP		EXIT_INT0_ISR
INT0_ISR_01:	MOV		40H,30H			
				CALL	WRITE_SS  				;SECOND
INT0_ISR_02:
				MOV		R0,#1
				CALL	READ_REG_DS1307

				MOV		A,31H
				CJNE	A,41H,INT0_ISR_03
				JMP		EXIT_INT0_ISR
INT0_ISR_03:	MOV		41H,31H
				CALL	WRITE_MM				;MINUTE
INT0_ISR_04:
				MOV		R0,#2
				CALL	READ_REG_DS1307

				MOV		A,32H
				CJNE	A,42H,INT0_ISR_05
				JMP		EXIT_INT0_ISR
INT0_ISR_05:	MOV		42H,32H
				CALL	WRITE_HH				;HEURE
INT0_ISR_06:
				MOV		R0,#3
				CALL	READ_REG_DS1307

				MOV		A,33H
				CJNE	A,43H,INT0_ISR_07
				JMP		EXIT_INT0_ISR
INT0_ISR_07:	MOV		43H,33H
				CALL	WRITE_JJ				;JOUR
INT0_ISR_08:
				MOV		R0,#4
				CALL	READ_REG_DS1307

				MOV		A,34H
				CJNE	A,44H,INT0_ISR_09
				JMP		EXIT_INT0_ISR
INT0_ISR_09:	MOV		44H,34H
				CALL	WRITE_DD				;DATE
INT0_ISR_10:
				MOV		R0,#5
				CALL	READ_REG_DS1307

				MOV		A,35H
				CJNE	A,45H,INT0_ISR_11
				JMP		EXIT_INT0_ISR
INT0_ISR_11:	MOV		45H,35H
				CALL	WRITE_MOIS				;MOIS
INT0_ISR_12:
				MOV		R0,#6
				CALL	READ_REG_DS1307

				MOV		A,36H
				CJNE	A,46H,INT0_ISR_13
				JMP		EXIT_INT0_ISR
INT0_ISR_13:	MOV		46H,36H
				CALL	WRITE_YY				;AN
				
EXIT_INT0_ISR:	
				MOV		A,32H
				CJNE	A,#07H,DONT_RING_BELL	;AT 07:00:00 RING BELL
				MOV		A,31H
				CJNE	A,#00H,DONT_RING_BELL
				MOV		A,30H
				CJNE	A,#00H,DONT_RING_BELL
				MOV		R6,#10
				MOV		R7,#240
				SETB	ET0
				SETB	TR0

DONT_RING_BELL:	POP		PSW
				POP		ACC				
				RETI
;=============================================
T0_ISR:		
				PUSH 	ACC		 			;R6 = #10(X50ms) ;R7 = #240	 (2m)
				PUSH	PSW
				
				CLR		TR0
				MOV		TH0,#HIGH(-50000)
				MOV		TL0,#LOW(-50000)
				SETB	TR0
				DJNZ	R6,EXIT_INT1_ISR
				CPL		BELL
				MOV		R6,#10

				DJNZ	R7,EXIT_INT1_ISR
				CLR		TR0
				SETB	BELL
				CLR		ET0
				SJMP	EXIT_INT1_ISR
						
EXIT_INT1_ISR:	POP		PSW
				POP		ACC													
				RETI
;=============================================
INT1_ISR:	
				RETI
;=============================================
T1_ISR:				
				RETI
;============================================				
SPI_ISR:			
				RETI
;=============================================				
T2_ISR:					
				RETI
;=============================================
WRITE_SS:
				MOV		A,#0CEH			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				MOV		R1,#30H
				CALL	WRITE_RAM
				RET
				;----------------
WRITE_MM:
				MOV		A,#0CBH			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				MOV		R1,#31H
				CALL	WRITE_RAM
				RET
				;----------------
WRITE_HH:
				MOV		A,#0C8H			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				MOV		R1,#32H
				CALL	WRITE_RAM
				RET
				;----------------
WRITE_JJ:
				MOV		A,#85H			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				MOV		DPTR,#TAB_7JOUR
				MOV		A,33H
				MOV		B,#2
				MUL		AB
				MOV		B,A
				MOVC	A,@A+DPTR
				CALL	DELAY_2MS
				SETB	RS
				CALL	WRITE_OUT

				MOV		A,B
				INC		A
				MOVC	A,@A+DPTR
				CALL	DELAY_2MS
				SETB	RS
				CALL	WRITE_OUT
				RET
				RET
				;----------------
WRITE_DD:
				MOV		A,#88H			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT


				MOV		R1,#34H
				CALL	WRITE_RAM
				RET
				;----------------
WRITE_MOIS:
				MOV		A,#8BH			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT


				MOV		R1,#35H
				CALL	WRITE_RAM
				RET
				;----------------
WRITE_YY:
				MOV		A,#8EH			;CHUYEN CON TRO VE 08H
				CALL	DELAY_2MS				
				CLR		RS
				CALL	WRITE_OUT

				MOV		R1,#36H
				CALL	WRITE_RAM
				RET
				;----------------
;===============================================================
SET_TIME_DS1307:
				CALL 	I2C_INIT
				CALL 	STARTC

				MOV 	A,#0D0H
				CALL 	SEND

				MOV 	A,#00H
				CALL 	SEND

				MOV 	A,#00H				;SECONDE
				CALL 	SEND
				MOV		A,#10H				;MINUTE
				CALL	SEND
				MOV		A,#10H				;HEURE
				CALL	SEND				
				MOV		A,#04H				;JOUR
				CALL	SEND
				MOV		A,#15H 				;DATE
				CALL	SEND
				MOV		A,#06H 				;MOIS
				CALL	SEND
				MOV		A,#22H 				;AN
				CALL	SEND
				CALL 	STOP
				RET
;==============================================================
READ_TIME_DS1307:	
				CALL 	I2C_INIT
				CALL 	STARTC

				MOV 	A,#0D0H
				CALL	SEND
				MOV 	A,#00H
				CALL	SEND
				CALL	RSTART
				MOV 	A,#0D1H
				CALL	SEND

				MOV		R0,#30H
THEN0:			CALL 	RECV  				;SECONDE
				CALL 	ACK
				MOV		@R0,A
				INC		R0				
				CJNE	R0,#36H,THEN0

				CALL	RECV
				MOV		36H,A
EXIT_READ:		CALL 	NAK				
				CALL 	STOP
				RET
				;----------------------
READ_REG_DS1307:
				;MOV	R0,#01H
				CALL 	I2C_INIT
				CALL 	STARTC

				MOV 	A,#0D0H
				CALL	SEND
				MOV 	A,R0
				CALL	SEND
				CALL	RSTART
				MOV 	A,#0D1H
				CALL	SEND
				
				CALL	RECV
				CALL 	NAK				
				CALL 	STOP
				PUSH	ACC
				MOV		A,R0
				ADD		A,#30H
				MOV		R0,A
				POP		ACC
				MOV		@R0,A						
				RET
;========================================================			
I2C_INIT:
				SETB	SDA
				SETB 	SCL
				RET
   				;----------
RSTART:			;REPETTED START
				CLR 	SCL
				SETB 	SDA
				SETB 	SCL
				CLR 	SDA
				RET
 				;----------
STARTC:
				SETB 	SCL
				CLR 	SDA
				CLR 	SCL
				RET
 				;----------
STOP:
				CLR 	SCL
				CLR 	SDA
				SETB 	SCL
				SETB 	SDA
				RET
 				;----------
SEND:
				MOV 	R3,#08
BACK:
				CLR 	SCL
				RLC 	A
				MOV 	SDA,C
				SETB 	SCL
				DJNZ 	R3,BACK
				CLR 	SCL
				SETB 	SDA
				SETB 	SCL
				MOV 	C, SDA
				CLR 	SCL
				RET
 				;-------------
ACK:
				CLR 	SDA
				SETB 	SCL
				CLR 	SCL
				SETB 	SDA
				RET
NAK:
				SETB 	SDA
				SETB 	SCL
				CLR 	SCL
				SETB 	SCL
				RET
				;--------------
RECV:
				MOV 	R3,#08
BACK2:
				CLR 	SCL
				CALL	SCL_DELAY 			;khong delay la xung scl giu muc 1 rat lau so voi muc 0
				SETB 	SCL				
				MOV 	C,SDA
				RLC 	A
				DJNZ 	R3,BACK2
				CLR 	SCL
				SETB 	SDA
				RET
				;----------------
SCL_DELAY:
				NOP
				NOP
				RET
;=========================================================
PRINT_LINE:		MOV		R0,#16
				MOV		A,#0
PRINT_LINE_1:	PUSH	ACC
				CALL	PRINT_CHAR
				POP		ACC
				INC		A
				DJNZ	R0,PRINT_LINE_1
				RET
;=========================================================
PRINT_CHAR:	
				MOVC	A,@A+DPTR
				CJNE	A,#00H,PRINT_CHAR1
				SETB	C
				RET
PRINT_CHAR1:	CALL	DELAY_2MS
				SETB	RS
				PUSH	DPH
				PUSH	DPL
				CALL	WRITE_OUT
				POP		DPL
				POP		DPH
				CLR		C
PRINT_CHAR2:	RET
;----------------------------------------------------------
WRITE_RAM:												;NAP R1 VO TRUOC KHI CALL, viet thoi gian chua trong thanh ghi
				;MOV		R1,#36H
				MOV		A,@R1
				ANL		A,#0F0H
				SWAP	A
				ADD		A,#30H
				CALL	DELAY_2MS
				SETB	RS
				CALL	WRITE_OUT

				MOV		A,@R1
				ANL		A,#0FH  
				ADD		A,#30H
				CALL	DELAY_2MS
				SETB	RS
				CALL	WRITE_OUT
				RET
;---------------------------------------------
INITIAL:		
				CLR		EN				;do EN tich cu muc cao (khong co lenh nay cung khong sao)
				MOV		A,#38H	 		;8 bits 5x8 dots
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#01H		  	;clscr
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#0CH		   	;Hien man hinh, chop ky tu
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				MOV		A,#06H		  	;Dich con tro sang phai (khi ghi/doc data)
				CALL	DELAY_2MS
				CLR		RS
				CALL	WRITE_OUT
				;----------------
				RET
 ;---------------------------------------------------------------
DELAY_2MS:		SETB	RS0
				MOV		R7,#4
DELAY_2MS_0:	MOV		R6,#250
				DJNZ	R6,$
				DJNZ	R7,DELAY_2MS_0
				CLR		RS0
				RET
;-----------------------------------------------------------------
WRITE_OUT:		
				MOV		BUS_LCD,A
				SETB	EN
				CLR		EN
				RET																							
				END