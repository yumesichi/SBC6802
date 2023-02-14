***------------------------------***
*** SBC6802 ROM Version
***             V1  MAY-21-'21
***             V2  FEB-13-'23
***------------------------------***
**--------------------------------**
**  MIXDBUG ROM Version
**              V10  FEB.-13-'23
**              V9   NOV.-28-'18
**              V7   NOV.-21-'18
**              V5   NOV.-15-'18
**              V3   OCT.-15-'18
**		V1   JULY-30-'18
**--------------------------------**
*	NAM	SWTBUG
*	VERSION 1.00
*
*	OPT	PAG
**
**--------------------------------**
*REPLACEMENT FOR MIKBUG ROM
*FOR SWTPC 6800 COMPUTER SYSTEM
*COPYRIGHT 1977
*SOUTHWEST TECHNICAL PROD. CORP.
*AUGUST, 1977
**--------------------------------**
;
SYSROM	EQU	$E000	<--ROM     VERSION=$E000
SYSRAM	EQU	$6000	<--SBC-IO VERSION=$A000
;
	ORG	SYSRAM	ORIGINAL
IRQ	RMB	2	IRQ POINTER
BEGA	RMB	2	BEGADDR DUMP&PNCH
ENDA	RMB	2	ENDADDR DUMP$PNCH
NMI	RMB	2	NMI VECTOR
SP	RMB	1	S HIGH
	RMB	1	S LOW
PORADD	RMB	2	PORT ADDR
PORECH	RMB	1	ECHO ON/OFF FLAG
XHI	RMB	1	X-REG HIGH
XLOW	RMB	1	X-REG LOW
CKSM	RMB	1	CHECKSUM
XTEMP	RMB	2	X-REG TEMP STGE
SWIJMP	RMB	2	SWI JUMP VECTOR
BKPT	RMB	2	BREAKPOINT ADDR
BKLST	RMB	1	BREAKPOINT DATA
	RMB	43
STACK	RMB	2	<--$A042	SWTBUG STACK
TW	RMB	2	<--$A044	TEMP WORD
TEMP	RMB	1	<--$A046	TEMP BYTE
BYTECT	RMB	1	<--$A047	BYTECT AND MCONT TEMP.
USR	RMB	2	<--$A048	USR PROGRAM
PRNFLG	RMB	1	<--$A04A	NO PRINTER:0
;
;
CTLPOR	EQU	$8018	<--$8004	ACIA PORT ADDR
* PROM	EQU	$C000	<--$C000	JUMP TO PROM ADDR
;
	ORG	SYSROM	<--$E000
*
* I/O INTERRUPT SEQUENCE
*
IRQV	LDX	IRQ
	JMP	0,X
*
*JUMP TO USER PROGRAM
*
JUMP	BSR	BADDR
	JMP	0,X

CURSOR	FCB	$10,$07,4	CT-1024 CURSOR CONTROL
*
*ASCII LOADING ROUTINE
*
LOAD	EQU	*
	JSR	CRLF
LOAD3	BSR	INCH
	CMP A	#'S
	BNE	LOAD3	1ST CHAR NOT S
LOAD31	BSR	INCH	READ CHAR
	CMP A	#'9
	BEQ	LOAD21
	CMP A	#'1
	BNE	LOAD3	2ND CHAR NOT 1
	CLR	CKSM	ZERO CHECKSUM
	BSR	BYTE	READ BYTE
	SUB A	#2
	STA A	BYTECT BYTE COUNT
	BSR	BADDR
LOAD11	BSR	BYTE
	DEC	BYTECT
	BEQ	LOAD15	ZERO BYTE COUNT
	STA A	0,X	STORE DATA
	CMP A	0,X	DATA STORED?
	BNE	LOAD19
	INX
	BRA	LOAD11
LOAD15	INC	CKSM
	BEQ	LOAD3
LOAD19	LDA A	#'?
	BSR	OUTCH
LOAD21	JMP	CONTRL
*
* BUILD ADDRESS
*
BADDR	BSR	BYTE	READ 2 FRAMES
	STA A	XHI
	BSR	BYTE
	STA A	XLOW
	LDX	XHI	LOAD IXR WITH NUMBER
	RTS
*
* INPUT BYTE (TWO FRAMES)
*
BYTE	BSR	INHEX	GET HEX CHAR
BYTE1	ASL A
	ASL A
	ASL A
	ASL A
	TAB
	BSR	INHEX
	ABA
	TAB
	ADD B	CKSM
	STA B	CKSM
	RTS
*
OUTHL	LSR A	OUT	HEX LEFT BCD DIGIT
	LSR A
	LSR A
	LSR A
OUTHR	AND A	#$F	OUT HEX RIGHT BCD DIGIT
	ADD A	#$30
	CMP A	#$39
	BLS	OUTCH
	ADD A	#$7
*
* OUTPUT ONE CHAR
*
OUTCH	JMP	OUTEEE
*
* INPUT ONE CHAR
*
INCH	JMP	INEEE
*
* PRINT DATA POINTED TO BY X REG
*
PDATA2	BSR	OUTCH
	INX
PDATA1	LDA A	0,X
	CMP A	#4
	BNE	PDATA2
	RTS	STOP	ON HEX 04

C1	JMP	SWTCTL
*
* MEMORY EXAMINE AND CHANGE
*
CHANGE	BSR	BADDR
CHA51	LDX	#MCL
	BSR	PDATA1	C/R L/F
	LDX	#XHI
	BSR	OUT4HS	PRINT ADDRESS
	LDX	XHI
	BSR	OUT2HS	PRINT OLD DATA
	BSR	OUTS	OUTPUT SPACE
	BSR	INCH	INPUT CHAR
	CMP A	#$20
	BEQ	SK1
	CMP A	#$D
	BEQ	C1
	CMP A	#'^	UP ARROW?
	BRA	AL3	BRANCH FOR ADJUSTMENT
	NOP
*
* INPUT HEX CHARACTER
*
INHEX	BSR	INCH
INHEX1	SUB A	#$30
	BMI	C3
	CMP A	#$9
	BLE	IN1HG
	CMP A	#$11
	BMI	C3	NOT HEX
	CMP A	#$16
	BGT	C3	NOT HEX
	SUB A	#7
IN1HG	RTS

OUT2H	LDA A	0,X	OUTPUT 2 HEX CHAR
OUT2HA	BSR	OUTHL	OUT LEFT HEX CHAR
	LDA A	0,X
	INX
	BRA	OUTHR	OUTPUT RIGHT HEX CHAR

OUT4HS	BSR	OUT2H	<--OUTPUT 4 HEX CHAR + SPACE
OUT2HS	BSR	OUT2H	<--OUTPUT 2 HEX CHAR + SPACE
OUTS	LDA A	#$20		<--SPACE
	BRA	OUTCH
**
** ENTER POWER ON SEQUENCE
**
START	LDS	#STACK	<--$E0D0 BRANCH FOR MIKBUG
	BRA	AL1	
*
* PART OF MEMORY EXAMINE AND CHANGE
*
AL3	BNE	SK1
	DEX
	DEX
	STX	XHI
	BRA	CHA51
SK1	STX	XHI
	BRA	AL4
*
EOE3	BRA	CONTRL	<--$E0E3 BRANCH FOR MIKBUG
*
AL4	CMP A	#$30
	BCS	CHA51
	CMP A	#$46
	BHI	CHA51
	BSR	INHEX1
	JSR	BYTE1
	DEX
	STA A	0,X	CHANGE MEMORY
	CMP A	0,X
	BEQ	CHA51	DID CHANGE
	JMP	LOAD19	DIDN'T CHANGE
C3	LDS	SP
	BRA	SWTCTL
**
** CONTINUE POWER UP SEQUENCE
**
AL1	STS	SP	INIT TARGET STACK PTR.
	LDA A	#$FF
	JSR	SWISET
	LDX	#CTLPOR
	LDA A	0,X
	LDAA	CTLPOR+1
	BRA	AL2
	BRA	PRINT	<--BRA FOR BILOAD
AL2	BNE	CONTRL
*
* INITIALIZE ACIA
*
	LDA A	#3	ACIA MASTER RESET
	STA A	0,X
	LDA A	#$15
	STA A	0,X
	JSR	INITAC
	BRA	CONTRL
*
* ENTER FROM SOFTWARE INTERRUPT
*
SF0	NOP
SFE1	STS	SP	SAVE TARGETS STACK POINTER
*			DECREMENT P COUNTER
	TSX
	TST	6,X
	BNE	*+4
	DEC	5,X
	DEC	6,X
*			PRINT CONTENTS OF STACK.
PRINT	LDX	#MCL
	JSR	PDATA1
	LDX	SP
	INX
	JSR	OUTCC	CC
	BSR	OUT2HS	ACC B
	BSR	OUT2HS	ACC A
	BSR	OUT4HS	IXR
	BSR	OUT4HS	PGM COUNTER
	LDX	#SP
	JSR	OUT4HS	STACK POINTER
SWTCTL	LDX	SWIJMP
	CPX	#SF0
	BEQ	CONTR1
CONTRL	LDS	#STACK	SET CONTRL STACK POINTER
	LDX	#CTLPOR	RESET TO CONTROL PORT
	STX	PORADD
	CLR	PORECH	TURN ECHO ON
	BSR	SAVGET	GET PORT # AND TYPE
CONTR1:
	LDX	#MCLOFF
	JSR	PDATA1	PRINT DATA STRING
	BSR	INEEE	READ COMMAND CHARACTER
*
*
* COMMAND LOOKUP ROUTINE
*
	LDX	#TABLE
OVER	CMP A	0,X
	BNE	SK3
	JSR	OUTS	SKIP SPACE
	LDX	1,X
	JMP	0,X
SK3	INX
	INX
	INX
	CPX	#TABEND+3
	BNE	OVER
SWTL1	BRA	SWTCTL
*
* SOFTWARE INTERRUPT ENTRY POINT
*
SFE	LDX	SWIJMP	JUMP TO VECTORED SOFTWARE INT
	JMP	0,X
**--------------------------------**
S9		FCB	$D,$A,'S9',4	END OF TAPE
MTAPE1	FCB	$D,$A,'S1',4	PUNCH FORMAT
MCLOFF	FCB	$13	READER OFF
MCL	FCB	$D,$A,'$',4
EIA5	BRA	BILD	BINARY LOADER INPUT
**--------------------------------**
*
* NMI SEQUENCE
*
NMIV	LDX	NMI	GET NMI VECTOR
	JMP	0,X
*
* GENERAL PURPOSE DELAY LOOP
*
DELAY	LDX	#$2000
DELAY1	DEX
	BNE	DELAY1
	RTS
*
	NOP
	NOP
	NOP
*
INEEE1	BSR	INCH8	INPUT 8 BIT CHARACTER
	AND A	#%01111111	GET RID OF PARITY BIT
	RTS
*
INEEE	BRA	INEEE1	<--$E1AC
*
*
* GO TO USER PROGRAM ROUTINE
*
GOTO	RTI
*
* SAVE IXR AND LOAD IXR WITH CORRECT
* PORT NUMBER AND TEST FOR TYPE
*
SAVGET	STX	XTEMP	STORE INDEX REGISTER
	LDX	PORADD
	RTS
*
BILD	INS	FIX UP STACK WHEN USING
	INS	BINARY LOADER ON SWTPC TAPES
	INS
*
* INPUT ONE CHAR INTO ACC B
*
INCH8	PSH B		SAVE ACC B
	BSR	SAVGET	SAVE IXR, GET PORT# AND TYPE
	LDA A	#$15	RECONFIG FOR 8 BIT, 1 SB
	STA A	0,X
ACIAIN	LDA A	0,X
	ASR A
	BCC	ACIAIN	NOT READY
	LDA A	1,X	LOAD CHAR
	LDA B	PORECH
	BEQ	ACIOUT	ECHO
	BRA	RES	DON'T ECHO
	NOP
	NOP
	NOP
*
OUTEEE	BRA	OUTEE1	<--$E1D1
*
* OUTPUT ONE CHARACTER
*
OUTEE1	PSH B		SAVE ACC B
	BSR	SAVGET
ACIOUT	LDA B	#$11
	STA B	0,X
ACIOU1	LDA B	0,X
	ASR B
	ASR B
	BCC	ACIOU1	ACIA NOT READY
	STA A	1,X	OUTPUT CHARACTER
RES	PUL B		RESTORE ACC B
	LDX	XTEMP
	RTS
*
* CONTINUATION OF SEARCH ROUTINE
*
SKP0	JSR	OUT4HS
	LDX	XHI
INCR1	CPX	ENDA
	BEQ	SWTL1
	INX
	BRA	OVE
*
* BYTE SEARCH ROUTINE
*
SEARCH	JSR	STADR	GET TOP ADDRESS
	JSR	BADDR	GET BOTTOM ADDRESS
	STX	ENDA
	JSR	OUTS
	JSR	BYTE	GET BYTE TO SEARCH FOR
	TAB
	LDX	BEGA
OVE	LDA A	0,X
	STX	XHI
	CBA
	BEQ	PNT
	BRA	INCR1
PNT	LDX	#MCL
	JSR	PDATA1
	LDX	#XHI
	BRA	SKP0
*
* CLRAR SCREEN FOR CT-1024 TYPE TERMINALS
*
CLEAR	LDX	#CURSOR
	JSR	PDATA1
	JSR	DELAY	DELAY
	BRA	C4
*
* BREAKPOINT ENTERING ROUTINE
*
BREAK	LDX	#SF0
	CPX	SWIJMP	BREAKPOINTS ALREADY IN USE?
	BEQ	INUSE
	INX
BREAK0	BSR	STO1
	JSR	BADDR
	STX	BKPT
	LDA A	0,X
	STA A	BKLST
	LDA A	#$3F
	STA A	0,X
	LDX	#SF0
	BSR	STO1
	JMP	CONTR1
INUSE	LDX	BKPT
	LDA A	BKLST
	STA A	0,X
	LDX	#SFE1
	BRA	BREAK0
