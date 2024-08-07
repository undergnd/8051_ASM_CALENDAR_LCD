;*****************************************************************************
; PROGRAM STERUJACY UKLADEM KONTROLI DOSTEPU Z DS1990
;*****************************************************************************
$NOMOD51
$INCLUDE (REG8252.INC)
TAKT                    EQU   0FDH ; Wartosc pocz. timera                              
SPR                     EQU   0DH  ; "ENTER"
;******************************************************************************

ORG 00H
AJMP IN

;******************************************************************************
;       PRZERWANIE OD LICZNIKA T0
;******************************************************************************
               ORG     0BH
               SETB    C
               RETI

;******************************************************************************
;	PRZERWANIE OD RS - STEROWANIE ZEGAREM 
;******************************************************************************

               ORG      023H 
               PUSH     ACC
               PUSH     0F0H      
               AJMP     PRZERW_RS

;******************************************************************************
;    PRZERWANIE T2 - LICZNIK SEKUNDOWY        
;******************************************************************************

                ORG     02BH
                PUSH    ACC
	        CLR     0CFH
                MOV     A,PSW
                ANL     A,#00011000B
                CLR     PSW.3
                CLR     PSW.4
       	        DJNZ    R6,OK_T2
	        MOV     0CBH,#0EFH
		MOV     0CAH,#0FFH
		MOV     R6,#0FH                      
                PUSH    ACC
                PUSH    PSW
                ACALL   SEKUNDY
                POP     PSW
                POP     ACC
                LCALL   BANK_1
                DEC     R4
                MOV     R5,#0FFH                     ; WSKAZNIK SEKUNDOWY
                ORL     PSW,A
                POP     ACC
		RETI
	OK_T2:
		MOV     0CBH,#00H                    
		MOV     0CAH,#00H                    
                ORL     PSW,A
                POP     ACC
	        RETI

;*****************************************************************************

	PRZERW_RS:
               MOV     A,SCON
               ANL     A,#00000010B        ; SPR. CZY SCON.1 (TI)-NADAJNIK
               JNZ     NADAJ_OK            
               CLR     SCON.0              ; ZERUJ ZNACZNIK  (RI)-ODBIORNIK
               SETB    0D5H
               MOV     A,PSW
               ANL     A,#00011000B
               CLR     PSW.3               ; BANK_0
               CLR     PSW.4               ; BANK_0
               MOV     R4,SBUF             ; W R4 SLOWO STERUJACE
               ORL     PSW,A
	NADAJ_OK:			   ; UZNAJE ZE TO NADAJNIK ZGL.PRZERW 
               POP     0F0H
               POP     ACC 
               RETI                        ;

;*****************************************************************************


    CLR_PAM: 
               MOV   R0,#0FFH              ; CZYSZCZENIE PAMIECI RAM
    CLRP:                                  
               MOV   @R0,#00H
               DEC   R0
               CJNE  R0,#1FH,CLRP
               MOV   R0,#00H
               MOV   R1,#00H
               MOV   R2,#00H
               MOV   R3,#00H
               MOV   R4,#00H
               MOV   R5,#00H
               MOV   R6,#00H
               MOV   R7,#00H
               RET

;******************************************************************************
	PETLA:
                CLR  PSW.4
                CLR  PSW.3
                SETB P3.5
                CLR  P3.5
		MOV  R3,#030H
	PETLA1:
		DJNZ R3,PETLA1
                SETB PSW.3
                SETB PSW.4
		RET
;******************************************************************************
	PETL_A:
                MOV  A,PSW
                ANL  A,#00011000B
                CLR  PSW.4
                CLR  PSW.3
		MOV  R2,#02H
	PETL_A1:
		MOV  R3,#0FFH
	PETL_A2:
		DJNZ R3,PETL_A2
		DJNZ R2,PETL_A1
                ORL  PSW,A
		RET
;******************************************************************************
	OP_PETL_AA:
                MOV  A,PSW
                ANL  A,#00011000B
                CLR   PSW.4
                CLR   PSW.3
		MOV   R5,#03FH
                MOV   R7,#004H
	OP_PETL_AA1:
                CLR   PSW.3
                CLR   PSW.4 
                ACALL PETL_A
		DJNZ  R5,OP_PETL_AA1
                MOV   R5,#03FH  
                DJNZ  R7,OP_PETL_AA1 
                ORL  PSW,A
		RET
		  
;******************************************************************************
	PRZESTEPNY:
                SETB  PSW.3                ; OBLICZANIE ROKU PRZESTEPNEGO
                SETB  PSW.4                ; (CO 4 LATA)
                MOV   A,R6
                MOV   B,#04H
                DIV   AB
                MOV   A,B
                ACALL BANK_0
                JZ    LUTY_PRZES
                MOV   R0,#0F2H
                MOV   @R0,#01CH
                RET
	LUTY_PRZES:
                MOV   R0,#0F2H             ; JESLI ROK PRZESTEPNY
                MOV   @R0,#01DH            ; LUTY MA 29 DNI
                RET  
;******************************************************************************
	BANK_0:                            ; USTAWIANIE BANKU REJESTROW
                CLR  PSW.3
                CLR  PSW.4
                RET
;******************************************************************************
        BANK_1:
                CLR  PSW.3
                SETB PSW.4
                RET
;******************************************************************************
	BANK_2:
                SETB PSW.3
                CLR  PSW.4
                RET
;******************************************************************************
	BANK_3:
                SETB PSW.3
                SETB PSW.4
                RET
;******************************************************************************

IN:
   ACALL CLR_PAM
   MOV   SP,#0C0H
   ACALL INIT_LCD
   AJMP  ZAPISZ_LICZBY

;******************************************************************************
; INICJALIZACJA WYSWIETLACZA LCD
;******************************************************************************

INIT_LCD:                                  ; USTAWIENIE WYSWIETLACZA LCD
	CLR  P3.3                          ; ZAPIS ZNAKOW W ODPOW. MIEJSACH
	CLR  P3.4
        SETB P3.5
	MOV  P1,#00000001B
	CLR  P3.5
	LCALL PETL_A
        SETB P3.5
	MOV  P1,#00000010B
	CLR  P3.5
	LCALL PETL_A
        SETB P3.5
	MOV  P1,#00110000B
	CLR  P3.5
	LCALL PETL_A
        SETB P3.5
	MOV  P1,#00001100B
	CLR  P3.5
	LCALL PETL_A
 
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000111B
        LCALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#2EH
        CLR   P3.5
        ACALL PETLA

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10001010B
        LCALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#2EH
        CLR   P3.5
        ACALL PETLA

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10001111B
        LCALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#20H
        CLR   P3.5
        ACALL PETLA

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010010B
        LCALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#3AH
        CLR   P3.5
        ACALL PETLA

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010101B
        LCALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#3AH
        CLR   P3.5
        ACALL PETLA

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000000B
        LCALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#30H
        CLR   P3.5
        ACALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#30H
        CLR   P3.5
        ACALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#30H
        CLR   P3.5
        ACALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#30H
        CLR   P3.5
        ACALL PETLA

        SETB  P3.3
        SETB  P3.5
        MOV   P1,#20H
        CLR   P3.5
        ACALL PETLA
        RET

;******************************************************************************
; ZAPISUJE W PAMIECI ILOSCI DNI W DANYM MIESIACU
;******************************************************************************

ZAPISZ_LICZBY:                             ; W PAMIECI RAM ZAPISYWANE SA
        MOV   R0,#0F1H                     ; ILOSCI DNI POSZCZEGOLNYCH
        MOV   @R0,#1FH                     ; MIESIECY
        INC   R0
        MOV   @R0,#1DH
        INC   R0
        MOV   @R0,#1FH
        INC   R0
        MOV   @R0,#1EH
        INC   R0
        MOV   @R0,#1FH
        INC   R0
        MOV   @R0,#1EH
        INC   R0
        MOV   @R0,#1FH  
        INC   R0
        MOV   @R0,#1FH  
        INC   R0
        MOV   @R0,#1EH  
        INC   R0
        MOV   @R0,#1FH  
        INC   R0
        MOV   @R0,#1EH  
        INC   R0
        MOV   @R0,#1FH

