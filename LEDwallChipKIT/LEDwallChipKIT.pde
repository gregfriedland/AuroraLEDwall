#include <DSPI.h>

// Pin 10 (SS), Pin 11 (MOSI=white), Pin 12 (MISO), Pin 13 (SCK=green).

//#define CHANGE_HEAP_SIZE(size)  __asm__ volatile ("\t.globl _min_heap_size\n\t.equ _min_heap_size, " #size "\n")
//CHANGE_HEAP_SIZE(5000);

#define NUM_LEDS 32*17
#define LED_BYTES NUM_LEDS*3
byte leds[LED_BYTES];
#define FPS 45

#define LOC_BYTES 1
#define EXPECTED_LENGTH 100
#defidne RECV_SUCCESS 17
#define RECV_FAILURE 1
byte buffer[EXPECTED_LENGTH+100];

DSPI0 spi;

void setup() {
  // 230400, 460800, 921600  
  Serial.begin(921600);
  
  //SPI.begin();
  //SPI.setClockDivider(SPI_CLOCK_DIV16);
  //SPI.setDataMode(SPI_MODE0);  
  spi.begin();
  spi.setMode(DSPI_MODE0);
  spi.enableInterruptTransfer();
}


void loop() {
  int rxLen = processInput(buffer);
  if (rxLen > 0) {
    // first byte is the packet number
    int bi = 0;
    int di0 = buffer[bi++] * (EXPECTED_LENGTH-LOC_BYTES);
    
    for (int di=di0; di<di0+rxLen-LOC_BYTES; di++) {
      if (di >= LED_BYTES) break;
      leds[di] = buffer[bi++];
    }
  }
  update(); 
}

long lastUpdate = 0;
void update(void) {
  if (millis() - lastUpdate < 1000/FPS) {
    return;
  }
  
  
  while(spi.transCount() > 0);
  spi.intTransfer(LED_BYTES, leds);
      
  //for(int i=0; i<LED_BYTES; i++) {
    //SPI.transfer(leds[i]);
  //}
  //delay(1);
  lastUpdate =  millis();
}


// *********************************************




byte MAGIC_START[3] = { 127, 57, 7 };
int MAGIC_LEN = 3;
int CKSUM_BYTES = 2;
boolean _reading = false;
int _len = 0;
int _idx = 0;

// when return value is greater than 0, that many bytes are in the buffer
int processInput(byte *_inBytes) {
  if (Serial.available() == 0) return 0;

  if (_reading == false) {
    if (Serial.available() < MAGIC_LEN + 2) {
      return 0;
    } else {
      // look for the first few bytes to match the start sequence                                                                                                                                               
      for (int i=0; i<MAGIC_LEN; i++) {
        if (Serial.read() != MAGIC_START[i]) return 0;
      }

      byte lenHigh = Serial.read();
      byte lenLow = Serial.read();
      _len = (lenHigh << 8) + lenLow;

      //Serial.println(_len-CKSUM_BYTES);
      if (_len == EXPECTED_LENGTH+CKSUM_BYTES) {
        _reading = true;
      } else {
        Serial.write(RECV_FAILURE);
      }
    }
  }

  if (_reading == true) {
    while (Serial.available() > 0) {
      if (_idx >= _len) {
        _reading = false;
        _idx = 0;
        
        int readCkSum = _inBytes[_len-2] << 8;
        readCkSum += _inBytes[_len-1];
        
        int calcCkSum = 0;
        for (int i=0; i<_len-CKSUM_BYTES; i++) calcCkSum += _inBytes[i];

        if (readCkSum != calcCkSum) {
          //blink13(1, 100);
          Serial.write(RECV_FAILURE);
          return -1; 
        }  else {
          //blink13(1, 10);
          Serial.write(RECV_SUCCESS);
          return _len - CKSUM_BYTES;
        }
      }
      byte s = Serial.read();
      _inBytes[_idx] = s;                                                                                                                                                                                     
      _idx++;
    }
  }
  return 0;
}

