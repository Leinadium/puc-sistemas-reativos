#include "logica_interrupcao.h"

#include <avr/interrupt.h>
#include <avr/io.h>

#define BOTAO A1
#define MIN_LOOPS 10

// para botao
volatile bool botao_estado = true;
volatile int q_pode_mudar = 0;     // tem que esperar MIN_LOOP para mudar

// para timer
volatile int loop_delay = 1;
volatile int loop_q = 0;


void set_timer_loop(int q) {
    loop_delay = q;
}

/** roda a configuração das interrupções */
void setup_interrupcao() {
    // configura o timer (???) documentação do adriano confusa
    // TIMSK2 = (TIMSK2 & B11111110) | 0x01;
    // TCCR2B = (TCCR2B & B11111000) | 0x07;

    // alguma documentação: http://www.gammon.com.au/interrupts (não ajudou muito)

    // https://forum.arduino.cc/t/arduino-timer-interrupt/37971/8   (a que melhor ajudou)
    TCCR2A = 0;                     // set entire TCCR2A register to 0
    TCCR2B = 1 << CS22 | 1 << CS21;
    TIMSK2 = 1 << TOIE2;              // Timer2 Overflow Interrupt Enable
    TCNT2 = 0;                      // reset timer


    // configura o botao (?) documentação do adriano confusa
    pinMode(BOTAO, INPUT_PULLUP);
    // *digitalPinToPCMSK(BOTAO) |= bit (digitalPinToPCMSKbit(BOTAO));  // enable pin
    // PCIFR  |= bit (digitalPinToPCICRbit(BOTAO)); // clear any outstanding interrupt
    // PCICR  |= bit (digitalPinToPCICRbit(BOTAO)); // enable interrupt for the group

    // https://www.electrosoftcloud.com/en/pcint-interrupts-on-arduino/ (a que melhor ajudou)
    PCICR  |= B00000010;         // We activate the interrupts of the PC port
    PCMSK1 |= B00000010;        // ativando a porta A1

}

// handle pin change interrupt for A0 to A5 here
ISR (PCINT1_vect) {
    // se nao pode mudar, ignora
    if (q_pode_mudar > 0) return;

    q_pode_mudar = MIN_LOOPS;
    botao_estado = !botao_estado;
    if (botao_estado) {
        interrupcao_botao_pressionado();
    }
}

// handle timer interrupt
ISR (TIMER2_OVF_vect) {
    // atualiza a variavel
    if (q_pode_mudar > 0) q_pode_mudar--;
    
    // executa o loop
    loop_q++;
    if (loop_q >= loop_delay) {
        loop_q = 0;
        interrupcao_loop_timer();
    }
}