;****************************************************************************
;          ZAPISUJE ZNAKI ":." W PAMIECI RAM          
;****************************************************************************            
        MOV   R0,#20H
        MOV   @R0,#20
        MOV   R0,#21H
        MOV   @R0,#20
        MOV   R0,#22H
        MOV   @R0,#20
        MOV   R0,#23H
        MOV   @R0,#20H
        MOV   R0,#26H
        MOV   @R0,#3AH
        MOV   R0,#29H
        MOV   @R0,#20H
        MOV   R0,#2CH
        MOV   @R0,#2EH
        MOV   R0,#2FH
        MOV   @R0,#2EH
;******************************************************************************
;	INICJALIZACJA TIMERA/LICZNIKA SEKUND
;******************************************************************************

        ACALL BANK_3
        MOV   R0,#59                         ; sekunda
        MOV   R1,#059                        ; minuta                        
        MOV   R2,#023                        ; godzina
        MOV   R3,#028                        ; dzien miesiaca  
        MOV   R4,#00    		     ; dzien tygodnia
        MOV   R5,#09                         ; miesiac 
        MOV   R6,#98                         ; rok_ml  
        MOV   R7,#19                         ; rok_st 
        ACALL BANK_0
	MOV   0C8H,#00000100B
	MOV   TCON,#01000000B                ;  ZALACZANY T1
        MOV   TMOD,#00100000B                ;  T1 W TRYBIE 2, AUTOM PRZELAD
        MOV   IP  ,#00100000B
        MOV   SCON,#01010000B                ;  RS TRYB 1, BIT PARZ, 1 BIT STOPU
        MOV   08DH,#TAKT                     ;  Wartosc poczatkowa timera T1 
	MOV   R6  ,#0FH
        CLR   C
        CLR   0D5H
        ACALL BANK_2
        MOV   R5,#02H
	MOV   IE  ,#10110000B                ;  USTAW PRZERWANIE T2
        LCALL BANK_0
        MOV   R0,#0FFH
        MOV   @R0,#00H

;******************************************************************************
;       OBLICZANIE CZASU I DATY
;******************************************************************************
; W TEJ CZESCI PROGRAMU REALIZOWANA JEST KILKA RAZY NA SEKUNDE PROCESDURA 
; ODCZYTU DS1990
;******************************************************************************        
START:  
        MOV    P0,#11101110B                 ; POCZATKOWA WARTOSC DIOD 
        ACALL  WYSW_ROK_ST                   ; CZYTNIKOW DS1990

PRACA_STER:
        MOV   P0,#11101110B
        JNB   0D5H,PRACA
        AJMP  STER_RS

PRACA:
        MOV    P0,#11101110B 
        LCALL  BANK_0
        CJNE   R6,#01H,PRACA_1
        LCALL  CZYTAJ_DS_1
PRACA_1:
        CJNE   R6,#03H,PRACA_2               
        LCALL  CZYTAJ_DS_2
PRACA_2:
        CJNE   R6,#05H,PRACA_3
        LCALL  CZYTAJ_DS_1
PRACA_3:
        CJNE   R6,#07H,PRACA_4
        LCALL  CZYTAJ_DS_2
PRACA_4:
        CJNE   R6,#09H,PRACA_5
        LCALL  CZYTAJ_DS_2
PRACA_5:
        CJNE   R6,#1BH,PRACA_6
        LCALL  CZYTAJ_DS_1
PRACA_6:
        CJNE   R6,#1DH,PRACA_7
        LCALL  CZYTAJ_DS_2
PRACA_7:
        LCALL  BANK_1
        MOV    A,R5                    ; WSKAZNIK SEKUNDOWY
        JZ     PRACA_STER
        MOV    R5,#00H
        ACALL  WYSW_ROK_ST
        LCALL  WLACZ_ALARM
        AJMP   PRACA_STER

;******************************************************************************
;  OBLICZANIE GODZINY I DATY
;******************************************************************************
SEKUNDY:
	ACALL BANK_3
        INC   R0
	CJNE  R0,#3CH,OK_SEK
	MOV   R0,#00H
        LCALL BANK_0
        AJMP  MINUTY
OK_SEK: 
        RET          
  
MINUTY:
        ACALL BANK_3
        INC   R1
        CJNE  R1,#3CH,OK_MIN
        MOV   R1,#00H
        AJMP  GODZINY
OK_MIN: 
        RET

GODZINY:
        ACALL BANK_3
        INC   R2
        CJNE  R2,#18H,OK_GODZ
        MOV   R2,#00H
        AJMP  DNI
OK_GODZ:
        RET        

DNI:
        ACALL BANK_3
        INC   R4
        CJNE  R4,#07H,OK_DNI_TYG
        MOV   R4,#00H
OK_DNI_TYG:
ILE_DNI_MA_TEN_MIESIAC:
        ACALL BANK_3
        MOV   A,R5
        CJNE  R5,#02H,OK_ILE_DNI
        ACALL PRZESTEPNY
OK_ILE_DNI:
        ACALL BANK_3
        MOV   A,R5 
        ADD   A,#0F0H
        ACALL BANK_0
        MOV   R0,A
        MOV   A,@R0
        MOV   R0,A
        ACALL BANK_3 
        INC   R3     
        MOV   A,R3
        ACALL BANK_0
        INC   R0   
        CJNE  A,00H,OK_DNI_MIES
        ACALL BANK_3
        MOV   R3,#01H
        AJMP  MIES
OK_DNI_MIES:
        RET

MIES:          
        ACALL BANK_3
        INC   R5
        CJNE  R5,#0DH,OK_MIES
        MOV   R5,#01H
        AJMP  ROK_ML
OK_MIES:
        RET
  
ROK_ML:
        ACALL BANK_3
        INC   R6
        CJNE  R6,#64H,OK_ROK_ML
        MOV   R6,#00H
        AJMP  ROK_ST
OK_ROK_ML:
        RET

ROK_ST:
        ACALL BANK_3
        INC   R7
        CJNE  R7,#64H,OK_ROK_ST
        MOV   R7,#00H
OK_ROK_ST:
        RET
;***************************************************************************
; WYSWIETLANIE GODZINY I DATY
;***************************************************************************
WYSW_ROK_ST:

        MOV   DPTR,#LICZBY
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10001011B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R7
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#030H
        MOV   @R0,A
        LCALL PETLA
        CLR   P3.4
        CLR   P3.3
        MOV   P1,#10001100B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R7
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#031H
        MOV   @R0,A
        LCALL PETLA

WYSW_ROK_ML:

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10001101B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R6
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR 
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#032H
        MOV   @R0,A
        LCALL PETLA
        CLR   P3.4
        CLR   P3.3
        MOV   P1,#10001110B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R6    
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR 
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#033H
        MOV   @R0,A
        LCALL PETLA

WYSW_MIES:

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10001000B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R5
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#02DH
        MOV   @R0,A
        LCALL PETLA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10001001B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R5
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR 
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#02EH
        MOV   @R0,A
        LCALL PETLA


WYSW_DNI:

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000101B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R3
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#02AH
        MOV   @R0,A
        LCALL PETLA
        CLR   P3.4
        CLR   P3.3
        MOV   P1,#10000110B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R3
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#02BH
        MOV   @R0,A
        LCALL PETLA

DNI_TYG:
        MOV   DPTR,#PON
        LCALL BANK_3
        MOV   A,R4
        MOV   B,#04H
        MUL   AB 
        MOV   B,A
        MOVC  A,@A+DPTR
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000000B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A 
        LCALL PETLA
        INC   B
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        INC   B
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        INC   B
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        
WYSW_GODZ:

        MOV   DPTR,#LICZBY
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010000B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R2
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#024H
        MOV   @R0,A
        LCALL PETLA
        CLR   P3.4
        CLR   P3.3
        MOV   P1,#10010001B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R2
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#025H
        MOV   @R0,A
        LCALL PETLA

