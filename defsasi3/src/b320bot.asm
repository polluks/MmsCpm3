********** BOOT MODULE LOADER ROUTINE **********
**********  FOR DRIVES ON SASI BUS    **********
************************************************
VERS	EQU	'2 '		; December 3,1982 3:30 klf "L320.ASM"
************************************************
********** MACRO ASSEMBLER DIRECTIVES **********
	MACLIB	Z80
	$-MACRO
************************************************

************************************************
********** PORTS AND CONSTANTS *****************
************************************************
?PORT	EQU	0F2H
?STACK	EQU	2680H
BASE$PORT EQU	2150H		; PORT ADDRESS SAVED BY BOOT PROM
BTDRV	EQU	2034H		; BOOT DRIVE NUMBER SAVED BY PROM
BOOT	EQU	2280H		; ADDRESS TO LOAD BOOT MODULE INTO
SECTR0	EQU	2280H		; LOCATION OF 'MAGIC SECTOR'
DCTYPE	EQU	SECTR0+3	; DRIVE/CONTROLLER TYPE
ISTRING EQU	SECTR0+13	; CONTROLLER INITIALIZATION STRING
NPART	EQU	SECTR0+19	; NUMBER OF PARTITIONS ON THIS DRIVE
CONTROL EQU	SECTR0+4	; CONTROL BYTE
DRVDATA EQU	SECTR0+5	; DRIVE CHARACTERISTIC DATA
SECTBL	EQU	SECTR0+20	; START OF PARTITION DEFINITION TABLE
DPB	EQU	SECTR0+47	; START OF DPB TABLE
SYSADR	EQU	2377H		; LOCATION IN BOOT MODULE TO PLACE SECTOR
				;  ADDRESS OF OPERATING SYSTEM
DRIV0	EQU	168

REQ	EQU	10000000B
POUT	EQU	01000000B
MSG	EQU	00100000B
CMND	EQU	00010000B
BUSY	EQU	00001000B

RUN	EQU	00000000B
SWRS	EQU	00010000B
SEL	EQU	01000000B

;
; STACK OPERATIONS -- GET BOOT STRING
;
	ORG	2480H
	JMP	START
BLCODE: DB	0		; VALUES TO BE PASSED TO BOOT MODULE
LSP:	DB	0
START:	DCX	SP		; BOOT ERROR ROUTINE ADDRESS IS LOCATED HERE
	DCX	SP
	POP	D		; SAVE IT IN REG. D
	LXI	H,STRNG
	POP	B		; GET THE COMMAND STRING PUSHED BY PROM 
	MOV	A,C		;  OFF THE STACK
	CPI	0C3H		; IF FIRST BYTE IS C3H THEN THERE IS NO STRING
	JRZ	NOSTR
	MOV	M,A
	MOV	A,B		; SECOND BYTE
	ORA	A		; BYTE OF 0 TERMINATES STRING
NOSTR:	LXI	SP,?STACK	; SET UP LOCAL STACK
	PUSH	D		;  AND PUSH ADDRESS OF BOOT ERROR ROUTINE
	RNZ			; ERROR IF MORE THAN 1 CHARACTER IN STRING

;
; SET UP LOGICAL UNIT NUMBER
;
	LDA	BTDRV		; BOOT DRIVE FROM PROM DETERMINES LOGICAL
	CPI	5		; Z67 DRIVE NUMBERS ARE 3 AND 4
	JRNC	NOT67
	SUI	3
	JR	GOTLUN
NOT67:	SUI	DRIV0		;  UNIT NUMBER FOR CONTROLLER
GOTLUN: ANI	00000011B	; MAKE SURE NO EXTRANEOUS BITS ARE SET
	RRC
	RRC
	RRC			; MOVE INTO POSITION FOR COMMAND
	STA	CMBFR+1