*
SWISET	STA A	STACK+1	FIX POWER UP INTERRUPT
	LDX	SWIJMP
	CPX	#SF0
	BEQ	STORTN
	LDX	#SFE1
STO1	STX	SWIJMP
STORTN	RTS
*
PUNCH1	JSR	PUNCH
	LDX	#S9
	JSR	PDATA1
	JMP	CONTRL
*
* FORMAT END OF TAPE WITH PGM. CTR. AND S9
*
PNCHS9	LDX	#USR+1
	STX	ENDA
	DEX
	JSR	PUNCH2
	LDX	#S9
	JSR	PDATA1
C4	JMP	CONTRL
*
* GET STARTING ADDRESS
*
STADR	JSR	BADDR
	STX	BEGA
	JMP	OUTS
*
* GET ENDING ADDRESS
*
ENADR	JSR	BADDR
	STX	ENDA
CRLF	PSH A
	LDA A	#$0D		OUTPUT CR
	JSR	OUTCH
	LDA A	#$0A		OUTPUT LF
	JSR	OUTCH
	PUL A
	RTS
*
* DUMP FROM BEG BEGA THRU ENDA
*
DUMP	BSR	STADR		GET START ADDRESS
	BSR	ENADR		GET END ADDRESS
	LDA A	BEGA+1		SET UP ADDRESS(0 LOW NIBBLE)
	AND A	#$F0
	STA A	BEGA+1
	LDX	BEGA
	STX	TW
	LDA A	ENDA+1		SET UP ADDRESS (0 LOW NIBBLE)
	AND A	#$F0
	STA A	ENDA+1
DUMP1	LDX	#TW		OUTPUT ADDRESS
	JSR	OUT4HS
	LDX	TW		OUTPUT DATA BYTES
	LDA B	#$08
DUMP2	JSR	OUT2HS		PRINT IT
	DEC B			DECREMENT COUNT
	BNE	DUMP2
*---------------------------@V3
	JSR	OUTS
	JSR	OUTS
	LDX	TW
	LDAB	#$08
DUMP4	LDA A	0,X
	CMP A	#$7F
	BEQ	DUMP5
	CMP A	#$20
	BCC	DUMP6
DUMP5	LDA A	#$2E
DUMP6	JSR	OUTCH
	INX
	DEC B
	BNE	DUMP4
	JSR	CRLF		NEWLINE
	STX	TW		SAVE CURRENT POINTER
	CPX	#$0000
	BEQ	DUMP3
	CPX	ENDA		DONE?
	BNE	DUMP1
DUMP3
	JMP	CONTRL
*----------------------------@V3	
*
* PUNCH FROM BEG BEGA THRU ENDA
*
PUNCH	JSR	STADR
	JSR	ENADR
	LDX	BEGA
PUNCH2	STX	TW
PUN11	LDA A	ENDA+1
	SUB A	TW+1
	LDA B	ENDA
	SBC B	TW
	BNE	PUN22
	CMP A	#16
	BCS	PUN23
PUN22	LDA A	#15
PUN23	ADD A	#4
	STA A	BYTECT
	SUB A	#3
	STA A	TEMP
	LDX	#MTAPE1	<--PUNCH C/R L/F NULLS S1
	JSR	PDATA1
	CLR B
	LDX	#BYTECT	<--PUNCH FRAME COUNT
	BSR	PUNT2		<--PUNCH 2 HEX CHARACTERS
	LDX	#TW
	BSR	PUNT2		<--ADDR
	BSR	PUNT2
	LDX	TW
PUN32	BSR	PUNT2		<--DATA
	DEC	TEMP
	BNE	PUN32
	STX	TW
	COM B
	PSH B
	TSX
	BSR	PUNT2	PUNCH CHECKSUM
	PUL B	RESTORE	STACK
	LDX	TW
	DEX
	CPX	ENDA
	BNE	PUN11
RTN5	RTS
*
* PUNCH 2 HEX CHAR, UPDATE CHECKSUM
*
PUNT2	ADD B	0,X
	JMP	OUT2H	OUTPUT 2 HEX CHAR AND RTS
*
* INIT ACIA DATA
*
INITAC	LDAA CTLPOR+1
	LDAA CTLPOR+1
	LDAA CTLPOR+1
	RTS
*
SFMT	JSR	INCH
	JSR	CRLF
	CMPA	#'1
	BNE	SFMT1
	JMP	LOAD31
SFMT1	JMP	CONTRL
*
*
* COMMAND TABLE
*

TABLE	FCC	'G
	FDB	GOTO
	FCC	'Z
	FDB	NTBSTART
	FCC	'M
	FDB	CHANGE
	FCC	'F
	FDB	SEARCH
	FCC	'R
	FDB	PRINT
	FCC	'J
	FDB	JUMP
	FCC	'C
	FDB	CLEAR
	FCC	'D
	FDB	DUMP
	FCC	'B
	FDB	BREAK
	FCC	'P
	FDB	PUNCH1
	FCC	'L
	FDB	LOAD
	FCC	'S
	FDB	SFMT
	FCC	'?
	FDB	HELP
	FCC	'X
	FDB	TBUG
TABEND	FCC	'E
	FDB	PNCHS9
*
HELP	LDX	#HELPMSG
	JSR	PDATA1
	JMP	CONTRL
HELPMSG	FCB	$0D,$0A,' B **     :BREAK'
	FCB	$0D,$0A,' C        :CLEAR'
	FCB	$0D,$0A,' D ** ++  :DUMP'
	FCB	$0D,$0A,' E        :S9'
	FCB	$0D,$0A,' F ** ++ @:FIND'
	FCB	$0D,$0A,' G        :GO'
	FCB	$0D,$0A,' J **     :JUMP'
	FCB	$0D,$0A,' L        :LOAD'
	FCB	$0D,$0A,' M **     :MEMCHG  NEXT[SP]BACK[^]'
	FCB	$0D,$0A,' P ** ++  :PUNCH'
	FCB	$0D,$0A,' R        :REG     CC B A IX PC SP'
	FCB	$0D,$0A,' Z        :J PROM '
	FCB	$04    
*
OUTCC	LDAB	0,X
	LDAA	#'[
	BSR	OUTCH1
	INX
	ASLB
	ASLB
	ASLB
	BCC	OU1
	LDAA	#'H
	BRA	OU2
OU1	LDAA	#'*
OU2	BSR	OUTCH1
	ASLB
	BCC	OU3
	LDAA	#'I
	BRA	OU4
OU3	LDAA	#'.
OU4	BSR	OUTCH1
	ASLB
	BCC	OU5
	LDAA	#'N
	BRA	OU6
OU5	LDAA	#'.
OU6	BSR	OUTCH1
	ASLB
	BCC	OU7
	LDAA	#'Z
	BRA	OU8
OU7	LDAA	#'.
OU8	BSR	OUTCH1
	ASLB
	BCC	OU9
	LDAA	#'V
	BRA	OU10
OU9	LDAA	#'.
OU10	BSR	OUTCH1
	ASLB
	BCC	OU11
	LDAA	#'C
	BRA	OU12
OU11	LDAA	#'.
OU12	BSR	OUTCH1
	LDAA	#']
	BSR	OUTCH1
	JSR	OUTS
	RTS
;
OUTCH1	JMP	OUTEE1

**--------------------------------**
** PUNCH&LOAD ROUTINE 
**                 OF JBUG MONITOR
**    REV 1.8 9-6-'76
**--------------------------------**
* SUBROUTINE TO PUNCH DATA(SBC-IO)
*
LED	EQU	$8000	<--LED TOGGLE
ACIAS	EQU	$8094	<--PUNCH ACIA(SBC-IO)
ACIAD	EQU	$8095
*
	ORG	SYSROM+$500	<--$600@11.21
*
	BSR	PNCHJ
	JMP	START
*
PNCHJ:
	BSR	INITAJ	<--ACIA(SBC-IO)
	LDX	#$0F	<--#$03FF LDR LENGTH
	BSR	PNLDR
PUND10	LDAB	ENDA+1
	SUBB	BEGA+1
	LDAA	ENDA
	SBCA	BEGA
	BEQ	PUND25
	LDAB	#$FF
PUND25	LDAA	#'B
	BSR	OUTCHJ
	PSHB
	TSX
	BSR	PUN
	PULA
	INCA
	STAA	TEMP
	LDX	#BEGA
	BSR	PUN
	BSR	PUN
	LDX	BEGA
PUND30	BSR	PUN
	DEC	TEMP
	BNE	PUND30
	STX	BEGA
	LDX	#$0019
	BSR	PNLDR
	LDX	BEGA
	DEX
	CPX	ENDA
	BNE	PUND10
	LDAA	#'G
	BSR	OUTCHJ
	RTS
* SUB TO PUNCH DATA BYTE
OUTCHJ	PSHB
OUTC1	LDAB	ACIAS
	ASRB
	ASRB
	BCC	OUTC1
	STAA	ACIAD
	STAA	LED	<--LED TOGGLE
	PULB
	RTS
*
* SUB TO PUNCH ONE BYTE
PUN	LDAA	X
	BSR	OUTCHJ
	INX
	RTS
* PUNCH LEADER
PNLDR	LDAA	#$FF
	BSR	OUTCHJ
	DEX
	BNE	PNLDR
	RTS
*
* INIT ACIAJ DATA
*
INITAJ:
	LDAA	#$01
	STAA	ACIAS
	NOP
	NOP
	NOP
	LDAA	#%01010001
	STAA	ACIAS
	RTS
*
* SUBROUTINE TO LOAD DATA(SBC-IO)
*
	ORG	SYSROM+$580
	BSR	LOADJ
	JMP	START
*
LOADJ:
	BSR	INITAJ	<--ACIA(SBC-IO)
BILDJ	BSR	INCHR
	CMPA	#'B
	BEQ	RDBLCK
	CMPA	#'G
	BNE	BILDJ
	RTS
RDBLCK	BSR	INCHR
	TAB
	INCB
	BSR	INCHR
	STAA	BEGA
	BSR	INCHR
	STAA	BEGA+1
	LDX	BEGA
STBLCK	BSR	INCHR
	STAA	X
	INX
	DECB
	BNE	STBLCK
	BRA	BILDJ
* INPUT ONE CHR TO A REG
INCHR	LDAA	ACIAS
	ASRA
	BCC	INCHR
	LDAA	ACIAD
	STAA	LED	<--LED TOGGLE
*---------------------------@10.28
	PSHA
	PSHB
	STX	TW
	LDX	#TEMP
	STAA	0,X
	JSR	OUT2HS
	LDX	TW
	PULB
	PULA
*---------------------------@10.28
	RTS
*
	ORG	$FFF8
	FDB	IRQV	IRQ VECTOR
	FDB	SFE	SOFTWARE INTERRUPT
	FDB	NMIV	NMI VECTOR
	FDB	START	RESTART VECTOR
*
* SWTBUG	END
*
*
**-----------------------------------**
** NTB&TBUG  FOR SBC-IO
** NOV. 15 2018 VER15 
**-----------------------------------**
* TBUG TOP
**---SYSRAM	EQU	$A000	<--$A000@ORIGINAL
TBUG	EQU	$E600	<--$6000 PROGRAM@11.21
NTB	EQU	$F300	<--NTBSTART
RSVRAM	EQU	$3F00	<--RESERVED BY NTB
;
_STACK:	EQU	RSVRAM+$047	<--$A047@ORIGINAL
SUBSTK:	EQU	RSVRAM+$080	<--$A080@ORIGINAL,FOR-NEXT STACK
MONSTK:	EQU	RSVRAM+$0C0	<--$A100@ORIGINAL
;
**IRQV	EQU	SYSRAM
IRQ	EQU	SYSRAM		<--@IO
IRQCHR	EQU	SYSRAM+$17	<--IRQ CHAR=$03
STARTV	EQU	SYSRAM+$48	<--MIKBUG,MIXDBUG
;
SBSTK:	EQU	SYSRAM+$78
PRNWK:	EQU	SYSRAM+$100
;
START:	EQU	$E0D0	<--MIKBUG ENTRY
INEEE:	EQU	$E1AC	<--L627F L6C5E
OUTEEE:	EQU	$E1D1	<--L632F L675D
;
*	EX_BREAK:	EQU	$626D
*	VM_COPY:	EQU	$62C0
*	VM_GRA:	EQU	$6973
*	EX_675D:	EQU	$675D
*	EX_689A:	EQU	$689A
*	EX_68DD:	EQU	$68DD
*	VM_69EC:	EQU	$69EC
*	VM_PIX:	EQU	$69F8
*	VM_WH:	EQU	$6A00
*	VM_BL:	EQU	$6A06
*	VM_REV:	EQU	$6A0D	
;
GRRAM	EQU	$4000
CHRAM	EQU	$5000
GCRAM	EQU	$5400
CG2513	EQU	$5800
;

NULCH	EQU	$20	<--INIT CHAR
NULGC	EQU	$30	<--$A0 INIT COLOR
;
ASKREG	EQU	$8050	<--$8004 ASCII KEYBORD-MC6820
ASKCTR	EQU	$8051	<--$8005
PRNREG	EQU	$8052	<--$8006 PRINTER DATA-MC6820
PRNCTR	EQU	$8053	<--$8007
PACICS	EQU	$8094	<--PUNCH ACIA(SBC-IO)
PACIDA	EQU	$8095
ACIACS	EQU	$8018	<--ACIA(SBC)
ACIADA	EQU	$8019
LED	EQU	$8000	<--LED(SBC-IO)
;
;
	ORG	TBUG
;
	jmp	L62CC
T_CRLF:
	FCB	$0D	<--CR
	FCB	$0A
	FCB	$04	<--ETX
T_MCL:
	FCB	$0D
	FCB	$0A
	FCB	$07	<--BEL
	FCB	'+
	FCB	$04	<--ETX
L6009:
	FCB	'?
	FCB	$07	<--BEL
	FCB	$07	<--BEL
	FCB	$04	<--ETX