WYSW_MIN:

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010011B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R1
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#027H
        MOV   @R0,A
        LCALL PETLA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010100B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R1
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL BANK_1
        MOV   R0,#028H
        MOV   @R0,A
        LCALL PETLA

WYSW_SEK:

        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010110B
        LCALL PETLA
        ACALL BANK_3
        MOV   A,R0
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL PETLA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010111B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        ACALL BANK_3
        MOV   A,R0
        MOV   B,#02H
        MUL   AB        
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        RET

;******************************************************************************
;		STEROWANIE RS 
;******************************************************************************

STER_RS:
	ACALL BANK_0
        CJNE  R4,#0DH,STER
        LJMP  STER_DS      	

;******************************************************************************
;  STEROWANIE ZEGAREM, MAM WOLNA PAMIEC 0E8H - 0EFH 
;******************************************************************************

WYBIERZ_A:
        LJMP  WYBIERZ
STER:
        ACALL BANK_0
        CJNE  R4,#020H,WYBIERZ_A
        MOV   R4,#00H
        ACALL BANK_2
        INC   R5
        CJNE  R5,#04H,OK_STER 
        MOV   R5,#00H

OK_STER:
         CLR  0D5H
ZAZNACZ:
         ACALL BANK_2
         CJNE  R5,#00H,ZAZNACZ1
         CLR   P3.3
         CLR   P3.4
         SETB  P3.5
         MOV   P1,#10010100B
         CLR   P3.5
         ACALL PETL_A
         CLR   P3.3
         CLR   P3.4
         SETB  P3.5
         MOV   P1,#00001111B
         CLR   P3.5
         ACALL OP_PETL_AA
         AJMP  PRACA_STER

ZAZNACZ1: 
         ACALL BANK_2
         CJNE  R5,#01H,ZAZNACZ2
         CLR   P3.3
         CLR   P3.4
         SETB  P3.5
         MOV   P1,#10010001B
         CLR   P3.5
         ACALL PETL_A
         CLR   P3.3
         CLR   P3.4
         SETB  P3.5
         MOV   P1,#00001111B
         CLR   P3.5
         ACALL OP_PETL_AA
         AJMP  PRACA_STER

ZAZNACZ2:
         ACALL BANK_2
         CJNE  R5,#02H,SKOCZ_LARUM
         CLR   P3.3
         CLR   P3.4
         SETB  P3.5
         MOV   P1,#10000110B
         CLR   P3.5
         ACALL PETL_A
         CLR   P3.3
         CLR   P3.4
         SETB  P3.5
         MOV   P1,#00001111B
         CLR   P3.5
         ACALL OP_PETL_AA         
         AJMP  PRACA_STER

SKOCZ_LARUM:
         ACALL BANK_2
         CJNE  R5,#03H,OK_STER
         LJMP  ALARM

WYBIERZ2:
         ACALL BANK_2
         CJNE  R5,#02H,OK_STER
         AJMP  STER_DATA 

WYBIERZ:
         ACALL BANK_2
         CJNE  R5,#00H,WYBIERZ1
         AJMP  STER_MIN
WYBIERZ1: 
         ACALL BANK_2
         CJNE  R5,#01H,WYBIERZ2
         AJMP  STER_GODZ

STER_MIN:
        ACALL BANK_3
        MOV   A,R1       
        ACALL BANK_0
        CJNE  R4,#02BH,MINUS_MIN
        MOV   R4,#00H
        MOV   R5,A
        INC   R5
        CJNE  R5,#3CH,OK_ST_MIN
        MOV   R5,#00H
OK_ST_MIN:
        MOV   R6,#0FH
        MOV   A,R5
        ACALL BANK_3
        MOV   R0,#00H
        MOV   R1,A
        AJMP  STER_CD_MIN
MINUS_MIN:
        ACALL BANK_0
        CJNE  R4,#02DH,STER_CD_MIN
        MOV   R4,#00H
        MOV   R5,A
        DEC   R5
        CJNE  R5,#0FFH,OK_ST_MIN
        MOV   R5,#3BH
        AJMP  OK_ST_MIN
STER_CD_MIN:
        ACALL WYSW_ROK_ST  
        ACALL BANK_0    
        MOV   R4,#00H
        CLR   0D5H
        AJMP  PRACA

STER_GODZ:
        ACALL BANK_3
        MOV   A,R2       
        ACALL BANK_0
        CJNE  R4,#02BH,MINUS_GODZ
        MOV   R4,#00H
        MOV   R5,A
        INC   R5
        CJNE  R5,#18H,OK_ST_GODZ
        MOV   R5,#00H
OK_ST_GODZ:
        MOV   A,R5
        ACALL BANK_3
        MOV   R2,A
        AJMP  STER_CD_GODZ
MINUS_GODZ:
        ACALL BANK_0
        CJNE  R4,#02DH,STER_CD_GODZ
        MOV   R4,#00H
        MOV   R5,A
        DEC   R5
        CJNE  R5,#0FFH,OK_ST_GODZ
        MOV   R5,#17H
        AJMP  OK_ST_GODZ
STER_CD_GODZ:
        ACALL WYSW_ROK_ST 
        ACALL BANK_0    
        MOV   R4,#00H
        CLR   0D5H
        AJMP  PRACA

STER_DATA:
        ACALL BANK_0
        CJNE  R4,#02BH,MINUS_DATA
        MOV   R4,#00H
        ACALL BANK_3
        ACALL DNI
        AJMP  STER_CD_DATA

MINUS_DATA:
        ACALL BANK_0
        CJNE  R4,#02DH,STER_CD_DATA
        MOV   R4,#00H

STER_DNI_MIES:

STER_DNI_TYG:
        ACALL BANK_3
        DEC   R4
        CJNE  R4,#0FFH,OK_STER_DNI_TYG
        MOV   R4,#06H
        ACALL DNI_TYG
OK_STER_DNI_TYG:
        ACALL BANK_3
        MOV   A,R3
        ACALL BANK_0
        MOV   R5,A
        DEC   R5
        CJNE  R5,#00H,OK_STER_DNI_MIES
        ACALL BANK_3
        CJNE  R5,#03H,DNI_POP_MIES        
        ACALL PRZESTEPNY 
        ACALL BANK_0
        MOV   R0,#0F2H
        MOV   A,@R0
        ACALL BANK_3
        MOV   R3,A
        AJMP  STER_MIES

OK_STER_DNI_MIES:
        MOV   A,R5
        ACALL BANK_3
        MOV   R3,A
        AJMP  STER_CD_DATA
      
DNI_POP_MIES:
        ACALL BANK_3
        MOV   A,R5
        CJNE  A,#01H,OK_DNI_POP_MIES
        MOV   A,#0DH
OK_DNI_POP_MIES:
        ACALL BANK_0
        MOV   R0,#0F0H
        ADD   A,R0
        MOV   R0,A
        DEC   R0
        MOV   A,@R0
        ACALL BANK_3
        MOV   R3,A
        AJMP  STER_MIES

STER_MIES:
        ACALL BANK_3
        DEC   R5
        CJNE  R5,#00H,OK_STER_MIES
        MOV   R5,#0CH
        AJMP  STER_ROK_ML
OK_STER_MIES:
        AJMP  STER_CD_DATA      

STER_ROK_ML:
        ACALL BANK_3
        DEC   R6
        CJNE  R6,#0FFH,OK_STER_ROK_ML
        MOV   R6,#063H
        AJMP  STER_ROK_ST
OK_STER_ROK_ML:
        AJMP  STER_CD_DATA      

STER_ROK_ST:
        ACALL BANK_3
        DEC   R7
        CJNE  R7,#0FFH,OK_STER_ROK_ST
        MOV   R7,#063H
