#include "EnvPkt.h"
#include "printf.h"


module EnvRxC {
  uses interface Boot;
  uses interface Leds;
  uses interface Timer<TMilli> as EnvTimer;
  //uses interface Timer<TMilli> as TimerResponse;
  uses interface SplitControl as RadioControl;
  uses interface Receive as EnvReceiver;
  uses interface AMSend as RxTransmitter;  // Per inviare messaggi di controllo
  uses interface ESP32;
  //uses interface HplMsp430GeneralIO as CTRL_port; // Controllo del pin
  uses interface Packet;
  uses interface Read<uint16_t> as AdcPIN;  // Interfaccia per l'ADC1 per controllare il pin, non funzionano i GIO3 e GIO1
}

implementation {

  uint16_t val, i = 0;
  message_t ControlMsg;  // Messaggio di controllo

  event void Boot.booted() {
    //call CTRL_port.makeInput(); // Configura CTRL_port come input
    call RadioControl.start();  // Avvia la radio
  }

  event void AdcPIN.readDone(error_t result, uint16_t data) {
    if (result == SUCCESS) {
      val = data;
    }
  }

  event void RadioControl.startDone(error_t code) {
    if (code == SUCCESS) {
      call Leds.led2On();
      call EnvTimer.startOneShot(500);  // Timer per controllare il pin ogni 500 ms
    } else {
      call Leds.led1On();  // Indica errore
    }
  }

  event void RadioControl.stopDone(error_t code) {
    call Leds.led2Off();
  }

  event void EnvTimer.fired() {
    // Legge lo stato del pin
    call AdcPIN.read();
    if (val > 2500) {
      EnvControlMsg* payload = (EnvControlMsg*)(call RxTransmitter.getPayload(&ControlMsg, sizeof(EnvControlMsg)));
        payload->cmd = START_TRANSMISSION;  // Imposta il comando di avvio
        call RxTransmitter.send(1, &ControlMsg, sizeof(EnvControlMsg));
        call Leds.led1Toggle();  // Indica trasmissione avvenuta

    } else call EnvTimer.startOneShot(500);
  }

  event void RxTransmitter.sendDone(message_t * msg, error_t code) {

  }

  event message_t* EnvReceiver.receive(message_t * msg, void* payload, uint8_t payloadLength) {
    atomic {
      if (payloadLength == sizeof(EnvMsgStr)) {
        EnvMsgStr* EnvReceived = (EnvMsgStr*)payload;
        call ESP32.setData(EnvReceived->temp);
        call ESP32.setData(EnvReceived->hum);
        call ESP32.setData(EnvReceived->light);
        call ESP32.setData(EnvReceived->light_IR);
        call ESP32.setData(EnvReceived->soil_moisture);
        call ESP32.setData(EnvReceived->rain);
        call Leds.led0Toggle();
        call EnvTimer.startOneShot(2000);
      }
    }
    return msg;
  }
}

