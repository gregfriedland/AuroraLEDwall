// Class to send end image pixel data in packet form to the microcontroller

import processing.serial.*;

boolean TIMING = false; // turn on timing output

int MAGIC_LEN = 3;
byte[] MAGIC_START = { (byte)127, (byte)57, (byte)7 };
int CKSUM_BYTES = 2;
byte RECV_SUCCESS = 17;
byte RECV_FAILURE = 1;
int MAXINT = 32767;

class SerialPacketWriter {
  Serial myPort;
  int rcvCountGood, rcvCountTot;
  float startTime;
  int pktSize;

  SerialPacketWriter() {
  }
  
  void init(PApplet p, int baud, int pktSize) {
    String portName = Serial.list()[0];
    myPort = new Serial(p, portName, baud);
    startTime = 0;
    rcvCountGood = 0;
    rcvCountTot = 0;
    this.pktSize = pktSize;
  }
  
  int processInput() {
    while (myPort.available() > 0) {
      int s = myPort.read();
      if (s == RECV_SUCCESS) rcvCountGood++;
      rcvCountTot++;
    }

    if (TIMING) {
      if (rcvCountTot % 100 == 99) {
        float goodBps = rcvCountGood * pktSize * 8 / (millis() - startTime) * 1000;
        float totalBps = rcvCountTot * pktSize * 8 / (millis() - startTime) * 1000;
        println(goodBps + " intact bps; " + totalBps + " total bps");
        startTime = millis();
        rcvCountGood = 0;
        rcvCountTot = 0;
      }
    }

    return 0;
  }  
  
  void send(byte[] data) {
    // wait 6s for the chipkit32 to be ready
    if (millis() < 6000) {
      delay(100);
      return;
    }
    
    if (startTime == 0) startTime = millis();
  
    int pktLen = sendPackets(data, pktSize);
    int bytesRead = processInput();  
  }  

  // send 3 start bytes, 2 bytes of length (including crc), data, then 2 bytes of crc
  int sendPackets(byte[] data, int pktSize) {
    int numPkts = ceil(float(data.length)/pktSize);
    byte[] buffer = new byte[data.length+numPkts*(MAGIC_LEN+2+CKSUM_BYTES)];
    
    int di = 0, bi = 0;
    while (di < data.length) {
      for (int i=0; i<MAGIC_LEN; i++) buffer[bi++] = MAGIC_START[i];
      
      int nDataBytes = min(data.length-di, pktSize);
      int pktLen = nDataBytes + CKSUM_BYTES;
      buffer[bi++] = byte((pktLen >> 8) & 0xFF);
      buffer[bi++] = byte(pktLen & 0xFF);
      
      int ckSum = 0;
      for (int i=0; i<nDataBytes; i++) {
        ckSum += int(data[di]); 
        buffer[bi++] = data[di++];
      }
    
      ckSum = ckSum % MAXINT;
      buffer[bi++] = byte((ckSum >> 8) & 0xFF);
      buffer[bi++] = byte(ckSum & 0xFF);
    }
    myPort.write(buffer);
    
    return buffer.length;
  }
}
