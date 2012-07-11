// The main sketch

import oscP5.*;
import netP5.*;
import ddf.minim.analysis.*;
import ddf.minim.*;
import java.util.Arrays;
import java.lang.reflect.Method;
import java.util.List;

int W = 32;
int H = 17;
int S = 5;
int baud = 921600;
Pixels px;
SerialPacketWriter spw;
Console console;

OscP5 oscP5;
NetAddress oscReceiver;
int NUM_COLORS = 512;
//int FRAME_RATE = 100;

HashMap controlInfo;
float DEFAULT_GAMMA = 2.5;

// Audio
BeatDetect bd;
int HISTORY_SIZE = 50;
int SAMPLE_SIZE = 1024;
int NUM_BANDS = 3;
boolean[] analyzeBands = {true, true, true };
int SAMPLE_RATE = 44100;
//AudioSocket signal;
AudioInput in;
AudioOutput out;
FFT fft;
Minim minim;
int MAX_BEAT_LENGTH = 750, MAX_AUDIO_SENSITIVITY = 12;

Drawer[] modes;
int modeInd = 0;

PaletteManager pm = new PaletteManager();
Settings settings = new Settings(NUM_BANDS);

void setup() {
  size(W*S, H*S);
  
  // redirect stdout/err
  try {
    console = new Console();
  } catch(Exception e) {
    println("Error redirecting stdout/stderr: " + e);
  }
  
  try {
    px = new Pixels(this, W, H, S, baud); 
    println("### Started at " + baud);
  } catch (Exception e) {
    baud = 0;
    px = new Pixels(this, W, H, S, baud);
    println("### Started in standalone mode");
  }
  
  modes = new Drawer[] { new Paint(px, settings), new Bzr3(px, settings), 
                         new Fire(px, settings), new AlienBlob(px, settings), new BouncingBalls2D(px, settings) }; 

  initOSC();

  modes[modeInd].setup();

  pm.init(this);
  updatePaletteType();
  newPalette();  
  
  // Audio features
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, SAMPLE_SIZE, SAMPLE_RATE);
  fft = new FFT(SAMPLE_SIZE, SAMPLE_RATE);  

  bd = new BeatDetect(fft, NUM_BANDS, HISTORY_SIZE);
  for (int i=0; i<NUM_BANDS; i++) bd.analyzeBand(i, analyzeBands[i]);
  bd.setFFTWindow(FFT.HAMMING);

  frameRate(SAMPLE_RATE/SAMPLE_SIZE);
  println("Done setup");
}

//long lastDraw = millis();
void draw() {
  if (key == ' ') return;
  
  for (int i=0; i<NUM_BANDS; i++) {
    bd.setSensitivity(i, settings.getParam("audioSensitivity" + (i+1)) * MAX_AUDIO_SENSITIVITY, (int)(settings.getParam("beatLength")*MAX_BEAT_LENGTH));
  }
  bd.update(in.mix);
  for (int i=0; i<NUM_BANDS; i++) settings.setIsBeat(i, bd.isBeat("spectralFlux", i));

//  if (millis() - lastDraw < 1000.0/FRAME_RATE) return;
  
  Drawer d = modes[modeInd];

  if (settings.palette == null) return;

  d.setMousePressed(mousePressed);
  
  if (d.getLastMouseX() != mouseX || d.getLastMouseY() != mouseY) {
    d.setMouseCoords(mouseX, mouseY);
  }
  
//  sendParamsOSC();
  d.update();                        
  px.drawToScreen();                 
  if (baud != 0) px.drawToLedWall(); 
  
//  lastDraw = millis();  
}

void newPalette() {
  settings.palette = new color[NUM_COLORS];
  pm.getNewPalette(NUM_COLORS, settings.palette);
}

void newPaletteType() {
  pm.nextPaletteType();
  newPalette();
  updatePaletteType();
}

void newProgram() {
  modeInd = (modeInd + 1) % modes.length;
  modes[modeInd].setup();
  updateModeName();
  println("Advancing to next mode");
}


interface VoidFunction { void function(); }
interface FunctionFloatFloat { void function(float x, float y); }

void reset() {
  modes[modeInd].reset();
}

