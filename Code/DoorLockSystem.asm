ORG 0000H
MOV R6,#0D	
MOV R5,#3D ;number of attempts
MOV A,#0
MOV p2, #00h
;--------------------------------
Start_up_MSG:
ACALL LCD_INIT ; initialize LCD
MOV DPTR,#INITIAL_MSG_1 ;DPTR point to initial text
ACALL SEND_DAT ;DISPLAY DPTR content on LCD
ACALL DELAY2 ;GIVE DELAY
ACALL CLRSCR ; clear our screen
;--------------------------------
MAIN:
CLR P2.7 ; port 2.7 will be used for buzzer
CLR P2.4 ; led lockdown
CLR P2.3 ; led Pass
ACALL LCD_INIT ; initialize LCD
MOV DPTR,#INITIAL_MSG_2 ;DPTR point to initial text
ACALL SEND_DAT ;DISPLAY DPTR content on LCD
ACALL DELAY ;GIVE DELAY 
ACALL LINE2 ;MOVE TO LINE 2
ACALL READ_KEYPRESS ;take input from keypad
ACALL DELAY ;give some delay
ACALL CLRSCR ; clear our screen
MOV DPTR, #CHECK_PASS_MSG ;send checking pass.. msg to lcd
ACALL SEND_DAT
ACALL DELAY2
ACALL CHECK_PASSWORD  ;CHECK for correct password
SJMP MAIN ;short jump to main
;---------------------------------
LCD_INIT:MOV DPTR,#MYDATA
C1:CLR A
MOVC A,@A+DPTR
JZ     ; jump if A  = 0
ACALL COMNWRT
ACALL  DELAY
INC DPTR
SJMP C1
DAT:RET
;---------------------------------
SEND_DAT:  
CLR A
MOVC A,@A+DPTR
JZ AGAIN ; jump if A = 0
ACALL DATAWRT
ACALL DELAY
INC DPTR
SJMP SEND_DAT
AGAIN: RET
;--------------------------------- 
READ_KEYPRESS:
MOV R0, #5      ; R0 = 5 (Number of keypresses to read)
MOV R1, #160    ; R1 = 160 (Address to store keypresses in memory)
ROTATE:ACALL KEY_SCAN  ; Take the input key
MOV R7, A       ; Store key in R7 for processing
MOV A, R7       ; Move key to A for comparison
CJNE A, #23H, STORE_KEY ; Compare with '#' (23H) and branch if not equal
SJMP SKIP_DISPLAY ; If the key is '#', skip displaying it
STORE_KEY:
MOV A, R7       ; Load the key again from R7
MOV @R1, A      ; Store key at the address in R1
ACALL DATAWRT   ; Display the key on the LCD
ACALL DELAY2    ; Delay
ACALL DELAY2    ; Another delay to ensure smooth input
SKIP_DISPLAY:
MOV A, R7       ; Load the key again from R7
MOV @R1, A      ; Store key at the address in R1
INC R1           ; Move to the next memory location
DJNZ R0, ROTATE ; Repeat for 5 keypresses
RET
;----------------------------------
CHECK_PASSWORD:MOV R0,#5D  ;R0 = 5
MOV R1,#160D ; R1= 160
MOV DPTR,#PASSWORD ;DPTR Point to actual PASSWORD
RPT:CLR A ; A = 0
MOVC A,@A+DPTR ; A = FIRST NUMBER OF THE ACTUAL PASSWORD
XRL A,@R1 ; XOR with the actual password
;if both the numbers are equal then A = 0;
JNZ FAIL ; jump if a not = 0
INC R1
INC DPTR
DJNZ R0,RPT ;repeat this process for 5 times
ACALL SUCCESS
RET
;-----------------------------------
SUCCESS: ACALL CLRSCR
SETB p2.3
ACALL DELAY2
MOV DPTR,#TEXT_S1
ACALL SEND_DAT ;display correct password
ACALL DELAY2
ACALL CLRSCR ; clear our screen
MOV DPTR,#TEXT_S2
ACALL SEND_DAT ;display opening door
ACALL DELAY2
ACALL DELAY2
CLR P2.3
CLR P2.4 
ACALL DELAY3 ; GIVE SECOND DELAY
ACALL CLRSCR
MOV DPTR, #TEXT_S3
ACALL SEND_DAT
ACALL DELAY2
ACALL DELAY3; GIVE SECOND DELAY
ACALL Start_up_MSG
MOV R5,#3D ;reset attempts value
RET
;----------------------------
FAIL:ACALL CLRSCR
SETB p2.4
SETB p2.7
ACALL DELAY2
MOV DPTR,#TEXT_F1 
ACALL SEND_DAT ;display incorrect text
ACALL DELAY2
ACALL LINE2
MOV DPTR, #TEXT_F2
ACALL SEND_DAT ;display access denied text
ACALL DELAY2
CLR p2.4
CLR p2.7
DJNZ R5,LOOP
ACALL ALERT
LOOP: ACALL ATTEMPT
LJMP MAIN ;go to main funtion
;------------------------------
ATTEMPT: ACALL CLRSCR
MOV DPTR,#ATTEMPT_TEXT ;number of attempts left
ACALL SEND_DAT
ACALL DELAY2
MOV A,#48D ; 48 = 0
ADD A,R5
DA A
ACALL DATAWRT
ACALL DELAY
ACALL DELAY2
ACALL DELAY2 ;
RET
;-------------------------------
ALERT:
MOV R2,#10D
ACALL CLRSCR
SETB P2.7
SETB P0.3
SETB P0.4
MOV DPTR, #ALERT_TEXT ;display alert text
ACALL SEND_DAT
ACALL DELAY3
CLR P2.7
CLR P0.3
CLR P0.4
MOV R5,#3D
ACALL Start_up_MSG
LJMP MAIN
;--------------------------------------------------
;algorithm to check for key scan
KEY_SCAN:MOV P1,#11111111B  ;TAKE INPUT FROM PORT 1
;CHECKING FOR ROW 1 COLUMN 1
CLR P1.0  ;first row checking #11111110
JB P1.4, NEXT1 ;when 1 column is 1 then no button is pressed , check for next column
MOV A,#55D ; if above fails then 7 is pressed , A =7
RET 
NEXT1:JB P1.5,NEXT2 ; ROW 1 COULMN 2
MOV A,#56D ; A = 8
RET
NEXT2: JB P1.6,NEXT3 ; ROW 1 COLUMN 3
MOV A,#57D ; A=9 		  
RET
NEXT3:SETB P1.0 ; ROW 1 IS RESET
CLR P1.1 ;CHECK FOR ROW 2
JB P1.4, NEXT4 ; ROW 2 COLUMN 1
MOV A,#52D ; A = 4
RET
NEXT4:JB P1.5,NEXT5 ; ROW 2 COLUMN 2
MOV A,#53D	;A = 5
RET
NEXT5: JB P1.6,NEXT6 ; ROW 2 COLUMN 3
MOV A,#54D ;A = 6
RET
NEXT6:SETB P1.1 ;ROW IS RESET
CLR P1.2 ; CHECK FOR ROW 3
JB P1.4, NEXT7 ; ROW 3 COLUMN 1
MOV A,#49D  ;A = 1
RET
NEXT7:JB P1.5,NEXT8 ; ROW 3 COLUMN 2
MOV A,#50D ;A =2 
RET
NEXT8: JB P1.6,NEXT9 ; ROW 3 COLUMN 3
MOV A,#51D ;A = 3
RET
NEXT9:SETB P1.2 ; ROW 3 IS RESET
CLR P1.3 ; CHECK FOR ROW 4
JB P1.4, NEXT10 ; ROW 4 COLUMN 1
MOV A,#42D ; A = *
RET
NEXT10:JB P1.5,NEXT11; ROW 4 COLUMN 2
MOV A,#48D ; A = 0
RET
NEXT11: JB P1.6,NEXT12 ; ROW 4 COLUMN 3
MOV A,#35D	 ; A = #
RET
NEXT12:LJMP KEY_SCAN ; again check for keys
;-----------------------------------------------

