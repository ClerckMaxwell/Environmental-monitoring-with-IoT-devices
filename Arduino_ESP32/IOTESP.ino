#include <SPI.h>

// Definizione dei pin SPI
#define CS_PIN 5     // Chip Select (usato per abilitare/disabilitare il TelosB)
#define CLK_PIN 18   // Clock (SCLK)
#define MISO_PIN 19  // Master In Slave Out (MISO)
#define START_PIN 23
#define STROBE_PIN 22
#define RESET 33
// Numero di dati da leggere (6 valori da TelosB)
#define DATA_LENGTH 6

SPISettings spiSettings(102, MSBFIRST, SPI_MODE0);  // Configura SPI a 100Hz, MSB-first, mode 0

uint16_t receivedData[DATA_LENGTH];  // Buffer per i dati ricevuti
uint8_t cont = 0;

void setup() {
  Serial1.begin(115200, SERIAL_8N1, 16, 17);  // Configura UART su GPIO 16 (RX) e 17 (TX)
  // Configura i pin SPI
  pinMode(CS_PIN, OUTPUT);
  digitalWrite(CS_PIN, HIGH);                // CS inizialmente alto (disabilita slave)
  SPI.begin(CLK_PIN, MISO_PIN, -1, CS_PIN);  // Inizializza SPI senza MOSI (-1 indica ignorare)

  // Configura il pin START_PIN
  pinMode(START_PIN, OUTPUT);
  digitalWrite(START_PIN, LOW);  // START_PIN inizialmente basso

  pinMode(RESET, OUTPUT);
  digitalWrite(RESET, LOW);  // START_PIN inizialmente basso

  pinMode(STROBE_PIN, INPUT);
}

void loop() {

  if (digitalRead(STROBE_PIN)) {
    if (cont % 2 == 0) {
      digitalWrite(RESET, HIGH);
      delay(300);
      digitalWrite(RESET, LOW);
      delay(100);
    }
    digitalWrite(START_PIN, HIGH);
    delay(1000);
    digitalWrite(START_PIN, LOW);
    // Avvia la comunicazione SPI con le impostazioni specifiche
    SPI.beginTransaction(spiSettings);
    delay(200);  //delay empirico
    // Legge i dati uno alla volta
    for (int i = 0; i < DATA_LENGTH; i++) {
      // Abilita la comunicazione SPI abbassando CS
      digitalWrite(CS_PIN, LOW);

      // Riceve i dati dallo slave
      receivedData[i] = spi_read16();

      // Disabilita la comunicazione SPI alzando CS
      digitalWrite(CS_PIN, HIGH);
      delay(50);  // Ritardo per separare le letture
    }

    SPI.endTransaction();
    // Invia i dati ricevuti tramite UART (Serial1)
    Serial1.write((uint8_t*)receivedData, sizeof(receivedData));  // Invia i dati come binario
    cont++;
  }
  delay(500);
}

// Funzione per leggere 16 bit dallo slave
uint16_t spi_read16() {
  uint16_t value = SPI.transfer16(0x0000);  // Trasferisce 16 bit in una sola operazione
  return value;
}