void touchXY(int touchNum, float x, float y) {
  if (frameCount % 10 == 0) println("Touch" + touchNum + " at " + nf(x,1,2) + " " + nf(y,1,2));
  modes[modeInd].setTouch(touchNum, x, y);
}

void tap() {
}


void initOSC() {
  oscP5 = new OscP5(this,8000);
  oscReceiver = new NetAddress("192.168.1.100",9000);

  // define param info: name -> OSC control
  controlInfo = new HashMap();
  controlInfo.put("/1/fader1", Arrays.asList("speed", 0.3));
  controlInfo.put("/1/fader2", Arrays.asList("colorCyclingSpeed", 0.3));
  controlInfo.put("/1/fader3", Arrays.asList("custom1", 0.3));
  controlInfo.put("/1/fader4", Arrays.asList("custom2", 0.3));
  controlInfo.put("/1/multixy1/1", Arrays.asList("touchxy", new FunctionFloatFloat() { public void function(float x, float y) { touchXY(1, x, y); }}));
  controlInfo.put("/1/multixy1/2", Arrays.asList("touchxy", new FunctionFloatFloat() { public void function(float x, float y) { touchXY(2, x, y); }}));
  controlInfo.put("/1/multixy1/3", Arrays.asList("touchxy", new FunctionFloatFloat() { public void function(float x, float y) { touchXY(3, x, y); }}));
  controlInfo.put("/1/multixy1/4", Arrays.asList("touchxy", new FunctionFloatFloat() { public void function(float x, float y) { touchXY(4, x, y); }}));
  controlInfo.put("/1/multixy1/5", Arrays.asList("touchxy", new FunctionFloatFloat() { public void function(float x, float y) { touchXY(5, x, y); }}));
  controlInfo.put("/1/rotary1", Arrays.asList("brightness", 0.5));
  controlInfo.put("/1/push1", Arrays.asList("newProgram", new VoidFunction() { public void function() { newProgram(); } }));
  controlInfo.put("/1/push2", Arrays.asList("newPaletteType", new VoidFunction() { public void function() { newPaletteType(); } }));
  controlInfo.put("/1/push3", Arrays.asList("newPalette", new VoidFunction() { public void function() { newPalette(); } }));
  controlInfo.put("/1/push4", Arrays.asList("reset", new VoidFunction() { public void function() { reset(); } }));
  controlInfo.put("/2/multifader1/1", Arrays.asList("audioSpeedChange1", 0.0));
  controlInfo.put("/2/multifader1/2", Arrays.asList("audioSpeedChange2", 0.0));
  controlInfo.put("/2/multifader1/3", Arrays.asList("audioSpeedChange3", 0.0));
  controlInfo.put("/2/multifader2/1", Arrays.asList("audioColorChange1", 0.0));
  controlInfo.put("/2/multifader2/2", Arrays.asList("audioColorChange2", 0.0));
  controlInfo.put("/2/multifader2/3", Arrays.asList("audioColorChange3", 0.0));
  controlInfo.put("/2/multifader3/1", Arrays.asList("audioBrightnessChange1", 0.0));
  controlInfo.put("/2/multifader3/2", Arrays.asList("audioBrightnessChange2", 0.0));
  controlInfo.put("/2/multifader3/3", Arrays.asList("audioBrightnessChange3", 0.0));
  controlInfo.put("/2/multifader4/1", Arrays.asList("audioSensitivity1", 0.0));
  controlInfo.put("/2/multifader4/2", Arrays.asList("audioSensitivity2", 0.0));
  controlInfo.put("/2/multifader4/3", Arrays.asList("audioSensitivity3", 0.0));
  controlInfo.put("/2/push1", Arrays.asList("tap",new VoidFunction() { public void function() { tap(); } }));
  controlInfo.put("/2/rotary1", Arrays.asList("beatLength", 0.5));
  
  for (Object controlName : controlInfo.keySet()) {
    List al = (List) controlInfo.get(controlName);
    if (al.size() > 1) {
      try {
        String name = (String) al.get(0);
        float val = ((Float)(al.get(1))).floatValue();
        settings.setParam(name, val);
      
        OscMessage myMessage = new OscMessage((String)controlName);
        myMessage.add(val);
        oscP5.send(myMessage, oscReceiver);
      } catch (java.lang.ClassCastException e) {
      }
    }
  }
  
  updateModeName();
}  

