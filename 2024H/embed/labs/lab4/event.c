/*
 * File:   main.c
 * Author: morten
 *
 * Created on November 1, 2024, 1:07 PM
 */


#include <xc.h>
#include <avr/io.h>
#include <avr/sleep.h>

int main(void) {
    // Run off of the 32kHz clock instead of 4MHz
    //FUSE.OSCCFG = 0x1;
    
    // Disable and connect unused ports to internal pull-up resistor to reduce leakage power
    PORTB.PINCONFIG = PORT_ISC_INPUT_DISABLE_gc | PORT_PULLUPEN_bm;
    PORTB.PINCTRLUPD = 0xFF;
    PORTC.PINCONFIG = PORT_ISC_INPUT_DISABLE_gc | PORT_PULLUPEN_bm;
    PORTC.PINCTRLUPD = 0xFF;
    PORTD.PINCONFIG = PORT_ISC_INPUT_DISABLE_gc | PORT_PULLUPEN_bm;
    PORTD.PINCTRLUPD = 0xFF;
    PORTE.PINCONFIG = PORT_ISC_INPUT_DISABLE_gc | PORT_PULLUPEN_bm;
    PORTE.PINCTRLUPD = 0xFF;
    PORTF.PINCONFIG = PORT_ISC_INPUT_DISABLE_gc | PORT_PULLUPEN_bm;
    PORTF.PINCTRLUPD = 0xFF;
    
    PORTA.PINCONFIG = PORT_ISC_INPUT_DISABLE_gc | PORT_PULLUPEN_bm;
    
    // Configure Vref
    VREF.ACREF = VREF_REFSEL_1V024_gc;
    
    // Configure AC input signals
    PORTD.DIRCLR = PIN2_bm;
    PORTD.PIN2CTRL = PORT_ISC_INPUT_DISABLE_gc;
    AC0.MUXCTRL = AC_MUXPOS_AINP0_gc | AC_MUXNEG_DACREF_gc;
    
    // Configure AC
    AC0.CTRLA   = AC_RUNSTDBY_bm | AC_POWER_PROFILE2_gc | AC_ENABLE_bm; // Last one to invert the output signal
    
    // Set Vdacref voltage to 0.1V
    AC0.DACREF  = 25;    
    
    // Configure Event System
    EVSYS.CHANNEL1 = EVSYS_CHANNEL1_AC0_OUT_gc;
    EVSYS.USEREVSYSEVOUTA = EVSYS_USER_CHANNEL1_gc;
    PORTA.DIRCLR = ~(PIN2_bm);
    
    // Go to sleep
    set_sleep_mode(SLEEP_MODE_STANDBY);
    sleep_mode();
    
    return 0;
}

