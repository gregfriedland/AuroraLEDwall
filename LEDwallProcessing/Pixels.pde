// Class to abstract out interfacing with the microcontroller (which in turn sends signals to the wall) and
// to the processing display.

int PACKET_SIZE = 100;
int LOC_BYTES = 1; // how many bytes to use to store the index at the beginning of each packet
int MAX_RGB = 255;

class Pixels {
  int w, h, pixelSize;
  color[][] px;
  SerialPacketWriter spw;
  byte txData[];
  
  Pixels(PApplet p, int wi, int he, int pSize, int baud) {
    w = wi; 
    h = he;
    pixelSize = pSize;
    px = new color[w][h];
    
    if (baud > 0) {
      int npkts = ceil(w*h*3.0/(PACKET_SIZE-LOC_BYTES));
      txData = new byte[npkts*PACKET_SIZE];
      
      spw = new SerialPacketWriter();
      spw.init(p, baud, PACKET_SIZE);
    }
  }

  void setPixel(int x, int y, color c) {
    px[x][y] = c;
  }

  void setAll(color c) {
    for (int x=0; x<w; x++) {
      for (int y=0; y<h; y++) {
        setPixel(x, y, c);
      }
    }
  }
  
  void drawToScreen() {
    //println(red(px[0][0]) + " " + green(px[0][0]) + " " + blue(px[0][0]));
    background(0);
    loadPixels();
    for (int x=0; x<w; x++) {
      for (int y=0; y<h; y++) {
        color col = px[x][y];
        for (int i=x*pixelSize; i<(x+1)*pixelSize; i++) {
          for (int j=y*pixelSize; j<(y+1)*pixelSize; j++) {
            pixels[j*w*pixelSize + i] = col;
          }
        }
        //rect(x*pixelSize, y*pixelSize, pixelSize, pixelSize); 
      }
    }    
    updatePixels();
  }
  
  void drawToLedWall() {
    // r, g, b for 1,1 then 1,2; etc.
    int ti=0;
     for (int y=h-1; y>=0; y--) {
      int dx, x;
      if (y%2 == 0) {
        dx = -1;
        x = w-1;
      } else {
        dx = 1;
        x = 0;
      }
      
      while (x >= 0 && x < w) {
        byte[] rgb = new byte[3];
        rgb[2] = (byte) constrain(px[x][y] & 0xFF, 0, MAX_RGB);
        rgb[1] = (byte) constrain((px[x][y] >> 8) & 0xFF, 0, MAX_RGB);
        rgb[0] = (byte) constrain((px[x][y] >> 16) & 0xFF, 0, MAX_RGB);
        
        for (int c=0; c<3; c++) {
          if (ti%PACKET_SIZE == 0) {
            int pktNum = floor(float(ti)/PACKET_SIZE);
            txData[ti++] = byte(pktNum);
          }
          
          txData[ti++] = rgb[c];
        }

        x += dx;
      }
    }        
    
    spw.send(txData);
  }
  
  int getHeight() { return h; }
  int getWidth() { return w; }
  int getPixelSize() { return pixelSize; }
}