T_TABLE:
	FCB	'?
	FCB	$00
	FDB	T_HELP
	FCB	'B
	FCB	$02
	FDB	L64F7
	FCB	'D
	FCB	$02
	FDB	T_DUMP
	FCB	'J
	FCB	$01
	FDB	T_GOTO
	FCB	'T
	FCB	$02
	FDB	TRACE
	FCB	'T
	FCB	$03
	FDB	L6485
	FCB	'T
	FCB	$04
	FDB	L6497
	FCB	'T
	FCB	$05
	FDB	TRACE
	FCB	'Z
	FCB	$00
	FDB	NTBSTART
	FCB	'M
	FCB	$01
	FDB	T_CHANGE
	FCB	'P
	FCB	$02
	FDB	T_PUNCH
	FCB	'L
	FCB	$00
	FDB	LOADJ
T_TABEND	FCB	'G
	FCB	$00
	FDB	START
;
**-----OUTPUT CHRAM  ACCA
VOUTCH:
*	COMA			<--FOR VDC6845@V10
	STAA	0,X
*	COMA			<--FOR VDC6845@V10
	RTS
**-----OUTPUT GCRAM  ACCB
VOUTGC:
*	COMB			<--FOR VDC6845@V10
	STAB	0,X
*	COMB			<--FOR VDC6845@V10
	RTS
**
T_OUTS	LDAA	#$20
	JMP	T_OUT
**
;
L605A:
	bsr	L60C6
L605C:
	ldaa	$00,x
	bsr	L60D1
	staa	$00,x
	inx
	dex
	ldab	#$36
	stab	$03,x
	ldab	#$69
L606A:
	decb
	bne	L606A
	ldab	#$3E
	stab	$03,x
	bsr	L60E4
	bne	L605C
	dec	$0011
	bne	L605A
	bsr	L60C2
	ldab	#$FF
	stab	$00,x
L6080:
	ldab	#$C0
	stab	$0010
	bsr	L60C6
L6086:
	ldaa	$00,x
	bsr	L60D1
	cmpa	$00,x
	bne	L6095
	bsr	L60E4
	bne	L6086
L6092:
	ldaa	#$A0
	FCB	$8C
L6095:
	ldaa	#$C0
	bsr	L60C8
	clr	$00,x
	jmp	START	<--$E0D0 MIKBUG
;
L609E:
	bsr	L60C2
	com	$00,x
	com	$02,x
	ldaa	#$3E
	staa	$01,x
	staa	$03,x
	clr	$00,x
	clr	$02,x
L60AE:
	ldab	#$3E
	stab	$01,x
	ldab	#$36
	stab	$01,x
	rts
;
L60B7:
	bsr	L60C8
L60B9:
	tst	$01,x
	bpl	L60B9
	clra
L60BE:
	deca
	bne	L60BE
	rts
;
L60C2:
	ldx	#ASKREG
	rts
L60C6:
	bra	L6120
;
L60C8:
	bsr	L60C2
	staa	$02,x
	bsr	L60AE
	clr	$02,x
	rts
;
* INIT 
L60D1:
	bsr	L60C2
	ldab	$0012
	andb	#$03
	addb	$0010
	stab	$02,x
	bsr	L60AE
	ldab	$0013
	stab	$02,x
	inx
	dex
	rts
;
L60E4:
	ldx	$0012
L60E6:
	inx
	stx	$0012
	cpx	#$0800	<--
	rts
;
L6112:
	bsr	L609E
	ldaa	#$C0
	staa	$0010
	ldaa	#$A0
	bsr	L60B7
	ldaa	#$FF
	staa	$00,x
L6120:
	ldx	#$0400
	stx	$0012
	rts
;
L6126:
	stx	PRNWK+$20
	psha
	pshb
	ldx	PRNWK+$58
	ldab	#$20
	cmpa	#$20
	bmi	L6153
	tst	PRNWK+$5F
	bne	L6149
	cpx	#PRNWK+$58
	beq	L6146
	staa	$00,x
	inx
L6141:
	stx	PRNWK+$58
	bra	L614C
;
L6146:
	sec
	bra	L614D
;
L6149:
	dec	PRNWK+$5F
L614C:
	clc
L614D:
	pulb
	pula
	ldx	PRNWK+$20
	rts
;
L6153:
	cmpa	#$0D
	beq	L61D0
	cmpa	#$08
	bne	L616F
	cpx	#PRNWK+$38
	beq	L6165
	dex
	stab	$00,x
	bra	L6141
;
L6165:
	ldaa	$27,x
	cmpa	$26,x
	beq	L614C
	inc	$27,x
	bra	L614C
;
L616F:
	cmpa	#$18
	beq	L619C
	cmpa	#$1A
	beq	L619C
	bra	L614C
L6179:
	stx	PRNWK+$20
	ldx	#PRNWK+$38
	psha
	pshb
	ldaa	#$C0
	staa	$22,x
	ldaa	#$20
	staa	$23,x
	clr	$24,x
	clr	$25,x
	clr	$26,x
	ldx	#PRNREG
	clr	$01,x
	ldaa	#$BF
	staa	$00,x
	ldaa	#$06
	staa	$01,x
L619C:
	ldaa	#$A0
	staa	PRNREG
	ldab	#$20
	ldaa	#$20
	ldx	#PRNWK+$38
	stx	$20,x
L61AA:
	staa	$00,x
	inx
	decb
	bne	L61AA
	ldaa	$06,x
	staa	$07,x
	bra	L614D
;
	stx	PRNWK+$20
	psha
	pshb
	ldx	#PRNWK+$38
	ldaa	$22,x
	tab
	oraa	#$10
	staa	$22,x
	bsr	L61F8
	stab	$22,x
	bra	L619C
;
	stx	PRNWK+$20
	psha
	pshb
L61D0:
	ldaa	PRNREG
	asla
	BVC	L619C	<--BVC
	ldx	#PRNWK+$38
	sei
	ldab	$22,x
	andb	#$0F
	beq	L61E9
L61E0:
	bsr	L61F8
	bcs	L61EB
	bsr	L622E
	decb
	bne	L61E0
L61E9:
	bsr	L61F8
L61EB:
	ldab	#$20
L61ED:
	ldaa	$00,x
	bsr	PRNCH1
	inx
	decb
	bne	L61ED
	cli
	bra	L619C
;
L61F8:
	psha
	pshb
	ldaa	$22,x
	bmi	L6202
	clr	$20,x
	bra	L622B
;
L6202:
	oraa	#$6F
	inca
	bne	L6211
	tst	$24,x
	beq	L6215
L620B:
	bsr	L622E
	dec	$24,x
	bne	L620B
L6211:
	tst	$24,x
	bne	L6229
L6215:
	ldaa	$25,x
	adda	#$01
	daa
	staa	$25,x
	ldaa	$23,x
	staa	$24,x
	bsr	L622E
	bsr	L622E
*	bsr	L6242	<--'PAGE NO'
	bsr	L622E
	sec
L6229:
	dec	$24,x
L622B:
	pulb
	pula
	rts
;
L622E:
	ldaa	#$20
	pshb
	ldab	#$20
L6233:
	psha
	bsr	PRNCH1
	pula
	decb
	bne	L6233
	pulb
	rts
;
L623C:
	jsr	T_BCDHR
PRNCH1:
	jmp	PRNCH
;
L6242:
	ldaa	#$50
	bsr	PRNCH1
	ldaa	#$41
	bsr	PRNCH1
	ldaa	#$47
	bsr	PRNCH1
	ldaa	#$45
	bsr	PRNCH1
	ldaa	#$20
	bsr	PRNCH1
	ldaa	$25,x
	lsra
	lsra
	lsra
	lsra
	bsr	L623C
	ldaa	$25,x
	bsr	L623C
	ldaa	#$20
	bsr	PRNCH1
	ldaa	#$2D
	pshb
	ldab	#$18
	bra	L6233
;
INITPI:
	ldx	#ASKREG
	clra
	staa	$01,x
	staa	$03,x
	staa	$00,x
	ldaa	#$BF
	staa	$02,x
	ldaa	#$06
	staa	$01,x
	staa	$03,x
	ldaa	#$A0
	staa	$02,x
	rts
;
CLRTXT:
	ldaa	#$20
	ldx	#CHRAM
L62A9:
*	staa	$00,x
	JSR	VOUTCH
	inx
	cpx	#GCRAM
	bne	L62A9
	rts
;
CLRCOL:
	LDAB	#NULGC
CLRCO1:	ldx	#GCRAM
L62B7:
	JSR	VOUTGC
	inx
	CPX	#CG2513
	bne	L62B7
	rts
;
CLRALL:
	CLR	PRNFLG	<--NO PRINTER
	JSR	L6179
	bsr	INITPI	<--INIT PIA
	bsr	CLRTXT
	bsr	CLRCOL
	jsr	INITWRK
	jmp	INITGRA
;
MONSTART:
L62CC:
	bsr	CLRALL
T_CONTRL:
	LDS	#SYSRAM+$C0
	LDX	#T_MCL
	JSR	T_PDATA1
	BSR	INECHO1	<--INPUT COMMAND
	cmpa	#'?
	bcs	T_ERR1	<--NOT CHAR
	psha
	ldx	#MONSTK+$2E
L62DB:
	dex
	clr	$00,x
	cpx	#MONSTK+$20
	bne	L62DB
	cmpa	#'L
	beq	L62EF
	inx
	inx
	cmpa	#'P
	beq	L62EF
	inx
	inx
L62EF:
	clrb
	PULA
	LDX	#T_TABLE
T_OVER:
	
	CMPA	$00,X
	BNE	T_SK3
;
T_SK1	CMPB	$01,X
	BNE	T_SK4

T_SK2	LDX	$02,X
	JSR	$00,X	<--IX JMP
	BRA	T_CONTRL
;
T_SK3	INX
	INX
	INX
	INX
	CPX	#T_TABEND+4
	BNE	T_OVER
	JMP	T_ERR1	
T_SK4:
	JSR	T_OUTS
	INCB
	STX	MONSTK+$60
	LDX	#MONSTK+$24
	JSR	T_BADDR
	LDX	MONSTK+$60
	CMPB	$01,X
	BEQ	T_SK2
;
	JSR	T_OUTS
	INCB
	LDX	#MONSTK+$26
	JSR	T_BADDR
	LDX	MONSTK+$60
	BRA	T_SK2	
;
T_ERR1:
	jsr	T_ERR	
	bra	T_CONTRL
;
INECHO1:
	jmp	INECHO
;
* NO CALL ROUTINE?
L632F:
	ldaa	MONSTK+$2F
	bne	L6341
	jsr	L674E
	cmpa	#$05
	beq	L633E
L633B:
	jmp	T_OUT
;
L633E:
	inc	MONSTK+$2F
L6341:
	stx	MONSTK+$10
	pshb
	cmpa	#$02
	beq	L63AA
L6349:
	ldx	MONSTK+$02
	stx	MONSTK+$00
	jsr	L69BE
	ldab	$00,x
	eorb	#$90
	stab	$00,x
	jsr	INFFF
	eorb	#$90
	stab	$00,x
	ldab	#$01
	suba	#$1C
	beq	L6374
	deca
	beq	L6372
	deca
	beq	L6370
	deca
	bne	L6379
	deca
	decb
L6370:
	inca
	inca
L6372:
	deca
	decb
L6374:
	jsr	L68DD
	bra	L6349
;
L6379:
	adda	#$1F
	ldx	MONSTK+$02
	cmpa	#$0D
	beq	L639A
	cmpa	#$09
	bne	L638A
	bsr	L63C5
	bra	L6349
;
L638A:
	cmpa	#$0B
	bne	L6392
	bsr	L63DF
	bra	L6349
;
L6392:
	cmpa	#$20
	bcs	L6349
	bsr	L633B
	bra	L6349
;
L639A:
	inc	MONSTK+$2F
L639D:
	cpx	MONSTK+$0A
	beq	L63AE
	bsr	L63FE
	ldaa	$00,x
	cmpa	#$A0
	bne	L639D
L63AA:
	bsr	L63F9
	bcs	L63B7
L63AE:
	ldab	#$A0
	ldaa	$00,x
	stab	$00,x
	cba
	bne	L63C0
L63B7:
	clr	MONSTK+$2F
L63BA:
	bsr	L63F9
	bcc	L63BA
	ldaa	#$0D
L63C0:
	pulb
	ldx	MONSTK+$10
	rts
;
L63C5:
	ldab	#$20
L63C7:
	ldaa	$00,x
	stab	$00,x
	psha
	bsr	L63F9
	pulb
	bcc	L63C7
	ldx	MONSTK+$06
	stx	MONSTK+$02
L63D7:
	bsr	L63FE
	cpx	MONSTK+$00
	bne	L63D7
	rts
;
L63DF:
	bsr	L63F9
	bcc	L63DF
	ldx	MONSTK+$06
	stx	MONSTK+$02
	ldaa	#$20
L63EB:
	psha
	bsr	L63FE
	pulb
	ldaa	$00,x
	stab	$00,x
	cpx	MONSTK+$00
	bne	L63EB
	rts
;
L63F9:
	jsr	L68C3
	bra	L6401
;
L63FE:
	jsr	L6957
L6401:
	ldx	MONSTK+$02
	rts
;
T_GOTO:	ldx	MONSTK+$24
	jmp	$00,x	<--IX JAMP
;
L640D:
	bsr	L6479
	bsr	L6480
	stx	MONSTK+$24
	dex
	clra
	ldab	$00,x
	bpl	L641B
	coma
L641B:
	addb	MONSTK+$25
	adca	MONSTK+$24
	ldx	#MONSTK+$20
	bsr	L6456
	ldx	MONSTK+$24
	rts
;
L642A:
	ldaa	$00,x
	cmpa	#$CE
	beq	L644C
	cmpa	#$8C
	beq	L644C
	cmpa	#$8E
	beq	L644C
	cmpa	#$8D
	beq	L640D
	anda	#$F0
	cmpa	#$20
	beq	L640D
	cmpa	#$60
	bcs	L647B
	anda	#$30
	cmpa	#$30
	bne	L6479
L644C:
	bsr	L647B
	bsr	L6476
	dex
	dex
	ldaa	$00,x
	ldab	$01,x
