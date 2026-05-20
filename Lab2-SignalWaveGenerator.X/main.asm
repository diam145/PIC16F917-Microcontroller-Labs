;************************************************************************************
; LAB 2: Square Signal Generator (Group n=8)
; Student Name: Diallo Mountaga (#)
; 
; Description:  A precise square wave frequency generator utilizing the Timer0 
;               peripheral of the PIC16F917. Configured to toggle pin RB0 at a 
;               target period of 320ms (T = 160ms half-period delay).
;    
; Target Period: 320ms (T = 160ms) -> (2T = 320ms)
;     
; OBSERVED RESULTS:
; 1. Prescaler 1:32 (TMR0=100) -> Period = 320.10ms (Better Resolution)
; 2. Prescaler 1:64 (TMR0=178) -> Period = 320.22ms (Coarser Resolution)
;
; Note: 1:32 is more accurate because each timer tick is smaller (1.024ms).
;************************************************************************************

    #include <p16f917.inc>
    __CONFIG _CP_OFF & _CPD_OFF & _BOD_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF
    errorlevel -302

    org 0x00
    GOTO Initialize
    org 0x05

Initialize
    ; --- Set up Hardware (Bank 1) ---
    BSF     STATUS, RP0     ; Switch to Bank 1
    BCF     STATUS, RP1

    MOVLW   B'00010000'     ; Set clock to 125kHz
    MOVWF   OSCCON

    MOVLW   B'00000100'     ; Set Prescaler to 1:32 
    ;MOVLW  B'00000101'     ; Alternate: 1:64
    MOVWF   OPTION_REG

    BCF     TRISB, 0        ; Set RB0 as output

    ; --- Set up Hardware (Bank 0) ---
    BCF     STATUS, RP0     ; Back to Bank 0
    
    MOVLW   0x07            ; Disable comparators
    MOVWF   CMCON0
    
    BCF     PORTB, 0        ; Start with LED off
    BCF     INTCON, T0IF    ; Clear timer flag

Main 
    ; 1. Reset Timer
    BCF     INTCON, T0IF    ; Clear overflow flag
    MOVLW   D'100'          ; Load 160ms start value (Use 178 for PS 1:64)
    MOVWF   TMR0

    ; 2. Toggle Pin
    MOVLW   B'00000001'     ; Bit mask for RB0
    XORWF   PORTB, f        ; Flip the bit (0 to 1 or 1 to 0)

WaitLoop
    ; 3. Wait for Overflow
    BTFSS   INTCON, T0IF    ; Did the timer hit 255?
    GOTO    WaitLoop        ; No, keep waiting
    
    GOTO    Main            ; Yes, go reset and toggle again

    END