COMNWRT:MOV P3,A  ;to send command
CLR P2.0 ; R/s = 0
CLR P2.1 ;R/w =0
SETB P2.2 ;high
ACALL DELAY ; delay
CLR P2.2 ;low
RET

DATAWRT: MOV P3,A  ;to send data
SETB P2.0
CLR P2.1
SETB P2.2
ACALL DELAY
CLR P2.2
RET
;-------------------------------------------------
LINE2: MOV A,#0C0H ;move to line 2 of LCD
ACALL COMNWRT
RET

;---------------------------------
DELAY: MOV R3,#65 ; r3 = 65 , m = 1
HERE2: MOV R4,#255 ;r4 = 255 , m =1
HERE: DJNZ R4,HERE ; m = 2
DJNZ R3,HERE2 ;m =2
RET ;m =2
;for here loop , 2 * 255 * 1.085 uS = 553.35 us
;HERE 2 loop repeats HERE loop 65 times then  553.35 us * 65 = 35967.75uS
;mov r4 is also repating 65 times  and djnz r3 too so 3 * 65 * 1.085 us = 211uS
;for return 2 * 1.085 = 2.17uS
;total machine cycle = 35967.75 + 211 + 2.17 = 36180.92 uS
;time delay = 0.036 S
 
;------------------------------------------
DELAY2:	MOV R3,#250D ; R3  = 250
        MOV TMOD,#01 ; timer 0 mode 1
