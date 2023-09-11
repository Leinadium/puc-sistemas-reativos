#define LED1       10
#define LED2       11
#define LED3       12
#define LED4       13
#define BUZZ        3
#define KEY1       A1
#define KEY2       A2
#define KEY3       A3
#define POT        A0

#define LOOP_DELAY 500

int state = 1;
unsigned long now;
unsigned long last1;
unsigned long last2;
unsigned long lastLed;
float ledInterval = 500;
bool isBlinking = true;

void setup() {
  pinMode(LED1, OUTPUT);
  pinMode(KEY1, INPUT_PULLUP);
  pinMode(KEY2, INPUT_PULLUP);
  pinMode(KEY3, INPUT_PULLUP);

  last1 = millis();
  last2 = millis();
  lastLed = millis();

}

void loop() {
  now = millis();

  bool state1 = false;
  bool state2 = false;
  
  if ((now - last1) >= LOOP_DELAY) {
    // se apertou o botao1, diminui
    state1 = digitalRead(KEY1);
    if (state1 == LOW) {
      ledInterval = ledInterval > 100 ? ledInterval / 2 : 100;
      last1 = now;
    }
  }
  if ((now - last2) >= LOOP_DELAY) {
    state2 = digitalRead(KEY2);
    if (state2 == LOW) {
      ledInterval = ledInterval < 2000 ? ledInterval * 2 : 2000;
      last2 = now;
    }


    if (state1 == LOW && state2 == LOW) {
      isBlinking = !isBlinking;
    }
  }


  if ((now - lastLed) >= ledInterval && isBlinking) {
    lastLed = now;
    state = !state;
    digitalWrite(LED1, state);
  }
}