;
; INITIALIZE THE CONTROLLER -- ASSIGN DRIVE TYPE
;
	LDA	ISTRING 	; GET RELEVANT BYTES FROM INITIALIZATION STRING
	STA	CMBFR		;  AND PUT TNEM INTO COMMAND BUFFER
	LDA	ISTRING+4
	STA	CMBFR+4
	LDA	BASE$PORT	; SET UP PORT ADDRESS
	MOV	C,A
	INR	C		; CONTROL PORT TO REG. C
	CALL	GETCON		; GET CONTROLLER'S ATTENTION
	CALL	OUTCOM		; SEND THE COMMAND
	CALL	CHK$STAT	; CHECK STATUS

;
; INITIALIZE DRIVE CHARACTERISTICS
;
	LDA	DCTYPE		; FIRST CHECK FOR XEBEC
	ANI	11100000B
	JNZ	CKPART		; SKIP IF NOT XEBEC
	INR	C		; CONTROL PORT TO REG. C
	MVI	A,0CH		; INITIALIZE DRIVE CHARACTERISTICS COMMAND
	STA	CMBFR
	CALL	GETCON		; GET CONTROLLER'S ATTENTION
	CALL	OUTCOM		; OUTPUT COMMAND
	LXI	H,DRVDATA	; DRIVE CHARACTERISTIC DATA
	MVI	B,8		; 8 BYTES LONG
	MVI	E,(REQ OR POUT OR BUSY)
	CALL	OUTCM1		; OUTPUT THE DATA
	CALL	CHK$STAT	;  AND CHECK STATUS

;
; NOW, LOOK AT THE COMMAND STRING WE GOT OFF STACK TO SEE WHAT PARTITION
; THE USER REQUESTED.
;
CKPART: LXI	H,STRNG 	; GET FIRST BYTE OF COMMAND STRING
	MOV	A,M
	ORA	A		; NO STRING => DEFAULT TO PARTITION 0
	JRZ	PART0
	SUI	'0'
	LXI	H,NPART
	CMP	M		; RETURN TO BOOT PROMPT IF PARTITION
	RNC			;  NUMBER IS OUT OF RANGE
PART0:	LXI	H,SECTBL
	MOV	C,A
	MVI	B,0
	DAD	B
	DAD	B
	DAD	B		; POINT TO SECTOR TABLE ENTRY

;
; GOT CORRECT PARTITION. PREPARE TO READ THE SECTOR
;
	PUSH	H		; SAVE POINTER INTO SECTOR TABLE
	LXI	H,DPB-21
	LXI	D,21
NXTDPB: DAD	D
	DCR	C
	JP	NXTDPB		; POINT TO DISK PARAMETER BLOCK
	LXI	D,15
	DAD	D
	MOV	A,M		; GET MODE BYTE 1
	POP	H		; RECALL POINTER INTO SECTOR TABLE
	MOV	C,M		; SET UP REGISTERS C,E,D TO CONTAIN SECTOR
	INX	H		;  ADDRESS FOR ROTATION
	MOV	E,M
	INX	H
	MOV	D,M
	ANI	00000011B	; ISOLATE SECTOR SIZE BITS
	MOV	B,A
	STA	BLCODE		; SAVE FOR USE BY BOOT MODULE
	JRZ	NOMULT		; DON'T ROTATE IF SECTOR SIZE IS 128
	MOV	A,C
	ANI	00011111B	; EXCLUDE 3 MSB'S FROM ROTATION
	MOV	C,A
	MVI	A,1		; INITIAL VALUE FOR SECTOR COUNT
RCED:	RARR	C		; ROTATE THE THREE BYTES
	RARR	E
	RARR	D
	RLC
	ORA	A		; CLEAR CARRY FOR NEXT ROTATION
	DJNZ	RCED		; ROTATE AGAIN ?
	STA	LSP		; SAVE SECTOR COUNT FOR USE LATER
NOMULT: LDA	CMBFR+1 	; GET LOGICAL UNIT NUMBER
	ORA	C		;  AND OR IT INTO NEW SECTOR ADDRESS.
	STA	CMBFR+1 	; SAVE NEW ADDRESS IN COMMAND BUFFER
	SDED	CMBFR+2
	MVI	A,1
	STA	CMBFR+4 	; READ IN 1 SECTOR
	LDA	CONTROL 	; CONTROL BYTE
	STA	CMBFR+5
	MVI	A,8
	STA	CMBFR		; READ COMMAND

