/* daniel guimarães - 1910462*/

#include "app.h"
#include "eventdriven.h"
#include "pindefs.h"

#define LOOP_DELAY 500
#define LED_MOSTRAR_DELAY 500
#define LEN_RESPOSTA 5

const int LEN_TIMER = 3;
const int LEN_BUTTON = 3;
int BUTTONS[] = {KEY1, KEY2, KEY3};

// 0 --> undefined
// N  -> vai expirar no millis() >= N
unsigned int timer_list[LEN_TIMER] = {0, 0, 0};

bool button_enable[LEN_BUTTON] = {false, false, false};
bool button_states[LEN_BUTTON] = {false, false, false};

unsigned long now;
unsigned long last;

void button_listen(int pin) {
  int i = pin - 1;
  if (!button_enable[i]) {
    button_enable[i] = true;
    button_states[i] = digitalRead(BUTTONS[i]);
  }
}

void timer_set(int t, int ms) {
  if (timer_list[t] == 0) {
    timer_list[t] = millis() + ms;
  }
}

void atualiza_botoes() {
  // mesma funcao do exercicio 2 da semana passada
  if (now - last >= LOOP_DELAY) {
    for (int i = 0; i < LEN_BUTTON; i++) {
      int temp = digitalRead(BUTTONS[i]);
      if (temp != button_states[i]) {
        button_states[i] = temp;
        last = now;
        if (button_enable[i]) {
          button_changed(i + 1, temp);
        }    
      }
    }
  }
}

void atualiza_timers() {
  for (int i = 0; i < LEN_TIMER; i++) {
    if (timer_list[i] > 0 && now >= timer_list[i]) {
      timer_list[i] = 0;
      timer_expired(i);
    }
  }
}

void setup() {
  // as listas ja foram configuradas...
  pinMode(KEY1, INPUT_PULLUP);
  pinMode(KEY2, INPUT_PULLUP);
  pinMode(KEY3, INPUT_PULLUP);

  appinit();
}

void loop() {
  now = millis();
  atualiza_botoes();
  atualiza_timers();

}