L6456:
	cmpa	MONSTK+$28
	bne	L645E
	cmpb	MONSTK+$29
L645E:
	bcs	L647E
	cmpa	MONSTK+$2A
	bne	L6468
	cmpb	MONSTK+$2B
L6468:
	bhi	L647E
	addb	MONSTK+$2D
	adca	MONSTK+$2C
	staa	$00,x
	stab	$01,x
	bsr	L6480
L6476:
	jmp	T_OUT4HS
;
L6479:
	bsr	L647B
L647B:
	jmp	L6722
;
L647E:
	inx
	inx
L6480:
	bsr	L6482
L6482:
	jmp	L6724
L6485:
	ldx	MONSTK+$28
	stx	MONSTK+$2A
	bra	L6497
TRACE:
	ldx	#MONSTK+$28
	jsr	L656D
	stab	$05,x
	staa	$04,x
L6497:
	ldx	MONSTK+$24
L649A:
	bsr	L64E8
	bsr	L642A
	stx	MONSTK+$24
	ldaa	MONSTK+$24
	ldab	MONSTK+$25
	cmpa	MONSTK+$26
	bne	L64AF
	cmpb	MONSTK+$27
L64AF:
	bls	L649A
	rts
T_CHANGE:
	ldx	MONSTK+$24
	dex
L64B6:
	inx
	bsr	L64E8
	jsr	L6728
	JSR	T_OUTS
	dex
	jsr	INECHO
	cmpa	#$0D
	beq	L64F6
	cmpa	#$20
	BEQ	L64B6	<--
	JSR	T_BYTE1	<--
	STAA	$00,X	<--
	cmpa	$00,x
	beq	L64B6
	jmp	T_ERR
T_DUMP:
	ldx	MONSTK+$24
L64D6:
	bsr	L64E8
	ldab	#$08
L64DA:
	bsr	L647B
	dex
	cpx	MONSTK+$26
	beq	L64F6
	inx
	decb
	bne	L64DA
	bra	L64D6
;
L64E8:
	stx	MONSTK+$20
	LDX	#T_CRLF
	JSR	T_PDATA1
	ldx	#MONSTK+$20
	JSR	L6476
	ldx	MONSTK+$20
L64F6:
	rts
L64F7:
	ldx	#MONSTK+$24
	ldab	$03,x
	ldaa	$02,x
	subb	#$02
	sbca	#$00
	subb	$01,x
	sbca	$00,x
	bcs	L651C
	bne	L6522
	tstb
	bmi	L6522
L650D:
	ldx	MONSTK+$24
	stab	$01,x
	bsr	L6517
	ldx	MONSTK+$26
L6517:
	bsr	L64E8
	jmp	L642A
;
L651C:
	coma
	bne	L6522
	tstb
	bmi	L650D
L6522:
	rts
;
	ldx	#MONSTK+$24
	bsr	L656D
	bcs	L6545
	bsr	L6576
L652C:
	ldx	MONSTK+$26
	ldaa	$00,x
	dex
	stx	MONSTK+$26
	ldx	MONSTK+$2A
	bsr	L6560
	cpx	MONSTK+$28
	beq	L656C
	dex
	stx	MONSTK+$2A
	bra	L652C
;
L6545:
	bsr	L6576
L6547:
	ldx	MONSTK+$24
	ldaa	$00,x
	inx
	stx	MONSTK+$24
	ldx	MONSTK+$28
	bsr	L6560
	cpx	MONSTK+$2A
	beq	L656C
	inx
	STX	MONSTK+$28	<--@11.14
	BRA	L6547		<--@11.14
;
L6560:
	STAA	0,X		<--@11.14
	cmpa	$00,x
	beq	L656C
	jsr	L66BB
	ldx	MONSTK+$20
L656C:
	rts
;
L656D:
	ldab	$05,x
	ldaa	$04,x
	subb	$01,x
	sbca	$00,x
	rts
;
L6576:
	addb	$03,x
	adca	$02,x
	stab	$07,x
	staa	$06,x
	rts
;
L657F:
	ldx	#$AA55
	stx	MONSTK+$20
	clr	MONSTK+$2A
	bsr	L65AB
	ldx	#MONSTK+$20
L658D:
	bsr	L65B4
	inx
	cpx	#MONSTK+$2A
	bne	L658D
	bsr	L65AB
	ldx	MONSTK+$24
	bsr	L65B4
L659C:
	cpx	MONSTK+$26
	beq	L65A6
	inx
	bsr	L65B4
	bra	L659C
;
L65A6:
	ldaa	MONSTK+$2A
	bsr	L65B6
L65AB:
	ldx	#$0C00
L65AE:
	bsr	SOUND
	dex
	bne	L65AE
	rts
;
L65B4:
	ldaa	$00,x
L65B6:
	psha
	adda	MONSTK+$2A
	staa	MONSTK+$2A
	pula
	clr	MONSTK+$2B
	ldab	#$08
	bsr	L65D7
L65C5:
	asla
	bcs	L65CD
	inc	MONSTK+$2B
	bsr	L65F0
L65CD:
	bsr	SOUND
	decb
	bne	L65C5
	lsr	MONSTK+$2B
	bcc	SOUND
L65D7:
	bsr	L65F0
SOUND:
	pshb
	ldab	#$3E
	stab	PRNCTR
	ldab	#$10
L65E1:
	decb
	bne	L65E1
	ldab	#$36
	stab	PRNCTR
	ldab	#$0F
L65EB:
	decb
	bne	L65EB
	pulb
	rts
;
L65F0:
	pshb
	ldab	#$3E
	stab	PRNCTR
	ldab	#$14
L65F8:
	decb
	bne	L65F8
	pulb
	rts
;
L65FD:
	ldx	#MONSTK+$28
	tst	$00,x
	bne	L6606
	tst	$01,x
L6606:
	rts
;
L6607:
	clr	MONSTK+$2B
L660A:
	bsr	L6683
	tba
	addb	#$02
	subb	MONSTK+$2A
	staa	MONSTK+$2A
	bcs	L6607
	cmpb	#$04
	bcc	L6607
	inc	MONSTK+$2B
	bpl	L660A
	deca
	tab
	lsrb
	aba
	staa	MONSTK+$2C
L6627:
	clr	MONSTK+$2A
	bsr	L6693
	cmpa	#$AA
	bne	L6607
	bsr	L6693
	cmpa	#$55
	bne	L6627
	ldx	#MONSTK+$22
L6639:
	bsr	L6693
	staa	$00,x
	inx
	cpx	#MONSTK+$2A
	bne	L6639
	bsr	PDATA3
	ldx	#MONSTK+$22
	bsr	L66C0
	ldx	MONSTK+$20
	cpx	MONSTK+$22
	bne	L660A
	ldx	#MONSTK+$24
	bsr	L66C0
	bsr	L66C0
	bsr	L65FD
	beq	L665F
	bsr	L66C0
L665F:
	ldx	MONSTK+$24
	bsr	L6693
L6664:
	staa	$00,x
	cpx	MONSTK+$26
	beq	L6670
	inx
	bsr	L6693
	bra	L6664
;
L6670:
	bsr	L6693
	asla
	cmpa	MONSTK+$2A
	bne	T_ERR
	bsr	L65FD
	beq	L6682
	ldaa	$01,x
	psha
	ldaa	$00,x
	psha
L6682:
	rts
;
L6683:
	clrb
L6684:
	tst	ASKREG
	bpl	L6684
L6689:
	incb
	tst	ASKREG
	bmi	L6689
	cmpb	MONSTK+$2C
	rts
;
L6693:
	clra
	staa	MONSTK+$2B
L6697:
	bsr	L6683
	bcs	L6697
	ldab	#$09
L669D:
	pshb
	bsr	L6683
	bcs	L66A5
	inc	MONSTK+$2B
L66A5:
	rola
	pulb
	decb
	bne	L669D
	rora
	ror	MONSTK+$2B
	bcs	L66B9
	psha
	adda	MONSTK+$2A
	staa	MONSTK+$2A
	pula
	rts
;
L66B9:
	ins
	ins
L66BB:
	bsr	T_ERR
	ldx	#MONSTK+$20
L66C0:
	bra	T_OUT4HS
;
PDATA3:
	ldx	#T_CRLF
	bra	T_PDATA1
;
T_ERR:
	stx	MONSTK+$20
	ldx	#L6009	<--'?'
	bra	T_PDATA1
;
	bsr	L6724
T_BADDR:
	bsr	L66D3
L66D3:
	bsr	T_BYTE
	staa	$00,x
	inx
	rts
;
T_BYTE:
	pshb
	bsr	T_INHEX
	PULB
T_BYTE1:
	PSHB
	asla
	asla
	asla
	asla
	tab
	bsr	T_INHEX
	aba
	pulb
	rts
;
L66E6:
	ldaa	#$10
	staa	PACICS
L66EB:
	ldaa	PACICS
	asra
	bcc	L66EB
	ldaa	PACIDA
	rts
;
* PUNCH TO SBC-IO ACIA
PUNDA:
	psha
	ldaa	#$51
	staa	PACICS
L66FB:
	ldaa	PACICS
	asra
	asra
	bcc	L66FB
	pula
	staa	PACIDA
	STAA	LED	<--LED TOGLEE
	rts
;
T_INHEX:
	bsr	T_INCH
	suba	#$30
	bmi	INH1
	cmpa	#$09
	ble	L671B
	cmpa	#$11
	bmi	INH1
	cmpa	#$16
	bgt	INH1
	suba	#$07
L671B:
	psha
	bsr	T_OUTHR
	pula
	rts
;
INH1	PULB
CONT1:	JMP	T_CONTRL
;
T_OUT4HS:
	bsr	L6728
L6722:
	bsr	L6728
L6724:
	ldaa	#$20
	bra	T_OUT
;
L6728:
	ldaa	$00,x
	bsr	T_OUTHL
	ldaa	$00,x
	inx
	bra	T_OUTHR
;
T_PDATA2:
	bsr	T_OUT
	inx
T_PDATA1:
	ldaa	$00,x
	cmpa	#$04
	bne	T_PDATA2
	rts
;
T_BCDHR:
	anda	#$0F
	adda	#$30
	cmpa	#$39
	bls	L6745
	adda	#$07
L6745:
	rts
;
T_OUTHL:
	lsra
	lsra
	lsra
	lsra
T_OUTHR:
	bsr	T_BCDHR
	bra	T_OUT
;
L674E:
	tst	MONSTK+$0E
	beq	L6755
	bra	L66E6
L6755:
	bra	T_INCH
;
	bsr	L674E
	bra	OUTRAM
;
INECHO:
	bsr	T_INCH
T_OUT:
	tst	MONSTK+$0F
	beq	L6764
	bsr	PUNDA
L6764:
	TST	PRNFLG
	BEQ	PR1
	JSR	L6126	<--PRINTER
PR1	JSR	OUTEEE
	bra	OUTRAM
;
*
;
T_INCH:
	stx	MONSTK
	pshb
	ldx	MONSTK+$02
	ldab	$00,x
	ldaa	#$5F
	staa	$00,x
	bsr	INFFF
	stab	$00,x
	pulb
	ldx	MONSTK
	rts
;
**------ PARALLEL KEYBOARD ROUTINE -----**
* INFFF:
* 	tst	ASKREG
* L677F:
* 	tst	ASKCTR
* 	bpl	L677F
* L6784:
* 	ldaa	ASKREG
* 	anda	#$7F
* 	cmpa	#$60
* 	bmi	L678F
* 	suba	#$20
* L678F:
* 	rts
*
*
INFFF:
	LDAA	ACIACS
	ASRA
	BCC	INFFF
	ldaa	ACIADA
	anda	#$7F
	rts
*
* OUTEEE TO VRAM
*
OUTRAM:
	stx	MONSTK
	pshb
	psha
	ldx	MONSTK+$02
	ldab	#$20
	cmpa	#$20
	bcs	L67BE
	JSR	VOUTCH
	inx
	stx	MONSTK+$02
	cpx	MONSTK+$06
	bne	L67B5
L67A9:
	tst	MONSTK+$0E
	bne	L67B0
	bsr	L6808
L67B0:
	bsr	L6829
	ldx	MONSTK+$04
L67B5:
	stx	MONSTK+$02
L67B8:
	pula
	pulb
	ldx	MONSTK
	rts
;
L67BE:
	cmpa	#$0D
	bne	L67C8
	ldaa	#$A0
	JSR	VOUTCH
	bra	L67A9
;
L67C8:
	cmpa	#$08
	bne	L67D6
	cpx	MONSTK+$04
	beq	L67B5
	dex
	stab	$00,x
	bra	L67B5
;
L67D6:
	cmpa	#$18
	bne	L67DE
	JSR	L685A
	bra	L67B5
;
L67DE:
	cmpa	#$1A
	bne	L67E6
	bsr	L683C
	bra	L67B8
;
L67E6:
	suba	#$14
	beq	L67FA
	inca
	beq	L67F4
	inca
	beq	L67F9
	inca
	bne	L67FF
	inca
L67F4:
	staa	MONSTK+$0E
	bra	L67B5
;
L67F9:
	inca
L67FA:
	staa	MONSTK+$0F
	bra	L67B5
;
L67FF:
	tst	MONSTK+$0E
	bne	L67B5
	bsr	L6866
	bra	L67B5
;
L6808:
	ldaa	PRNREG
	asla
	bpl	L6828
	ldx	MONSTK+$04
	cpx	MONSTK+$02
	beq	L6828
	cli
	dex
L6818:
	inx
	ldaa	$00,x
L681B:
	bsr	PRNCH
	decb
	cpx	MONSTK+$02
	bne	L6818
	andb	#$1F
	bne	L681B
	sei
L6828:
	rts
L6829:
	JMP	L68AA
;
** PRINTER OUTCH
;
PRNCH:
	TST	PRNFLG
	BEQ	PRN2
	psha
	STX	TW
	STAA	LED	<--LED TOGGLE
	CMPA	#$60
	BPL	PRN1
	tst	PRNREG
	staa	PRNREG
	LDX	#$600	<--WAIT PRINTER ON TIME