;
;  READ IN BOOT MODULE AND JUMP TO IT WHEN DONE
;
LOAD:	LDA	BASE$PORT	; GET BASE PORT ADDRESS
	MOV	C,A
	INR	C
	CALL	GETCON		; GET CONTROLLER'S ATTENTION
	CALL	OUTCOM		; OUTPUT THE READ COMMAND
	CALL	RD$SEC		; READ IN THE SECTOR
	CALL	CHK$STAT	; CHECK STATUS OF READ
	LXI	H,CMBFR+1
	LXI	D,SYSADR
	LXI	B,5		; SYSTEM ADDRESS FOR USE BY BOOT MODULE
	LDIR			;  (ALSO CONTROL BYTE)
	JMP	BOOT

;
;  SUBROUTINE TO GET CONTROLLER'S ATTENTION
;

GETCON: MVI	B,0
GETCN1: INP	A
	ANI	BUSY
	JRZ	GETCN2
	DJNZ	GETCN1
	JR	ERROR
GETCN2: MVI	A,SEL
	OUTP	A
	MVI	B,0
GETCN3: INP	A
	ANI	BUSY
	JRNZ	GETCN4
	DJNZ	GETCN3
	JR	ERROR
GETCN4: MVI	A,RUN
	OUTP	A
	RET

; 
;  SUBROUTINE TO OUTPUT THE COMMAND
;
OUTCOM: DCR	C
	LXI	H,CMBFR
	MVI	B,6
	MVI	E,(REQ OR CMND OR POUT OR BUSY)
OUTCM1: PUSH	B
	INR	C		; CONTROL PORT
	MVI	B,16		; TIMER COUNTER
OUTLOP: INP	A
	ANI	(REQ OR CMND OR POUT OR BUSY)
	CMP	E
	JRZ	OUTOK
	DJNZ	OUTLOP
	POP	B		; CLEAN UP STACK
	JR	ERROR		; TIME OUT ERROR
OUTOK:	POP	B
	OUTI
	JNZ	OUTCM1
	RET

ERROR:	POP	D
	RET			; RETURN TO BOOT PROMPT

; 
;  SUBROUTINE TO READ IN A SECTOR
;
RD$SEC: LXI	H,BOOT		; ADDRESS TO LOAD BOOT MODULE
SASICK: INR	C		; CONTROL PORT
	INP	A
	DCR	C
	ANI	(CMND OR BUSY OR REQ OR POUT)
	CPI	(CMND OR BUSY OR REQ)	; IF POUT DROPS
	RZ				;  WE ARE INTO STATUS PHASE
	ANI	(CMND OR BUSY OR REQ)
	CPI	(BUSY OR REQ)	; WHEN CMND DROPS,SEEK IS COMPLETE, AND WE ARE
	JRNZ	SASICK		;  READY FOR DATA TRANSFER
	LDA	LSP   
MORE:	MVI	B,128
	INIR
	DCR	A
	JRNZ	MORE		; READ IN ANOTHER 128 BYTES ?
	RET

;
;  SUBROUTINE TO CHECK STATUS OF PREVIOUS OPERATION
;
CHK$STAT:
	LXI	H,STAT
	JR	CHK01
CHKNXT: INP	A
	MOV	M,A
CHK01:	INR	C
	INP	A
	DCR	C
	ANI	(MSG OR REQ OR CMND OR POUT)
	CPI	(REQ OR CMND)
	JRZ	CHKNXT
	CPI	(MSG OR REQ OR CMND)
	JRNZ	CHK01
	INP	A
	MOV	A,M
	ANI	3
	JRNZ	ERROR
	RET

;
;  MISCELLANEOUS STORAGE
;
CMBFR:	DB	0,0,0,0,0,0
STAT:	DB	0
STRNG:	DB	0

	END
