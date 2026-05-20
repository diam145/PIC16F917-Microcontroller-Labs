;**********************************************************************
; ELG4159 Lab 4: Analog Signal Generation
; Group Number: A01 - 8
; Student Name: Diallo Mountaga (#)
;
; Description:  A high-precision 10-bit Digital-to-Analog Converter (DAC) emulator.
;               Continuously tracks a DC input voltage from POT1 (AN0) and translates
;               the input scale into a high-frequency Pulse Width Modulated (PWM) 
;               square wave to drive an analog motor via a low-pass filter.
;    
; Parameters (Group 8):
;   - Oscillator: 8 MHz
;   - Analog Input: POT1 on AN0 (RA0)
;   - PWM Output: CCP2 on RD2
;**********************************************************************

    #include <p16f917.inc>
 
    __CONFIG _CP_OFF & _CPD_OFF & _BOD_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF
    errorlevel -302

;-------------------------------------------------------------------------------
; RAM VARIABLES
;-------------------------------------------------------------------------------
    CBLOCK 0x20
        DUTY_LSB_HOLD       ; Temporary storage for calculating the lower 2 bits of duty cycle
    ENDC

;-------------------------------------------------------------------------------
; RESET VECTOR
;-------------------------------------------------------------------------------
    ORG     0x00
    GOTO    Setup_Hardware

;-------------------------------------------------------------------------------
; PERIPHERAL INITIALIZATION
;-------------------------------------------------------------------------------
    ORG     0x05
Setup_Hardware
    ; --- 1. Oscillator Configuration (8 MHz) ---
    BANKSEL OSCCON
    MOVLW   0x71            ; IRCF=111 (8 MHz), SCS=1 (Internal Oscillator Block)
    MOVWF   OSCCON

    ; --- Disable unused modules to prevent pin interference ---
    BANKSEL LCDCON
    CLRF    LCDCON          ; Turn off LCD controller to free up pins

    BANKSEL CMCON0
    MOVLW   0x07            ; Turn off Analog Comparators (CRITICAL: RA0 is shared with C1IN+)
    MOVWF   CMCON0

    ; --- 2. I/O & Analog Configuration ---
    ; Group 8 -> Potentiometer Input on AN0 (RA0)
    BANKSEL TRISA
    BSF     TRISA, 0        ; Configure RA0 as an input

    ; PWM Output on CCP2 (RD2)
    BANKSEL TRISD
    BCF     TRISD, 2        ; Configure RD2 as an output

    ; Enable analog function strictly on AN0
    BANKSEL ANSEL
    MOVLW   B'00000001'     ; Set bit 0 to 1 (enables AN0)
    MOVWF   ANSEL

    ; --- 3. PWM Configuration ---
    BANKSEL PR2
    MOVLW   D'255'          ; Set max period (0xFF) to achieve exactly 10-bit resolution
    MOVWF   PR2

    BANKSEL T2CON
    MOVLW   B'00000100'     ; Turn Timer2 ON with a 1:1 Prescaler
    MOVWF   T2CON

    BANKSEL CCP2CON
    MOVLW   B'00001100'     ; Enable PWM mode on CCP2 module
    MOVWF   CCP2CON

    ; --- 4. ADC Configuration ---
    BANKSEL ADCON1
    MOVLW   B'01010000'     ; Set Vref=VSS/VDD, Conversion Clock=Fosc/16, Left Justified
    MOVWF   ADCON1

    BANKSEL ADCON0
    MOVLW   B'00000001'     ; Select Channel 0 (AN0), Turn ADC ON (ADON=1)
    MOVWF   ADCON0

;-------------------------------------------------------------------------------
; MAIN LOOP
;-------------------------------------------------------------------------------
Main_Loop
    ; --- 5. ADC Acquisition ---
    BANKSEL ADCON0
    BSF     ADCON0, GO      ; Trigger the ADC conversion

Wait_For_ADC
    BTFSC   ADCON0, GO      ; Wait here until the GO bit drops back to 0 (conversion complete)
    GOTO    Wait_For_ADC

    ; --- 6. Potentiometer Response Logic ---
    ; Check if ADRESH is perfectly zero to implement a "hard stop". 
    ; This prevents the motor from whining or flickering at very low potentiometer settings.
    BANKSEL ADRESH
    MOVF    ADRESH, W
    BTFSS   STATUS, Z
    GOTO    Apply_Duty_Cycle ; If W is not zero, proceed to update the PWM

    ; Execute Hard Stop: Force duty cycle to absolute zero
    BANKSEL CCPR2L
    CLRF    CCPR2L
    BANKSEL CCP2CON
    MOVLW   B'00001100'     ; Reset CCP2CON to just the basic PWM enable bits
    MOVWF   CCP2CON
    GOTO    Main_Loop       ; Return to the start of the loop

Apply_Duty_Cycle
    ; Transfer the 8 Most Significant Bits (MSB) directly into the PWM holding register
    BANKSEL ADRESH
    MOVF    ADRESH, W
    BANKSEL CCPR2L
    MOVWF   CCPR2L          ; Update the high 8 bits of the Duty Cycle

    ; Extract and transfer the 2 Least Significant Bits (LSB) to CCP2CON<5:4>
    BANKSEL ADRESL
    MOVF    ADRESL, W
    ANDLW   B'11000000'     ; Apply mask to isolate the top 2 bits of ADRESL
    
    BANKSEL DUTY_LSB_HOLD   ; Ensure we are securely in Bank 0 before storing the temp variable
    MOVWF   DUTY_LSB_HOLD

    ; Bitwise shift right twice to align the data into positions 5 and 4
    BCF     STATUS, C       ; Clear carry bit to avoid dragging garbage data
    RRF     DUTY_LSB_HOLD, F
    BCF     STATUS, C
    RRF     DUTY_LSB_HOLD, W ; Final shifted result sits in the Working register (B'00xx0000')
    
    ; Merge the new LSBs without overwriting the crucial PWM Mode bits in CCP2CON
    ANDLW   B'00110000'     ; Safety mask: ensure only bits 5 and 4 contain data
    IORLW   B'00001100'     ; OR the data with the basic PWM mode bits (11xx)
    BANKSEL CCP2CON
    MOVWF   CCP2CON         ; Write the final, perfect 10-bit configuration to the control register

    GOTO    Main_Loop       ; Infinite loop

    END                     ; End of program