#define DATA_LENGTH 6
#include <WiFiS3.h>
#include <WiFiSSLClient.h>
#include <UniversalTelegramBot.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#define SCREEN_WIDTH 128  // Larghezza del display OLED in pixel
#define SCREEN_HEIGHT 64  // Altezza del display OLED in pixel

#define OLED_RESET -1  // Pin di reset (o -1 se condiviso con il reset di Arduino)
#define SCREEN_ADDRESS 0x3C

// Configura il Wi-Fi
const char* ssid = "iPhone";
const char* password = "12345678";

// Token del Bot Telegram
const char* botToken = "your_bot";

WiFiSSLClient client;
UniversalTelegramBot bot(botToken, client);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Buffer per i dati ricevuti
uint16_t receivedData[DATA_LENGTH];
// Pin per controllo richiesta dati
const int STROBE_PIN = 8;  // al pin D22 della ESP32 tramite partitore N.B 5V * 2/3 = 3.3V
unsigned long lastTimeBotRan = 0;
unsigned long WatchDog = 0;
const int botRequestDelay = 2000;  // Intervallo tra controlli

int periodic = 0;
int ctrl = 0;
int problem = 0;
int soil_moisture = 0;
String pioggia = "NO";
String message;
void setup() {

  display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS);
  display.clearDisplay();
  display.setTextSize(1);               // Scala normale 1:1
  display.setTextColor(SSD1306_WHITE);  // Testo bianco ma il nostro oled ha i pixel blu e gialli
  display.display();
  // Configurazione pin
  pinMode(STROBE_PIN, OUTPUT);
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(STROBE_PIN, LOW);

  // Avvio seriali
  Serial.begin(115200);   // Porta seriale principale (USB) per debug
  Serial1.begin(115200);  // Porta UART per ricezione (RX/TX)
  // Connessione Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connessione al Wi-Fi...");
  }
  Serial.println("Connesso al Wi-Fi");

  client.setCACert(TELEGRAM_CERTIFICATE_ROOT);
  Serial.println("Bot online");
  digitalWrite(LED_BUILTIN, HIGH);
}

void loop() {
  // Controlla nuovi messaggi dal bot
  if (millis() - lastTimeBotRan > botRequestDelay) {
    int numNewMessages = bot.getUpdates(bot.last_message_received + 1);
    while (numNewMessages) {
      handleNewMessages(numNewMessages);
      numNewMessages = bot.getUpdates(bot.last_message_received + 1);
    }
    lastTimeBotRan = millis();
  }
}

void handleNewMessages(int numNewMessages) {
  for (int i = 0; i < numNewMessages; i++) {
    String chat_id = String(bot.messages[i].chat_id);
    String text = bot.messages[i].text;
    if (text == "/start") {
      bot.sendMessage(chat_id, "Benvenuto! Sto monitorando un terreno dove ci sono ulivi, puoi usare il comando /dati per\ 
effettuare una singola acquisizione oppure /periodic se vuoi effettuare acquisizioni periodiche.\
 Puoi stoppare le acquisizioni periodiche col comando /stop.",
                      "");
    } else if (text == "/dati" || periodic) {
      if (!periodic) {
        message = "Messaggio ricevuto! Procedo!\n";
        bot.sendMessage(chat_id, message, "Markdown");
      }
      if (periodic) {
        i = -1;  //resto nel ciclo for esterno
        bot.getUpdates(bot.last_message_received + 1);
        text = bot.messages[0].text;
        if (text == "/stop") {
          message = "Acquisizione periodica terminata\n";
          bot.sendMessage(chat_id, message, "Markdown");
          periodic = 0;
          return;
        }
      }
      // Richiesta dati: alza il pin per attivare la trasmissione
      digitalWrite(STROBE_PIN, HIGH);
      delay(500);
      digitalWrite(STROBE_PIN, LOW);

      // Legge dati dalla porta seriale
      WatchDog = millis();
      while (Serial1.available() < 12) {  // DATA_LENGTH * 2 perchè uint16_t è 2 byte
        if (millis() - WatchDog > 6000) {
          message = "Qualcosa è andato storto!\n";
          bot.sendMessage(chat_id, message, "Markdown");
          return;
        }
      }
      problem = 0;
      for (int k = 0; k < DATA_LENGTH; k++) {
        receivedData[k] = Serial1.read() | (Serial1.read() << 8);  // LSB prima, poi MSB
        if (receivedData[k] == 0) problem++;
      }
      if(receivedData[4]>2500) soil_moisture = 0; 
      
      else soil_moisture = 100 * (2500 - receivedData[4])/(2500 - 300); //valore secco circa 2500, valore bagnato circa 300

//Serial.println(receivedData[4]);
//Serial.println(receivedData[5]);

      if (receivedData[5] < 1200)
        pioggia = "SI";
      else pioggia = "NO";
      // Scrittura dei valori
      display.clearDisplay();
      display.setCursor(0, 0);  // Prima riga
      display.println("Temperatura: " + String(receivedData[0]) + " 'C");
      display.setCursor(0, 9);  // Seconda riga
      display.println("Umidita': " + String(receivedData[1]) + "%");

      display.setCursor(0, 20);  // Terza riga
      display.println("Luce solare: " + String(receivedData[2]) + " lx");

      display.setCursor(0, 30);  // Quarta riga
      display.println("Luce IR: " + String(receivedData[3]) + " lx");

      display.setCursor(0, 40);  // Quinta riga
      display.println("Umid. suolo: " + String(soil_moisture) + "%");
      display.setCursor(0, 50);  // Sesta riga
      display.println("Pioggia: " + pioggia);

      // Mostra tutto sul display
      display.display();

      // Costruisce il messaggio con i dati ricevuti
      message = "";
      message += "Temperatura: " + String(receivedData[0]) + "°C\n";
      message += "Umidità: " + String(receivedData[1]) + "%\n";
      message += "Luce: " + String(receivedData[2]) + " lx\n";
      message += "Luce IR: " + String(receivedData[3]) + " lx\n";
      message += "Umidità suolo: " + String(soil_moisture) + "%\n"; // (3400) a vuoto , 200 da bagnato. 
      message += "Pioggia: " + pioggia; // (1686) a vuoto , 840 bagnato. 

      // Invia il messaggio al bot Telegram
      bot.sendMessage(chat_id, message, "Markdown");
      if (problem >= 5) {
        message = "Forse con tutti sti zeri c'è stato un malfunzionamento del tramsettitore\n";
        bot.sendMessage(chat_id, message, "Markdown");
      }
    } else if (text == "/periodic" && !periodic) {
      message = "Messaggio ricevuto! Procedo!\n";
      bot.sendMessage(chat_id, message, "Markdown");
      periodic = 1;
      i = -1;
    } else if (text == "/stop") {
      if (!periodic) {
        message = "Non ci sono acquisizioni in corso!\n";
        bot.sendMessage(chat_id, message, "Markdown");
      }
    } else {
      message = "Comando non riconosciuto! I comandi che puoi utilizzare sono:\n/dati\n/periodic\n/stop\n/start\n";
      bot.sendMessage(chat_id, message, "Markdown");
    }
  }
}
