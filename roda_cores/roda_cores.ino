/** Roda das cores - Daniel Guimarães - 1910462 */

# include "controle_led.h"
# include "logica_interrupcao.h"
# include "logica_jogo.h"

// contador para separar a varredura do loop do jogo
volatile int q = 0;

// separarando a varredura do jogo 
void interrupcao_loop_timer() { 
    faz_varredura();
    q++;
    if (q == 4) {       // isso define a velocidade do jogo basicamente
        loop_jogo();
        q = 0;
    }
}

void interrupcao_botao_pressionado() {
    botao_pressionado(); 
}


// setup dos componentes
void setup() {
    setup_leds();
    setup_interrupcao();
}

// loop principal
void loop() {
    // enter_sleep();
}
