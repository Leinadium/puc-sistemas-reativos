/* daniel guimarães - 1910462*/

#include "eventdriven.h"
#include "app.h"
#include "pindefs.h"

int state = LOW;

void appinit() {
  pinMode(LED1, OUTPUT);
  
  button_listen(1);
  timer_set(1, 1000);
}

void button_changed(int pin, int v) {
  digitalWrite(LED1, LOW);
  exit(1);
}

void timer_expired(int t) {
  state = !state;
  digitalWrite(LED1, state);
  timer_set(1, 1000);
}