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

;Variables para manejo Delay de display,TMR0 Y TMR1 y resguardo de contexto
COUNTER1     EQU 0x77
COUNTER2     EQU 0x78
COUNTER_TMR0 EQU 0x79
COUNTER_TMR1 EQU 0x7A
W_TEMP       EQU 0x7B
STATUS_TEMP  EQU 0x7C

;Variable que indica el estado en el cual se encuentra el turnero 
;( que es lo que se muestra en el display)
STATE        EQU 0x7D


;Variable que indica el string que se debe enviar por el puerto USART 
; o si corresponde un salto de línea 	
String_Flag    EQU 0x7E
;Variable que indica si el paciente tiene fiebre ("SI" o "NO") 
YesOrNo    EQU 0x7F

;Variables para manejo de display ADC/sensor de temperatura	
ADC_VAL1 EQU 0xA0
Digit4   EQU 0xA1 
Digit3   EQU 0xA2
Digit2   EQU 0xA3
Digit1   EQU 0xA4

;Variables para manejo de la fecha
Day2     EQU 0x20
Day1     EQU 0x21
Days     EQU 0x22
Month2   EQU 0x23
Month1   EQU 0x24
Months   EQU 0x25
Year2    EQU 0x26
Year1    EQU 0x27

;Variables para manejo consultorio,numero paciente y contador para envío por puerto USART
Patient3      EQU 0x29
Patient2      EQU 0x2A
Patient1      EQU 0x2B
Consult3      EQU 0x2C
Consult2      EQU 0x2D
Consult1      EQU 0x2E
USART_COUNTER EQU 0x2F
   
 
     ORG 0x0000
     GOTO MAIN
     ORG 0x0004
     GOTO INTERRUPT
   
     ORG 0x0005
MAIN
;------------------------CONFIGURACIÓN DE PUERTOS------------------------------
     BANKSEL ANSELH
     CLRF    ANSELH
     BSF     ANSEL,0    ;RA0(AN0) como puerto analógico (Puerto que se conecta a sensor temp)
     BANKSEL TRISD
     CLRF    TRISD
     CLRF    TRISC
     MOVLW   B'0001111' ;RB3-RB0 como entradas digitales
     MOVWF   TRISB
        
     
 ;------CONFIGURACIÓN DE INTERRUPCIONES: TMR0,TMR1,ADC,PORTB,INT/RB0,TX USART
 
     MOVLW   B'11011000'   ;(GIE=1,PEIE=1,T0IE=0,INTE=1,RBIE=1,T0IF=0,INTF=0,RBIF=0)
     MOVWF   INTCON
     MOVLW   B'00000111'   ; (RBPU=0 PORTB Pull-ups are enabled,INTEDG=0 Descending flank, TMR0 Prescaler=256)
     MOVWF   OPTION_REG
     BANKSEL PIE1
     BSF     PIE1,ADIE
     BSF     PIE1,TMR1IE
     MOVLW   B'00001111'
     MOVWF   WPUB          ; habilitación de resistencias de PULL-UP en RB3-RB0
     MOVLW   B'00001110'
     MOVWF   IOCB          ; habilitación de interupcion por cambio de nivel en RB3-RB1
     BANKSEL PIR1
     BCF     PIR1,ADIF
     BCF     PIR1,TMR1IF
     MOVLW   B'00110000'   ;(TMR1 always counting,Preescaler=8,internal clock,TMR1ON=0 Disabled)
     MOVWF   T1CON
     MOVLW   B'01000000'   ;(Fosc/8 ,Analog Channel=AN0,GO/DONE=0,ADON=0)
     MOVWF   ADCON0
     BANKSEL ADCON1
     MOVLW   B'10000000'   ;(ADFM=1 right justified ,VCFG1=0 Vss,VCFG0=0 Vdd)
     BSF     ADCON1,ADFM
     