OK_STER_ROK_ST:
STER_CD_DATA:
        ACALL WYSW_ROK_ST
        ACALL BANK_0     
        MOV   R4,#00H
        CLR   0D5H
        AJMP  PRACA

;*******************************************************************************
;       ALARM - MOZLIWOSC USTAWIENIA DO TYGODNIA WPRZOD
;       WSZYSTKIE FUNKCJE STERUJACE ALARMEM 
;*******************************************************************************

INIT_LCD_ALARM:
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000000B
        LCALL PETLA 
        SETB  P3.3
        CLR   P3.4
        MOV   P1,#041H
        LCALL PETLA             
        MOV   P1,#04CH
        LCALL PETLA             
        MOV   P1,#041H
        LCALL PETLA             
        MOV   P1,#052H
        LCALL PETLA             
        MOV   P1,#04DH
        LCALL PETLA             
        MOV   P1,#03AH
        LCALL PETLA             
        MOV   P1,#020H
        LCALL PETLA             
        MOV   P1,#057H
        LCALL PETLA             
        MOV   P1,#045H
        LCALL PETLA             
        MOV   P1,#045H
        LCALL PETLA             
        MOV   P1,#04BH
        LCALL PETLA             
        MOV   P1,#020H
        LCALL PETLA             
        MOV   P1,#020H
        LCALL PETLA             
        MOV   P1,#048H
        LCALL PETLA             
        MOV   P1,#04FH
        LCALL PETLA             
        MOV   P1,#055H
        LCALL PETLA             
        MOV   P1,#052H
        LCALL PETLA             
        MOV   P1,#03AH
        LCALL PETLA             
        MOV   P1,#020H
        LCALL PETLA             
        MOV   P1,#030H
        LCALL PETLA             
        MOV   P1,#030H
        LCALL PETLA             
        MOV   P1,#03AH
        RET

LCD_ALARM_WLA:
        LCALL BANK_0
        MOV   R0,#00H
        MOV   DPTR,#ALARM_WLA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000000B
        LCALL PETLA 
        SETB  P3.3
        CLR   P3.4
WPIS_AL_WLA:
        LCALL BANK_0
        MOV   A,R0
        MOVC  A,@A+DPTR
        MOV   P1,A
        INC   R0
        LCALL PETLA
        LCALL BANK_0
        CJNE  R0,#018H,WPIS_AL_WLA 
        RET

LCD_ALARM_WYL:
        LCALL BANK_0
        MOV   R0,#00H
        MOV   DPTR,#ALARM_WYL
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000000B
        LCALL PETLA 
        SETB  P3.3
        CLR   P3.4
WPIS_AL_WYL:
        LCALL BANK_0
        MOV   A,R0
        MOVC  A,@A+DPTR
        MOV   P1,A
        INC   R0
        LCALL PETLA
        LCALL BANK_0
        CJNE  R0,#018H,WPIS_AL_WYL 
        RET

ALARM:  
        CLR   0D5H 
        LCALL BANK_0
        MOV   R0,#0FFH
        MOV   A,@R0
        JNZ   WLACZONY
WYLACZONY:
        LCALL LCD_ALARM_WYL
        LCALL BANK_0
        MOV   R0,#0FFH
        MOV   @R0,#00H
        JNB   0D5H,$
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#20H,WLACZONY
        AJMP  EXIT_ALARM                      ;DALEJ_ALARM
WLACZONY:
        LCALL LCD_ALARM_WLA
        LCALL BANK_0
        MOV   R0,#0FFH         
        MOV   @R0,#0FFH
        JNB   0D5H,$
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#20H,WYLACZONY       
DALEJ_ALARM:
        LCALL INIT_LCD_ALARM
        LCALL DNI_TYG_AL
        LCALL WYSW_GODZ_AL
        LCALL WYSW_MIN_AL             
        LCALL MRYGAJ_ALARM
        CLR   0D5H  
        LCALL BANK_0
        CJNE  R4,#02BH,CZY_EXIT_ALARM
        LJMP  WYBIERZ_ALARM

EXIT_ALARM:
        MOV   R4,#00H
        LCALL BANK_2
        MOV   R5,#00H
        LCALL INIT_LCD
        LCALL WYSW_ROK_ST
        CLR   0D5H   
        LJMP  ZAZNACZ

CZY_EXIT_ALARM:
        LCALL BANK_0 
        CJNE  R4,#020H,DALEJ_ALARM
        LJMP  EXIT_ALARM

WYBIERZ_ALARM: 
        LCALL MRYGAJ_DZIEN
        CLR   0D5H        
        LCALL BANK_0
        CJNE  R4,#02BH,AL_DZIEN
        CLR   0D5H
        LCALL MRYGAJ_GODZ
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#02BH,AL_HOUR
        CLR   0D5H
        LJMP  WYBIERZ_ALARM

AL_DZIEN:
        LCALL BANK_0
        CJNE  R4,#20H,EXIT_ALARM
        LCALL BANK_3
        MOV   A,R4
        LCALL BANK_0
        LCALL DNI_TYG_AL
WEEK:
        JNB   0D5H,WEEK
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#02BH,WEEK_MIN
        LCALL BANK_0
        MOV   R0,#0E8H
        MOV   A,@R0
        INC   A
        CJNE  A,#08H,NOTUJ_WEEK
        MOV   A,#00H 

NOTUJ_WEEK:
        MOV   @R0,A
        LCALL DNI_TYG_AL
        LJMP  WEEK

WEEK_MIN:
        CJNE  R4,#02DH,WEEK_EXIT
        LCALL BANK_0
        MOV   R0,#0E8H
        MOV   A,@R0
        DEC   A
        CJNE  A,#0FFH,NOTUJ_WEEK
        MOV   A,#07H                      
        LJMP  NOTUJ_WEEK
  
WEEK_EXIT:         
        CJNE  R4,#20H,END_WEEK
END_WEEK:
        LJMP  DALEJ_ALARM 
       
AL_HOUR:
        LCALL BANK_0
        CJNE  R4,#20H,EXIT_ALARM_AL
AL_HOUR_AA:
        LCALL MRYGAJ_MINUTY
        CLR   0D5H        
        LCALL BANK_0
        CJNE  R4,#02BH,AL_MINUTY
        CLR   0D5H
        LCALL MRYGAJ_GODZINY
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#02BH,AL_GODZINY
        CLR   0D5H
        LJMP  AL_HOUR_AA

EXIT_ALARM_AL:
        LJMP EXIT_ALARM

AL_GODZINY:
        LCALL BANK_0
        CJNE  R4,#20H,EXIT_ALARM_AL
        LCALL BANK_3
        MOV   A,R2
        LCALL BANK_0
        LCALL WYSW_GODZ_AL

AL_HOUR_A:
        JNB   0D5H,AL_HOUR_A                 
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#02BH,HOUR_MIN         
        LCALL BANK_0
        MOV   R0,#0EAH
        MOV   A,@R0
        INC   A
        CJNE  A,#018H,NOTUJ_HOUR        
        MOV   A,#00H 
NOTUJ_HOUR:                             
        MOV   @R0,A    
        LCALL WYSW_GODZ_AL
        LJMP  AL_HOUR_A
HOUR_MIN:                               
        CJNE  R4,#02DH,HOUR_EXIT        
        LCALL BANK_0
        MOV   R0,#0EAH
        MOV   A,@R0
        DEC   A
        CJNE  A,#0FFH,NOTUJ_HOUR
        MOV   A,#017H
        LJMP  NOTUJ_HOUR  
HOUR_EXIT:         
        CJNE  R4,#20H,END_HOUR          
END_HOUR:
        LJMP  DALEJ_ALARM

EXIT_ALARM_AL_A:
        LJMP  EXIT_ALARM

AL_MINUTY:
        LCALL BANK_0
        CJNE  R4,#20H,EXIT_ALARM_AL_A
        LCALL BANK_3
        MOV   A,R1
        LCALL BANK_0
        LCALL WYSW_MIN_AL

