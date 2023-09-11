/** Logica do jogo Roda das Cores
 * Por Daniel Guimarães - 1910462 
 * 
 * O jogo tem 4 estados: "jogo", "vitoria", "derrota", "inicio"
 * 
 * No estado "inicio", um dos leds é sorteado para ficar piscando, 
 * esperando o jogador pressionar o botão para começar o jogo.
 * Quando o usuário pressionar o botão, aquele LED foi selecionado, e 
 * a roda começa a girar. Vai para o estado "jogo".
 * 
 * No estado "jogo", a roda gira, esperando o jogador pressionar o botão
 * Se o botão foi pressionado, o jogo checa se está em um led pressionado.
 * Se sim, o jogo vai para o estado de "derrota". Se não, 
 * 
 * 
*/

#include "logica_jogo.h"
#include "controle_led.h"

#define E_JOGO    0b0001
#define E_INICIO  0b0010
#define E_VITORIA 0b0100
#define E_DERROTA 0b1000

#define MAX_DELAY_JOGO 10
#define MIN_DELAY_JOGO 5


char estado = E_INICIO;       // maquina de estado
bool estado_led = false;     // usar para piscar os leds
int led_agora = 0;              // 0 <= led_agora < 12
int led_anterior = 0;           // 0 <= led_anterior < 12
int leds_acertos = 0;           // quantidade de leds ja pressionados
int delay_jogo = 0;

// mantem o valor real dos leds
bool leds[] = {              // estado dos leds
    false, false, false, false,
    false, false, false, false,
    false, false, false, false 
};


void mudar_estado(char novo_estado) {
    if (novo_estado == E_VITORIA) {
        // por enquanto nada
    }

    else if (novo_estado == E_DERROTA) {
        // apaga todos os leds, exceto o que errou
        for (int i = 0; i < 12; i++) { 
            set_led(i, (i == led_agora));
            leds[i] = (i == led_agora); 
        }
    }

    else if (novo_estado == E_INICIO) {
        // escolhe um novo led inicial
        // apaga todos os leds, exceto o do inicio
        leds_acertos = 1;   // reinicia tudo pro inicio
        led_agora = random(0, 12);
        led_anterior = (led_agora - 1) % 12;
        for (int i = 0; i < 12; i++) { 
            set_led(i, (i == led_agora));
            leds[i] = (i == led_agora); 
        }
    }

    estado = novo_estado;
}

void loop_jogo() {
    // delay()
    if (delay_jogo > 0) {
      delay_jogo--;
      return;
    }

    if (estado == E_VITORIA) {
        // acende todos os leds
        set_todos_leds(estado_led);
        estado_led = !estado_led;
        delay_jogo = MAX_DELAY_JOGO;    // grande delay
    }
    else if ((estado == E_DERROTA ) || (estado == E_INICIO)) {
        // pisca so o led que está o led_agora
        set_led(led_agora, estado_led);
        estado_led = !estado_led;
        delay_jogo = MAX_DELAY_JOGO;    // grande delay
    }
    else if (estado == E_JOGO) {
        // muda o led atual, e corrige o led anterior
        led_anterior = led_agora;
        led_agora = (led_agora + 1) % 12;
        set_led(led_agora, !leds[led_agora]);
        set_led(led_anterior, leds[led_anterior]);
        delay_jogo = MIN_DELAY_JOGO;    // delay padrão
    }
}

void botao_pressionado() {
    if (estado == E_JOGO) {
        if (leds[led_agora]) {  // errou
            mudar_estado(E_DERROTA);
        }
        else {  // acertou
            leds[led_agora] = true;
            leds_acertos++;
            if (leds_acertos == 12) { mudar_estado(E_VITORIA); }
        }
    }
    else if (estado == E_INICIO) {
      mudar_estado(E_JOGO);
    }
    else {
        mudar_estado(E_INICIO);
    }
}