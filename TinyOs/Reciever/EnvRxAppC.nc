#include "EnvPkt.h"

configuration EnvRxAppC {
}
implementation {
	components MainC, LedsC;
	components EnvRxC;

	components HplMsp430GeneralIOC as MSP430C;
	components new TimerMilliC() as TimerC;
	//components new TimerMilliC() as TimerC2;	
	components ActiveMessageC; 
	components new AMSenderC(ENV_AM) as AMSender; //serve per la trasmissione
	components new AMReceiverC(ENV_AM) as AMReceiver; //servono per la ricezione
	components SpiEspC as ESPSPI;
	components PrintfC, SerialStartC; //Servono solo per la stampa a video

	components new AdcReadClientC() as AdcReaderC;
    	components new AdcConfigC(INPUT_CHANNEL_A0) as AdcConfig;
	
	EnvRxC.Boot -> MainC;
	EnvRxC.Leds -> LedsC;

	EnvRxC.EnvTimer -> TimerC;
	//EnvRxC.TimerResponse->TimerC2;

	EnvRxC.ESP32 -> ESPSPI;  

	EnvRxC.RadioControl -> ActiveMessageC;

	EnvRxC.Packet -> AMSender;
	EnvRxC.RxTransmitter -> AMSender; //serve per la trasmissione

	EnvRxC -> AMSender.AMSend;
	EnvRxC.EnvReceiver -> AMReceiver.Receive;
	EnvRxC.Packet -> AMSender.Packet;
	//EnvRxC.CTRL_port -> MSP430C.Port26;//GPIO3 PIN D23 ESP
    	EnvRxC.AdcPIN -> AdcReaderC.Read;
    	AdcReaderC.AdcConfigure -> AdcConfig;
}
