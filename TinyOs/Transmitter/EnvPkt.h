#ifndef ENVPKT_H
#define ENVPKT_H

enum {
	ENV_AM = 77
};

typedef nx_struct EnvMsgStr {
	
	nx_uint16_t temp;
	nx_uint16_t hum;
	nx_uint16_t light;
	nx_uint16_t light_IR;
	nx_uint16_t soil_moisture;
	nx_uint16_t rain;

} EnvMsgStr;

typedef nx_struct EnvControlMsg{
	nx_uint8_t cmd;
} EnvControlMsg;

enum {
	START_TRANSMISSION = 1
};


#endif
