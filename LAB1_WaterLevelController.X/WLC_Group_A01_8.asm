;************************************************************************************
;   Filename:      WLC_Group_A01_8.asm                                          
;   Date:          January 25,2008                                          
;   File Version:  1.00                                                                  
;                                                                      
;************************************************************************************
;    Student: Diallo Mountaga                                                                 
;    Files required:                                                  
;          WLC_Group_A01_8.inc                                                           
;************************************************************************************
;                                                                     
;    Description:  A Finite State Machine Water Level Controller designed for the 
;               PIC16F917 microcontroller mounted on a Mechatronics board. It manages
;               tank levels via water thresholds (LOW and HIGH) with integrated 
;               anti-ghosting/hardware switch debouncing loops
;************************************************************************************
	#include	<WLC_Group_A01_8.inc> 			; this file includes variable definitions and pin assignments	

;************************************************************************************
  org 0x00
	goto	Initialize

  org 0x05

;************************************************************************************
; Initialize - Initialize comparators, internal oscillator, I/O pins, 
;	analog pins, variables	
;
;************************************************************************************
Initialize
    ; 1. Set Clock Speed (Bank 1)
    banksel OSCCON
    movlw   b'01110000'     ; Set to 8MHz
    movwf   OSCCON

    ; 2. Disable Comparators (Bank 0)
    banksel CMCON0
    movlw   0x07            ; 0x07 turns off comparators to allow digital I/O
    movwf   CMCON0

    ; 3. Disable Analog (Bank 3)
    banksel ANSEL       ;banksel is vital here because ANSEL is in Bank 3!
    clrf    ANSEL       

    ; 4. Configure I/O Direction (Bank 1)
    banksel TRISA
    movlw   b'00001100'     ; RA2 and RA3 as inputs (1)
    movwf   TRISA
    
    banksel TRISD
    clrf    TRISD           ; Set Port D as outputs (0) for LEDs

    ; 5. Configure Timer0 (Bank 1)
    banksel OPTION_REG
    movlw   b'10000110'     ; Pull-ups disabled, TMR0 Prescaler 1:128
    movwf   OPTION_REG

    ; 6. Final Reset and Enter Main (Bank 0)
    banksel PORTA
    clrf    PORTA
    clrf    PORTD
    goto    Main

;************************************************************************************
; Main Control Loop
;************************************************************************************
Main
    bcf     STATUS, RP0     ; Ensure we are in Bank 0
    
    ; --- Step 1: Pump Logic (Hysteresis) ---
    ; If Sensor High (LED2) is ON (1), turn Pump (LED7) OFF
    btfsc   LED2            ; Is LED2 high?
    bcf     LED7            ; Yes, Tank is Full -> Pump OFF
    
    ; If Sensor Low (LED1) is OFF (0), turn Pump (LED7) ON
    btfss   LED1            ; Is LED1 low?
    bsf     LED7            ; Yes, Tank is Empty -> Pump ON

    ; --- Step 2: Poll Switches ---
    btfss   SW2             ; Is SW2 pressed (0)?
    goto    SENSOR_LOW      ; Yes, go update LED1
    
    btfss   SW3             ; Is SW3 pressed (0)?
    goto    SENSOR_HIGH     ; Yes, go update LED2
    
    goto    Main            ; No buttons pressed? Loop back to start

SENSOR_LOW
    movlw   b'00100000'     ; Mask for LED1 (RD5)
    xorwf   PORTD, F        ; Toggle LED1
    goto    DebounceStateSW2 ; Wait for release, then goto Main

SENSOR_HIGH
    movlw   b'01000000'     ; Mask for LED2 (RD6)
    xorwf   PORTD, F        ; Toggle LED2
    goto    DebounceStateSW3 ; Wait for release, then goto Main


;************************************************************************************
; Debounce Routines
;************************************************************************************
DebounceStateSW2				; Wait here until SW2 is released
	btfss	SW2
	goto	DebounceStateSW2
	clrf	TMR0			; Once released clear TMR0 and the TMR0 interrupt flag
	bcf	INTCON,T0IF		;  in preparation to time 16ms

DebounceState2SW2				; State2 makes sure than SW2 is unpressed for 16ms before
	btfss	SW2					;  returning to look for the next time SW2 is pressed
	goto	DebounceStateSW2	; If SW2 is pressed again in this state then return to State1
	btfss	INTCON,T0IF 		; Else, continue to count down 16ms
	goto	DebounceState2SW2	; Time = TMR0_max * TMR0 prescaler * (1/(Fosc/4)) = 256*128*0.5E-6 = 16.4ms
	goto	Main

DebounceStateSW3				; Wait here until SW2 is released
	btfss	SW3
	goto	DebounceStateSW3
	clrf	TMR0			; Once released clear TMR0 and the TMR0 interrupt flag
	bcf	INTCON,T0IF		;  in preparation to time 16ms

DebounceState2SW3					; State2 makes sure than SW2 is unpressed for 16ms before
	btfss	SW3					;  returning to look for the next time SW2 is pressed
	goto	DebounceStateSW3	; If SW2 is pressed again in this state then return to State1
	btfss	INTCON,T0IF 		; Else, continue to count down 16ms
	goto	DebounceState2SW3		; Time = TMR0_max * TMR0 prescaler * (1/(Fosc/4)) = 256*128*0.5E-6 = 16.4ms
	goto	Main

	END						; directive 'end of program'
