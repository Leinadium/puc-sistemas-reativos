/**
 * Observação: a ideia original era evitar ter o vetor estados `bool estados[]`,
 * e ao inves disso utilizar somente um inteiro `int v_leds` para armazenar 
 * todo o estado dos leds.
 * Porém, a operação final para salvar nas portas estava dando muitos problemas,
 * por isso, afim de funcionar, foi utilizada a abordagem com o vetor de estados e com os
 * 7 digitalWrites para uma varredura (ao inves de 3 digitalsWrites e um write nas 4 outras portas direto...)
 * 
 * Depois, estudar melhor o funcionamento do PORTB
 * 
 * O funcionamento original utilizando o int está no meu github, salvo.
*/

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
volatile int v_leds = 0x00;
bool estados[] = {false, false, false, false, false, false, false, false, false, false, false, false};

int i_varredura = 0;

void setup_leds() {
    int i;
    for (i = 0; i < 4; pinMode(ENTS[i++], OUTPUT)) { }
    for (i = 0; i < 3; pinMode(SAIS[i++], OUTPUT)) { }
    set_todos_leds(false);
}

void set_led(int led, bool modo) {
    estados[led] = modo;
}

void set_todos_leds(bool modo) {
    for (int i=0; i < 12; i++) {estados[i] = modo;}
}

/** Faz a proxima etapa da varredura.*/
void faz_varredura() {
    // configura os outs
    digitalWrite(SAIS[0], !(i_varredura == 0));
    digitalWrite(SAIS[1], !(i_varredura == 1));
    digitalWrite(SAIS[2], !(i_varredura == 2));

    // configura os ins
    digitalWrite(ENTS[0], estados[i_varredura]);
    digitalWrite(ENTS[1], estados[i_varredura + 3]);
    digitalWrite(ENTS[2], estados[i_varredura + 6]);
    digitalWrite(ENTS[3], estados[i_varredura + 9]);

    // PORTB = B1000 & (v_leds >> (4 * i_varredura));

    // configura para a proxima varredura
    i_varredura = (i_varredura + 1) % 3;
}