;Configuracion del transmisor UART      
     MOVLW   .25
     MOVWF   SPBRG
     MOVLW   B'00100100'        ; TXEN=1,SYNC=0, BRGH=1
     MOVWF   TXSTA
     BANKSEL RCSTA
     BSF     RCSTA,SPEN
  
; Inicialización de variables: Fecha
     BANKSEL PORTC
     CLRF   Day2
     CLRF   Day1
     CLRF   Month2
     CLRF   Month1
     CLRF   Year2
     CLRF   Year1
     MOVLW  B'11111111'
     MOVWF  PORTC
     
; Inicialización de variables: Consultorio/Paciente
     CLRF   Patient3
     CLRF   Patient2
     CLRF   Patient1
     CLRF   Consult3
     CLRF   Consult2 
     CLRF   Consult1 
     
; Inicialización de variables: Clock
     BANKSEL PORTD
     CLRF    PORTD
     CLRF    PORTC
     MOVLW   .0
     MOVWF   Second2
     MOVLW   .0
     MOVWF   Second1
     MOVLW   .0
     MOVWF   Minute2
     MOVLW   .0
     MOVWF   Minute1
     MOVLW   .8
     MOVWF   Hour2
     MOVLW   .0
     MOVWF   Hour1
     MOVWF   AmountOfHours
     
; Inicialización de variables: TMR0 y TMR1 
     MOVLW .20
     MOVWF COUNTER_TMR0
     MOVLW .10
     MOVWF COUNTER_TMR1
     MOVLW .61
     MOVWF TMR0
     CLRF  TMR1L       
     CLRF  TMR1H

; Inicialiazción Variable de Estado y Variables para transmisión USART
     CLRF  STATE
     CLRF  String_Flag
     CLRF  YesOrNo
     BANKSEL PORTA
     CLRF  USART_COUNTER
     
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
     MOVLW .3
     SUBWF STATE,W
     BTFSC STATUS,Z 
     GOTO  Display_ADC
     GOTO  Transmitting_Data
     
     
;--------------------------DELAYS-TABLAS--------------------------------------
     
          ORG 0x0070
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
     RETLW B'11110011' ;P
     RETLW B'11110111' ;A
     RETLW B'11111001' ;E
     
;-----------------------------------------------------------------------------
     ORG 0x007E
String1    
    ADDWF PCL,F
    RETLW 'P' ;0
    RETLW 'A'
    RETLW 'C'
    RETLW 'I'
    RETLW 'E'
    RETLW 'N'
    RETLW 'T'
    RETLW 'E'
    RETLW ':'
    RETLW ' ' ;9
    
    ORG 0x008A
String2
    ADDWF PCL,F
    RETLW ',' ;0
    RETLW 'F' 
    RETLW 'I'
    RETLW 'E'
    RETLW 'B'
    RETLW 'R'
    RETLW 'E'
    RETLW ':' ;7
    
    ORG 0x0094
Fever
    ADDWF PCL,F
    RETLW 'S' 
    RETLW 'I'
 
    ORG 0x0097
Not_Fever    
    ADDWF PCL,F
    RETLW 'N'
    RETLW 'O' 
;-----------------------------------------------------------------------------
     ORG  0x09C
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
	
;-----------------------------------------------------------------------------	
     	ORG 0x0107
Sampling_Delay
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP                  ;Delay de muestreo del ADC
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	RETURN
	  
;----------------------RUTINA DISPLAY DE LA FECHA-----------------------------     
     ORG   0x0120
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
     MOVF  Patient3,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC0
     ;-----------------------------------------------------
     BCF   PORTC,RC1
     MOVF  Patient2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC1
     ;-----------------------------------------------------
     BCF   PORTC,RC2
     MOVF  Patient1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC2
     ;-----------------------------------------------------
     BCF   PORTC,RC3
     MOVF  Consult3,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC3
     ;-----------------------------------------------------
     BCF   PORTC,RC4
     MOVF  Consult2,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC4
     ;-----------------------------------------------------
     BCF   PORTC,RC5
     MOVF  Consult1,w
     CALL  TO_7SEG
     MOVWF PORTD
     CALL  DELAY_3ms
     BSF   PORTC,RC5
     
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

