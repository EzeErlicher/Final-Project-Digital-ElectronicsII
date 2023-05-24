LIST p=16f887
#INCLUDE <p16f887.inc>
    
     ; CONFIG1
; __config 0x3FD4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
; CONFIG2
; __config 0x3FFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
     
;Variables para manejo del display
Hour1 EQU 0x70
Hour2 EQU 0x71
Minute1 EQU 0x72
Minute2 EQU 0x73
Second1 EQU 0x74
Second2 EQU 0x75
AmountOfHours EQU 0x76 
 
COUNTER1 EQU 0x77
COUNTER2 EQU 0x78
COUNTER3 EQU 0x79 
COUNTER_TMR0 EQU 0x7A
COUNTERADC   EQU 0x7B
W_TEMP  EQU 0x7C
STATUS_TEMP EQU 0x7D
ADC_VAL1 EQU 0xA0
ADC_VAL2 EQU 0xA1

 
     ORG 0x0000
     GOTO MAIN
     ORG 0x0004
     GOTO INTERRUPT
   
     ORG 0x0005
MAIN
; Configuracion de puertos
     BANKSEL ANSELH
     CLRF    ANSELH
     BSF     ANSEL,0    ; RA0(AN0) como puerto analógico (Puerto que se conecta a sensor temp)
     BANKSEL TRISD
     CLRF    TRISD
     CLRF    TRISC
     MOVLW   B'00000001'
     MOVWF   TRISB
        
 ;Configuración de interrupciones: TMR0,ADC
 
     MOVLW   B'11100000'   ;(GIE=1,PEIE=1,T0IE=1,T0IF=0)
     MOVWF   INTCON
     MOVLW   B'00000111'   ;( TMR0 Prescaler=256)
     MOVWF   OPTION_REG
     BANKSEL PIE1
     BSF     PIE1,ADIE
     BANKSEL PIR1
     BCF     PIR1,ADIF
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
     
;     CLRF  Second2
;     CLRF  Second1
;     CLRF  Minute2
;     CLRF  Minute1
;     CLRF  Hour2
;     CLRF  Hour1
     BANKSEL PORTC
     MOVLW B'11111111'
     MOVWF PORTC
     BANKSEL ADCON0
     BSF     ADCON0,GO   ;ADC inicia conversion
     ;MOVLW .20
     ;MOVWF COUNTER_TMR0
     ;MOVLW .61
     ;MOVWF TMR0
     
     
;----------------------MULTIPLEXACION DEL DISPLAY------------------------------     
Display_Digits
     
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
;     ;-----------------------------------------------------
;     BCF   PORTC,RC4
;     MOVF  Hour2,w
;     CALL  TO_7SEG
;     MOVWF PORTD
;     CALL  DELAY_3ms
;     BSF   PORTC,RC4
;     ;-----------------------------------------------------
;     BCF   PORTC,RC5
;     MOVF  Hour1,w
;     CALL  TO_7SEG
;     MOVWF PORTD
;     CALL  DELAY_3ms
;     BSF   PORTC,RC5
     
   
     GOTO Display_Digits
     
;----------------------*Fin programa Principal*--------------------------------

     ORG  0x0060
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
	
	ORG 0x0070
Sampling_Delay
	
	MOVLW	.10
	MOVWF	COUNTERADC
    LOOP  
	DECFSZ	COUNTERADC, F	
	GOTO	LOOP
	RETURN
	
     
;--------------------------TABLA BCD 7 SEGMENTOS-------------------------------
     ORG 0x0080
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
     
;------------------------------------------------------------------------------  
     ORG 0x0090
INTERRUPT
    
; Guardado del contexto
    MOVWF W_TEMP
    SWAPF STATUS,W
    MOVWF STATUS_TEMP
    
    BANKSEL PIR1
    BTFSC PIR1,ADIF
    GOTO  ADC_ISR
    GOTO  TMR0_ISR

END_INTERRUPT
;Recuperación del contexto y retorno a MAIN
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    RETFIE
    
;--------------------------SUBRUTINA ADC---------------------------------------   
    ORG 0x0110
ADC_ISR
    BANKSEL ADRESL
    MOVF    ADRESL,W
    MOVWF   ADC_VAL1
    BCF     STATUS,C
    RRF     ADC_VAL1,F
    MOVLW   .38
    SUBWF   ADC_VAL1
    BTFSC   STATUS,C
    GOTO    FEVER
    GOTO    NOT_FEVER
    
FEVER
    CLRF    Second2
    CLRF    Second1
    CLRF    Minute2
    CLRF    Minute1
    GOTO    END_ADC_ISR
    
NOT_FEVER
    MOVLW   .12
    MOVWF   Second2
    MOVLW   .5
    MOVWF   Second1
    MOVLW   .11
    MOVWF   Minute2
    MOVLW   .10
    MOVWF   Minute1
    
END_ADC_ISR    
    BANKSEL PIR1
    BCF     PIR1,ADIF
    CALL    Sampling_Delay
    ;BANKSEL ADCON0
    BSF     ADCON0,GO
    GOTO    END_INTERRUPT
    
    
;--------------------------SUBRUTINA TMR0--------------------------------------     
    
    ORG 0x0130
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
