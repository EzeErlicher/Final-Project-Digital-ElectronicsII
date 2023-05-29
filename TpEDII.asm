LIST p=16f887
#INCLUDE <p16f887.inc>
    
     ; CONFIG1
; __config 0x3FD4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
     
;Variables para manejo del Clock
Hour1         EQU 0x70
Hour2         EQU 0x71
Minute1       EQU 0x72
Minute2       EQU 0x73
Second1       EQU 0x74
Second2       EQU 0x75
AmountOfHours EQU 0x76 

;Variables para manejo TMR0,TMR1 y resguardo de contexto
COUNTER1     EQU 0x77
COUNTER2     EQU 0x78
COUNTER3     EQU 0x79 
COUNTER_TMR0 EQU 0x7A
COUNTER_TMR1 EQU 0x7B
COUNTERADC   EQU 0x7C
W_TEMP       EQU 0x7D
STATUS_TEMP  EQU 0x7E
STATE        EQU 0x7F

	
ADC_VAL1 EQU 0xA0

;Variables para manejo de la fecha
Day2     EQU 0x20
Day1     EQU 0x21
Days     EQU 0x22
Month2   EQU 0x23
Month1   EQU 0x24
Months   EQU 0x25
Year2    EQU 0x26
Year1    EQU 0x27
Years    EQU 0x28
   
 
     ORG 0x0000
     GOTO MAIN
     ORG 0x0004
     GOTO INTERRUPT
   
     ORG 0x0005
MAIN
; Configuracion de puertos
     BANKSEL ANSELH
     CLRF    ANSELH
     BSF     ANSEL,0    ;RA0(AN0) como puerto analógico (Puerto que se conecta a sensor temp)
     BANKSEL TRISD
     CLRF    TRISD
     CLRF    TRISC
     MOVLW   B'0001111' ;RB3-RB0 como entradas digitales
     MOVWF   TRISB
        
 ;Configuración de interrupciones: TMR0,ADC,PORTB,INT/RB0
 
     MOVLW   B'11011000'   ;(GIE=1,PEIE=1,T0IE=0,INTE=1,RBIE=1,T0IF=0,INTF=0,RBIF=0)
     MOVWF   INTCON
     MOVLW   B'00000111'   ; (RBPU=0 PORTB Pull-ups are enabled,INTEDG=0 Descending flank, TMR0 Prescaler=256)
     MOVWF   OPTION_REG
     BANKSEL PIE1
     BSF     PIE1,ADIE
     BSF     PIE1,TMR1IE
     MOVLW   B'00011110'
     MOVWF   WPUB          ; habilitación de resistencias de PULL-UP en RB4-RB1
     MOVWF   IOCB          ; habilitación de interupcion por cambio de nivel en RB4-RB1
     BANKSEL PIR1
     BCF     PIR1,ADIF
     BCF     PIR1,TMR1IF
     MOVLW   B'00110000'   ;(TMR1 always counting,Preescaler=8,internal clock,TMR1ON=0 Disabled)
     MOVWF   T1CON
     MOVLW   B'01000001'   ;(Fosc/8 ,Analog Channel=AN0,GO/DONE=0,ADON=1)
     MOVWF   ADCON0
     BANKSEL ADCON1
     MOVLW   B'10000000'   ;(ADFM=1 right justified ,VCFG1=0 Vss,VCFG0=0 Vdd)
     BSF     ADCON1,ADFM
     
     
; Inicialización de variables
     BANKSEL PORTD
     CLRF    PORTD
     CLRF    PORTC
     MOVLW   .9
     MOVWF   Second2
     MOVLW   .5
     MOVWF   Second1
     MOVLW   .6
     MOVWF   Minute2
     MOVLW   .5
     MOVWF   Minute1
     MOVLW   .2
     MOVWF   Hour2
     MOVLW   .2
     MOVWF   Hour1
     MOVLW   .2
     MOVWF   AmountOfHours
     
     CLRF  Day2
     CLRF  Day1
     CLRF  Month2
     CLRF  Month1
     CLRF  Year2
     CLRF  Year1
     BANKSEL PORTC
     MOVLW B'11111111'
     MOVWF PORTC
     ;BANKSEL ADCON0
     ;BSF     ADCON0,GO   ;ADC inicia conversion
     MOVLW .20
     MOVWF COUNTER_TMR0
     MOVLW .10
     MOVWF COUNTER_TMR1
     MOVLW .61
     MOVWF TMR0
     CLRF  TMR1L       ;remember to enable TMR1 (TMR10N)
     CLRF  TMR1H
     CLRF  STATE
     