;----------------------RUTINA DISPLAY ADC/SENSOR DE TEMP----------------------    
Display_ADC
    
    BANKSEL PORTC
    BCF   PORTC,RC0
    BANKSEL ADRESL
    MOVF  Digit4,w
    CALL  TO_7SEG
    BANKSEL PORTD
    MOVWF PORTD
    CALL  DELAY_3ms
    BSF   PORTC,RC0
     ;-----------------------------------------------------
    BANKSEL PORTC
    BCF   PORTC,RC1
    BANKSEL ADRESL
    MOVF  Digit3,w
    CALL  TO_7SEG
    BANKSEL PORTD
    MOVWF PORTD
    CALL  DELAY_3ms
    BSF   PORTC,RC1
     ;-----------------------------------------------------
    BANKSEL PORTC
    BCF   PORTC,RC2
    BANKSEL ADRESL
    MOVF  Digit2,w
    CALL  TO_7SEG
    BANKSEL PORTD
    MOVWF PORTD
    CALL  DELAY_3ms
    BSF   PORTC,RC2
    ;-----------------------------------------------------
    BANKSEL PORTC
    BCF   PORTC,RC3
    BANKSEL ADRESL
    MOVF  Digit1,w
    CALL  TO_7SEG
    BANKSEL PORTD
    MOVWF PORTD
    CALL  DELAY_3ms
    BSF   PORTC,RC3
    
    GOTO State_Decision
    
;----------------------RUTINA TRANSMISIÓN USART DE DATOS----------------------
Transmitting_Data
    
    BANKSEL PORTC
    BCF   PORTC,RC3
    MOVLW  .12
    CALL  TO_7SEG
    MOVWF PORTD
    CALL  DELAY_3ms
    BSF   PORTC,RC3
    
    GOTO State_Decision
       
;------------------RUTINA DE SERVICIO A LAS INTERRUPCIONES--------------------	
     ORG 0x0220
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
    BTFSC   PIR1,ADIF
    GOTO    ADC_ISR
    BTFSC   PIR1,TXIF
    GOTO    TX_ISR

END_INTERRUPT
;Recuperación del contexto y retorno a MAIN
    SWAPF STATUS_TEMP,W
    MOVWF STATUS
    SWAPF W_TEMP,F
    SWAPF W_TEMP,W
    RETFIE
    
;----------------------SUBRUTINA INTERRUPCIÓN TMR1---------------------------     
    
    ORG 0x240
TMR1_ISR
    
    BANKSEL TMR1
    CLRF    TMR1L                ;Se carga el TMR1 en 0
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
    GOTO    EQUALS_4
    
EQUALS_0
    MOVLW  .2
    MOVWF  STATE
    GOTO   END_TMR1_ISR

EQUALS_1
    CLRF  STATE
    GOTO  END_TMR1_ISR
    
EQUALS_2
    INCF    STATE
    BANKSEL ADCON0
    BSF     ADCON0,ADON            ;Se habilita ADC
    CALL    Sampling_Delay
    BSF     ADCON0,GO
    GOTO    END_TMR1_ISR
    
