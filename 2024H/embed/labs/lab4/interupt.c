/*
 * File:   main.c
 * Author: morten
 *
 * Created on November 1, 2024, 1:07 PM
 */

#include <xc.h>
#include <avr/io.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

#define F_CPU 4000000
#include <util/delay.h>

#include <avr/sleep.h>
#include <avr/interrupt.h>

void AC_Init() {
    PORTD.DIRCLR = PIN2_bm;
    PORTD.PIN2CTRL = PORT_ISC_INPUT_DISABLE_gc;
    
    AC0.MUXCTRL = AC_MUXPOS_AINP0_gc | AC_MUXNEG_DACREF_gc;
    AC0.CTRLA = AC_RUNSTDBY_bm | AC_POWER_PROFILE2_gc | AC_ENABLE_bm;   // AC_POWER_PROFILE2_gc
    AC0.INTCTRL = AC_INTMODE_NORMAL_BOTHEDGE_gc | AC_CMP_bm;
    
    AC0.DACREF = 25;    // 0.1V / 1.024V * 256
}

void VREF_Init() {
    VREF.ACREF = VREF_REFSEL_1V024_gc;
}

void LED_Init() {
    PORTA.DIRSET = PIN2_bm;
}

void set_LED_on() {
    PORTA.OUTCLR = PIN2_bm;
}

void set_LED_off() {
    PORTA.OUTSET = PIN2_bm;
}

void sleep_init(void) {
    set_sleep_mode(SLEEP_MODE_STANDBY);
}

ISR(AC0_AC_vect) {
    if (AC0.STATUS & AC_CMPSTATE_bm) {
        set_LED_off();
    } else {
        set_LED_on();
    }
    
    // Clear interrupt flat
    AC0.STATUS = AC_CMPIF_bm;
}

int main(void) {
    VREF_Init();
    AC_Init();
    LED_Init();
    
    PORTB.PIN0CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTB.PIN1CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTB.PIN2CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTB.PIN3CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    
    PORTC.PIN0CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTC.PIN1CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTC.PIN2CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTC.PIN3CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    
    PORTD.PIN0CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTD.PIN1CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTD.PIN2CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTD.PIN3CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    
    PORTE.PIN0CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTE.PIN1CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTE.PIN2CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    PORTE.PIN3CTRL = PORT_PULLUPEN_bm | PORT_ISC_INPUT_DISABLE_gc;
    
    sei();
    sleep_init();
    
    while (true) {
        sleep_mode();
    }
    
    return 0;
}
