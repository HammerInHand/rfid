#include <ESP8266WiFi.h>
#include <SPI.h>
#include "MFRC522.h"
#include <ESP8266WebServer.h>


#define RST_PIN  15 // RST-PIN für RC522 - RFID - SPI - Modul GPIO15 
#define SS_PIN   2 // SDA-PIN für RC522 - RFID - SPI - Modul GPIO2 

const char *ssid =  "etheira.net";  // change according to your Network - cannot be longer than 32 characters!
const char *pass =  "0418372966"; // change according to your Network

MFRC522 mfrc522(SS_PIN, RST_PIN);  // Create MFRC522 instance
boolean match = false;
ESP8266WebServer server(80);
byte readCard[10];
String lastuuid = "HelloString";
String currentchar = "";


void handleRoot() {
	server.send(200, "text/html", "<h1>" + lastuuid + "</h1>");
}

//char *lastUUID = "";

void setup() {
	Serial.begin(230400);  // Initialize serial communications
	delay(250);
	Serial.println(F("Booting...."));

	SPI.begin();   // Init SPI bus
	mfrc522.PCD_Init(); // Init MFRC522
	ShowReaderDetails();  // Show details of PCD - MFRC522 Card Reader details
	mfrc522.PCD_SetAntennaGain(mfrc522.RxGain_33dB);
	// mfrc522.PCD_SetAntennaGain(mfrc522.RxGain_max);
	byte gain=mfrc522.PCD_GetAntennaGain();
	Serial.println(gain);

	WiFi.begin(ssid, pass);

	int retries = 0;
	while ((WiFi.status() != WL_CONNECTED) && (retries < 10)) {
		retries++;
		delay(500);
		Serial.print(".");
	}

	if (WiFi.status() == WL_CONNECTED) {
		Serial.println(F("WiFi connected"));
	}

	Serial.println(F("Ready!"));
	Serial.println(F("======================================================")); 
	Serial.println(F("Scan for Card and print UID:"));
  
	Serial.println("");
	Serial.println("WiFi connected");  

	IPAddress myIP = WiFi.localIP();
	Serial.print("AP IP address: ");
	Serial.println(myIP);
	server.on("/", handleRoot);
	server.begin();
	Serial.println("HTTP server started");
  
}

void loop() { 
	// Look for new cards
	server.handleClient();
	Serial.print(".");
	if ( ! mfrc522.PICC_IsNewCardPresent()) {
		//delay(50);
		return;
	}
	Serial.println(F("Found Card"));
	// Select one of the cards
	if ( ! mfrc522.PICC_ReadCardSerial()) {
		//delay(50);
		return;
	}
	// Dump debug info about the card; PICC_HaltA() is automatically called
	//    mfrc522.PICC_DumpToSerial(&(mfrc522.uid));
	//    Serial.println(F("======================================================"));

	Serial.println("Scanned PICC's UID:");
	lastuuid = "";
	for (int i = 0; i < 4; i++) {  // 
		readCard[i] = mfrc522.uid.uidByte[i];
		Serial.print(readCard[i], HEX);
		currentchar = String(readCard[i], HEX);
		lastuuid = String(lastuuid + currentchar);
	}

	Serial.println();	
}


boolean checkTwo ( byte a[], byte b[] ) {
	if ( a[0] != NULL ) // Make sure there is something in the array first
		match = true; // Assume they match at first
	for ( int k = 0; k < 4; k++ ) { // Loop 4 times
		if ( a[k] != b[k] ) {// IF a != b then set match = false, one fails, all fail
			match = false;
			return false;
		}
	}
	if ( match ) { // Check to see if if match is still true
		return true; // Return true
	} else {
		return false; // Return false
	}
}

void ShowReaderDetails() {
	// Get the MFRC522 software version
	byte v = mfrc522.PCD_ReadRegister(mfrc522.VersionReg);
	Serial.print(F("MFRC522 Software Version: 0x"));
	Serial.print(v, HEX);
	if (v == 0x91)
		Serial.print(F(" = v1.0"));
	else if (v == 0x92)
		Serial.print(F(" = v2.0"));
	else
		Serial.print(F(" (unknown)"));
		Serial.println("");
	// When 0x00 or 0xFF is returned, communication probably failed
	if ((v == 0x00) || (v == 0xFF)) {
		Serial.println(F("WARNING: Communication failure, is the MFRC522 properly connected?"));
	}
}	
/**
 * Helper routine to dump a byte array as hex values to Serial.
 */
void dump_byte_array(byte *buffer, byte bufferSize) {
	for (byte i = 0; i < bufferSize; i++) {
		Serial.print(buffer[i] < 0x10 ? " 0" : " ");
		Serial.print(buffer[i], HEX);
	}
}