EQUALS_3
    INCF    STATE
    BANKSEL ADCON0
    BCF     ADCON0,ADON   ;Se deshabilita ADC
    
    BANKSEL PIE1
    BSF     PIE1,TXIE     ;Se habilita la interrupción por TXUSART el transmisor 
    BANKSEL TXREG
    MOVLW   '-'
    MOVWF   TXREG
    GOTO  END_TMR1_ISR
    
 EQUALS_4
    
    BANKSEL PIE1
    BCF     PIE1,TXIE       ;Se deshabilita la interrupción por TXUSART el transmisor
    MOVLW   .1
    MOVWF   STATE
    
    BANKSEL PORTA                              
    INCF    Patient3,F  
    MOVLW   .10
    SUBWF   Patient3,W
    BTFSS   STATUS,Z
    GOTO    RANDOM
    CLRF    Patient3
    
    INCF    Patient2,F
    MOVLW   .10
    SUBWF   Patient2,W
    BTFSS   STATUS,Z
    GOTO    RANDOM
    CLRF    Patient2
    
    INCF    Patient1,F
    MOVLW   .10
    SUBWF   Patient1,W
    BTFSS   STATUS,Z
    GOTO    RANDOM
    CLRF    Patient1 
    
RANDOM    
    MOVF    Second2,w              ;Se incrementa el contador de pacientes y se          
    MOVWF   Consult3               ; usan los ultimos 3 numeros del clock
    MOVF    Second1,w              ; como generador de numeros random
    MOVWF   Consult2               
    MOVF    Minute2,w
    MOVWF   Consult1
 
    
END_TMR1_ISR    
    BANKSEL PIR1
    BCF     PIR1,TMR1IF
    GOTO    END_INTERRUPT
    
;-------------------SUBRUTINA INTERRUPCIÓN TMR0-CLOCK--------------------------
   ORG 0x0300
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
    CLRF  Hour2
    INCF  Hour1
    GOTO  END_TMR0_ISR
    
Reset_24hs
    CLRF Hour2
    CLRF Hour1
    CLRF AmountOfHours
    
END_TMR0_ISR
    BCF   INTCON,T0IF  
    GOTO  END_INTERRUPT

;---------------------SUBRUTINA INTERRUPCIÓN PORTB-----------------------------    
    ORG 0x0330
PortB_ISR
    
    BANKSEL PORTA
    MOVF    PORTB,F
    
    BTFSS   PORTB,RB1
    GOTO    RB1_ISR           
    BTFSS   PORTB,RB2         
    GOTO    RB2_ISR
    BTFSS   PORTB,RB3
    GOTO    RB3_ISR
    GOTO    PortB_ISR_END

RB1_ISR
    INCF  Day2,F
    INCF  Days,F
    MOVLW .32
    SUBWF Days,W
    BTFSC STATUS,Z
    GOTO  Reset_Days
    MOVLW .10
    SUBWF Day2,W
    BTFSS STATUS,Z
    GOTO  PortB_ISR_END
    CLRF  Day2
    INCF  Day1,F
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
    CLRF  Year1
    CLRF  Year2
    GOTO  PortB_ISR_END
      
    
PortB_ISR_END
    BANKSEL INTCON
    BCF INTCON,RBIF
    GOTO END_INTERRUPT
    
    
;---------------------SUBRUTINA INTERRUPCIÓN INT/RB0---------------------------
      
    ;Se habilitan TMR0 Y TMR1
    ORG 0x0390
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
    
    
;------------------------SUBRUTINA INTERRUPCIÓN ADC----------------------------
    ORG 0x0400
ADC_ISR
    BANKSEL ADRESL
    MOVF    ADRESL,W
    MOVWF   ADC_VAL1
    BCF     STATUS,C
    RRF     ADC_VAL1,F     ;Se divide el valor entregado por el ADC en 2
    MOVLW   .38            ;para obtener el valor real de temperatura en grados
    SUBWF   ADC_VAL1,W     ;si dicho valor es mayor o igual a 38 el paciente 
    BTFSC   STATUS,C       ;tiene fiebre
    GOTO    FEVER
    GOTO    NOT_FEVER
    
FEVER
    CLRF    Digit4
    CLRF    Digit3          
    CLRF    Digit2           ; Se muestra "0000" en el display
    CLRF    Digit1
    GOTO    END_ADC_ISR
    
