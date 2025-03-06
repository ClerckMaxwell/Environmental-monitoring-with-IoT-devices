#include "EnvPkt.h"

module EnvTxC {

	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as EnvTimer;

	uses interface Read<uint16_t> as TemperatureSensor;
	uses interface Read<uint16_t> as HumiditySensor;
	uses interface Read<uint16_t> as LightSensor;
	uses interface Read<uint16_t> as IRSensor;
	uses interface Read<uint16_t> as Adc0Sensor; // Interfaccia per l'Adc0
	uses interface Read<uint16_t> as Adc1Sensor; // Interfaccia per l'ADC1
	uses interface SplitControl as RadioControl;
	uses interface AMSend;
	uses interface Packet;
	uses interface Receive as TxReceiver;
}

implementation {

	message_t Envmsg;
	EnvMsgStr* myPayload;
	uint16_t temperature = 0;
	uint16_t humidity = 0;
	uint16_t luce = 0;
	uint16_t luce_IR = 0;
	uint16_t Adc0_value = 0; // Valore letto da Adc0
	uint16_t adc1_value = 0; // Valore letto da ADC1

	event void Boot.booted() {
		call RadioControl.start();
		call TemperatureSensor.read();
		call HumiditySensor.read();
		call LightSensor.read();
		call IRSensor.read();
		call Adc0Sensor.read(); // Richiede una lettura dall'Adc0
		call Adc1Sensor.read(); // Richiede una lettura dall'ADC1
	}

	event void TemperatureSensor.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			temperature = -41 + 0.01 * data; //tarato + o -
		}
	}

	event void HumiditySensor.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			humidity = -4.0 + 0.0405 * data + (-2.8 * pow(10.0, -6)) * (pow(data, 2));
		}
	}

	event void LightSensor.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			luce = 0.625*100000*data*1.5/4096; //trovato sul datasheet del sensore
		
		}
	}

	event void IRSensor.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			luce_IR = 0.769*100000*data*1.5/4096; //trovato sul datasheet del sensore
		}
	}

	// Evento per l'Adc0 sensore di umidità del suolo
	event void Adc0Sensor.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			Adc0_value = data; //(valore secco - adc) / (valore secco - valore umido) * 100
		}
	}

	// Evento per l'ADC1 sensore di pioggia
	event void Adc1Sensor.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) {
			adc1_value = data; // in funzione di una soglia diremo se c'è o non c'è pioggia, per questo ci basta il dato grezzo.
		}
	}

	event void EnvTimer.fired() {

		myPayload = (EnvMsgStr*)(call Packet.getPayload(&Envmsg, sizeof(EnvMsgStr)));

		call TemperatureSensor.read();
		call HumiditySensor.read();
		call LightSensor.read();
		call IRSensor.read();
		call Adc0Sensor.read(); // Richiede una lettura dall'ADC0
		call Adc1Sensor.read(); // Richiede una lettura dall'ADC1
		myPayload->temp = temperature;
		myPayload->hum = humidity;
		myPayload->light = luce;
		myPayload->light_IR = luce_IR;
		myPayload->soil_moisture = Adc0_value; // Aggiungi il valore ADC0 al payload
		myPayload->rain = adc1_value; // Aggiungi il valore ADC1 al payload
		call AMSend.send((TOS_NODE_ID % PLAYERS) + 1, &Envmsg, sizeof(EnvMsgStr));

	}

	event void RadioControl.startDone(error_t code) {
		if (code == SUCCESS) {
			if (TOS_NODE_ID == 1) {
				call Leds.led0On();
			}
			call Leds.led2On();		
		} else {
			call RadioControl.start();
		}
	}

	event void RadioControl.stopDone(error_t code) {
		call Leds.led0Off();	
	}

	event void AMSend.sendDone(message_t* msg, error_t code) {
		if (code == SUCCESS) {
			call Leds.led0Toggle();		
		}
	}

	// Evento per ricevere pacchetti
	event message_t* TxReceiver.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(EnvControlMsg)) {
			EnvControlMsg* controlMsg = (EnvControlMsg*)payload;
			if (controlMsg->cmd == START_TRANSMISSION) {
				call EnvTimer.startOneShot(150);
				call Leds.led1Toggle();
			}
		}
		return msg;
	}
}


