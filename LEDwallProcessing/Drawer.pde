// Base class for drawing programs to be displayed on the LED wall. Subclasses must inherit
// draw(), setup(), getName(), reset() and a constructor. They then get access to height, width, mousePressed
// configured for the LEDwall dimensions and can use any PGraphics method like loadPixels, set, beginShape etc.

class Drawer {
  Pixels p;
  boolean pressed;
  int pressX, pressY;
  PGraphics pg;
  boolean mousePressed;
  int width, height;
  int mouseX, mouseY;
  int lastMouseX = -1, lastMouseY = -1;
  Gradient g;
  float[] xTouches, yTouches;
  int MAX_TOUCHES = 5;
  long[] lastTouchTimes;
  short[][] rgbGamma; 
  Settings settings;
  int MIN_SATURATION = 245;
  int MAX_AUDIO_COLOR_OFFSET = 300;
  
  Drawer(Pixels px, Settings s) {
    p = px;
    pressed = false;
    pg = createGraphics(p.getWidth(), p.getHeight(), JAVA2D);
    width = p.getWidth();
    height = p.getHeight();
    xTouches = new float[MAX_TOUCHES];
    yTouches = new float[MAX_TOUCHES];
    lastTouchTimes = new long[MAX_TOUCHES];
    rgbGamma = new short[256][3];
    setGamma(DEFAULT_GAMMA);    
    settings = s;
  }
  
  Drawer(Pixels px, Settings s, String renderer) {
    p = px;
    pressed = false;
    pg = createGraphics(p.getWidth(), p.getHeight(), renderer);
    width = p.getWidth();
    height = p.getHeight();
    rgbGamma = new short[256][3];
    setGamma(DEFAULT_GAMMA);
    settings = s;
  }    
  
  String getName() { return "None"; }
  void setup() {}
  void draw() {}
  void reset() {}
  
  void update() {
    draw();
        
    for (int x=0; x<p.getWidth(); x++) {
      for (int y=0; y<p.getHeight(); y++) {
        p.setPixel(x, y, pg.get(x, y));
      }
    }    
  }
  
  int getHeight() { return p.getHeight(); }
  int getWidth() { return p.getWidth(); }
    
  void setMousePressed(boolean mp) { 
    mousePressed = mp; 
  }
  
  void setMouseCoords(int mx, int my) {
    mouseX = mx/p.getPixelSize();
    mouseY = my/p.getPixelSize();
    lastMouseX = mx; 
    lastMouseY = my;
  }
  
  int getLastMouseX() { return lastMouseX; }
  int getLastMouseY() { return lastMouseY; }
  
  void setTouch(int touchNum, float x, float y) {
    lastTouchTimes[touchNum] = millis();
    if (touchNum == 1) {
      mouseX = round(x * width); 
      mouseY = round(y * width);
    }
    
    xTouches[touchNum] = x;
    yTouches[touchNum] = y;    
  }
  
  //void setColorPalette(color[] palette) {
  //  this.palette = palette;
  //}
  
  int getNumColors() { return settings.palette.length; }
  
  color getColor(int index) {
    int numColors = settings.palette.length;
    float bright = settings.getParam("brightness");    
    int cyclingOffset = int(settings.getParam("colorCyclingSpeed")*numColors/40)*frameCount;
    index = (index + cyclingOffset) % numColors;

    // calculate brightness and index offsets for audio beats
    float brightAdjust = 0;
    int audioOffset = 0;
    for (int i=0; i<settings.numBands(); i++) {
      float indRange = numColors/settings.numBands; //basePaletteColors;
      //float indStart = (i-0.5)*indRange
      //if (settings.isBeat(i) && index >= i*indRange && index < (i+1)*indRange) {
        float smooth = sin((index - i*indRange) / indRange * PI / 2);  // 1% cpu
        brightAdjust += /*settings.beatPos(i) */ (1-bright) * settings.getParam("audioBrightnessChange" + (i+1));
        audioOffset += smooth * int(settings.beatPos(i) * MAX_AUDIO_COLOR_OFFSET * settings.getParam("audioColorChange" + (i+1)));
      //}
    }

    //println(audioOffset);
    int ind = (index + audioOffset + numColors) % numColors;
    color col = settings.palette[ind];
    
    colorMode(RGB);
    short r = rgbGamma[(int)red(col)][0];
    short g = rgbGamma[(int)green(col)][1];
    short b = rgbGamma[(int)blue(col)][2];
    col = color(r, g, b);
    
    // adjust saturation
    colorMode(HSB);
    col = color(hue(col), constrain(saturation(col), MIN_SATURATION, 255), brightness(col));

    // cap max brightness on each RGB channel
    colorMode(RGB);
    col = color(constrain(red(col), 0, (bright+brightAdjust)*255), constrain(green(col), 0, (bright+brightAdjust)*255), constrain(blue(col), 0, (bright+brightAdjust)*255));
    
    return col;
  }

  boolean isTouching(int touchNum, int[] xy, long touchCutoffTime) {
    if (xy != null) {
      xy[0] = int(xTouches[touchNum] * (width-1) + 0.5);
      xy[1] = int(yTouches[touchNum] * (height-1) + 0.5);
    }
    
    return millis() - lastTouchTimes[touchNum] <= touchCutoffTime;
  }
  
  // adapted from https://github.com/adafruit/Adavision/blob/master/Processing/WS2801/src/WS2801.java
  // Fancy gamma correction; separate R,G,B ranges and exponents:
  double lastGamma = 0;
  private void setGamma(double gamma) {
    if (gamma != lastGamma) {
      setGamma(0, 255, gamma, 0, 255, gamma, 0, 255, gamma);
      lastGamma = gamma;
    }
  }
  private void setGamma(int rMin, int rMax, double rGamma,
	        int gMin, int gMax, double gGamma,
	        int bMin, int bMax, double bGamma) {
    double rRange, gRange, bRange, d;

    rRange = (double)(rMax - rMin);
    gRange = (double)(gMax - gMin);
    bRange = (double)(bMax - bMin);

    for(short i=0; i<256; i++) {
      d = (double)i / 255.0;
      rgbGamma[i][0] = (short)(rMin + (int)Math.floor(rRange * Math.pow(d,rGamma) + 0.5));
      rgbGamma[i][1] = (short)(gMin + (int)Math.floor(gRange * Math.pow(d,gGamma) + 0.5));
      rgbGamma[i][2] = (short)(bMin + (int)Math.floor(bRange * Math.pow(d,bGamma) + 0.5));
    }
  }  
}