;---------------------RUTINA DECISIÓN DE ESTADO-------------------------------     
State_Decision     
     MOVLW .0
     SUBWF STATE,W
     BTFSC STATUS,Z
     GOTO  Display_Date
     MOVLW .1
     SUBWF STATE,W
     BTFSC STATUS,Z
     GOTO  Display_Patient
     MOVLW .2
     SUBWF STATE,W
     BTFSC STATUS,Z
     GOTO  Display_Clock
     GOTO  $    ;GOTO Display_ADC
     
;----------------------RUTINA DISPLAY DE LA FECHA-----------------------------     
 
Display_Date     
     BCF   PORTC,RC0
     MOVF  Year2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC0
     ;-----------------------------------------------------
     BCF   PORTC,RC1
     MOVF  Year1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC1
     ;-----------------------------------------------------
     BCF   PORTC,RC2
     MOVF  Month2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC2
     ;-----------------------------------------------------
     BCF   PORTC,RC3
     MOVF  Month1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC3
     ;-----------------------------------------------------
     BCF   PORTC,RC4
     MOVF  Day2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC4
     ;-----------------------------------------------------
     BCF   PORTC,RC5
     MOVF  Day1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC5
     
     GOTO State_Decision

;----------------------RUTINA DISPLAY PACIENTE/CONSULTORIO--------------------  
Display_Patient
     
     BCF   PORTC,RC0
     MOVLW .9
     CALL  TO_7SEG
     MOVWF PORTD
     BSF   PORTC,RC0
     
     GOTO  State_Decision
     
;----------------------RUTINA DISPLAY DEL CLOCK------------------------------- 
     
Display_Clock
     
     BCF   PORTC,RC0
     MOVF  Second2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC0
     ;-----------------------------------------------------
     BCF   PORTC,RC1
     MOVF  Second1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC1
     ;-----------------------------------------------------
     BCF   PORTC,RC2
     MOVF  Minute2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC2
     ;-----------------------------------------------------
     BCF   PORTC,RC3
     MOVF  Minute1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC3
     ;-----------------------------------------------------
     BCF   PORTC,RC4
     MOVF  Hour2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC4
     ;-----------------------------------------------------
     BCF   PORTC,RC5
     MOVF  Hour1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC5
     
     GOTO State_Decision
      
;----------------------*Fin programa Principal*--------------------------------
     
      ORG 0x00F0
TO_7SEG
     ADDWF   PCL,f
     RETLW B'10111111' ;0
     RETLW B'10000110'
     RETLW B'11011011'
     RETLW B'11001111'
     RETLW B'11100110'         
     RETLW B'11101101'
     RETLW B'11111101'
     RETLW B'10000111'
     RETLW B'11111111'
     RETLW B'11100111' ;9
     RETLW B'1110011'  ;P
     RETLW B'1110111'  ;A
     RETLW B'1111001'  ;E
     
;-----------------------------------------------------------------------------
     ORG  0x0100
DELAY_3ms
     
        MOVLW	.4		
        MOVWF	COUNTER2			
    L4  
	MOVLW	.255
	MOVWF	COUNTER1
    L3  
	DECFSZ	COUNTER1, F	
	GOTO	L3	
	DECFSZ	COUNTER2, F	
	GOTO	L4
	RETURN
;----------------------------------------------------------------------------	
	ORG 0x0110
Sampling_Delay
	
	MOVLW	.10
	MOVWF	COUNTERADC
    LOOP  
	DECFSZ	COUNTERADC, F	
	GOTO	LOOP
	RETURN
	
     