AL_MINUTY_A:
        JNB   0D5H,AL_MINUTY_A          
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#02BH,MINUTY_MIN            
        LCALL BANK_0
        MOV   R0,#0E9H
        MOV   A,@R0
        INC   A
        CJNE  A,#03CH,NOTUJ_MINUTY            
        MOV   A,#00H 
NOTUJ_MINUTY:                                  
        MOV   @R0,A
        LCALL WYSW_MIN_AL
        LJMP  AL_MINUTY_A
MINUTY_MIN:                                    
        CJNE  R4,#02DH,MINUTY_EXIT             
        LCALL BANK_0
        MOV   R0,#0E9H
        MOV   A,@R0
        DEC   A
        CJNE  A,#0FFH,NOTUJ_MINUTY
        MOV   A,#03BH
        LJMP  NOTUJ_MINUTY 
MINUTY_EXIT:         
        CJNE  R4,#20H,END_MINUTY              
END_MINUTY:
        LJMP  DALEJ_ALARM 


MRYGAJ_MINUTY:
        JNB   0D5H,MRYGAJ_MIN
        RET
MRYGAJ_MIN:
        MOV   DPTR,#LICZBY
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010110B
        LCALL PETLA
        MOV   P1,#00001100B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        MOV   P1,#20H
        LCALL PETLA 
        MOV   P1,#20H
        LCALL PETLA 
        LCALL OP_PETL_AA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010110B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        LCALL BANK_0
        MOV   R0,#0E9H
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA 
        LCALL BANK_0
        MOV   R0,#0E9H
        MOV   A,@R0
        MOV   B,#02H        
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA 
        LCALL OP_PETL_AA
        LJMP  MRYGAJ_MINUTY


MRYGAJ_GODZINY:
        JNB   0D5H,MRYGAJ_GODZIN
        RET
MRYGAJ_GODZIN:
        MOV   DPTR,#LICZBY
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010011B
        LCALL PETLA
        MOV   P1,#00001100B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        MOV   P1,#20H
        LCALL PETLA 
        MOV   P1,#20H
        LCALL PETLA 
        LCALL OP_PETL_AA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010011B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        LCALL BANK_0
        MOV   R0,#0EAH
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        LCALL BANK_0 
        MOV   R0,#0EAH
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA 
        LCALL OP_PETL_AA
        LJMP  MRYGAJ_GODZINY
          


MRYGAJ_ALARM:
          JNB   0D5H,MRYGAJ_AL
          RET
MRYGAJ_AL:
          CLR   P3.3
          CLR   P3.4
          MOV   P1,#10000000B
          LCALL PETLA
          MOV   P1,#00001100B
          LCALL PETLA
          SETB  P3.3
          CLR   P3.4 
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          LCALL OP_PETL_AA 
          CLR   P3.3
          CLR   P3.4
          MOV   P1,#10000000B
          LCALL PETLA
          SETB  P3.3
          CLR   P3.4 
          MOV   P1,#041H
          LCALL PETLA
          MOV   P1,#04CH
          LCALL PETLA
          MOV   P1,#041H
          LCALL PETLA
          MOV   P1,#052H
          LCALL PETLA
          MOV   P1,#04DH
          LCALL PETLA
          LCALL OP_PETL_AA 
          LJMP  MRYGAJ_ALARM

MRYGAJ_DZIEN:
          JNB   0D5H,MRYGAJ_DZ
          RET
MRYGAJ_DZ:
          CLR   P3.3
          CLR   P3.4
          MOV   P1,#10000111B
          LCALL PETLA
          MOV   P1,#00001100B
          LCALL PETLA
          SETB  P3.3
          CLR   P3.4 
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          LCALL OP_PETL_AA 
          CLR   P3.3
          CLR   P3.4
          MOV   P1,#10000111B
          LCALL PETLA
          SETB  P3.3
          CLR   P3.4 
          MOV   P1,#057H
          LCALL PETLA
          MOV   P1,#045H
          LCALL PETLA
          MOV   P1,#045H
          LCALL PETLA
          MOV   P1,#04BH
          LCALL PETLA
          LCALL OP_PETL_AA 
          LJMP  MRYGAJ_DZIEN

MRYGAJ_GODZ:
          JNB   0D5H,MRYGAJ_GOD
          RET
MRYGAJ_GOD:
          CLR   P3.3
          CLR   P3.4
          MOV   P1,#10001101B
          LCALL PETLA
          MOV   P1,#00001100B
          LCALL PETLA
          SETB  P3.3
          CLR   P3.4 
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          MOV   P1,#020H
          LCALL PETLA
          LCALL OP_PETL_AA 
          CLR   P3.3
          CLR   P3.4
          MOV   P1,#10001101B
          LCALL PETLA
          SETB  P3.3
          CLR   P3.4 
          MOV   P1,#048H
          LCALL PETLA
          MOV   P1,#04FH
          LCALL PETLA
          MOV   P1,#055H
          LCALL PETLA
          MOV   P1,#052H
          LCALL PETLA
          LCALL OP_PETL_AA 
          LJMP  MRYGAJ_GODZ

DNI_TYG_AL:
        MOV   DPTR,#PON
        LCALL BANK_0
        MOV   R0,#0E8H
        MOV   A,@R0
        MOV   B,#04H
        MUL   AB 
        MOV   B,A
        MOVC  A,@A+DPTR
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10000111B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A 
        LCALL PETLA
        INC   B
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        INC   B
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        INC   B
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        RET

WYSW_GODZ_AL:
        MOV   DPTR,#LICZBY
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010011B
        LCALL PETLA
        LCALL BANK_0
        MOV   R0,#0EAH
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL PETLA
        CLR   P3.4
        CLR   P3.3
        MOV   P1,#10010100B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        LCALL BANK_0
        MOV   R0,#0EAH
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        RET
 
WYSW_MIN_AL:
        MOV   DPTR,#LICZBY
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010110B
        LCALL PETLA
        LCALL BANK_0
        MOV   R0,#0E9H
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        MOVC  A,@A+DPTR
        SETB  P3.3
        CLR   P3.4
        MOV   P1,A
        LCALL PETLA
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#10010111B
        LCALL PETLA
        SETB  P3.3
        CLR   P3.4
        LCALL BANK_0
        MOV   R0,#0E9H
        MOV   A,@R0
        MOV   B,#02H
        MUL   AB
        INC   A
        MOVC  A,@A+DPTR
        MOV   P1,A
        LCALL PETLA
        RET  

;******************************************************************************
;       ALARM POWODUJE MRUGANIE WYSWIETLACZA PRZEZ 1 MINUTE 
;******************************************************************************

WLACZ_ALARM:
        LCALL BANK_0
        MOV   R0,#0FFH
        MOV   A,@R0
        JZ    KONIEC
        LCALL BANK_0
        MOV   R0,#0E8H
        MOV   A,@R0
        CJNE  A,#07H,CD_ALARM
        LJMP  EVER_ALARM
CD_ALARM:
        LCALL BANK_3
        MOV   A,R4
        LCALL BANK_0
        MOV   R0,#0E8H
        XRL   A,@R0
        JNZ   KONIEC
EVER_ALARM:
        LCALL BANK_3
        MOV   A,R1
        LCALL BANK_0
        MOV   R0,#0E9H
        XRL   A,@R0
        JNZ   KONIEC
        LCALL BANK_3
        MOV   A,R2
        LCALL BANK_0
        MOV   R0,#0EAH
        XRL   A,@R0
        JNZ   KONIEC
STOP:
        CLR   P2.7                   ; PIN ALARMOWY
        CLR   IE.4
        CLR   P3.3
        CLR   P3.4
        MOV   P1,#00001000B
        LCALL PETLA
        LCALL OP_PETL_AA
        LCALL INIT_LCD
        LCALL WYSW_ROK_ST
        LCALL OP_PETL_AA
        RET
KONIEC:
        SETB  P2.7                   ; PIN ALARMOWY
        SETB  IE.4
        RET

