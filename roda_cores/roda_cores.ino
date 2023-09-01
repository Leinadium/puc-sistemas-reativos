# include "controle_led.h"

void setup() {
    config_leds();
}

void loop() {
    for (int i = 0; i < 12; i ++ ) {
        muda_led(i, true);
        
        faz_varredura(0);
        delay(5);
        faz_varredura(1);
        delay(5);
        faz_varredura(2);
        delay(5);
        // muda_led(i, false);
    }
}

void pciSetup(byte pin) {
    *digitalPinToPCMSK(pin) |= bit (digitalPinToPCMSKbit(pin));  // enable pin
    PCIFR  |= bit (digitalPinToPCICRbit(pin)); // clear any outstanding interrupt
    PCICR  |= bit (digitalPinToPCICRbit(pin)); // enable interrupt for the group
}