;---------------------------------------------------------------------------	
     ORG 0x0120
INTERRUPT
    
; Guardado del contexto
    MOVWF   W_TEMP
    SWAPF   STATUS,W
    MOVWF   STATUS_TEMP
    
    BANKSEL PIR1
    BTFSC   PIR1,TMR1IF
    GOTO    TMR1_ISR
    BANKSEL INTCON
    BTFSC   INTCON,T0IF
    GOTO    TMR0_ISR
    BTFSC   INTCON,RBIF
    GOTO    PortB_ISR
    BTFSC   INTCON,INTF
    GOTO    INT_ISR
    

END_INTERRUPT
;Recuperación del contexto y retorno a MAIN
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    RETFIE
    
;---------------------SUBRUTINA INTERRUPCIÓN INT/RB0-----------------------------
      
    ;Se habilitan TMR0 Y TMR1
    ORG 0x0135
INT_ISR
    MOVLW   .1
    MOVWF   STATE
    
    BANKSEL PIE1
    BSF     PIE1,TMR1IE
    BANKSEL T1CON
    BSF     T1CON,TMR1ON
    
    BANKSEL INTCON
    BSF     INTCON,T0IE
   
  
    BCF     INTCON,INTF
    GOTO    END_INTERRUPT
    
;---------------------SUBRUTINA INTERRUPCIÓN PORTB-----------------------------    
    ORG 0x0145
PortB_ISR
    
    BANKSEL PORTA
    MOVF    PORTB,F
    BTFSS   PORTB,RB1
    GOTO    RB1_ISR           ;Se identifica en que puerto ocurre un flanco
    BTFSS   PORTB,RB2         ;descendente
    GOTO    RB2_ISR
    BTFSS   PORTB,RB3
    GOTO    RB3_ISR
    GOTO    PortB_ISR_END

RB1_ISR
    INCF  Day2,F
    INCF  Days,F
    MOVLW .31
    SUBWF Days,W
    BTFSC STATUS,Z
    GOTO  Reset_Days
    MOVLW .10
    SUBWF Day2,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Day2
    
    INCF  Day1,F
    MOVLW .4
    SUBWF Day1,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Day2
    INCF  Day1
    GOTO  PortB_ISR_END
    
Reset_Days
    MOVLW .1
    MOVWF Day2
    MOVWF Days
    CLRF  Day1
    GOTO  PortB_ISR_END
;--------------------------------------------------------------------------
RB2_ISR
    INCF  Month2,F
    INCF  Months,F
    MOVLW .13
    SUBWF Months,W
    BTFSC STATUS,Z
    GOTO  Reset_Months
    MOVLW .10
    SUBWF Month2,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Month2
    
    INCF  Month1,F
    MOVLW .2
    SUBWF Month1,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Month2
    INCF  Month1
    GOTO  PortB_ISR_END
    
Reset_Months
    MOVLW .1
    MOVWF Month2
    MOVWF Months
    CLRF  Month1
    GOTO  PortB_ISR_END
    
;-----------------------------------------------------------------------------    
RB3_ISR
    INCF  Year2,F
    INCF  Years,F
    MOVLW .100
    SUBWF Years,W
    BTFSC STATUS,Z
    GOTO  Reset_Years
    MOVLW .10
    SUBWF Year2,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Year2
    
    INCF  Year1,F
    MOVLW .10
    SUBWF Year1,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Year2
    INCF  Year1
    GOTO  PortB_ISR_END
    
Reset_Years
    CLRF  Year2
    CLRF  Year1
    CLRF  Years
    
    
PortB_ISR_END
    BANKSEL INTCON
    BCF INTCON,RBIF
    GOTO END_INTERRUPT
    
    
    
    
