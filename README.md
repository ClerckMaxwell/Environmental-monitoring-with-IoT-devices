# 🍇 Sistema IoT Low-Power per il Monitoraggio Ambientale in Agricoltura

Questo progetto implementa un sistema IoT per il **monitoraggio in tempo reale** dei parametri ambientali di un terreno, con un'enfasi particolare sull'**ottimizzazione energetica** e l'**affidabilità della comunicazione** tra i nodi sensore e l'utente finale.

## 🎯 Obiettivi del Progetto

Il sistema è stato realizzato per:

* **Raccogliere dati ambientali in tempo reale** (temperatura, umidità, intensità luminosa, umidità del suolo e rilevamento pioggia) utilizzando sensori interni ed esterni collegati a un **TelosB**.
* Garantire una **comunicazione affidabile e integrata** tra i dispositivi di monitoraggio.
* Minimizzare i consumi tramite hardware a basso consumo (TelosB, ESP32), attivando l'acquisizione e la trasmissione solo su richiesta dell'utente.



[Image of IoT system architecture for agriculture]


---

## ⚙️ Architettura del Sistema

Il sistema si basa su una struttura a tre livelli, tipica delle applicazioni IoT per l'agricoltura, integrando nodi sensore basati su TinyOS con una piattaforma di visualizzazione utente.

### 1. Nodi Sensore (TelosB TX)

Il nodo sensore (TelosB Trasmitter) è responsabile della lettura dei parametri ambientali.

* **Piattaforma:** **TinyOS**.
* **Sensori Interni:** Umidità e Temperatura dell’aria (**SensirionSht11**), Luminosità e Intensità IR (**HamamatsuS1087**).
* **Sensori Esterni:** Rilevamento pioggia (**MH-RD Raindrops**) e Umidità del suolo (**AZDelivery**).

### 2. Gateway e Bridge (TelosB RX, ESP32, Arduino)

Questa sezione funge da ponte tra il nodo sensore radio e l'interfaccia utente, gestendo protocolli diversi:

| Componente | Ruolo | Comunicazione | Note |
| :---: | :---: | :---: | :--- |
| **TelosB Receiver** | Buffer dati | Radio (riceve da TX), **SPI Slave** (invia a ESP32) | Sviluppato in TinyOS. |
| **ESP32** | Master/Controller | **SPI Master** (riceve da TelosB RX), **UART** (invia ad Arduino) | Invia i dati tramite UART come binario. |
| **Arduino UNO** | Interfaccia Utente | **UART** (riceve da ESP32), **I2C** (display), **Wi-Fi** (Telegram Bot) | Gestisce la logica di controllo e l'interfaccia utente. |

> ⚠️ **Protezione Hardware:** Per proteggere l'ESP32 (3.3V) dalle sovratensioni in uscita dall'Arduino (5V), i canali di comunicazione sono dotati di un **partitore di tensione**.

---

## 💻 Logica di Comunicazione e Controllo Low-Power

L'efficienza energetica è garantita da un meccanismo di attivazione on-demand:

### 1. Attivazione Nodi

* **Sleep Mode:** Il **TelosB Receiver** è costantemente in uno stato di congelamento (`freezing state`).
* **Wake-up via Radio:** Il **TelosB Receiver** viene "svegliato" da un messaggio di controllo (`START_TRANSMISSION`) inviato via **comunicazione radio** dal **TelosB Trasmitter**.

### 2. Acquisizione Dati

* **Soglia di Attivazione:** Il **TelosB Trasmitter** utilizza il pin Analog Input 0 (ADC0) per monitorare lo stato di un pin dedicato ogni 500 ms (`EnvTimer`).
* **Trasmissione:** Se la lettura analogica del pin è **maggiore di 2V**, viene inviato il comando `START_TRANSMISSION` al TelosB Receiver per avviare l'acquisizione dei dati.

### 3. Logica del Bot Telegram

L'interazione con l'utente avviene tramite il bot **«BotDadoRaff»**.

| Comando | Funzione |
| :---: | :--- |
| **`/start`** | Avvia una nuova sessione. |
| **`/dati`** | Richiede una singola acquisizione dei dati. |
| **`/periodic`** | Avvia acquisizioni periodiche. |
| **`/stop`** | Interrompe le acquisizioni periodiche. |

### 4. Gestione delle Risposte

* **Check Messaggi:** Arduino controlla i nuovi messaggi dal bot ogni **due secondi** (`botRequestDelay`).
* **Richiesta Dati:** Se l'utente richiede dati, Arduino alza il pin **`STROBE_PIN`** (HIGH) per un istante, segnalando l'evento all'ESP32.
* **Visualizzazione:** I dati ricevuti sono visualizzati su un **display OLED** tramite protocollo **I2C** e inviati nuovamente all'utente tramite il **Bot Telegram**.
* **Controllo Malfunzionamenti:** Se **più di 5 valori** ricevuti sono nulli, viene inviato un messaggio di avviso per segnalare un possibile problema nella trasmissione.

---

## 👥 Autori

* **Raffaele Petrolo**
* **Davide Di Gesu**

---

*Questo progetto è stato sviluppato per il corso di Programmazione di Sistemi IoT e Wearable, Anno Accademico 2024/2025.*
