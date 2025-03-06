configuration SpiEspC {
  provides interface ESP32;
}

implementation {
    components MainC;

    components HplMsp430GeneralIOC as MSP430C;
    components HplMsp430InterruptC as I0;
    components new TimerMilliC() as TimerC;
    components new TimerMilliC() as TimerSincro;
    //components new TimerMilliC() as TimerWait;
    components SpiEspP;

    SpiEspP.Boot -> MainC;

    SpiEspP.CS_port -> I0.Port27; // GPIO per il pin di interrupt
    SpiEspP.CLK_port      -> MSP430C.Port20; //GPIO0 PIN D18 ESP
    SpiEspP.MISO_port     -> MSP430C.Port23;//GPIO2e PIN D19 ESP
    SpiEspP.TimerCLK->TimerC;
    SpiEspP.TimerSincro->TimerSincro;
    //SpiEspP.TimerWait->TimerWait;	

    ESP32 = SpiEspP;
}

