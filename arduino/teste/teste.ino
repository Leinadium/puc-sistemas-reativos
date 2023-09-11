#include <avr/interrupt.h>
#include <avr/io.h>

void setup() {
    // configura o timer (???)
    // TIMSK2 = (TIMSK2 & B11111110) | 0x01;
    // TCCR2B = (TCCR2B & B11111000) | 0x07;

    // alguma documentação: http://www.gammon.com.au/interrupts

    // https://forum.arduino.cc/t/arduino-timer-interrupt/37971/8
    TCCR2A = 0;                     // set entire TCCR2A register to 0
    TCCR2B = 1 << CS22 | 1 << CS21;
    TIMSK2 = 1<<TOIE2;              // Timer2 Overflow Interrupt Enable
    TCNT2 = 0;                      // reset timer


    // configura o botao (?)
    pinMode(A1, INPUT_PULLUP);
    // *digitalPinToPCMSK(BOTAO) |= bit (digitalPinToPCMSKbit(BOTAO));  // enable pin
    // PCIFR  |= bit (digitalPinToPCICRbit(BOTAO)); // clear any outstanding interrupt
    // PCICR  |= bit (digitalPinToPCICRbit(BOTAO)); // enable interrupt for the group

    // https://www.electrosoftcloud.com/en/pcint-interrupts-on-arduino/
    PCICR |= B00000010;         // We activate the interrupts of the PC port
    PCMSK1 |= B00000010;        // ativando a porta A1

    pinMode(8, OUTPUT);
    pinMode(11, OUTPUT);
    
    pinMode(7, OUTPUT);
    pinMode(6, OUTPUT);
    pinMode(5, OUTPUT);

    digitalWrite(7, LOW);
    digitalWrite(6, LOW);
    digitalWrite(5, LOW);

}

volatile bool s = false;
volatile bool ss = false;
volatile int q = 0;

ISR (PCINT1_vect) {
    s = !s;
    digitalWrite(8, s);
}

ISR (TIMER2_OVF_vect) {
    if (q >= 50) {
        ss = !ss;
        digitalWrite(11, ss);
        q = 0;
    } else {
        q++;
    }
}


void loop() {

}