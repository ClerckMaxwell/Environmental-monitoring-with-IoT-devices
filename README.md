# Environmental-monitoring-with-IoT-devices
Environmental monitoring by two transceivers working using nesC (event driven) controlled via a telegram bot. The transceivers communicate via radio, one of them acts as a base station and transmits the received data via SPI protocol to an ESP32 which streetcars it via UART protocol to an arduino which handles the telegram part, a ppt is attached.
Everything about the nesC part is in the TinyOs folder while everything about arduino and ESP is in the other