L6831:
	DEX
	BEQ	PRN1
	tst	PRNCTR
	bpl	L6831	<--
PRN1:	ldaa	#$A0
	staa	PRNREG
	LDX	TW
	pula
PRN2:	rts
;
L683C:
	ldaa	#$A0
	ldx	MONSTK+$0A
L6841:
	JSR	VOUTGC
	inx
	cpx	MONSTK+$0C
	bne	L6841
	bra	L689A
;
L684B:
	ldx	MONSTK+$0A
	ldab	#$A0
L6850:
	ldaa	$20,x
	staa	$00,x
	inx
	cpx	MONSTK+$04
	bne	L6850
L685A:
	ldx	MONSTK+$06
L685D:
	dex
	JSR	VOUTGC
	cpx	MONSTK+$04
	bne	L685D
	rts
;
L6866:
	adda	#$50
	pshb
L6869:
	pshb
	ldab	#$3E
	stab	PRNCTR
	tab
L6870:
	decb
	bne	L6870
	ldab	#$36
	stab	PRNCTR
	tab
L6879:
	decb
	bne	L6879
	pulb
	decb
	bne	L6869
	pulb
	rts
;
INITWRK:
	ldx	#$0000
	stx	MONSTK+$0E
	stx	MONSTK+$2E
	stx	MONSTK+$36
	ldx	#CHRAM+$40	<--$42 UPPER LEFT
	stx	MONSTK+$0A
	ldx	#CHRAM+$03DF	<--LOWER RIGHT
	stx	MONSTK+$0C
L689A:
	ldx	#CHRAM+$40	<--$42 UPPER LEFT
	stx	MONSTK+$02
	stx	MONSTK+$04
	ldx	#CHRAM+$005F	<--UPPER RIGHT
	stx	MONSTK+$06
	rts
;
L68AA:
	bsr	L68B0
	bcc	L68C2
	bra	L684B
;
L68B0:
	bsr	L691D
	ldab	MONSTK+$0C
	ldaa	MONSTK+$0D
	ldx	MONSTK+$06
	bsr	L6937
	bcc	L68C2
	bsr	L6910
	sec
L68C2:
	rts
;
L68C3:
	ldab	MONSTK+$06
	ldaa	MONSTK+$07
	ldx	MONSTK+$02
	inx
	stx	MONSTK+$02
	bsr	L6937
	bhi	L68DC
	bsr	L68B0
	ldx	MONSTK+$04
	stx	MONSTK+$02
L68DC:
	rts
;
L68DD:
	stx	MONSTK
	pshb
	tsta
	bmi	L68EF
	beq	L68F6
L68E6:
	psha
	bsr	L68C3
	pula
	deca
	bne	L68E6
	bra	L68F6
;
L68EF:
	psha
	bsr	L6957
	pula
	inca
	bne	L68EF
L68F6:
	pulb
	tstb
	bmi	L6905
	beq	L690C
L68FC:
	pshb
	bsr	L68B0
	pulb
	decb
	bne	L68FC
	bra	L690C
;
L6905:
	pshb
	bsr	L6944
	pulb
	incb
	bne	L6905
L690C:
	ldx	MONSTK
	rts
;
L6910:
	ldx	#MONSTK+$02
	bsr	L6917
	bsr	L6917
L6917:
	ldab	#$FF
	ldaa	#$E0
	bra	L6927
;
L691D:
	ldx	#MONSTK+$02
	bsr	L6924
	bsr	L6924
L6924:
	clrb
	ldaa	#$20
L6927:
	bsr	L692E
	inx
	inx
	rts
L692C:
	bra	L68B0
;
L692E:
	adda	$01,x
	adcb	$00,x
	staa	$01,x
	stab	$00,x
	rts
;
L6937:
	stx	MONSTK+$08
	ldx	#MONSTK+$08
	cmpb	$00,x
	bne	L6943
	cmpa	$01,x
L6943:
	rts
;
L6944:
	bsr	L6910
	ldab	MONSTK+$0A
	ldaa	MONSTK+$0B
	ldx	MONSTK+$04
	bsr	L6937
	bls	L6956
	bsr	L691D
	clc
L6956:
	rts
;
L6957:
	ldab	MONSTK+$04
	ldaa	MONSTK+$05
	ldx	MONSTK+$02
	dex
	stx	MONSTK+$02
	bsr	L6937
	BLS	L6971
	bsr	L6944
	ldx	MONSTK+$06
	dex
	stx	MONSTK+$02
L6971	rts
;
L6973:
	ldab	MONSTK+$1F
	lsrb
	lsrb
	lsrb
	stab	MONSTK+$11
	clra
	ldab	#$FE
L697F:
	psha
	ldaa	MONSTK+$1E
	lsra
	lsra
	lsra
	staa	MONSTK+$10
	pula
	ldx	MONSTK+$02
L698D:
	cpx	MONSTK+$06
	beq	L699F
	staa	$00,x
	stx	MONSTK
	bsr	L69BE
	stab	$00,x
	ldx	MONSTK
	inx
L699F:
	inca
	bne	L69A3
	incb
L69A3:
	dec	MONSTK+$10
	bne	L698D
	psha
	pshb
	bsr	L692C
	pulb
	pula
	bcs	L69B5
	dec	MONSTK+$11
	bne	L697F
L69B5:
	bsr	L6944
	bcs	L69B5
L69B9:
	bsr	L6957
	bne	L69B9
	rts
;
L69BE:
	pshb
	psha
	ldab	#$04
	clra
	adda	MONSTK+$01
	adcb	MONSTK
	staa	MONSTK+$09
	stab	MONSTK+$08
	ldx	MONSTK+$08
	pula
	pulb
	rts
;
INITGRA:
	ldaa	#$C0
	staa	MONSTK+$1E
	ldaa	#$A6
	staa	MONSTK+$1F
	ldx	#GRRAM
	stx	MONSTK+$1A
	ldx	#CHRAM
	stx	MONSTK+$1C
	rts
;
L69EC:
	ldx	MONSTK+$1A
L69EF:
	clr	$00,x
	inx
	cpx	MONSTK+$1C
	bne	L69EF
	rts
;
VM_PIX:
	bsr	L6A14
	anda	$00,x
	beq	L69FF
	incb
L69FF:
	rts
;
VM_WH:
	bsr	L6A14
	oraa	$00,x
	bra	L6A11
;
VM_BL:
	bsr	L6A14
	coma
	anda	$00,x
	bra	L6A11
;
VM_REV:
	bsr	L6A14
	eora	$00,x
L6A11:
	staa	$00,x
	rts
;
L6A14:
	staa	MONSTK+$16
	stab	MONSTK+$17
	ldx	MONSTK+$1A
	cmpa	MONSTK+$1E
	bhi	L6A71
	cmpb	MONSTK+$1F
	bhi	L6A71
	psha
	pshb
	ldx	MONSTK+$1A
	stx	MONSTK+$12
	anda	#$F8
	andb	#$07
	aba
	adda	MONSTK+$13
	staa	MONSTK+$13
	ldaa	MONSTK+$1E
	staa	MONSTK+$10
	clrb
	pula
	anda	#$F8
	lsra
	lsra
	lsra
L6A47:
	lsr	MONSTK+$10
	bcc	L6A5C
	psha
	pshb
	adda	MONSTK+$13
	adcb	MONSTK+$12
	staa	MONSTK+$13
	stab	MONSTK+$12
	pulb
	pula
L6A5C:
	asla
	rolb
	tst	MONSTK+$10
	bne	L6A47
	ldaa	#$80
	pulb
	andb	#$07
	beq	L6A6E
L6A6A:
	lsra
	decb
	bne	L6A6A
L6A6E:
	ldx	MONSTK+$12
L6A71:
	rts
;
L6A72:
	bsr	L6AE3
L6A74:
	bsr	VM_WH
	bsr	L6A8D
	bcs	L6A74
	rts
;
L6A7B:
	bsr	L6AE3
L6A7D:
	bsr	VM_BL
	bsr	L6A8D
	bcs	L6A7D
	rts
;
L6A84:
	bsr	L6AE3
L6A86:
	bsr	VM_REV
	bsr	L6A8D
	bcs	L6A86
	rts
;
L6A8D:
	ldaa	MONSTK+$39
	inca
	staa	MONSTK+$39
	cmpa	MONSTK+$36
	bhi	L6AD1
	ldaa	MONSTK+$38
	adda	MONSTK+$37
	bcs	L6AA9
	staa	MONSTK+$38
	cmpa	MONSTK+$36
	bcs	L6ABD
L6AA9:
	suba	MONSTK+$36
	staa	MONSTK+$38
	ldaa	MONSTK+$14
	ldab	MONSTK+$15
	adda	MONSTK+$34
	addb	MONSTK+$35
	bra	L6AC9
;
L6ABD:
	ldaa	MONSTK+$14
	ldab	MONSTK+$15
	adda	MONSTK+$32
	addb	MONSTK+$33
L6AC9:
	staa	MONSTK+$14
	stab	MONSTK+$15
	sec
	rts
;
L6AD1:
	ldaa	MONSTK+$14
	ldab	MONSTK+$15
	staa	MONSTK+$16
	stab	MONSTK+$17
	clc
	rts
;
L6AE3:
	staa	MONSTK+$18
	stab	MONSTK+$19
	clr	MONSTK+$32
	clr	MONSTK+$33
	clr	MONSTK+$34
	clr	MONSTK+$35
	suba	MONSTK+$16
	bcs	L6B02
	inc	MONSTK+$32
	inc	MONSTK+$34
	bra	L6B09
;
L6B02:
	nega
	dec	MONSTK+$32
	dec	MONSTK+$34
L6B09:
	subb	MONSTK+$17
	bcs	L6B16
	inc	MONSTK+$33
	inc	MONSTK+$35
	bra	L6B1D
;
L6B16:
	negb
	dec	MONSTK+$33
	dec	MONSTK+$35
L6B1D:
	cba
	bcs	L6B2C
	clr	MONSTK+$33
	staa	MONSTK+$36
	stab	MONSTK+$37
	tab
	bra	L6B35
;
L6B2C:
	clr	MONSTK+$32
	staa	MONSTK+$37
	stab	MONSTK+$36
L6B35:
	lsrb
	stab	MONSTK+$38
	clr	MONSTK+$39
	ldaa	MONSTK+$16
	ldab	MONSTK+$17
	staa	MONSTK+$14
	stab	MONSTK+$15
	rts
;
L6B49:
	clr	MONSTK+$37
	dec	MONSTK+$37
	bra	L6B5C
;
L6B51:
	clr	MONSTK+$37
	bra	L6B5C
;
L6B56:
	clr	MONSTK+$37
	inc	MONSTK+$37
L6B5C:
	staa	MONSTK+$14
	stab	MONSTK+$15
	stx	MONSTK+$24
	jsr	L6A14
	staa	MONSTK+$32
	beq	L6BA1
L6B6D:
	ldaa	MONSTK+$12
	ldab	MONSTK+$13
	staa	MONSTK+$22
	stab	MONSTK+$23
	addb	#$08
	adca	#$00
	staa	MONSTK+$12
	stab	MONSTK+$13
	ldab	MONSTK+$15
	orab	#$F8
L6B88:
	stab	MONSTK+$34
L6B8B:
	ldaa	MONSTK+$32
	staa	MONSTK+$33
	ldx	MONSTK+$24
	ldaa	$00,x
	inx
	stx	MONSTK+$24
	tsta
	bne	L6BA2
	ldaa	$00,x
	bne	L6B6D
L6BA1:
	rts
;
L6BA2:
	ldx	MONSTK+$22
	psha
	ldaa	MONSTK+$22
	ldab	MONSTK+$23
	cmpa	MONSTK+$1C
	bne	L6BB4
	cmpb	MONSTK+$1D
L6BB4:
	pula
	bcc	L6BE1
	clrb
	asl	MONSTK+$33
	bcs	L6BC4
L6BBD:
	lsra
	rorb
	asl	MONSTK+$33
	bcc	L6BBD
L6BC4:
	tst	MONSTK+$37
	bmi	L6BD9
	beq	L6BD1
	eora	$00,x
	eorb	$08,x
	bra	L6BDD
;
L6BD1:
	coma
	comb
	anda	$00,x
	andb	$08,x
	bra	L6BDD
;
L6BD9:
	oraa	$00,x
	orab	$08,x
L6BDD:
	staa	$00,x
	stab	$08,x
L6BE1:
	inx
	stx	MONSTK+$22
	inc	MONSTK+$34
	bne	L6B8B
	clra
	ldab	MONSTK+$1E
	subb	#$08
	addb	MONSTK+$23
	adca	MONSTK+$22
	staa	MONSTK+$22
	stab	MONSTK+$23
	ldab	#$F8
	bra	L6B88
*
T_PUNCH	LDX	MONSTK+$24
	STX	BEGA
	LDX	MONSTK+$26
	STX	ENDA
	JMP	PNCHJ	<--MIXDBUG
*
* TBUG HELP MSG
*
T_HELP	LDX	#T_HELPMSG
	JSR	T_PDATA1
	RTS
T_HELPMSG:
	FCB	$0D,$0A,' B ** ++ :BRANCH'
	FCB	$0D,$0A,' D ** ++ :DUMP'
	FCB	$0D,$0A,' G       :GO SWTBUG'
	FCB	$0D,$0A,' J **    :JUMP'
	FCB	$0D,$0A,' L       :KC LOAD'
	FCB	$0D,$0A,' M **    :MEMCHG [SP]'
	FCB	$0D,$0A,' P ** ++ :KC PUNCH'
	FCB	$0D,$0A,' T ** ++ :TRANS'
	FCB	$0D,$0A,' Z       :J BASIC'
	FCB	$04    