;--------------------------SUBRUTINA ADC---------------------------------------   
;    ORG 0x0110
;ADC_ISR
;    BANKSEL ADRESL
;    MOVF    ADRESL,W
;    MOVWF   ADC_VAL1
;    BCF     STATUS,C
;    RRF     ADC_VAL1,F
;    MOVLW   .38
;    SUBWF   ADC_VAL1
;    BTFSC   STATUS,C
;    GOTO    FEVER
;    GOTO    NOT_FEVER
;    
;FEVER
;    CLRF    Second2
;    CLRF    Second1
;    CLRF    Minute2
;    CLRF    Minute1
;    GOTO    END_ADC_ISR
;    
;NOT_FEVER
;    MOVLW   .12
;    MOVWF   Second2
;    MOVLW   .5
;    MOVWF   Second1
;    MOVLW   .11
;    MOVWF   Minute2
;    MOVLW   .10
;    MOVWF   Minute1
;    
;END_ADC_ISR    
;    BANKSEL PIR1
;    BCF     PIR1,ADIF
;    CALL    Sampling_Delay
;    ;BANKSEL ADCON0
;    BSF     ADCON0,GO
;    GOTO    END_INTERRUPT
;    
    
;----------------------SUBRUTINA INTERRUPCIÓN TMR1---------------------------     
    
    ORG 0x019A
TMR1_ISR
    
    BANKSEL TMR1
    CLRF    TMR1L
    CLRF    TMR1H
    DECFSZ  COUNTER_TMR1
    GOTO    END_TMR1_ISR
    MOVLW   .10
    MOVWF   COUNTER_TMR1
    
    MOVLW   .1
    SUBWF   STATE,W
    BTFSC   STATUS,Z
    GOTO    EQUALS_1
    MOVLW   .0
    SUBWF   STATE,W
    BTFSC   STATUS,Z
    GOTO    EQUALS_0
    MOVLW   .2
    SUBWF   STATE,W
    BTFSC   STATUS,Z
    GOTO    EQUALS_2
    MOVLW   .3
    SUBWF   STATE,W
    BTFSC   STATUS,Z
    GOTO    EQUALS_3
    
EQUALS_0
    MOVLW  .2
    MOVWF  STATE
    GOTO   END_TMR1_ISR

EQUALS_1
    CLRF  STATE
    GOTO  END_TMR1_ISR
    
EQUALS_2
    INCF  STATE
    GOTO  END_TMR1_ISR
    
EQUALS_3
    CLRF STATE
    
END_TMR1_ISR    
    BANKSEL PIR1
    BCF     PIR1,TMR1IF
    GOTO    END_INTERRUPT
    
;------------------------------------------------------------------------------    
   ORG 0x0210
TMR0_ISR
    
    MOVLW .61
    MOVWF TMR0
    DECFSZ COUNTER_TMR0
    GOTO END_TMR0_ISR
    
    MOVLW .20
    MOVWF COUNTER_TMR0
    
    INCF Second2,F
    MOVLW .10
    SUBWF Second2,W
    BTFSS STATUS,Z
    GOTO END_TMR0_ISR
    CLRF Second2
    
    INCF Second1,F
    MOVLW .6
    SUBWF Second1,W
    BTFSS STATUS,Z
    GOTO END_TMR0_ISR
    CLRF Second1
    
    INCF  Minute2,F
    MOVLW .10
    SUBWF Minute2,W
    BTFSS STATUS,Z
    GOTO END_TMR0_ISR
    CLRF Minute2
    
    INCF Minute1,F
    MOVLW .6
    SUBWF Minute1,W
    BTFSS STATUS,Z
    GOTO END_TMR0_ISR
    CLRF Minute1
    
    INCF Hour2,F
    INCF AmountOfHours
    MOVLW .24
    SUBWF AmountOfHours,W
    BTFSC STATUS,Z
    GOTO  Reset_24hs
    MOVLW .10
    SUBWF Hour2,W
    BTFSS STATUS,Z
    GOTO  END_TMR0_ISR
    CLRF Hour2
    INCF Hour1
    GOTO END_TMR0_ISR
    
Reset_24hs
    CLRF Hour2
    CLRF Hour1
    CLRF AmountOfHours
    
END_TMR0_ISR
    BCF   INTCON,T0IF  
    GOTO  END_INTERRUPT
    END

;------------------------------------------------------------------------------
    

