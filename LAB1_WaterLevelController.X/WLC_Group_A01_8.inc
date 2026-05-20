#include <p16f917.inc>

	__CONFIG    _CP_OFF & _CPD_OFF & _BOD_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _FCMEN_OFF & _IESO_OFF

	errorlevel -302		; supress "register not in bank0, check page bits" message

; Pin Declarations
#define SW2     PORTA, 2    ; SensorLOW (RA2)
#define SW3     PORTA, 3    ; SensorHIGH (RA3)
#define LED1    PORTD, 5    ; Reflects SensorLOW status (D5)
#define LED2    PORTD, 6    ; Reflects SensorHIGH status (D6)
#define LED7    PORTD, 7    ; Pump Status (D7)
	
;--- Student Complete Section above
; Variable Declarations
	cblock	0x20
		Temp
	endc