*
* TBUG	END
**
**------------------------------------------------------**
**      NAKAMOZU TINY BASIC                             **
**      BY HARUO YAMASHITA                              **
**      ASCII, Vol.3 #4 April, 1979                     **
** http://hyamasynth.web.fc2.com/ACII_NTB/ACII_NTB.html **
**------------------------------------------------------**
*       NTBV9.ASM  Ver.9  IRQ BREAK MODE                 *
*                             2018-08-08                 *
**------------------------------------------------------**
BOP:	EQU	$0036
EOP:	EQU	$0038
MEMEND:	EQU	$003A
WKA:	EQU	$0050
WKB:	EQU	$0052
WKC:	EQU	$0054
XS:	EQU	$0056
SPS:	EQU	$0058
MDS:	EQU	$005A
FS:	EQU	$005C
RNDS:	EQU	$0060
FLOD:	EQU	$0062
FAUT:	EQU	$0063
LPCT:	EQU	$0064
CHCT:	EQU	$0065
WKUSE:	EQU	$0066
OPT:	EQU	$0068	<--OPTION
LNB:	EQU	$006A
EOB:	EQU	$006C
EADRS:	EQU	$006E
XSP:	EQU	$0070
EOBF:	EQU	$00C0
CSTACK:	EQU	$00C8
TXTTOP	EQU	$2000	<--NTB PROGRAM TOP
TXTEND	EQU	RSVRAM	<--NTB PROGRAM END $3F00
;
;
	ORG	NTB	<--$F300
;
L6C00:
NTBSTART:
	jmp	L6CB2
WSTART:
	jmp	L6CBE
;
L6C06:
	FDB	TXTTOP
L6C08:
	FDB	TXTEND	
L6C0A:
	ldaa	FLOD
	bne	L6C66
	ldaa	FAUT
	beq	L6C25
	ldx	#LNB
	clrb
	ldaa	#$0A
	jsr	L6FE0
	jsr	L6F17
	jsr	L7386
	bra	L6C35
;
L6C23:
	bsr	L6C6E
L6C25:
	ldaa	#'>
	bsr	L6C98
	FCB	$8C	<-SKIP
L6C2A:
	BSR	L6C71
L6C2C:
	ldx	#XSP+9
L6C2F:
	dex
	cpx	#XSP+7
	beq	L6C2A
L6C35:
	eora	RNDS
	staa	RNDS
	bsr	L6C5E
	staa	$00,x
	cmpa	#$08
	beq	L6C2F
	cmpa	#$0D
	bne	L6C4B
	clr	$00,x
	stx	EOB
	bra	L6C71
;
L6C4B:
	cmpa	#$18
	beq	L6C23
	cmpa	#$1F
	bcs	L6C35
	inx
	cpx	#EOBF
	bne	L6C35
L6C59:
	ldab	#$01
	jmp	ERRMSG
;
L6C5E:
	jsr	INEEE
	cmpa	#$03
	beq	END
	JSR	OUTRAM	
	rts
;
L6C66:
	bsr	L6C5E
	cmpa	#$02
	bne	L6C66
	bra	L6C2C
;
L6C6E:
	jsr	NWLINE
L6C71:
	ldx	#XSP+8
	clr	CHCT
	rts
;
L6C78:
	ldx	BOP
	clr	$00,x
	inx
L6C7D:
	stx	EOP
	ldaa	#$80
	staa	$00,x
	rts
;
L6C8C:
	pula
	rts
_LOAD:
	bsr	L6C78
APPEND:
	bsr	L6C96
	staa	FLOD
	bra	L6CD3
;
L6C96:
	ldaa	#$11
L6C98:
	jmp	L6F64
AUTO:
	tpa
	staa	FAUT
	jsr	L7216
	suba	#$0A
	sbcb	#$00
L6CA5:
	staa	LNB+1
	stab	LNB
	rts
STOP:
	jsr	_PRINT
	jsr	DO
	bra	L6CC7
;
**------------ NTB START -------------**
L6CB2:
	LDS	#_STACK	<--@V9X
	ldx	L6C06
	stx	BOP
	ldx	L6C08
	stx	MEMEND
	LDX	#WSTART	<--@V9Y
	STX	STARTV	<--@V9Y
	LDX	#IRQ_BREAK
	STX	IRQ	<--IRQV	<--@IO
	CLR	IRQCHR
	JSR	IRQON	<--ACIA IRQ ON
NEW:
	bsr	L6C78
**------------ WARM START ------------**
L6CBE:
	jsr	CLRALL	<--VM_COPY@V7
END:
	lds	#_STACK
	jsr	INIT2
L6CC7:
	ldx	#RDYMSG
	jsr	PD
	jsr	NWLINE
	tpa
	staa	EADRS
L6CD3:
	lds	#_STACK
L6CD6:
	jsr	L6C0A
	jsr	L6FA3
	beq	L6CD6
	jsr	GETN
	bcc	L6D2F
	bsr	L6CA5
	bsr	L6CE9
	bra	L6CD3
;
L6CE9:
	stx	XS
	sts	SPS
	jsr	L6D81
	stx	WKC
	bcs	L6D0F
	jsr	NXTL
	inx
	sei
	txs
	ldx	WKC
	dex
	bra	L6D05
;
L6CFF:
	inx
	pulb
	stab	$00,x
	bne	L6CFF
L6D05:
	inx
	pulb
	stab	$00,x
	cmpb	#$80
	bne	L6CFF
	stx	EOP
L6D0F:
	ldx	XS
	ldaa	$00,x
	beq	INS3
	ldaa	EOB+1
	suba	XS+1
	adda	#$03
	ldx	EOP
	adda	EOP+1
	staa	EOP+1
	bcc	L6D26
	inc	EOP
L6D26:
	jsr	SIZE
	bcc	INS2
	stx	EOP
	bra	L6D92
L6D2F:
	bra	L6D6C
;
INS2:
	lds	EOP
	inx
MOVE2:
	dex
	ldaa	$00,x
	psha
	cpx	WKC
	bne	MOVE2
	lds	LNB
	sts	$00,x
	inx
	lds	XS
	des
MOVE3:
	inx
	pula
	staa	$00,x
	bne	MOVE3
INS3:
	lds	SPS
	cli
	rts
;
INIT2:
	ldx	#$0000
	stx	FLOD
	stx	FAUT
	stx	WKUSE
	ldx	#MONSTK
	stx	XSP+4
	ldx	#SUBSTK
	stx	XSP
	ldx	#CSTACK
	stx	XSP+2
	ldx	L6C06
	stx	XSP+6
	rts
;
L6D6C:
	jsr	L6F83
	bcc	L6DD2
	ldx	#L764C
	bra	L6DDA
;
NXTL:
	inx
L6D77:
	inx
NXTL2:
	tst	$00,x
	bne	L6D77
	rts
;
L6D7D:
	ldx	EADRS
	bpl	L6D84
L6D81:
	ldx	BOP
	inx
L6D84:
	ldaa	LNB+1
	ldab	LNB
	bmi	ERR120
	bne	LNFD3
	tsta
	bne	LNFD3
ERR120:
	ldab	#$03
	FCB	$8C	<-SKIP
L6D92
	LDAB	#$02
	jmp	ERRMSG
;
L6D97:
	bsr	NXTL
L6D99:
	inx
LNFD3:
	jsr	L6E0D
	bhi	L6D97
	rts
;
IF2:
	jsr	L7216
	tstb
	bne	L6DA7
	tsta
L6DA7:
	rts
IF:
	bsr	IF2
	beq	NXTL2
	bra	STMT3
;
SIZE:
	ldaa	MEMEND+1
	ldab	MEMEND
	suba	EOP+1
	sbcb	EOP
	rts
C7:
	jmp	L6CC7
RUN:
	bsr	INIT2
	ldx	BOP
	inx
STMT:
	stx	EADRS
	ldaa	$00,x
	asla
	ldaa	EADRS
	bls	C7
	inx
	inx
STMT3:
	jsr	L6F83
	bcs	L6DD7
L6DD2:
	jsr	L7258
	bra	L6DE0
;
L6DD7:
	ldx	#DEL2
L6DDA:
	lds	#_STACK
	jsr	L70D0
L6DE0:
	dex
L6DE1:
	jsr	L6FA2
	bne	L6DE1
	INX
	bcc	STMT
	bra	STMT3
;
L6DEA:
	rola
	asla
	asla
	asla
	asla
L6DEF:
	rol	WKC
	rolb
	asla
	bne	L6DEF
L6DF6:
	inx
	bsr	L6DFE
	bcs	L6DEA
	ldaa	WKC
	rts
;
L6DFE:
	jsr	L7064
	bcs	L6E0C
	suba	#$07
	cmpa	#$3A
	clc
	blt	L6E0C
	cmpa	#$40
L6E0C:
	rts
;
L6E0D:
	cmpb	$00,x
	bne	L6E13
	cmpa	$01,x
L6E13:
	rts
;
L6E14:
	stx	XS
	ldx	#XS2
L6E19:
	sts	SPS
	sei
L6E1C:
	lds	XS
	des
	inx
L6E20:
	inx
	pula
	tab
	subb	$00,x
	aslb
	beq	L6E36
L6E28:
	ldab	$00,x
	inx
	bpl	L6E28
	cmpa	#'.
	beq	L6E39
	comb
	bne	L6E1C
	bra	L6E3C
;
L6E36:
	bcc	L6E20
	inx
L6E39:
	ins
	sts	XS
L6E3C:
	lds	SPS
	cli
	rts
;
_PRINT:
	clr	WKUSE
	bsr	L6E67
	beq	L6E6A
L6E47:
	bsr	L6E8B
	beq	L6E53
	stx	XS
	ldx	#L7740
	jsr	L70D0
L6E53:
	bsr	L6E67
	beq	L6E6A
	cmpa	#';
	beq	L6E61
	cmpa	#',
	bne	L6EA4
	bsr	L6E70
L6E61:
	inx
	bsr	L6E67
	bne	L6E47
	rts
L6E67:
	jmp	L6FA3
L6E6A:
	jmp	NWLINE
;
L6E6D:
	jsr	L7386
L6E70:
	ldaa	CHCT
	bita	#$07
	bne	L6E6D
	rts
CHR:
	jsr	L7216
L6E7A:
	jmp	L6F64
TAB:
	jsr	L7216
	tab
	bra	L6E86
;
L6E83:
	jsr	L7386
L6E86:
	cmpb	CHCT
	bhi	L6E83
	rts
;
L6E8B:
	bsr	L6E67
	cmpa	#'"
	beq	L6E95
	cmpa	#$27
	bne	L6EA3
L6E95:
	tab
	inx
	bra	L6E9B
;
L6E99:
	bsr	L6E7A
L6E9B:
	ldaa	$00,x
	beq	L6EA4
	inx
	cba
	bne	L6E99
L6EA3:
	rts
;
L6EA4:
	ldab	#$04
	FCB	$8C
L6EA7:
	LDAB	#$05
	jmp	ERRMSG
;
L6EAC:
	ldaa	$00,x
	oraa	$01,x
	beq	L6EA7
	bsr	L6EF8
	bsr	L6EE6
	rola
	nega
	tab
	bsr	L6EEB
	rola
	eora	#$01
	rora
	bsr	L6EE1
	staa	$5B
	stab	$5A
	jsr	L6E0D
	bne	L6ED2
	clra
	tab
	inc	$03,x
	bne	L6ED2
	inc	$02,x
L6ED2:
	inx
	inx
	rts
;
L6ED5:
	bsr	L6EF8
L6ED7:
	bsr	L6EE6
	rola
	rolb
	suba	$01,x
	sbcb	$00,x
	bsr	L6EEB
L6EE1:
	dec	LPCT
	bne	L6ED7
L6EE6:
	rol	$03,x
	rol	$02,x
	rts
;
L6EEB:
	pshb
	eorb	$00,x
	pulb
	sec
	bpl	L6EF7
L6EF2:
	adda	$01,x
	adcb	$00,x
	clc
L6EF7:
	rts
;
L6EF8:
	ldaa	#$10
	staa	LPCT
	clra
	clrb
	rts
;
L6EFF:
	bsr	L6EF8
L6F01:
	asla
	rolb
	rol	$01,x
	rol	$00,x
	bcc	L6F0D
	adda	$03,x
	adcb	$02,x
L6F0D:
	dec	LPCT
	bne	L6F01
	inx
	inx
	jmp	L6FE4
;
L6F17:
	ldx	$00,x
	stx	WKB
	ldx	#WKB
	bsr	L6F6D
	bcs	L6F28
	ldab	WKUSE
	beq	L6F2C
	tba

	FCB	$8C
L6F28:
	LDAA	#2D
	bsr	L6F64
L6F2C:
	dex
	dex
	ldab	#$0A
	stab	$01,x
	clr	$00,x
	asrb
L6F35:
	pshb
	bsr	L6ED5
	pulb
	psha
	decb
	bne	L6F35
	ldx	#XSP+8
	ldab	#$04
L6F42:
	ldaa	LPCT
	pula
	bne	L6F54
	staa	LPCT
	bne	L6F54
	tst	WKUSE
	beq	L6F56
	ldaa	$67
	suba	#$30
L6F54:
	bsr	L6F5A
L6F56:
	decb
	bne	L6F42
	pula
L6F5A:
	adda	#$30
	tst	FAUT
	beq	L6F64
	staa	$00,x
	inx
L6F64:
	inc	CHCT
*	jsr	OUTEEE	<--
	jmp	T_OUT	<--
;
L6F6D:
	tst	$00,x
	bpl	L6F79
L6F71:
	neg	$01,x
	bne	L6F77
	dec	$00,x
L6F77:
	com	$00,x
L6F79:
	rts
;
L6F7A:
	cmpa	#'@
	bcs	L6F81
	cmpa	#'[
	rts
;
L6F81:
	clc
	rts
;
L6F83:
	bsr	L6FA3
	stx	XS
	cmpa	#'!
	beq	L6FAE
	cmpa	#'.
	beq	L6FAE
	cmpa	#'*
	beq	L6FAE
	bsr	L6F7A
	bcc	L6F81
	ldaa	$01,x
	cmpa	#'.
	beq	L6FAE
	bsr	L6F7A
	bcc	L6F81
	rts
;
L6FA2:
	inx
	JSR	IRQON	<--IRQ ON
