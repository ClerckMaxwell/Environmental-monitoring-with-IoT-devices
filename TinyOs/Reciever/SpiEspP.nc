#include "Msp430Adc12.h"
#include "msp430hardware.h"
#include "Timer.h"

module SpiEspP {
  uses {
    interface HplMsp430Interrupt as CS_port;
    interface HplMsp430GeneralIO as CLK_port;
    interface HplMsp430GeneralIO as MISO_port;
    interface Boot;
    interface Timer<TMilli> as TimerCLK;  // Timer per la gestione del ritardo tra i bit
    interface Timer<TMilli> as TimerSincro;
    //interface Timer<TMilli> as TimerWait;
  }

  provides interface ESP32;  // Interfaccia per gestire il trasferimento di dati
}

implementation {
  uint8_t bit_index = 16;
  uint8_t k = 0;
  bool data_consumed = FALSE;

#define BUFFER_SIZE 6  // Numero massimo di dati in coda

  uint16_t txBuffer[BUFFER_SIZE];
  uint8_t txHead = 0;
  uint8_t txTail = 0;
  uint16_t data_to_send;  // Dati da inviare al master (ESP32)

  // Aggiungi un dato al buffer di trasmissione
  bool enqueue(uint16_t value) {
    uint8_t nextHead = (txHead + 1) % BUFFER_SIZE;
    txBuffer[txHead] = value;
    txHead = nextHead;
    return TRUE;
  }

  // Estrai un dato dal buffer di trasmissione
  bool dequeue(uint16_t * value) {
    *value = txBuffer[txTail];
    txTail = (txTail + 1) % BUFFER_SIZE;
    return TRUE;
  }

  // Funzione per inviare un dato via SPI (bit-banging in modalità slave)
  void spi_write_slave(uint16_t data) {
    if (bit_index > 0) {
      // Scrivi il bit corrente in base all'indice
      if ((data >> (bit_index - 1) & 0x01)) {
        call MISO_port.set();
      } else {
        call MISO_port.clr();  // Mette MISO a zero
      }
      bit_index--;
    } else {
     if(call MISO_port.get()) call MISO_port.clr();
      bit_index = 16;
      data_consumed = TRUE;
      
    }
  }

  event void Boot.booted() {

    call CS_port.enable();
    call CLK_port.makeInput();    // CLK controllato dal master
    call MISO_port.makeOutput();  // MISO per inviare dati al master
  }

  // Comando per impostare un dato da trasmettere
  command error_t ESP32.setData(uint16_t value) {
    enqueue(value);
    return SUCCESS;
  }

  async event void CS_port.fired() {
    atomic {
      if (!call CS_port.getValue() && k == 0 && !call CLK_port.get()) {
        k = 1;
        // Avvia il timer per sincronizzare la trasmissione
        if (dequeue(&data_to_send)) {        // Estrai il prossimo dato dal buffer
          data_consumed = FALSE;             // Segnala che il dato è in corso di trasmissione
          call TimerSincro.startOneShot(6);  // Avvia il timer di sincronizzazione
          call CS_port.disable();            // Disabilita l'interrupt sul pin CS
        }
      }
    }
  }

  event void TimerSincro.fired() {
    spi_write_slave(data_to_send);
    call TimerCLK.startPeriodic(10);  //100Hz
  }

  // Funzione per gestire il ciclo di scrittura dei bit
  event void TimerCLK.fired() {
    if (!data_consumed) {
      spi_write_slave(data_to_send);
    } else {
      atomic {
        if (call CS_port.getValue()) {
          k = 0;
          call TimerCLK.stop();
          call CS_port.enable();
          data_consumed = FALSE;
        }
      }
    }
  }
}


