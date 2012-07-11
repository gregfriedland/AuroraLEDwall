// Class to keep track of the current palette mode and current palette gradient colors.

import colorLib.calculation.*;
import colorLib.*;
import colorLib.webServices.*;
import toxi.color.*;
import toxi.color.theory.*;
import toxi.util.datatypes.*;

class PaletteManager {
  Kuler k;
  Palette[] kPs;
  int kPalInd = 0;
  int PT_KULER=0;
  int paletteType = PT_KULER;
  ArrayList ptStrategies = ColorTheoryRegistry.getRegisteredStrategies();
  int NUM_PT = 1 + ptStrategies.size();
  int basePaletteColors = -1;
  
  void init(PApplet pa) {
    kPs = new Palette[21];
  
    // the first palette should be the basic full saturation/brightness HSB colors
    colorMode(HSB);
    color[] hsbWheel = new color[256];
    for (int i=0; i<256; i++) {
      hsbWheel[i] = color(i,255,255);
    }
    kPs[0] = new Palette(pa, hsbWheel);
    
    k = new Kuler(pa);
    k.setKey("5F5D21FE5CA6CBE00A40BD4457BAF3BA");
    k.setNumResults(20);
      
    KulerTheme[] kt = (KulerTheme[]) k.getHighestRated();
    for (int i=0; i<kt.length; i++) {
      kPs[i+1] = kt[i];
      kPs[i+1].addColor(kPs[i+1].getColor(0));
    }
  }
  
  void getNewPalette(int numColors, color[] colors) {
    color[] c;
    println("Advancing to next palette");

    //color[] colors = new color[numColors];
    colorMode(RGB, 255);
    
    if (paletteType == PT_KULER) {
      kPalInd = (kPalInd + 1) % kPs.length;
      Palette p = kPs[kPalInd];
      basePaletteColors = p.totalSwatches();      
      
      Gradient g = new Gradient(p, numColors, false);
      for (int i=0; i<g.totalSwatches(); i++) {
        colors[i] = g.getColor(i);
      }
    } else {
      ColorTheoryStrategy s = (ColorTheoryStrategy) ptStrategies.get(paletteType-1);
      TColor col = ColorRange.BRIGHT.getColor();
      ColorList colList = ColorList.createUsingStrategy(s, col);
      basePaletteColors = colList.size();
      
      ColorGradient grad = new ColorGradient();
      for (int i=0; i<colList.size(); i++) {
        grad.addColorAt(float(i)*numColors/colList.size(), colList.get(i));
      }
      grad.addColorAt(numColors-1, colList.get(0));
      ColorList colList2 = grad.calcGradient(0, numColors);
      
      for (int i=0; i<colList2.size(); i++) {
        colors[i] = colList2.get(i).toARGB();
      }
    }
  }
  
  int basePaletteColors() { return this.basePaletteColors; }
  
  void nextPaletteType() {
    paletteType = (paletteType + 1) % NUM_PT;    
  } 
  
  String getPaletteType() {
    if (paletteType == PT_KULER) {
      return "Kuler";
    } else {
      ColorTheoryStrategy s = (ColorTheoryStrategy) ptStrategies.get(paletteType-1);
      return s.getName();
    }
  }
}