L6FA3:
	ldaa	$00,x
	cmpa	#$20
	beq	L6FA2
	tsta
	beq	L6FAF
	cmpa	#':
L6FAE:
	sec
L6FAF:
	rts
;
L6FB0:
	bsr	L6FA3
	cmpa	#'-
	bne	L6FBA
	bsr	L6FD7
	bra	L6FC1
;
L6FBA:
	cmpa	#'+
	beq	L6FBF
	dex
L6FBF:
	bsr	L700F
L6FC1:
	ldx	XS
	bsr	L6FA3
	cmpa	#'+
	bne	L6FCF
	bsr	L700F
L6FCB:
	bsr	L6FDB
	bra	L6FC1
;
L6FCF:
	cmpa	#'-
	bne	L6FE8
	bsr	L6FD7
	bra	L6FCB
;
L6FD7:
	bsr	L700F
	bra	L6F71
;
L6FDB:
	jsr	L7218
	inx
	inx
L6FE0:
	adda	$01,x
	adcb	$00,x
L6FE4:
	staa	$01,x
	stab	$00,x
L6FE8:
	rts
ABS:
	jsr	L7105
	bsr	L7011
	jsr	L6F6D
	ldx	XS
	rts
;
L6FF4:
	orab	#$01
	FCB	$8C	<-SKIP
L6FF7:
	orab	#$02
	FCB	$8C	<-SKIP
L6FFA:
	orab	#$04
	FCB	$08	<--?
	FCB	$C1	<--?
REL:
	clrb	


	bsr	L6FA3
	cmpa	#'>
	beq	L6FF4
	cmpa	#'=
	beq	L6FF7
	cmpa	#'<
	beq	L6FFA
	clra
	rts
;
L700F:
	bsr	L706F
L7011:
	stx	XS
	ldx	XSP+2
L7015:
	rts
;
EXPR:
	bsr	L6FB0
	bsr	REL
	tstb
	beq	L7015
	pshb
	bsr	L6FB0
	jsr	L7218
	ldx	XSP+2
	suba	$01,x
	sbcb	$00,x
	pulb
	blt	LT
	bgt	GT
	tsta
	beq	EQ
GT:
	asrb
EQ:
	asrb
LT:
	andb	#$01
	stab	$01,x
	clr	$00,x
	ldx	WKC
	rts
;
GETN:
	bsr	L7064
	bcc	L7063
	clrb
	stab	WKC+1
L7043:
	stab	WKC
	anda	#$0F
	staa	LPCT
	ldaa	WKC+1
	asla
	rolb
	asla
	rolb
	adda	WKC+1
	adcb	WKC
	asla
	rolb
	adda	LPCT
	staa	WKC+1
	adcb	#$00
	inx
	bsr	L7064
	bcs	L7043
	ldaa	WKC+1
	sec
L7063:
	rts
;
L7064:
	jsr	L6FA3
	cmpa	#'0
	clc
	blt	L706E
	cmpa	#':
L706E:
	rts
;
L706F:
	bsr	L70B3
L7071:
	jsr	L6FA3
	cmpa	#'*
	bne	L7083
	bsr	L708E
	jsr	L6EFF
L707D:
	stx	XSP+2
	ldx	XS
	bra	L7071
;
L7083:
	cmpa	#'/
	bne	L7063
	bsr	L708E
	jsr	L6EAC
	bra	L707D
;
L708E:
	bsr	L70B3
	jmp	L7011
;
L7093:
	clrb
	stab	WKC
	jsr	L6DF6
	bra	L70E4
;
L709B:
	bsr	L70B3
	jsr	L7218
	bsr	L7117
	ldaa	$00,x
	clrb
	bra	L70E2
;
L70A7:
	cmpa	$02,x
	bne	L70F9
	ldaa	$01,x
	clrb
	inx
	inx
	inx
	bra	L70E4
;
L70B3:
	inx
	bsr	GETN
	bcs	L70E4
	cmpa	#'#
	beq	L709B
	cmpa	#'"
	beq	L70A7
	cmpa	#$27
	beq	L70A7
	cmpa	#'$
	beq	L7093
	jsr	L6F83
	bcc	L7101
	ldx	#L76F7
L70D0:
	jsr	L6E19
	ldaa	$01,x
	psha
	ldaa	$00,x
	psha
	ldx	XS
	rts
;
L70DC:
	bsr	L7117
	ldaa	$01,x
	ldab	$00,x
L70E2:
	ldx	XS
L70E4:
	stx	WKC
	ldx	XSP+2
	dex
	dex
	cpx	EOB
	ble	L70F6
L70EE:
	jsr	L6FE4
	stx	XSP+2
L70F3:
	ldx	WKC
	rts
;
L70F6:
	ldab	#$06
	FCB	$8C	<-SKIP
L70F9:
	LDAB	#$07
	FCB	$8C	<-SKIP
L70FC:
	LDAB	#$08
	jmp	ERRMSG
;
L7101:
	bsr	L717C
	bcc	L70DC
L7105:
	ldaa	$00,x
	cmpa	#'(
	bne	L70F9
L710B:
	inx
L710C:
	jsr	EXPR
L710F:
	ldaa	$00,x
	cmpa	#')
	bne	L70F9
	inx
	rts
;
L7117:
	stx	XS
	staa	WKC+1
	stab	WKC
	bra	L70F3
MOD:
	jsr	L74C8
	beq	L712A
	ldab	MDS
	ldaa	MDS+1
	bra	L70E4
;
L712A:
	inx
	jsr	EXPR
	bsr	L713E
	bne	L70FC
	inx
	bsr	L710C
L7135:
	stx	WKC
	ldx	XSP+2
	jsr	L6EAC
	bra	L70EE
;
L713E:
	ldaa	$00,x
	cmpa	#',
	rts
RND:
	ldab	RNDS+1
	ldaa	RNDS
	aba
	adcb	#$95
	adca	#$AB
	staa	RNDS+1
	stab	RNDS
	bsr	L70E4
	bsr	L7105
	bra	L7135
USER:
	jsr	L7567
	bsr	L715D
	bra	L70E2
;
L715D:
	bsr	L7175
	psha
	pshb
	bsr	L7170
	psha
	pshb
	bsr	L7170
	psha
	pshb
	tpa
	psha
	bsr	L710F
	stx	XS
	rti
;
L7170:
	bsr	L713E
	bne	L7178
	inx
L7175:
	jmp	L7216
;
L7178:
	clra
	clrb
L717A:
	sec
	rts
;
L717C:
	jsr	L6FA3
	cmpa	#'%
	beq	L7191
	cmpa	#'@
	bcs	L717A
	cmpa	#']
	bhi	L717A
	anda	#'?
	asla
	clrb
	inx
	rts
;
L7191:
	inx
	jsr	L7064
	bcc	L71D0
	inx
	jsr	L74C8
	beq	L71A4
L719D:
	anda	#$0F
	asla
	adda	#$3C
	clrb
	rts
;
L71A4:
	psha
	jsr	L710B
	pula
	bsr	L719D
	jsr	L7117
	jsr	L721A
	asla
	rolb
	jsr	L6EF2
	ldx	XS
	rts
;
L71B9:
	jsr	L717C
	bcs	L71D3
L71BE:
	staa	WKB+1
	stab	WKB
	ldaa	$00,x
	cmpa	#'=
	bne	L71D3
	inx
	bsr	L7216
	stx	XS
	ldx	WKB
	rts
;
L71D0:
	ldab	#$0E
	FCB	$8C	<-SKIP
L71D3:
	LDAB	#$09
	FCB	$8c	<-SKIP
L71D6:
	LDAB	#$0A
	jmp	ERRMSG
THEN:
	clr	FS+3
	jsr	GETN
	bcs	L7236
	jmp	STMT3
;
L71E6:
	jsr	L70B3
	bsr	L7218
	bsr	L71BE
	tab
	bra	L7261
;
DO:
	sts	SPS
	sei
	txs
	ldx	XSP
	cpx	#_STACK+3
	beq	L71D6
	dex
	dex
	sts	$00,x
L71FF:
	stx	XSP
	tsx
	lds	SPS
	cli
	rts
;
RET:
	ldx	XSP
	cpx	#SUBSTK
	beq	L71D6
	sts	SPS
	sei
	lds	$00,x
	inx
	inx
	bra	L71FF
;
L7216:
	bsr	L722E
L7218:
	stx	WKC
L721A:
	ldx	XSP+2
	cpx	#CSTACK
	beq	L71D3
	ldaa	$01,x
	ldab	$00,x
	inx
	inx
	stx	XSP+2
	ldx	WKC
L722B:
	rts
;
L722C:
	ldx	XS
L722E:
	jmp	EXPR
_GOTO:
	clra
GOSUB:
	staa	FS+3
	bsr	L7216
L7236:
	jsr	L6CA5
	tstb
	bne	L723F
	tsta
	beq	L722B
L723F:
	tst	FS+3
	beq	L7246
	bsr	DO
L7246:
	ldx	EADRS
	jsr	L6E0D
	bcc	L7250
	ror	EADRS
L7250:
	jsr	L6D7D
	bcs	L72AD
	jmp	STMT
;
L7258:
	cmpa	#'#
	beq	L71E6
L725C:
	jsr	L71B9
	staa	$01,x
L7261:
	stab	$00,x
	ldx	XS
	rts
FOR:
	bsr	L725C
	ldaa	WKB+1
	ldab	WKB
	jsr	L70E4
	jsr	L6E14
	cpx	#L773C
	bne	L72AA
	bsr	L722C
	jsr	L6E14
	cpx	#L7742
	beq	L7289
	ldaa	#$01
	clrb
	jsr	L70E2
	bra	L728D
;
L7289:
	bsr	L722C
	stx	XS
L728D:
	ldaa	XS+1
	ldab	XS
	jsr	L70E4
	ldaa	WKB+1
	ldab	WKB
	ldx	XSP+4
	cpx	#MONSTK
	beq	L72B7
	bsr	L72BB
	bcc	L72B5
	ldx	XSP+4
	cpx	#CSTACK
	bne	L72B7
L72AA:
	ldab	#$0C
	FCB	$8C	<-SKIP
L72AD:
	LDAB	#$0B
	FCB	$8C	<-SKIP
	LDAB	#$0D
	jmp	ERRMSG
;
L72B5:
	bsr	L730B
L72B7:
	bsr	L72C9
	bra	L7306
;
L72BB:
	jsr	L6E0D
	beq	L72C8
	bsr	L730B
L72C2:
	cpx	#MONSTK
	bne	L72BB
	sec
L72C8:
	rts
;
L72C9:
	bsr	L72CB
L72CB:
	bsr	L72CD
L72CD:
	jsr	L7218
	dex
	dex
	jmp	L6FE4
NEXT:
	jsr	L717C
	stx	XS
	ldx	XSP+4
	bcc	L72E2
	ldaa	$01,x
	ldab	$00,x
L72E2:
	bsr	L72C2
	FCB	$25
	FCB	$CA
	stx	XSP+4
	ldaa	$05,x
	ldab	$04,x
	ldx	$00,x
	jsr	L6FE0
	ldx	XSP+4
	cmpb	$02,x
	sec
	blt	L72FF
	clc
	bgt	L72FF
	cmpa	$03,x
	beq	L7314
L72FF:
	rora
	eora	$04,x
	bmi	L7314
	bsr	L730B
L7306:
	stx	XSP+4
	ldx	XS
	rts
;
L730B:
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	inx
	rts
;
L7314:
	ldx	$06,x
	rts
INPUT:
	stx	WKB
	ldaa	WKB
	beq	L7373
	ldx	EOB
	stx	WKA
	ldx	WKB
	jsr	L6E8B
	bne	L732A
	bsr	L7376
L732A:
	jsr	L717C
	bcs	L7373
	psha
	pshb
	stx	WKB
	ldx	WKA
	bsr	L7383
	bne	L7342
L7339:
	ldaa	#$3F
	bsr	L7388
	bsr	L7386
	jsr	L6C2C
L7342:
	jsr	L6FA3
	cmpa	#'$
	bcs	L734D
	cmpa	#'[
	bcs	L7357
L734D:
	stx	WKC
	ldx	#L7645
	jsr	L7402
	bra	L7339
;
L7357:
	jsr	L7216
	bsr	L7376
	stx	WKA
	tsx
	ldx	$00,x
	ins
	ins
	jsr	L6FE4
	ldx	WKB
	bsr	L7383
	beq	L737B
	cmpa	#',
	bne	L7373
	inx
	bra	L732A
L7373:
	jmp	L6C59
;
L7376:
	bsr	L737C
	bne	L737B
	inx
L737B:
	rts
;
L737C:
	psha
	bsr	L7383
	cmpa	#',
	pula
	rts
L7383:
	jmp	L6FA3
;
L7386:
	ldaa	#$20
L7388:
	jmp	L6F64
;
L738B:
	bsr	L738D
L738D:
	stx	WKC
	ldx	#$20	<--DELAY
L7392:
	dex
	bne	L7392
	ldx	WKC
	rts
;
L7398:
	ldaa	#$12
	bsr	L7388
	staa	FS
	bsr	L738B
	bra	L73A5
LIST:
	clr	FS
L73A5:
	clrb
	stab	WKUSE
	ldaa	#$01
	jsr	L6CA5
	ldab	#$7F
	ldaa	#$FF
	psha
	bsr	L7383
	pula
	beq	L73C5
	jsr	L7216
	jsr	L6CA5
	bsr	L737C
	bne	L73C5
	inx
	jsr	L7216
L73C5:
	staa	SPS+1
	stab	SPS
	ldx	SPS
	bgt	L73D2
	ldx	#$7FFF	<--
	stx	SPS
L73D2:
	jsr	L6D81
	FCB	$8C
L73D6
	FDB	$8D13
	ldaa	SPS+1
	ldab	SPS
	jsr	L6E0D
	bcc	L73D6
	stx	WKC
	ldx	#L762B	<--STOP PUNCH
	bsr	L7402
C9:
	jmp	END
