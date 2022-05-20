# usb_pd_monitor
USB PD monitor implemented in a Tang Nano 9K FPGA. The only connections needed are CC1, CC2 and their ground pins. The Tang Nano 9K is powered by the USB connection the UART data also goes over the USB connection. A software implementation of the FTDI FT2232C is run by the BL702 IC.
![picture](https://github.com/charkster/tang_nano_9k-uart_block_ram/blob/main/images/tang_nano_9k_pinout.png)
Using the 1.8V pins, this FPGA board is able to monitor the USB-PD messages on the CC pins without any levelshifters.

See [fpga/src/tang_nano_9k_generic.cst](https://github.com/charkster/usb_pd_monitor/blob/main/fpga/src/tang_nano_9k_generic.cst) for pins used. 3.3V buffered CC1 and CC2 outputs are available to veiw with a logic analyzer (I highly recommend the [$12 Saleae clones on Amazon.com](https://www.amazon.com/HiLetgo-Analyzer-Ferrite-Channel-Arduino/dp/B077LSG5P2), as sigrok pulseview has full USB PD decoding). I also have a 3.3 buffered "uart_tx_buf" signal which can connect to a logic analyzer or another serial-to-usb adapter.

Tang Nano 9k board Info:
https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html


I used the eLabBay USB C passthrough breakout board:
![picture](https://github.com/charkster/usb_pd_monitor/blob/main/images/usb_c_passthrough_breakout.png)
https://elabbay.myshopify.com/products/usb3-1-cm-cf-v1a-usb3-1-type-c-male-to-female-pass-through-breakout-board



Here are some captures from Sigrok's Pulseview using my HiLetgo $12 logic analyzer:

![picture](https://github.com/charkster/usb_pd_monitor/blob/main/images/usb_pd_get_source_cap1.png)
![picture](https://github.com/charkster/usb_pd_monitor/blob/main/images/usb_pd_good_crc.png)
