;----------------------EE322 EMBEDDED SYSTEMS DESIGN----------------------------
;PROJECT NAME: AUTOMATED COOLING SYSTEM
;GROUP: 07
;HARSHANA L.R.	    E/17/107
;HERATH H.M.K.L.    E/17/114
;MADUSHAN H.M.P.S   E/17/199
;-------------------------------------------------------------------------------
list p=16F877A
#include "p16f877a.inc"

org 0x00		;reset vector
;define variables
count1 equ 20h
count2 equ 21h
digit1 equ 23h
digit2 equ 24h
temp equ 25h
const1 equ 26h
const2 equ 27h
ref1 equ 28h
ref2 equ 29h
ref3 equ 30h
ref4 equ 31h 

;define lcd pins
#define lcdData PORTB
#define lcdRs PORTD,0
#define lcdRw PORTD,2 
#define lcdE PORTD,1

;lcd port initialization
bcf STATUS,6		;switch to bank2
bsf STATUS,5		;switch to bank1
clrf TRISB		;configure PORTB as output
clrf TRISD		;configure PORTD as output
bcf STATUS,5		;switch to bank0
clrf PORTB		;lcdData = '0000 0000' 
clrf PORTD		;lcdRs=0, lcdRw=0, lcdE=0
 
;adc port initialization
bsf STATUS,5		;switch to bank1
movlw 0x01		
movwf TRISA		;AN0 set as analog input
movlw 0x8E
movwf ADCON1		;bit7=1, right justify the ADC result
			;bit3->0=1110, ADC port configuration
bcf STATUS,5		;switch to bank0
movlw 0xC1		
movwf ADCON0		;bit7,6=11, ADC clock select
			;bit0=1, ADON-ADC is operating

;pwm port initialization
bsf STATUS,5		;switch to bank1
movlw 0x02		
movwf TRISA		;portA pin2 for sensA
clrf TRISC		;configure PORTC as output
bcf STATUS,5		;switch to bank0
clrf PORTC		
bcf PORTC,1		;in2=0  
bsf PORTC,0		;in1=1
clrf CCP1CON		;CCP module is off
clrf TMR2		;clear TMR2
movlw b'11111001'	;move 249 to Wreg
bsf STATUS,5		;switch to bank1 
movwf PR2		;pwm period=249x4
bcf STATUS,5		;switch to bank0
bsf T2CON,0		;timer2 prescalor=4
 
call init		;initialize the lcd
call line1		;set cursor to DDRAM address 0x80
;display "TEMPERATURE:"			
movlw 0x54
call print
movlw 0x45
call print
movlw 0x4D
call print
movlw 0x50
call print
movlw 0x45
call print
movlw 0x52
call print
movlw 0x41
call print
movlw 0x54
call print
movlw 0x55
call print
movlw 0x52
call print
movlw 0x45
call print
movlw 0x3A
call print
 
main
    call line1pt1	    ;set cursor to DDRAM address 0x8C
    bsf ADCON0,2	    ;start ADC
    adcloop 
	btfsc ADCON0,2	    ;bit2 gets cleared when ADC is not in progress
	goto adcloop	    ;skip if ADCON0,2=0
    bsf STATUS,5    	    ;switch to bank1
    movf ADRESL,0	    ;lower 8 bits of the ADC result moved to Wreg
    bcf STATUS,5	    ;switch to bank0
    bcf STATUS,0	    ;carry out bit is cleared
    movwf temp		    ;move ADRESL value to temp
    rrf temp,1		    ;rotate right temp through carry      
    movf temp,0		    ;move temp value to Wreg
    movwf const2	    ;move Wreg value to const2
    clrf const1		    ;clear const1
    ;get tens from the 8bit value
    gettens
	movlw 0x0A
	incf const1,1	    ;const1=cons1+1
	subwf const2,1	    ;const2=const2-Wreg
	btfsc STATUS,0
	goto gettens
    decf const1,0	    ;Wreg=const1-1
    movwf digit2	    ;move Wreg value to digit2
    movf temp,0		    ;move temp value to Wreg
    movwf const1	    ;move Wreg value to const1
    movlw 0x0A
    ;get ones from the 8bit value
    getones
	subwf const1,1	    ;const1=const1-Wreg
	btfsc STATUS,0
	goto getones
    addwf const1,0	    ;Wreg=const+Wreg
    movwf digit1	    ;move Wreg value to digit1
    movlw b'00110000'	    
    addwf digit2,0	    ;take the equivalent CGRAM value for digit2
    call print		    ;print digit2
    movlw b'00110000'
    addwf digit1,0	    ;take the equivalent CGRAM value for digit1
    call print		    ;print digit1
    call units		    ;print "'C"
    call comparison	    ;goto comparison subroutine
    goto main