;
LISTX:
	ldaa	#$02
	bsr	L7388
	bsr	PNUM9
	inx
	ldaa	#$20
	bsr	PD2
	bsr	NWLINE
	ldaa	FS
	bne	L738D
	rts
;
NWLINE:
	stx	WKC
	ldx	#_CRLF
L7402:
	bsr	PD
	clr	CHCT
LX2:
	ldx	WKC
	rts
;
PNUM9:
	stx	WKC
L740C:
	jsr	L6F17
	bra	LX2
;
PD2:
	jsr	L6F64
	inx
PD:
	ldaa	$00,x
	bne	PD2
	inx
	rts
;
ERRMSG:
	lds	#_STACK
	bsr	NWLINE
	ldx	#ERR
	bsr	PD
	tba
	clrb
	stab	WKUSE
	bsr	PRACC
	ldx	EADRS
	bmi	C9
	bsr	NWLINE
	bsr	LISTX
	bra	C9
USING:
	ldab	$00,x
	stab	WKUSE
	ldab	$01,x
	stab	WKUSE+1
	inx
	inx
PREXPR:
	jsr	L7216
PRACC:
	psha
	pshb
	stx	WKC
	tsx
	bsr	L740C
	pulb
	pula
	clr	WKUSE
	rts
;
L744F:
	lsra
	lsra
	lsra
	lsra
L7453:
	anda	#$0F
	cmpa	#$0A
	bcs	L745B
	adda	#$07
L745B:
	adda	#$30
L745D:
	jmp	L6F64
;
L7460:
	psha
	tba
	bsr	L7465
	pula
L7465:
	psha
	bsr	L744F
	pula
	bra	L7453
HD:
	ldaa	#$24
	bsr	L745D
	ldaa	$00,x
	inx
	cmpa	#'T
	beq	L747E
	jsr	L7216
	bsr	L7460
L747B:
	jmp	L7386
;
L747E:
	jsr	L7216
	bsr	L7465
	bra	L747B
GET:
	jsr	L6C5E
	clrb
	jmp	L70E4
COPY:
	jsr	CLRALL
	bra	L74AF
GRA:
	jsr	L6973
	LDAB	#$1A	<--GCRAM
	JSR	CLRCO1
	bra	L74AF
PIX:
	bsr	L74DE
	bsr	L74CF
	jsr	VM_PIX
	tba
	clrb
	ldx	XS
	jmp	L70E4
EXM:
	ldaa	$00,x
	cmpa	#'W
	bne	L74B2
	bsr	L74CD
	jsr	VM_WH
L74AF:
	ldx	XS
	rts
;
L74B2:
	cmpa	#'B
	bne	L74BD
	bsr	L74CD
	jsr	VM_BL
	bra	L74AF
;
L74BD:
	cmpa	#'R
	bne	L7528
	bsr	L74CD
	jsr	VM_REV
	bra	L74AF
;
L74C8:
	ldab	$00,x
	cmpb	#'(
	rts
;
L74CD:
	bsr	L74D8
L74CF:
	cmpa	#$C0
	bcc	L74EC
	cmpb	#$A6
	bcc	L74EC
	rts
;
L74D8:
	inx
	bsr	L74C8
	bne	L752E	<--ERR9
L74DD:
	inx
L74DE:
	jsr	L7570
	orab	FS
	bne	L74EC
	tab
	ldaa	FS+1
	rts
;
	ldab	#$0F
	FCB	$8C	<-SKIP
L74EC:
	LDAB	#$10
	jmp	ERRMSG
;
L74F1:
	bcc	L74EC
	cba
	bgt	L74EC
	rts
CLR:
	JSR	CLRCOL
	bsr	L74C8
	bne	L7503
	bsr	L74DD
	cmpb	#$1D
	bsr	L74F1
	bra	L7509
;
L7503:
	clra
	ldab	#$1C
	jsr	L69EC
L7509:
	psha
	ldaa	#$1C
	bsr	L7541
	stx	FS+2
	clra
	pulb
	bsr	L7541
L7514:
	jsr	L77ED
	bitb	#$02
	bne	L751F
	ldab	#$A0
	stab	$00,x
L751F:
	inx
	cpx	FS+2
	bne	L7514
	clra
	clrb
	bra	L753D
L7528:
	jmp	L775B
;
L752B:
	ldx	XS
	rts
L752E:
	jmp	L71D3
CURS:
	bsr	L7567
	bsr	L74DE
	cmpa	#$1D
	bcc	L74EC
	cmpb	#$1D
	bpl	L74EC
L753D:
	bsr	L7541
	bra	L752B
;
L7541:
	jsr	L689A	<--
	jsr	L68DD	<--
	ldx	MONSTK+$02
	rts
SGN:
	jsr	L7105
	jsr	L7218
	tstb
	bmi	L755E
	bne	L7559
	tsta
	beq	L7561
L7559:
	clrb
	ldaa	#$01
	bra	L7561
;
L755E:
	ldaa	#$FF
	tab
L7561:
	jmp	L70E4
L7564:
	jmp	L70F9
;
L7567:
	jsr	L74C8
	bne	L7564
	inx
	rts
;
L756E:
	bsr	L7567
L7570:
	jsr	L7216
	staa	FS+1
	stab	FS
	jsr	L713E
	bne	L752E	<--ERR9
L757C:
	inx
	jsr	L7216
	psha
	jsr	L710F
	pula
	stx	XS
	rts
AND:
	bsr	L756E
	anda	FS+1
	andb	FS
L758E:
	jmp	L70E4
OR:
	bsr	L756E
	oraa	FS+1
	orab	FS
	bra	L758E
XOR:
	bsr	L756E
	eora	FS+1
	eorb	FS
	bra	L758E
;
RESTORE:
	jsr	L7216
	stx	WKA
	ldx	BOP
	jsr	L6D99
	bcs	L75E7
	dex
	bra	L75D7
READ:
	stx	WKA
	ldx	XSP+6
	jsr	L6FA3
	cmpa	#',
	beq	L75D3
	tsta
	beq	L75C4
	jmp	L6C59
;
L75C1:
	jsr	NXTL
L75C4:
	ldaa	$01,x
	cmpa	#$80
	beq	L75EA
	ldaa	$03,x
	inx
	cmpa	#$2A
	bne	L75C1
	inx
	inx
L75D3:
	inx
	jsr	EXPR
L75D7:
	stx	XSP+6
	ldx	WKA
	rts
DEL:
	bsr	RESTORE
	ldx	XSP+6
	inx
	jsr	L6C7D
	jmp	END
L75E7:
	jmp	L72AD
;
L75EA:
	ldab	#$11
	jmp	ERRMSG
*
*KEY:
*	jsr	L74C8	<-@11.27
*	beq	L7600
*	ldaa	#$18
*L75F6:
*	deca
*	bmi	L760F
*	jsr	L77C6
*	bcs	L75F6
*	bra	L7611
;
*L7600:
*	jsr	L757C
*	tstb
*	bne	L7617
*	cmpa	#$18
*	bpl	L7617
*	jsr	L77C6
*	bcc	L7611
*
KEY:
	LDAA	IRQCHR
	BNE	L7611	<-@11.27	
L760F:
	ldaa	#$64
L7611:
	CLR	IRQCHR
	clrb
	ldx	$56
	jmp	L70E4
L7617:
	jmp	L74EC
UNTIL:
	jsr	IF2
	beq	L7625
	jsr	RET
	ldx	WKC
	rts
;
L7625:
	ldx	XSP
	ldx	$00,x
	inx
	rts
;
L762B:
	FCB	$03	<--TAPE IO
	FCB	$13
	FCB	$14
	FCB	$00
;
;	TABLE
N	EQU	$80
ERR:
	FCC	/ERROR NO./
	FCB	$00
	FCB	$0D,$0A
RDYMSG:	FCC	/READY/
	FCB	$07,$00
_CRLF:
	FCB	$0D,$0A,$00
L7645:
	FCC	/RE-ENTE/
L764C:
	FCB	'R
	FCB	$00
	FCB	'LIS
	FCB	N+'T
	FDB	LIST
	FCB	'LOA
	FCB	N+'D
	FDB	_LOAD
	FCB	'RU
	FCB	N+'N
	FDB	RUN
	FCB	'E
	FCB	N+'X
	FDB	START
	FCB	'AUT
	FCB	N+'O
	FDB	AUTO
	FCB	'NE
	FCB	N+'W
	FDB	NEW
	FCB	'SAV
	FCB	N+'E
	FDB	SAVE
	FCB	'APPEN
	FCB	N+'D
	FDB	APPEND
	FCB	'DE
	FCB	N+'L
DEL2:
	FDB	DEL
	FCB	'NEX
	FCB	N+'T
	FDB	NEXT
	FCB	'UNTI
	FCB 	N+'L
	FDB	UNTIL
	FCB	'GOT
	FCB	N+'O
	FDB	_GOTO
	FCB	'GOSU
	FCB	N+'B
	FDB	GOSUB
	FCB	'THE
	FCB	N+'N
	FDB	THEN
	FCB	'FO
	FCB	N+'R
	FDB	FOR
	FCB	'D
	FCB	N+'O
	FDB	DO
	FCB	N+'!
	FDB	EXM
	FCB	'RE
	FCB	N+'T
	FDB	RET
	FCB	'INPU
	FCB	N+'T
	FDB	INPUT
	FCB	'I
	FCB	N+'F
	FDB	IF
	FCB	'PRIN
	FCB	N+'T
	FDB	_PRINT
	FCB	'CL
	FCB	N+'R
	FDB	CLR
	FCB	'CUR
	FCB	N+'S
	FDB	CURS
	FCB	'GR
	FCB	N+'A
	FDB	GRA
	FCB	'RESTOR
	FCB	N+'E
	FDB	RESTORE
	FCB	'RE
	FCB	N+'M
	FDB	NXTL2
	FCC	N+'*
	FDB	NXTL2
	FCB	'EN
	FCB	N+'D
	FDB	END
	FCB	'STO
	FCB	N+'P
	FDB	STOP
	FCB	'COP
	FCB	N+'Y
	FDB	COPY
	FCB	$FF	<--?
L76F7:
	FDB	L752E
	FCB	'RN
	FCB	N+'D
	FDB	RND
	FCB	'REA
	FCB	N+'D
	FDB	READ
	FCB	'AB
	FCB	N+'S
	FDB	ABS
	FCB	'MO
	FCB	N+'D
	FDB	MOD
	FCB	'!P
	FCB	N+'( 
	FDB	PIX
	FCB	'USE
	FCB	N+'R
	FDB	USER
	FCB	'AN
	FCB	N+'D
	FDB	AND
	FCB	'O
	FCB	N+'R
	FDB	OR
	FCB	'XO
	FCB	N+'R
	FDB	XOR
	FCB	'SG
	FCB	N+'N
	FDB	SGN
	FCB	'KE
	FCB	N+'Y
	FDB	KEY
	FCB	'GET
	FCB	N+'$
	FDB	GET
	FCB	$FF	<--?
XS2:	
	FDB	L70F9
	FCB	'T
	FCB	N+'O
L773C:
	FDB	$0000
	FCB	'ST
L7740	FCB	'E
	FCB	$D0
L7742:
	FCB	'CHR
	FCB	N+'$
	FDB	CHR
	FCB	'TA
	FCB	N+'B
	FDB	TAB
	FCB	'H
	FCB	N+'D
	FDB	HD
	FCB	'USIN
	FCB	N+'G
	FDB	USING
	FCB	$FF	<--
	FDB	PREXPR
;
;
;	END OF NAKAMOZU TINY BASIC
;
;
L775B:
	cmpa	#'L
	bne	L777A
	bsr	L77A4
	dec	OPT
	beq	L7775
	dec	OPT
	beq	L7770
	jsr	L6A84
	bra	L77A1
;
L7770:
	jsr	L6A7B
	bra	L77A1
;
L7775:
	jsr	L6A72
	bra	L77A1
;
L777A:
	cmpa	#'S
	bne	L77C3
	bsr	L77A4
	psha
	pshb
	jsr	L7216
	jsr	L7117
	pulb
	pula
	dec	OPT
	beq	L779E
	dec	OPT
	beq	L7799
	jsr	L6B56
	bra	L77A1
;
L7799:
	jsr	L6B51
	bra	L77A1
;
L779E:
	jsr	L6B49
L77A1:
	ldx	XS
	rts
;
L77A4:
	clr	OPT
	inx
	ldaa	$00,x
	cmpa	#'W
	beq	L77BC
	cmpa	#'B
	beq	L77B9
	cmpa	#'R
	bne	L77C3
	inc	OPT
L77B9:
	inc	OPT
L77BC:
	inc	OPT
	jsr	L74D8
	rts
L77C3:
	jmp	L71D3
;
* L77C6:
*	psha
*	ldx	#$E3DB
*	inca
* L77CB:
*	inx
*	deca
*	bne	L77CB
*	ldaa	$00,x
*	staa	$8022
*	ldaa	$8022
*	tst	$8020
*	bpl	L77DD
*	sec
* L77DD:
*	pula
*	rts
* L77C6:
* 	PSHA
* 	JSR	INGGG
* 	PULA
*	RTS
SAVE:
	ldaa	#$51
	staa	PACICS
	jmp	L7398
L77ED:
	stx	MONSTK
	jsr	L69BE
	ldab	$00,x
	ldx	MONSTK
	rts
*
* IRQ SERVICE ROUTINE
*
IRQ_BREAK:
	LDAA	ACIACS
	ASLA
	BCC	RTIRQ
	LSRA
	LSRA		<--RDRF 
	BCC	IRQERR
	LDAA	ACIADA
	ANDA	#$7F
	STAA	IRQCHR	<-@11.27
	CMPA	#$03
	BNE	RTIRQ
	CLR	IRQCHR
	JMP	END	<--GO TO END
*
IRQERR	LDAA	ACIADA	<--DISCARD
	CLR	IRQCHR
RTIRQ	RTI
*
* ACIA IRQ ON
*
IRQON	PSHA
	LDA A	#$95	<--IRQ ON
	STA A	ACIACS
	PULA
	CLI		<--CLI
	RTS
*
	END
*
**--------------------------------**