# include "controle_led.h"
# include "logica_interrupcao.h"
# include "logica_jogo.h"

// contador para separar a varredura do loop do jogo
volatile int q = 0;

// separarando a varredura do jogo 
void interrupcao_loop_timer() { 
    faz_varredura();
    q++;
    if (q == 4) { 
        loop_jogo();
        q = 0;
    }
}

void interrupcao_botao_pressionado() {
    // set_todos_leds(false);
    // set_led(1, true);
    botao_pressionado(); 
    // Serial.println("a");
}


// setup dos componentes
void setup() {
    setup_leds();
    setup_interrupcao();
    Serial.begin(9600);
}

// loop principal
void loop() {
    // enter_sleep();
}
