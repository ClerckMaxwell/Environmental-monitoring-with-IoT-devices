# 🍇 Low-Power IoT System for Environmental Monitoring in Agriculture

This project implements an IoT system for the **real-time monitoring** of environmental parameters in a field, with a particular emphasis on **energy optimization** and **communication reliability** between sensor nodes and the end-user.

## 🎯 Project Objectives

The system was developed to achieve the following goals:

* **Real-time Data Collection:** Gather environmental data (temperature, humidity, light intensity, soil moisture, and rain detection) using internal and external sensors connected to a **TelosB**.
* **Reliable Communication:** Ensure **reliable and integrated communication** between the monitoring devices.
* **Low Power Consumption:** Minimize energy usage through low-power hardware (TelosB, ESP32), activating acquisition and transmission only upon user request.

---

## ⚙️ System Architecture

The system is based on a three-tier structure, typical of IoT applications for agriculture, integrating sensor nodes based on TinyOS with a user visualization platform.

### 1. Sensor Nodes (TelosB TX)

The sensor node (TelosB Transmitter) is responsible for reading environmental parameters.

* **Platform:** **TinyOS**.
* **Internal Sensors:** Air Humidity and Temperature (**SensirionSht11**), Light and IR Intensity (**HamamatsuS1087**).
* **External Sensors:** Rain Detection (**MH-RD Raindrops**) and Soil Moisture (**AZDelivery**).

### 2. Gateway and Bridge (TelosB RX, ESP32, Arduino)

This section acts as a bridge between the radio sensor node and the user interface, managing different protocols:

| Component | Role | Communication | Notes |
| :---: | :---: | :---: | :--- |
| **TelosB Receiver** | Data Buffer | Radio (receives from TX), **SPI Slave** (sends to ESP32) | Developed in TinyOS. |
| **ESP32** | Master/Controller | **SPI Master** (receives from TelosB RX), **UART** (sends to Arduino) | Sends data via UART as binary. |
| **Arduino UNO** | User Interface | **UART** (receives from ESP32), **I2C** (display), **Wi-Fi** (Telegram Bot) | Manages control logic and user interface. |

> ⚠️ **Hardware Protection:** To protect the ESP32 (3.3V) from overvoltage output from the Arduino (5V), the communication channels are equipped with a **voltage divider**.

---

## 💻 Low-Power Communication and Control Logic

Energy efficiency is guaranteed by an on-demand activation mechanism:

### 1. Node Activation

* **Sleep Mode:** The **TelosB Receiver** is constantly in a **freezing state** (`freezing state`).
* **Wake-up via Radio:** The **TelosB Receiver** is "woken up" by a control message (`START_TRANSMISSION`) sent via **radio communication** from the **TelosB Transmitter**.

### 2. Data Acquisition

* **Activation Threshold:** The **TelosB Transmitter** uses Analog Input 0 (ADC0) to monitor the state of a dedicated pin every 500 ms (`EnvTimer`).
* **Transmission:** If the analog reading of the pin is **greater than 2V**, the `START_TRANSMISSION` command is sent to the TelosB Receiver to start data acquisition.

### 3. Telegram Bot Logic

User interaction occurs via the **«BotDadoRaff»** bot.

| Command | Function |
| :---: | :--- |
| **`/start`** | Starts a new session. |
| **`/dati`** | Requests a single data acquisition. |
| **`/periodic`** | Starts periodic acquisitions. |
| **`/stop`** | Stops periodic acquisitions. |

### 4. Response Management

* **Message Check:** Arduino checks for new messages from the bot every **two seconds** (`botRequestDelay`).
* **Data Request:** If the user requests data, Arduino raises the **`STROBE_PIN`** (HIGH) momentarily, signaling the event to the ESP32.
* **Visualization:** The received data is displayed on an **OLED display** via the **I2C** protocol and sent back to the user through the **Telegram Bot**.
* **Malfunction Check:** If **more than 5 received values** are null, a warning message is sent to signal a possible transmission issue.

---

## 👥 Authors

* **Raffaele Petrolo**
* **Davide Di Gesu**

---

*This project was developed for the course of Programming IoT and Wearable Systems, Academic Year 2024/2025.*