BACK2:  MOV TH0,#0FCH 
        MOV TL0,#018H  ;initial count value = FC18 is loaded into timer
        SETB TR0 ;starting timer
HERE5:  JNB TF0,HERE5 ;monitor Timer flag if it is 1
        CLR TR0 ; stop the timer
        CLR TF0 ; reset the timer flag
        DJNZ R3,BACK2 ; repeat this process 250 times
        RET  
;COUNT = 65535 - 64536 + 1 = 1000
; 1000 * 1.085 uS = 1085 uS
; 1085uS * 250 = 0.271 S
;--------------------------------------------

DELAY3:MOV TMOD,#10H ;Timer 1, mod 1
MOV R3,#70 ; for multiple delay
AGAIN1: MOV TL1,#00H ;TL1=08,low byte of timer
MOV TH1,#00H ;TH1=01,high byte , TIMER = 0000
SETB TR1 ;Start timer 1
BACK: JNB TF1,BACK ;until timer rolls over
CLR TR1 ;Stop the timer 1
CLR TF1 ;clear Timer 1 flag
DJNZ R3,AGAIN1 ;if R3 not zero then
RET
;COUNT = 65535 - 0000 + 1 = 65536
;65536 * 1.085 uS = 71.1065mS
;71.1065 mS * 70 = 4977.45mS = 5S

;-----------------------------------------
CLRSCR: MOV A,#01H
ACALL COMNWRT
RET
;----------------------------------------
ORG 500H
DB 10000000B,01000000B,11000000B,00100000B,10100000B,01100000B,11100000B,00010000B,00110000B
MYDATA: DB 38H,0EH,01,06,80H,0; 
;initializer 5 X 7 MATRIX lcd
;display on cursor blinking
;clear the display screen
;cursor shift --> towards right
;start from the first line
INITIAL_MSG_1:   DB "Welcome Home -_-",0
INITIAL_MSG_2:   DB "Enter Password: ",0
CHECK_PASS_MSG:  DB "CHECKING PASS...",0	
PASSWORD:DB 49D,50D,51D,52D,35D,0  ;PASSWORD = 1 2 3 4 #
TEXT_F1: DB "WRONG PASS",0
TEXT_F2: DB "ACCESS DENIED",0
TEXT_S1: DB "ACCESS GRANTED",0
TEXT_S2: DB "OPENING DOOR",0
TEXT_S3: DB "CLOSING DOOR", 0
ALERT_TEXT: DB "INTRUDER ALERT !",0
ATTEMPT_TEXT: DB "ATTEMPTS LEFT:",0
LOCKDOWN_TEXT: DB "LOCKDOWN STARTED",0
END