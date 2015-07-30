# RMAP - RFID Machine Access Policy


Description:
An RFID access control system for machine tool interlock.
Our goal is to provide a simple method of enforcement of training and safety policy by only allowing trained personal able to power machines that they have received sufficient training on by using commonly available rfid smart cards.

Development Platform:

Reader:
Arduino Pro Mini 3.3V
NXP PN532
Mifare Classic 1k - NXP MF1ICS50
I2C 128x64 OLED Display
I2C Real Time Clock
3-35V to 2.2-30V Boost Buck Regulator
240-12V or 240-5VDC Power Supply
MOSFET or Relay Module for machine tool integration
RGB LED
ESP8266 wifi module

Back end - Registration:
Raspberry Pi2 B+ (Admin Web UI, Logging, Database)


User Interaction:
User: Places card on reader:
User has been trained: releases interlock and allows the tool to be powered.
User is trainer: releases interlock and allows the tool to be powered.
User is untrained: Displays that the user needs to be trained before operating
User and Trainer cards present: releases interlock and allows the tool to be powered, after set period of time updates database that user has now been sufficiently trained.

Admin UI:
Optional.