;****************************************************************************
;       KOMUNIKATY 
;****************************************************************************
KOM_MENU:
        MOV   DPTR,#MENU
        LCALL KOM
        RET

;****************************************************************************

KOM_OK:
        MOV   DPTR,#OK
        LCALL KOM
        RET


;****************************************************************************

KOM_SPODZ_ENTER:
        MOV   DPTR,#SPODZ_ENTER
        LCALL KOM
        RET


;****************************************************************************

KOM_OK_TERAZ_IMIE:
        MOV   DPTR,#OK_TERAZ_IMIE
        LCALL KOM
        RET


;****************************************************************************

KOM_JESZCZE_RAZ:
        MOV   DPTR,#JESZCZE_RAZ
        LCALL KOM
        RET

;****************************************************************************


KOM_DLUGI_KOD:
        MOV   DPTR,#DLUGI_KOD
        LCALL KOM
        RET

;****************************************************************************

KOM_NAZWISKO:
        MOV   DPTR,#NAZWISKO
        LCALL KOM
        RET

;****************************************************************************

KOM_WPISZ_KOD:
        MOV   DPTR,#WPISZ_KOD
        LCALL KOM
        RET        
        
;****************************************************************************

KOM_PRZYKLAD:
        MOV   DPTR,#PRZYKLAD
        LCALL KOM
        RET

;****************************************************************************

KOM_ZLE:
        MOV   DPTR,#ZLE
        LCALL KOM
        RET

;****************************************************************************

KOM_WYB_LICZ:
        MOV   DPTR,#WYB_LICZ
        LCALL KOM
        RET

;****************************************************************************

KOM_WYBIERAJ:
        MOV   DPTR,#WYBIERAJ
        LCALL KOM
        RET

;****************************************************************************

KOM:
        LCALL BANK_1
        MOV   B,#00H
        MOV   R0,#030H
	LCALL NADAJNIK_RS
        RET

;****************************************************************************

NADAJNIK_RS:
        MOV   SBUF,#0DH
        JNB   SCON.1,$
        CLR   SCON.1
NADAJNIK_RS_A:        
        MOV   A,B
        MOVC  A,@A+DPTR
        MOV   SBUF,A
        JNB   SCON.1,$
        CLR   SCON.1
        INC   B
        LCALL BANK_1
        DJNZ  R0,NADAJNIK_RS_A
        RET

;****************************************************************************
;		STEROWANIE KOMUNIKACJA Z KOMPUTEREM PC
; PODPROGRAMY ZAPISU I ODCZYTU DS1990, ORAZ KOMUNIKACJA Z PC-TEM
;****************************************************************************


STER_DS:
        LCALL USTAW_ODCZYT
        LCALL PRZEGLADAJ
        CLR   0D5H  
        JNB   0D5H,$
        CLR   0D5H

ZNAKI_STERUJACE:
        LCALL BANK_0
        MOV   A,R4
        LCALL BANK_1
        MOV   R7,A
        CLR   C
        SUBB  A,#30H
        MOV   R6,A
        JC    DALEJ_ESC
        SUBB  A,#0AH
        JNC   ZLY_ZNAK
        LCALL USTAL_ADRES
        LJMP  PRZEGLADAJ_1
DALEJ_ESC:
        LCALL BANK_0
        CJNE  R4,#01BH,ZLY_ZNAK                  ;ESCAPE
        LJMP  POWR_DO_ZEG

;****************************************************************************

PRZEGLADAJ_1:
        MOV   SBUF,#0DH
        JNB   SCON.1,$
        CLR   SCON.1
        LCALL BANK_1
        MOV   R0,#028H
        LCALL POKAZ_DANA
        LCALL BANK_1
        MOV   R1,#08H
        MOV   R0,#014H
PRZEGL:
        LCALL POKAZ
        LCALL BANK_1
        MOV   R0,#014H
        DJNZ  R1,PRZEGL
        LCALL KOM_MENU
        CLR   0D5H
        JNB   0D5H,$
        CLR   0D5H
        LCALL BANK_0
        CJNE  R4,#04EH,DALEJ_N
        LJMP  STER_DS
DALEJ_N:
        LCALL BANK_0
        CJNE  R4,#06EH,DALEJ_M
        LJMP  STER_DS
DALEJ_M:
        LCALL BANK_0
        CJNE  R4,#04DH,DALEJ__m
        LJMP  MODYFIKUJ        
DALEJ__m:
	LCALL BANK_0
        CJNE  R4,#06DH,DALEJ_ESC
        LJMP  MODYFIKUJ
   
;****************************************************************************

ZLY_ZNAK:
        LCALL KOM_ZLE
        LJMP  STER_DS 

;*****************************************************************************

POWR_DO_ZEG:
        LCALL BANK_0
        MOV   R4,#00H
        CLR   0D5H
        LJMP  PRACA 


;****************************************************************************
PRZEGLADAJ:
        MOV   SBUF,#0DH
        JNB   SCON.1,$
        CLR   SCON.1
        LCALL BANK_1
        MOV   R7,#30H
        MOV   R6,#00H
        MOV   DPTR,#00H
POKAZUJ:
        LCALL USTAL_ADRES
        LCALL POKAZ_DANE
        LCALL BANK_1
        INC   R6
        INC   R7
        CJNE  R6,#0AH,POKAZUJ
        LCALL KOM_WYBIERAJ
        RET

;*****************************************************            
POKAZ_DANE:
        LCALL BANK_1
        MOV   R0,#028H
POKAZ_DANA:
        LCALL BANK_1
        MOV   SBUF,R7
        JNB   SCON.1,$
        CLR   SCON.1
        MOV   SBUF,#03AH
        JNB   SCON.1,$
        CLR   SCON.1
        LCALL POKAZ
        RET

;*****************************************************
POKAZ:
        MOVX  A,@DPTR
        INC   DPTR
        MOV   SBUF,A
        JNB   SCON.1,$
        CLR   SCON.1
        LCALL BANK_1
        DJNZ  R0,POKAZ
        MOV   SBUF,#0DH
        JNB   SCON.1,$
        CLR   SCON.1
        RET

;*****************************************************************************
        
MODYFIKUJ:
        LCALL KOM_WPISZ_KOD
        LCALL KOM_PRZYKLAD
        LCALL BANK_1
        MOV   R0,#60H
        MOV   R1,#0DH         ;9
        CLR   0D5H
MODYF:
        CLR   0D5H
        JNB   0D5H,$
        CLR   0D5H
        LCALL BANK_0
        MOV   A,R4
        LJMP  SPRAWDZ_ZNAK
MODYF_OK:
        LCALL BANK_1
        MOV   @R0,A
        INC   R0
        DJNZ  R1,MODYF
        CJNE  A,#0DH,ZA_DLUGI_KOD
        LCALL USTAL_ADRES 
        LJMP  WPISZ_EE_KOD    

ZA_DLUGI_KOD:
        LCALL KOM_DLUGI_KOD
        LJMP  PONOWNIE_1

USTAL_ADRES:
        LCALL BANK_1
        MOV   A,R6
        MOV   B,#200
        MUL   AB
        MOV   DPH,B
        MOV   DPL,A       
        RET

WPISZ_NAZW:        
        LCALL KOM_OK_TERAZ_IMIE
        LCALL BANK_1
        MOV   R0,#060H
        MOV   R1,#01CH            ;20
WP_NAZW:
        CLR   0D5H
        JNB   0D5H,$
        CLR   0D5H
        LCALL BANK_0
        MOV   A,R4
        CJNE  A,#01BH,WP_DALEJ
        LJMP  STER_DS
WP_DALEJ:
        LCALL BANK_1
        MOV   @R0,A
        INC   R0
        CJNE  A,#0DH,DAL_WP_NAZW
        DEC   R0
WP_SPACE:
        MOV   @R0,#20H
        INC   R0
        DJNZ  R1,WP_SPACE
        LJMP  OK_NAZW
DAL_WP_NAZW:
        DJNZ  R1,WP_NAZW
        CJNE  A,#0DH,ZA_DLUG_NAZW