void updateModeName() {
  String name = modes[modeInd].getName();
  OscMessage myMessage = new OscMessage("/1/mode/");
  myMessage.add(name);
  oscP5.send(myMessage, oscReceiver);
}

void updatePaletteType() {
  OscMessage myMessage = new OscMessage("/1/palette/");
  myMessage.add(pm.getPaletteType());
  oscP5.send(myMessage, oscReceiver);
}  

// send param values to the iPad if they've been updated from within the mode
//void sendParamsOSC() {
//  for (int i=0; i<lastParams.length; i++) {
//    if (currParams[i] != lastParams[i]) {
//      println("Setting param " + i + " value from mode via OSC: " + currParams[i]);
//      OscMessage myMessage;
//      if (i < NUM_FADERS) {
//        myMessage = new OscMessage("/1/fader" + (i+1) + "/");
//      } else { 
//        myMessage = new OscMessage("/1/rotary" + (i+1-NUM_FADERS) + "/");
//      }
//      
//      myMessage.add(currParams[i]);
//      oscP5.send(myMessage, oscReceiver);
//      
//      lastParams[i] = currParams[i];
//    }
//  }
//}

/* unplugged OSC messages */
void oscEvent(OscMessage msg) {
  String addr = msg.addrPattern();

  for (Object controlName : controlInfo.keySet()) {
    String s = (String) controlName;
    List al = (List) controlInfo.get(controlName);
    String paramName = (String) al.get(0);
    //println(addr + " " + s);
    if (addr.equals(s)) {
      if (s.indexOf("fader") >= 0 || s.indexOf("rotary") >= 0) {
        settings.setParam(paramName, msg.get(0).floatValue());
        println("Set " + paramName + " to " + msg.get(0).floatValue());
        return; 
      } else if (s.indexOf("push") >= 0) {
        if (msg.get(0).floatValue() != 1.0) {
          VoidFunction fun = (VoidFunction) al.get(1);
          fun.function();
        }
        return;
      } else if (s.indexOf("multixy") >= 0) {
        FunctionFloatFloat fun = (FunctionFloatFloat) al.get(1);
        fun.function(msg.get(0).floatValue(), msg.get(1).floatValue());
        return;
      }
    }
  }
  
  print("### Received an unhandled osc message: " + msg.addrPattern() + " " + msg.typetag() + " ");
  Object[] args = msg.arguments();
  for (int i=0; i<args.length; i++) {
    print(args[i].toString() + " ");
  }
  println();
}


class Settings {  
  private color[] palette;
  private float[] params;
  private boolean[] isBeat;
  private HashMap paramMap;
  private int numBands;
  private int basePaletteColors = 1;
  
  Settings(int numBands) {
    this.numBands = numBands;
    isBeat = new boolean[numBands];
    paramMap = new HashMap();
  }
  
  int numBands() { return numBands; }
  
  void setParam(String paramName, float value) { paramMap.put(paramName, value); }
  //float getParam(String paramName) { println(paramMap.keySet()); println(paramName); return (Float) paramMap.get(paramName); }
  float getParam(String paramName) { 
    if (paramName.equals("speed")) {
      float speed = (Float) paramMap.get(paramName);
      for (int i=0; i<NUM_BANDS; i++) {
        if (isBeat(i)) {
          speed += beatPos(i)*(Float)paramMap.get("audioSpeedChange" + (i+1));
        }
      }
      return constrain(speed, 0, 1);
    }
    
    if (paramName.startsWith("audioSensitivity")) return 1 - (Float)paramMap.get(paramName);
    
    return (Float) paramMap.get(paramName); 
  }
  
  void setPalette(color[] p, int basePaletteColors) { 
    palette = p; 
    this.basePaletteColors = basePaletteColors;
  }
  color[] getPalette() { return palette; }
  int basePaletteColors() { return basePaletteColors; }
  boolean isBeat(int band) { return isBeat[band]; }
  void setIsBeat(int band, boolean state) { isBeat[band] = state; }
  float beatPos(int band) { return bd.beatPos("spectralFlux", band); }
  float beatPosSimple(int band) { return bd.beatPosSimple("spectralFlux", band); }
}
