#include "controle_led.h"

#define ENT1 11
#define ENT2 10
#define ENT3  9
#define ENT4  8
#define SAI1  7
#define SAI2  6
#define SAI3  5


int ENTS[] = {ENT1, ENT2, ENT3, ENT4};
int SAIS[] = {SAI1, SAI2, SAI3};

// estado = [00, 03, 06, 09, 01, 04, 07, 10, 02, 05, 08, 11, --, --, --, --]
int state = 0x00;

int i_varredura = 0;

void setup_leds() {
    int i;
    for (i = 0; i < 4; pinMode(ENTS[i++], OUTPUT)) { }
    for (i = 0; i < 3; pinMode(SAIS[i++], OUTPUT)) { }
    set_todos_leds(false);
}

void set_led(int led, bool modo) {
    state &= (modo ? 0b1 : 0b0) << (led / 4  + (led % 4) * 4);
}

void set_todos_leds(bool modo) {
    state = modo ? 0xffff : 0x0000;
}

/** Faz a proxima etapa da varredura.*/
void faz_varredura() {
    // configura os outs
    digitalWrite(SAIS[0], !(i_varredura == 0));
    digitalWrite(SAIS[1], !(i_varredura == 1));
    digitalWrite(SAIS[2], !(i_varredura == 2));

    // configura os ins
    PORTB = 0x00f | (state >> (4 * i_varredura));

    // configura para a proxima varredura
    i_varredura = (i_varredura + 1) % 3;
}