NOT_FEVER
    MOVLW   .12
    MOVWF   Digit4
    MOVLW   .5
    MOVWF   Digit3           ; Se muestra "PASE" en el display
    MOVLW   .11
    MOVWF   Digit2
    MOVLW   .10
    MOVWF   Digit1
    
END_ADC_ISR    
    BANKSEL PIR1
    BCF     PIR1,ADIF
    CALL    Sampling_Delay
    BSF     ADCON0,GO
    GOTO    END_INTERRUPT
    
    
;-----------------SUBRUTINA INTERRUPCIÓN TRANSMISIÓN USART---------------------   
    ORG 0x0440
TX_ISR
    
    MOVLW  .0
    SUBWF  String_Flag,w         ;"PACIENTE: {numero de paciente}"
    BTFSC  STATUS,Z
    GOTO   Send_String1
    
    MOVLW  .1
    SUBWF  String_Flag,w              
    BTFSC  STATUS,Z              ;"FIEBRE: "
    GOTO   Send_String2
    
    MOVLW  .2
    SUBWF  String_Flag,w         ;salto de línea
    BTFSC  STATUS,Z
    GOTO   newLine
      
     
Send_String1
    BANKSEL TXREG
   
    MOVLW   .10
    SUBWF  USART_COUNTER,W
    BTFSC  STATUS,Z
    GOTO   Send_Patient1
    
    MOVLW   .11
    SUBWF  USART_COUNTER,W
    BTFSC  STATUS,Z
    GOTO   Send_Patient2
    
    MOVLW   .12
    SUBWF  USART_COUNTER,W
    BTFSC  STATUS,Z
    GOTO   Send_Patient3
    
    MOVF   USART_COUNTER,W
    CALL   String1
    MOVWF  TXREG
    INCF   USART_COUNTER,F
    GOTO   END_TX_ISR
    
Send_Patient1    
    MOVF   Patient1,W
    ADDLW  .48
    MOVWF  TXREG
    INCF   USART_COUNTER,F
    GOTO   END_TX_ISR
    
Send_Patient2    
    MOVF   Patient2,W
    ADDLW .48
    MOVWF  TXREG
    INCF   USART_COUNTER,F
    GOTO   END_TX_ISR    
        
Send_Patient3    
    MOVF   Patient3,W
    ADDLW .48
    MOVWF  TXREG
    CLRF   USART_COUNTER
    INCF   String_Flag,f
    GOTO   END_TX_ISR
;--------------------------------------------------------------------------    

 Send_String2
 
    MOVLW  .8
    SUBWF  USART_COUNTER,W
    BTFSC  STATUS,Z
    GOTO   FeverOrNotFever
    MOVF   USART_COUNTER,W
    CALL   String2
    MOVWF  TXREG
    INCF   USART_COUNTER,F
    GOTO   END_TX_ISR
   
; si tiene fiebre se muestra "SI" caso contrario se envía "NO"
FeverOrNotFever
    
    BANKSEL ADRESL
    MOVLW   .38
    SUBWF   ADC_VAL1,W
    BTFSC   STATUS,C
    GOTO    OverEquals38
    
    BANKSEL TXREG
    MOVF  YesOrNo,w
    CALL  Not_Fever   
    MOVWF   TXREG
L    
    INCF  YesOrNo
    MOVLW .2
    SUBWF YesOrNo,w
    BTFSS STATUS,Z
    GOTO  END_TX_ISR
    CLRF  YesOrNo
    CLRF  USART_COUNTER
    INCF  String_Flag,f
    GOTO  END_TX_ISR
    
OverEquals38
    BANKSEL TXREG
    MOVF  YesOrNo,w
    CALL  Fever
    MOVWF TXREG
    GOTO  L 
 
newLine
    MOVLW   '\r'
    MOVWF   TXREG
    BANKSEL PIE1
    BCF     PIE1,TXIE 
    CLRF    String_Flag 

        
END_TX_ISR     
     GOTO END_INTERRUPT
     
     END
    

;------------------------------------------------------------------------------
    

