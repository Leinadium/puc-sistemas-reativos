/**
Escrever um programa que inicialmente mostre uma sequencia aleatoria
de 5 piscadas dos leds 1, 2 ou 3 e em seguida espere o usuario repetir
a sequencia usando as chaves 1, 2 e 3. Caso o usuario erre, o programa
deve acender o led 1 e deixa-lo aceso. Caso o usuario acerte a sequencia,
o programa deve acender todos os leds e deixa-los acesos. Em qualquer
caso, se o usuario paertar a chave 1 o programa deve voltar ao estado inicial
*/

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
#define LED_MOSTRAR_DELAY 1000
#define LEN_RESPOSTA 5

int LEDS[] = {LED1, LED2, LED3};

int state = 0;    // 0 eh mostrar, 1 eh receber, 2 é sucesso, 3 é erro
unsigned long now;
unsigned long last;

int respostaCorreta[] = {1, 2, 3, 1, 3};

// globais para estado MOSTRAR
int mostrarAtual;
unsigned long lastMostrar;
bool stateMostrar;

// globais para estado RECEBER
int receberAtual;


/** verifica os botoes. Devolve 0 se nada foi pressionado. Devole 1-3 caso seja pressionado */
int recebeBotao() {
  if (now - last >= LOOP_DELAY) {
    if (digitalRead(KEY1) == LOW) {
      last = now;
      return 1;
    }
    if (digitalRead(KEY2) == LOW) {
      last = now;
      return 2;
    }
    if (digitalRead(KEY3) == LOW) {
      last = now;
      return 3;
    }
  }
  return 0;
}

/** vai para um novo estado, reiniciando as variaveis necessarias */
void irPara(int newState) {
  if (newState == 0) {    // mostrar
    mostrarAtual = 0;
    lastMostrar = now;
    stateMostrar = false;
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, LOW);
  }

  if (newState == 1) {    // receber
    receberAtual = 0;
    digitalWrite(LED1, LOW);
    digitalWrite(LED2, LOW);
    digitalWrite(LED3, LOW);
    // TODO
  }
  
  if (newState == 2) {    // sucesso
    digitalWrite(LED1, HIGH);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, HIGH);
  }

  if (newState == 3) {    // erro
    digitalWrite(LED1, HIGH);
  }

  state = newState;
}


void mostrar() {
  // int mostrarAtual;
  // unsigned long lastMostrar;
  // bool stateMostrar;

  if (now - lastMostrar >= 1000) {
    if (!stateMostrar) {
      if (mostrarAtual >= LEN_RESPOSTA) {
        irPara(1);
        return;
      }
      // mostra o led
      digitalWrite(LEDS[respostaCorreta[mostrarAtual] - 1], HIGH);
    }
    else {
      // apaga o led
      digitalWrite(LEDS[respostaCorreta[mostrarAtual] - 1], LOW);
      mostrarAtual++;  // aumenta o contador
    }

    stateMostrar = !stateMostrar;
    lastMostrar = now;
  }
}

void receber() {
  int b = recebeBotao();
  if (b > 0) {
    // se acertou
    if (respostaCorreta[receberAtual] == b) {
      receberAtual++;   // passa pro proximo
      if (receberAtual >= LEN_RESPOSTA) {
        irPara(2);      // chegou no final
      }
    }
    // errou
    else {
      irPara(3);
    }
  }
}

void fimDeJogo() {
  if (recebeBotao() == 1) irPara(0);
}

void setup() {
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode(KEY1, INPUT_PULLUP);
  pinMode(KEY2, INPUT_PULLUP);
  pinMode(KEY3, INPUT_PULLUP);

  last = millis();
  state = 0;
}

void loop() {
  now = millis();

  if (state == 0) {
    mostrar();
  }
  if (state == 1) {
    receber();
  }
  else {
    fimDeJogo();
  }
}
