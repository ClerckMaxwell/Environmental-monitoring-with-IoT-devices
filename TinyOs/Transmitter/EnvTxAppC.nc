#include "EnvPkt.h"

configuration EnvTxAppC {
}
implementation {
	components MainC, LedsC;
	components EnvTxC;
	components new TimerMilliC() as TimerC;

	// Componenti sensori
	components new SensirionSht11C();
	components new HamamatsuS1087ParC() as Lumi;
	components new HamamatsuS10871TsrC() as IR; 
	components ActiveMessageC; 
	components new AMSenderC(ENV_AM);
	components new AMReceiverC(ENV_AM) as AMReceiver; //servono per la ricezione

	// Componente ADC
	components new AdcReadClientC() as Adc0ReaderC;
	components new AdcConfigC(INPUT_CHANNEL_A0) as Adc0Config;

	components new AdcReadClientC() as Adc1ReaderC;
    	components new AdcConfigC(INPUT_CHANNEL_A1) as Adc1Config;



	// Collegamenti
	EnvTxC.Boot -> MainC;
	EnvTxC.Leds -> LedsC;
	EnvTxC.LightSensor -> Lumi;
	EnvTxC.IRSensor -> IR;
	EnvTxC.TemperatureSensor -> SensirionSht11C.Temperature;
	EnvTxC.HumiditySensor -> SensirionSht11C.Humidity;
	
	EnvTxC.EnvTimer -> TimerC;

	EnvTxC.RadioControl -> ActiveMessageC;

	EnvTxC.Packet -> AMSenderC;
	EnvTxC.AMSend -> AMSenderC;
	EnvTxC.TxReceiver -> AMReceiver.Receive;

	// Collegamenti Adc0 e ADC1
	EnvTxC.Adc0Sensor -> Adc0ReaderC.Read;
	Adc0ReaderC.AdcConfigure -> Adc0Config;

    	EnvTxC.Adc1Sensor -> Adc1ReaderC.Read;
    	Adc1ReaderC.AdcConfigure -> Adc1Config;

}

