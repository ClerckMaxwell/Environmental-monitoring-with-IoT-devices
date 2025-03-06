#include "Msp430Adc12.h"

// Modulo generico con un parametro per il canale ADC
generic module AdcConfigC(uint8_t channel) {
    provides interface AdcConfigure<const msp430adc12_channel_config_t*>;
}

implementation {
    const msp430adc12_channel_config_t adcConfig = {
        inch: channel,                     // Canale passato come parametro
        sref: REFERENCE_AVcc_AVss,         // VR+ = AVcc, VR- = AVss
        ref2_5v: REFVOLT_LEVEL_NONE,       // Nessuna tensione di riferimento interna
        adc12ssel: SHT_SOURCE_SMCLK,       // Clock ADC = SMCLK
        adc12div: SHT_CLOCK_DIV_1,         // Divisore del clock = 1
        sht: SAMPLE_HOLD_16_CYCLES,        // Tempo di campionamento = 16 cicli
        sampcon_ssel: SAMPCON_SOURCE_SMCLK,// Controllo campionamento = SMCLK
        sampcon_id: SAMPCON_CLOCK_DIV_1    // Divisore campionamento = 1
    };

    async command const msp430adc12_channel_config_t* AdcConfigure.getConfiguration() {
        return &adcConfig;
    }
}