OK_NAZW:
        LCALL USTAL_ADRES
        LCALL WPISZ_EE_NAZW 
        LCALL KOM_OK
        LJMP  STER_DS
            
ZA_DLUG_NAZW:
        LCALL KOM_NAZWISKO
        LCALL KOM_JESZCZE_RAZ
        LJMP  WPISZ_NAZW
;****************************************************************************

WPISZ_EE_NAZW:
        MOV   A,DPL
        CLR   C
        ADDC  A,#0DH         ;9          
        MOV   DPL,A
        JNC   OK_ADD
        INC   DPH
OK_ADD:
        LCALL BANK_1
        MOV   R0,#060H 
        MOV   R1,#01AH        ;1E
        LCALL WPISZ_EE
        MOV   A,#020H
        LCALL USTAW_ZAPIS
        MOVX  @DPTR,A
        LCALL PAUSE_3MS 
        LCALL KASUJ_ZAPIS 
        RET

WPISZ_EE_KOD:
        LCALL BANK_1
        MOV   R1,#0CH           ;8
        MOV   R0,#60H
        LCALL WPISZ_EE
        MOV   A,#020H
        LCALL USTAW_ZAPIS
        MOVX  @DPTR,A
        LCALL PAUSE_3MS 
        LCALL KASUJ_ZAPIS 
        LJMP  WPISZ_NAZW

WPISZ_EE:
        LCALL BANK_1
        MOV   A,@R0
        LCALL USTAW_ZAPIS
        MOVX  @DPTR,A
        INC   R0
        INC   DPTR
        LCALL PAUSE_3MS
        LCALL KASUJ_ZAPIS
        LCALL BANK_1
        DJNZ  R1,WPISZ_EE
        RET
 
;*****************************************************************************                

SPRAWDZ_ZNAK:
        CJNE  A,#030H,SPR_0
        LJMP  MODYF_OK
SPR_0:
        CJNE  A,#031H,SPR_1
        LJMP  MODYF_OK
SPR_1:
        CJNE  A,#032H,SPR_2
        LJMP  MODYF_OK
SPR_2:
        CJNE  A,#033H,SPR_3
        LJMP  MODYF_OK
SPR_3:
        CJNE  A,#034H,SPR_4
        LJMP  MODYF_OK
SPR_4:
        CJNE  A,#035H,SPR_5
        LJMP  MODYF_OK
SPR_5:
        CJNE  A,#036H,SPR_6
        LJMP  MODYF_OK
SPR_6:
        CJNE  A,#037H,SPR_7
        LJMP  MODYF_OK
SPR_7:
        CJNE  A,#038H,SPR_8
        LJMP  MODYF_OK
SPR_8:
        CJNE  A,#039H,SPR_9
        LJMP  MODYF_OK
SPR_9:
SPR_A:
        CJNE  A,#041H,SPR_B
        LJMP  MODYF_OK
SPR_B:
        CJNE  A,#042H,SPR_C
        LJMP  MODYF_OK
SPR_C:
        CJNE  A,#043H,SPR_D
        LJMP  MODYF_OK
SPR_D:
        CJNE  A,#044H,SPR_E
        LJMP  MODYF_OK
SPR_E:
        CJNE  A,#045H,SPR_F
        LJMP  MODYF_OK
SPR_F:
        CJNE  A,#046H,SPR_OK
        LJMP  MODYF_OK
SPR_OK:
        LCALL BANK_1
        CJNE  R1,#01H,OLEJ_TO
        CJNE  A,#0DH,SPODZIEW_ENTER
        LJMP  MODYF_OK
OLEJ_TO:
        CJNE  A,#1BH,PONOWNIE
        LJMP  STER_DS
PONOWNIE:
        LCALL KOM_ZLE
        LCALL KOM_WYB_LICZ
PONOWNIE_1:
        LCALL KOM_JESZCZE_RAZ
        LJMP  MODYFIKUJ 
SPODZIEW_ENTER:
        LCALL KOM_SPODZ_ENTER
        LCALL KOM_JESZCZE_RAZ
        LJMP  MODYFIKUJ

;****************************************************************************

PAUSE_3MS:
        LCALL BANK_1
        MOV   R3,#03H
PAUSE:
        LCALL PETL_A
        LCALL BANK_1
        DJNZ  R3,PAUSE
        RET

;****************************************************************************
ORG 011DBH
USTAW_ODCZYT:
        MOV   WMCON,#08H
	RET

ORG 011EBH
USTAW_ZAPIS:
        MOV   WMCON,#18H
        RET

ORG 011FBH
KASUJ_ZAPIS:
        MOV   WMCON,#08H
        RET

;******************************************************************************

ORG 01204H

ZAPISZ_CZAS:

        CLR   0D5H
        LCALL BANK_0
        LCALL USTAL_ADRES
        MOV   A,DPL
        CLR   C
        ADDC  A,#28H
        MOV   DPL,A
        JNC   OK_ZAP_CZAS
        INC   DPH
OK_ZAP_CZAS:
        LCALL BANK_1
        MOV   R0,#34H
        LCALL USTAW_ODCZYT
CZYTAJ_EEPROM:
        MOVX  A,@DPTR
        LCALL BANK_1
        MOV   @R0,A
        INC   R0
        INC   DPTR       
        CJNE  R0,#0C0H,CZYTAJ_EEPROM
        LCALL USTAL_ADRES
        MOV   A,DPL
        CLR   C
        ADDC  A,#28H
        MOV   DPL,A
        JNC   OK_CZYT_EEP
        INC   DPH
OK_CZYT_EEP:
        LCALL BANK_1
        MOV   R0,#20H
ZAPISZ_CZAS_EEP:
        LCALL USTAW_ZAPIS
        LCALL BANK_1
        MOV   A,@R0
        MOVX  @DPTR,A
        INC   R0
        INC   DPTR
        LCALL PAUSE_3MS
        LCALL KASUJ_ZAPIS
        LCALL BANK_1
        CJNE  R0,#0C0H,ZAPISZ_CZAS_EEP
        SETB  IE.4
        RET

;*************************************************
; WYSYLAM I ODBIERAM SYGNAL OBECNOSCI
;*************************************************

CZYTAJ_DS_1:
        LCALL BANK_1
        CLR   P0.3
        MOV   R6,#240                  ;480
        DJNZ  R6,$
        SETB  P0.3
        MOV   R6,#33                   ;66
        DJNZ  R6,$
        JNB   P0.3,DS_DALEJ
        RET
DS_DALEJ:
        MOV   R6,#120                  ;240
        DJNZ  R6,$
        JB    P0.3,DS_DALEJ_1
        RET
DS_DALEJ_1:
        MOV   R6,#100                  ;200
        DJNZ  R6,$
        CLR   P0.3
        MOV   R7,#04

WPISZ_1:
        CLR   P0.3
        MOV   R6,#03
        DJNZ  R6,$
        SETB  P0.3
        MOV   R6,#60
        DJNZ  R6,$
        DJNZ  R7,WPISZ_1

        MOV   R7,#04
WPISZ_0:         
        CLR   P0.3
        MOV   R6,#030
        DJNZ  R6,$
        SETB  P0.3
        MOV   R6,#30
        DJNZ  R6,$
        DJNZ  R7,WPISZ_0 

;********************************** CZYTAM
        CLR   P0.3
        MOV   R7,#64
        MOV   R4,#08
        MOV   R0,#50H                    ;40     
CZYTAJ:
        MOV   8CH,#150                   ;100                 
        MOV   8AH,#235                   ;220  
        ORL   TMOD,#00000010B
        SETB  TCON.4
        SETB  IE.1
        SETB  P0.3
        CLR   C
        
CZYTAJ_BIT:
        JC    CZYTAJ_1        
        JB    P0.3,CZYTAJ_BIT
        CLR   IE.1
        CLR   C
        AJMP  BIT_1
CZYTAJ_1:
        SETB  C