;initialize the lcd    
init 
    ;clear display
    movlw 0x01
    movwf lcdData
    call enable		    ;enable the command
    call delayms 
 
    ;function set
    clrf PORTD
    movlw 0x38		    ;8 bit, 2 line, 5x7 dot
    movwf lcdData
    call enable

    ;display on/off control
    movlw 0x0C 
    movwf lcdData
    call enable
 
    ;entry mode set
    movlw 0x06
    movwf lcdData
    call enable
    return

;display "'C"
units
    movlw 0xDF
    call print
    movlw 0x43
    call print
    return

;print subroutine
print
    movwf lcdData		;move Wreg values to PORTB
    call enable			
    return

;cursor set at DDRAM address 0x80   
line1
    bcf lcdRs
    movlw 0x80
    movwf lcdData
    call enable
    call delayms
    bsf lcdRs
    return

;cursor set at DDRAM address 0x8C    
line1pt1
    bcf lcdRs
    movlw 0x8C
    movwf lcdData
    call enable
    call delayms
    bsf lcdRs
    return    

;cursor set at DDRAM address 0xC0
;enables the access to second row
line2
    bcf lcdRs
    movlw 0xc0
    movwf lcdData
    call enable
    call delayms
    bsf lcdRs
    return

;compare the temp value with reference
comparison
    movlw d'25'
    movwf ref1
    movlw d'30'
    movwf ref2
    movlw d'35'
    movwf ref3
    movlw d'40'
    movwf ref4
    comparison1			;for temp<=25'C
	movf ref1,0
	subwf temp,0
	btfss STATUS,0		;if temp<25'C call dutycycle0
	call dutycycle0
	btfsc STATUS,2		;if temp=25'C call dutycycle25
	call dutycycle25
	btfss STATUS,0		
	return
    comparison2			;for 25'C<temp<=30'C
	movf ref2,0
	subwf temp,0
	btfss STATUS,0		;if 25'C<temp<30'C call dutycycle25
	call dutycycle25
	btfsc STATUS,2		;if temp=30'C call dutycycle50
	call dutycycle50
	btfss STATUS,0
	return
    comparison3			;for 30'C<temp<=35'C
	movf ref3,0
	subwf temp,0
	btfss STATUS,0		;if 30'C<temp<35'C call dutycycle50
	call dutycycle50	
	btfsc STATUS,2		;if temp=35'C call dutycycle75
	call dutycycle75	
	btfss STATUS,0
	return
    comparison4			;for 35'C<=temp<=40'C
	movf ref4,0
	subwf temp,0
	btfss STATUS,0		;if 35<temp<=40'C call dutycycle75
	call dutycycle75
	btfsc STATUS,2
	call dutycycle100	;else call dutycycle100
	btfss STATUS,0
	return
    comparison5			;for 40'C<temp
	movf ref4,0
	subwf temp,0
	btfsc STATUS,0		
	call dutycycle100	;if them>40'C call dutycycle100
	return

;1us delay	
delayus
    decfsz count1,1
    goto delayus
    return

;1ms delay    
delayms
    decfsz count1,1
    goto delayms
    decfsz count2,1
    goto delayms
    return

;lcd enable command    
enable
    bsf lcdE
    call delayus
    bcf lcdE
    call delayus
    return

;pwm at 25% duty cycle
;560 rpm
dutycycle25
    movlw b'00111110'
    movwf CCPR1L		;duty cycle=0011 1110 01	    
    movlw b'00011100'
    movwf CCP1CON		;pwm enabled
    bsf T2CON,2			;TMR2 starts to increase
    return

;pwm at 50% duty cycle
;1080 rpm
dutycycle50
    movlw b'01111100'
    movwf CCPR1L		;duty cycle=0111 1100 10 
    movlw b'00101100'
    movwf CCP1CON		;pwm enabled
    bsf T2CON,2			;TMR2 starts to increase
    return

;pwm at 75% duty cycle  
;1520 rpm
dutycycle75
    movlw b'10111010'
    movwf CCPR1L		;duty cycle=1011 1010 11
    movlw b'00111100'
    movwf CCP1CON		;pwm enabled
    bsf T2CON,2			;TMR2 starts to increase
    return

;pwm at 100% duty cycle
;1940 rpm
dutycycle100
    movlw b'11111001'		
    movwf CCPR1L		;duty cycle=1111 1001 00
    movlw b'00001100'
    movwf CCP1CON		;pwm enabled
    bsf T2CON,2			;TMR2 starts to increase
    return

;pwm at 0% duty cycle 
;0 rpm
dutycycle0
    movlw b'00000000'
    movwf CCPR1L		;duty cycle=0000 0000 00
    movlw b'00001100'
    movwf CCP1CON		;pwm enabled
    bsf T2CON,2			;TMR2 starts to increase
    return
    
end






