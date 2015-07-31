#include <ESP8266WiFi.h>
#include <SPI.h>
#include "MFRC522.h"
#include <ESP8266WebServer.h>
#include <Time.h>
//#include <DateTimeStrings.h>
#include <WiFiUdp.h> 

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

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED }; 
// NTP Servers:
IPAddress timeServer(132, 163, 4, 101); // time-a.timefreq.bldrdoc.gov
// IPAddress timeServer(132, 163, 4, 102); // time-b.timefreq.bldrdoc.gov
// IPAddress timeServer(132, 163, 4, 103); // time-c.timefreq.bldrdoc.gov

const int timeZone = 10;     // Austrlaian Eastern Standard Time
WiFiUDP Udp;
unsigned int localPort = 8888;  // local port to listen for UDP packets
time_t prevDisplay = 0; // when the digital clock was displayed


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
  //mfrc522.PCD_SetAntennaGain(mfrc522.RxGain_max);
  byte gain=mfrc522.PCD_GetAntennaGain();
  Serial.println(gain);

  WiFi.begin(ssid, pass);

  int retries = 0;
  while ((WiFi.status() != WL_CONNECTED) && (retries < 20)) {
    retries++;
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(F("WiFi connected"));
  }
  delay(1000);
  IPAddress myIP = WiFi.localIP();
  Serial.print("AP IP address: ");
  Serial.println(myIP);
  server.on("/", handleRoot);
  server.begin();
  Serial.println("HTTP server started");

  Serial.println(F("Ready!"));
  Serial.println(F("======================================================")); 
  Serial.println(F("Scan for Card and print UID:"));

  Serial.println("Starting UDP");
  Udp.begin(localPort);
  Serial.print("Local port: ");
  Serial.println(Udp.localPort());
  setSyncProvider(getNtpTime);
  
}


void loop() { 
  // Look for new cards
  server.handleClient();

  if (timeStatus() != timeNotSet) {
    if (now() != prevDisplay) { //update the display only if time has changed
      prevDisplay = now();
      digitalClockDisplay();  
    }
  }

  // Serial.print(".");
  if ( ! mfrc522.PICC_IsNewCardPresent()) {
    //delay(50);
    return;
  }
  // Serial.println(F("Found Card"));
  // Select one of the cards
  if ( ! mfrc522.PICC_ReadCardSerial()) {
    //delay(50);
    return;
  }
  // Dump debug info about the card; PICC_HaltA() is automatically called
  //    mfrc522.PICC_DumpToSerial(&(mfrc522.uid));
  //    Serial.println(F("======================================================"));


  Serial.println("Scanned PICC's UID:");
  digitalClockDisplay();
  lastuuid = "";
  for (int i = 0; i < 4; i++) {  // 
    readCard[i] = mfrc522.uid.uidByte[i];
    Serial.print(readCard[i], HEX);
    currentchar = String(readCard[i], HEX);
    lastuuid = String(lastuuid + currentchar);
  }

  Serial.println();
  Serial.println(now());

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

void digitalClockDisplay(){
  // digital clock display of the time
  Serial.print(hour());
  printDigits(minute());
  printDigits(second());
  Serial.print(" ");
  Serial.print(day());
  Serial.print(" ");
  Serial.print(month());
  Serial.print(" ");
  Serial.print(year()); 
  Serial.println(); 
}

void printDigits(int digits){
  // utility for digital clock display: prints preceding colon and leading 0
  Serial.print(":");
  if(digits < 10)
    Serial.print('0');
  Serial.print(digits);
}

/*-------- NTP code ----------*/

const int NTP_PACKET_SIZE = 48; // NTP time is in the first 48 bytes of message
byte packetBuffer[NTP_PACKET_SIZE]; //buffer to hold incoming & outgoing packets

time_t getNtpTime()
{
  while (Udp.parsePacket() > 0) ; // discard any previously received packets
  Serial.println("Transmit NTP Request");
  sendNTPpacket(timeServer);
  uint32_t beginWait = millis();
  while (millis() - beginWait < 1500) {
    int size = Udp.parsePacket();
    if (size >= NTP_PACKET_SIZE) {
      Serial.println("Receive NTP Response");
      Udp.read(packetBuffer, NTP_PACKET_SIZE);  // read packet into the buffer
      unsigned long secsSince1900;
      // convert four bytes starting at location 40 to a long integer
      secsSince1900 =  (unsigned long)packetBuffer[40] << 24;
      secsSince1900 |= (unsigned long)packetBuffer[41] << 16;
      secsSince1900 |= (unsigned long)packetBuffer[42] << 8;
      secsSince1900 |= (unsigned long)packetBuffer[43];
      return secsSince1900 - 2208988800UL + timeZone * SECS_PER_HOUR;
    }
  }
  Serial.println("No NTP Response :-(");
  return 0; // return 0 if unable to get the time
}

// send an NTP request to the time server at the given address
void sendNTPpacket(IPAddress &address)
{
  // set all bytes in the buffer to 0
  memset(packetBuffer, 0, NTP_PACKET_SIZE);
  // Initialize values needed to form NTP request
  // (see URL above for details on the packets)
  packetBuffer[0] = 0b11100011;   // LI, Version, Mode
  packetBuffer[1] = 0;     // Stratum, or type of clock
  packetBuffer[2] = 6;     // Polling Interval
  packetBuffer[3] = 0xEC;  // Peer Clock Precision
  // 8 bytes of zero for Root Delay & Root Dispersion
  packetBuffer[12]  = 49;
  packetBuffer[13]  = 0x4E;
  packetBuffer[14]  = 49;
  packetBuffer[15]  = 52;
  // all NTP fields have been given values, now
  // you can send a packet requesting a timestamp:                 
  Udp.beginPacket(address, 123); //NTP requests are to port 123
  Udp.write(packetBuffer, NTP_PACKET_SIZE);
  Udp.endPacket();
}
