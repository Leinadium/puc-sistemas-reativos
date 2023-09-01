/** roda a configuração dos leds */
void setup_leds();

/** Altera o estado do LED. 0 <= led <= 11 */
void set_led(int led, bool modo);

/** Altera o estado de todos os LEDS */
void set_todos_leds(bool modo);

/** Faz a proxima etapa da varredura.*/
void faz_varredura();