BIT_1:
        MOV   A,B
        RRC   A
        MOV   B,A
        SETB  IE.1
        CLR   C
        DJNZ  R4,KONCZ_CZYTAC
        MOV   R4,#08
        MOV   @R0,B
        INC   R0
KONCZ_CZYTAC:
        MOV   8AH,#225                        ;170
        JNC   $
        CLR   P0.3
        DJNZ  R7,CZYTAJ
        CLR   IE.1
        SETB  P0.3
        CLR   TCON.4
        CLR   TCON.5
        MOV   R0,#20H
        MOV   @R0,#4FH   
        INC   R0
        MOV   @R0,#55H
        INC   R0
        MOV   @R0,#54H
        MOV   R3,#01011110B
        LJMP  KONWERT
;********************************************
;********************************************
;********************************************
CZYTAJ_DS_2:
        LCALL BANK_1
        CLR   P0.2
        MOV   R6,#240                  ;480
        DJNZ  R6,$
        SETB  P0.2
        MOV   R6,#33                   ;66
        DJNZ  R6,$
        JNB   P0.2,DS2_DALEJ
        RET
DS2_DALEJ:
        MOV   R6,#120                  ;240
        DJNZ  R6,$
        JB    P0.2,DS2_DALEJ_1
        RET
DS2_DALEJ_1:
        MOV   R6,#100                  ;200
        DJNZ  R6,$
        CLR   P0.2
        MOV   R7,#04

WPISZ_12:
        CLR   P0.2
        MOV   R6,#03
        DJNZ  R6,$
        SETB  P0.2
        MOV   R6,#60
        DJNZ  R6,$
        DJNZ  R7,WPISZ_12

        MOV   R7,#04
WPISZ_02:         
        CLR   P0.2
        MOV   R6,#030
        DJNZ  R6,$
        SETB  P0.2
        MOV   R6,#30
        DJNZ  R6,$
        DJNZ  R7,WPISZ_02 

;********************************** CZYTAM
        CLR   P0.2
        MOV   R7,#64
        MOV   R4,#08
        MOV   R0,#50H                    ;40     
CZYTAJ2:
        MOV   8CH,#150                   ;100                 
        MOV   8AH,#235                   ;220  
        ORL   TMOD,#00000010B
        SETB  TCON.4
        SETB  IE.1
        SETB  P0.2
        CLR   C
        
CZYTAJ_BIT2:
        JC    CZYTAJ_12        
        JB    P0.2,CZYTAJ_BIT2
        CLR   IE.1
        CLR   C
        AJMP  BIT_12
CZYTAJ_12:
        SETB  C
BIT_12:
        MOV   A,B
        RRC   A
        MOV   B,A
        SETB  IE.1
        CLR   C
        DJNZ  R4,KONCZ_CZYTAC2
        MOV   R4,#08
        MOV   @R0,B
        INC   R0
KONCZ_CZYTAC2:
        MOV   8AH,#225                        ;170
        JNC   $
        CLR   P0.2
        DJNZ  R7,CZYTAJ2
        CLR   IE.1
        SETB  P0.2
        CLR   TCON.4
        CLR   TCON.5
        MOV   R0,#20H
        MOV   @R0,#49H   
        INC   R0
        MOV   @R0,#4EH
        INC   R0
        MOV   @R0,#20H
        MOV   R3,#10101101B
        LJMP  KONWERT

;*****************************************************************************        
 
KONWERT:
       LCALL  SPR_CRC
       MOV    A,R2
       JZ     OK_CRC
       MOV    R2,#00H
       RET
OK_CRC:    
       MOV    DPTR,#HEXA_KOD
       MOV    R0,#57H
       MOV    R1,#40H
KONWERTUJ:
       MOV    A,@R0
       SWAP   A
       ANL    A,#0FH
       MOVC   A,@A+DPTR
       MOV    @R1,A
       INC    R1
       MOV    A,@R0
       ANL    A,#0FH
       MOVC   A,@A+DPTR
       MOV    @R1,A
       INC    R1
       DEC    R0
       CJNE   R0,#4FH,KONWERTUJ
       LCALL  POROWNAJ_KOD
       RET

POROWNAJ_KOD:
      LCALL   BANK_1
      MOV     R1,#42H
      MOV     R6,#00H
      LCALL   USTAL_ADRES
POROWNAJ:
      LCALL   USTAW_ODCZYT
      LCALL   BANK_1
      MOVX    A,@DPTR
      MOV     B,@R1
      XRL     A,B
      JNZ     NASTEPNE_POROWNANIE
      INC     R1
      INC     DPTR
      CJNE    R1,#04EH,POROWNAJ
      MOV     P0,R3                   ; ZIELONY  **** **** **** ****
      MOV     R4,#02H                 ; CZAS OTWARCIA
      CJNE    R4,#00H,$      
      AJMP    ZAPISZ_CZAS 
NASTEPNE_POROWNANIE:
      LCALL   BANK_1
      MOV     R1,#42H
      INC     R6
      LCALL   USTAL_ADRES      
      CJNE    R6,#0AH,POROWNAJ
      RET

;*****************************************************************************
; GENERATOR KODU CRC X8+X5+X4+1
;*****************************************************************************
SPR_CRC:
        MOV   R0,#50H
        MOV   R1,#08H
        MOV   R2,#00H
CRC:
        MOV   A,@R0
        INC   R0
        LCALL DO_CRC
        DJNZ  R1,CRC
        RET
DO_CRC:
	PUSH  ACC
        PUSH  B
        PUSH  ACC
        MOV   B,#08H
CRC_LOOP:
        XRL   A,R2
        RRC   A
        MOV   A,R2
        JNC   ZERO
        XRL   A,#18H
ZERO:
        RRC   A
        MOV   R2,A
        POP   ACC
        RR    A
        PUSH  ACC
        DJNZ  B,CRC_LOOP
        POP   ACC
        POP   B
        POP   ACC
        RET

;******************************************************************************       
;	       STALE W PAMIECI PROGRAMU	
;******************************************************************************
LICZBY:        DB '000102030405060708091011121314151617181920212223242526272829'
LICZBY_A:      DB '303132333435363738394041424344454647484950515253545556575859'
LICZBY_B:      DB '606162636465666768697071727374757677787980818283848586878889'
LICZBY_C:      DB '90919293949596979899'
PON:           DB 'PONI'
WTO:           DB 'WTOR'
SRO:           DB 'SROD'
CZW:           DB 'CZWA'
PIA:           DB 'PIAT'
SOB:           DB 'SOBO'
NIE:           DB 'NIED'
EVE:           DB 'EVER'
MENU:          DB 'M-MODYFIKACJA, N-NASTEPNY, ESC-KONIEC           ';48=030H
DLUGI_KOD:     DB 'NIEPRAWIDLOWA DLUGOSC KODU                      '
NAZWISKO:      DB 'ZBYT DLUGIE NAZWISKO                            ' 
WPISZ_KOD:     DB 'WPISZ KOD, IMIE I NAZWISKO                      '
PRZYKLAD:      DB 'PRZYKLAD:000002E67858(ENTER) JAN KOWALSKI(ENTER)'
ZLE:           DB 'WYBRALES ZLY KLAWISZ                            '
WYBIERAJ:      DB 'WYBIERZ: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ESC      '
WYB_LICZ:      DB 'WYBIERZ: 01234567890ABCDEF ,ESC                 '
JESZCZE_RAZ:   DB 'SPROBUJ JESZCZE RAZ                             ' 
SPODZ_ENTER:   DB 'SPODZIEWANY ZNAK ENTER                          '
OK_TERAZ_IMIE: DB 'TERAZ IMIE I NAZWISKO                           '
OK:            DB 'OK                                              '           
ALARM_WLA:     DB 'ALARM JEST WLACZONY      '
ALARM_WYL:     DB 'ALARM JEST WYLACZONY     '
HEXA_KOD:      DB '0123456789ABCDEF'
;****************************************************************************
END
