;************************************************************************************
; Group AO1 - 8
; Student:  Mountaga Diallo (#)
; Lab 3 - Continuous Polling & XOR Toggle Version (4 MSBs)
;
; Description:  A real-time dual-channel mixed-signal data acquisition system.
;               Continuously samples analog voltages from POT1 (AN0) and POT2 (AN1)
;               via polling. It outputs the 4 Most Significant Bits (MSBs) 
;               onto pins RD4-RD7 and alternates channels every 1.0 second.
;
; Parameters:
;   - Core Clock: 31 kHz Ultra-Low-Power Internal Oscillator Block
;   - Channel Indicator: RB0 (LED ON = POT1/AN0 Active | LED OFF = POT2/AN1 Active)
;   - Data Justification: Left-Justified (8 MSBs mapped entirely to ADRESH)
; 
; A = n modulo 8 = 8 mod 8 = 0 --> AN0(RA0)
; B = (n+1) modulo 8 = 9 mod 8 = 1 --> AN1(RA1)
; T = 1 second
;************************************************************************************

    #include <p16f917.inc>
    __CONFIG _CP_OFF & _CPD_OFF & _BOD_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF
    errorlevel -302

; Vars to store the result
RESULTH EQU 0xA0
RESULTL EQU 0xA1
    
    ORG 0x00
    GOTO Initialize
    ORG 0x05
    
Initialize
    BCF     STATUS, RP1     ; Bank 1
    BSF     STATUS, RP0
    
    ; Turn off comparators
    MOVLW   0x07
    MOVWF   CMCON0
    
    ; Ocillator frequency
    MOVLW   0x00            ; 31kHz
    MOVWF   OSCCON
    
    ; Prescaler (1:32 assigned to TMR0)
    MOVLW   B'10000100'     ; 0x84
    MOVWF   OPTION_REG
    
    ; Config Input pins (RA0 and RA1)
    BSF     TRISA, RA0
    BSF     TRISA, RA1
    
    ; Config Analog pins (AN0 and AN1)
    BSF     ANSEL, AN0
    BSF     ANSEL, AN1
    
    ; Config Outputs
    CLRF    TRISD           ; Output (LEDs 4-7 on PORTD)
    BCF     TRISB, 0        ; Output (LED0 on RB0)
    
    ; Turn ON the ADC and its Justification
    MOVLW   B'00000000'     ; Left Justified, Fosc/2
    MOVWF   ADCON1
    
    ; Back to Bank 0
    BCF     STATUS, RP0
    
    ; Set Initial State
    BSF     PORTB, 0        ; Start with LED0 ON (POT1)
    MOVLW   B'00000001'     ; Start with AN0, ADON=1
    MOVWF   ADCON0
    
    CALL    SampleTime      ; Initial charge delay
    
;**********************************************************************
; Main Program Loop
;**********************************************************************
Main
    BSF     ADCON0, GO      ; Start first conversion
    CALL    ResetTimer      ; Start the 1-second window
    CALL    ConversionLoop  ; Sample & Display continuously for 1s
    CALL    Toggle          ; Switch POTs and toggle LED0
    GOTO    Main

;**********************************************************************
; ConversionLoop (Continuously polls until 1 second is up)
;**********************************************************************
ConversionLoop
    BTFSC   ADCON0, GO      ; Wait for ADC to finish
    GOTO    ConversionLoop
    
    ; --- Save Results ---
    MOVF    ADRESH, W       ; Read High bits (Bank 0)
    BSF     STATUS, RP0     ; Bank 1
    MOVWF   RESULTH
    MOVF    ADRESL, W       ; Read Low bits (Bank 1)
    MOVWF   RESULTL
    
    CALL    DISPLAY_LEDS    ; Update the LEDs instantly
    
    ; --- Check Timer & Loop ---
    BCF     STATUS, RP0     ; Bank 0 for INTCON and ADCON0
    BSF     ADCON0, GO      ; Start next conversion immediately
    BTFSS   INTCON, T0IF    ; Has 1 second passed?
    GOTO    ConversionLoop  ; No? Keep sampling!
    RETURN                  ; Yes? Return to Main to toggle channels

;**********************************************************************
; Toggle (Switches between AN0/AN1 and flips LED0)
;**********************************************************************
Toggle
    BCF     STATUS, RP0     ; Bank 0
    
    ; Toggle LED0 on RB0
    MOVLW   B'00000001'
    XORWF   PORTB, F
    
    ; Toggle between AN0 (0000 0001) and AN1 (0000 0101)
    MOVLW   B'00000100'     ; Mask to flip bit 2 (CHS0)
    XORWF   ADCON0, F
    
    CALL    SampleTime      ; Let new channel voltage settle
    RETURN

;**********************************************************************
; ResetTimer (Clears flag and presets TMR0 for ~1 second)
;**********************************************************************
ResetTimer
    BCF     STATUS, RP0     ; Bank 0
    BCF     INTCON, T0IF    ; Clear flag
    MOVLW   D'14'           ; 1-second math for 31kHz & 1:32 prescaler
    MOVWF   TMR0
    RETURN

;**********************************************************************
; SampleTime (Acquisition Delay)
;**********************************************************************
SampleTime
    NOP
    NOP
    RETURN

;**********************************************************************
; DISPLAY_LEDS (Maps 4 MSBs to RD4-RD7 safely)
;**********************************************************************
DISPLAY_LEDS
    BCF     STATUS, RP0     ; Ensure Bank 0 to write to PORTD
    CLRF    PORTD           ; Clear LEDs before updating
    
    BSF     STATUS, RP0     ; Switch to Bank 1 to read variables
    
    ; Check 4th MSB (Left-Justified bit 6 is RESULTH, bit 4) -> LED 7 (RD7)
    BTFSC   RESULTH, 4
    GOTO    Set_LED7
Next_Bit1
    ; Check 3rd MSB (Left-Justified bit 7 is RESULTH, bit 5) -> LED 6 (RD6)
    BTFSC   RESULTH, 5
    GOTO    Set_LED6
Next_Bit2
    ; Check 2nd MSB (Left-Justified bit 8 is RESULTH, bit 6) -> LED 5 (RD5)
    BTFSC   RESULTH, 6
    GOTO    Set_LED5
Next_Bit3
    ; Check 1st MSB (Left-Justified bit 9 is RESULTH, bit 7) -> LED 4 (RD4)
    BTFSC   RESULTH, 7
    GOTO    Set_LED4
    
    BCF     STATUS, RP0     ; Return to Bank 0 when done
    RETURN

Set_LED7
    BCF     STATUS, RP0
    BSF     PORTD, 7
    BSF     STATUS, RP0
    GOTO    Next_Bit1

Set_LED6
    BCF     STATUS, RP0
    BSF     PORTD, 6
    BSF     STATUS, RP0
    GOTO    Next_Bit2

Set_LED5
    BCF     STATUS, RP0
    BSF     PORTD, 5
    BSF     STATUS, RP0
    GOTO    Next_Bit3

Set_LED4
    BCF     STATUS, RP0
    BSF     PORTD, 4
    RETURN

    END