/* daniel guimarães - 1910462*/

#include "eventdriven.h"
#include "app.h"
#include "pindefs.h"

#define LED_TIMER 1
#define BUT_TIMER 2
#define BOTH_INTERVAL 500

int state = LOW;
float currentTime = 1000;

// 0 = no button pressed recently
// 1 = button 1 was pressed recently
// 2 = button 2 was pressed recently
int lastPress = 0;      

void appinit() {
  pinMode(LED1, OUTPUT);
  
  button_listen(1);
  button_listen(2);
  timer_set(LED_TIMER, currentTime);
}

void button_changed(int pin, int v) {
  // if another button is pressed, and lastpress has not been reset
  if (lastPress != 0 && lastPress != pin) {
    digitalWrite(LED1, LOW);
    return;
  
  // else, normal logic
  } else if (v == LOW) {
    // divide logic
    if (pin == 1 && currentTime > 250) {
      currentTime /= 2;
    }
    // multiply logic
    else if (pin == 2 && currentTime < 2000) {
      currentTime *= 2;
    }
  }
  // start button timer
  lastPress = pin;
  timer_set(BUT_TIMER, BOTH_INTERVAL);
}

void timer_expired(int t) {
  if (t == LED_TIMER) {
    state = !state;
    digitalWrite(LED1, state);
    timer_set(LED_TIMER, currentTime);
  }

  else if (t == BUT_TIMER) {
    lastPress = 0;  // reset button timer
  }
  
}