// Visualization of an idealised Belousov-Zhabotinsky reaction
// Adapted from http://www.aac.bartlett.ucl.ac.uk/processing/samples/bzr.pdf
// Custom1: color gradient density; Custom2: 
  // TODO: zoom out on custom2; more colors in palette activated on beat

class Bzr3 extends Drawer {
  float [][][] a, b, c;
  int p = 0, q = 1;
  int state = 0;
  int PRESS_RADIUS = 1;
  int w = 64, h = 34; 
  
  Bzr3(Pixels p, Settings s) {
    super(p, s);
    a = new float [ w ][ h ][2];  
    b = new float [ w ][ h ][2];  
    c = new float [ w ][ h ][2];
  }
  
  void setup () {
    randomDots(0,0,w,h);
    settings.setParam("brightness", 0.5); // set brightness to 50%    
    settings.setParam("custom1", 0.3);
  }
  
  void reset() {
    randomDots(0,0,w,h);
  }
  
  void draw () {
    int numStates = 20 - int(settings.getParam("speed")*9);    
    
    if (state == 0) {
      for (int x = 0; x < w; x ++) {
        for (int y = 0; y < h; y ++) {
          float c_a = 0.0;
          float c_b = 0.0;
          float c_c = 0.0;
          
          for (int i = x - 1; i <= x +1; i ++) {
            int ii = (i + w) % w;
            for (int j = y - 1; j <= y +1; j ++) {       
              int jj = (j + h) % h;
              c_a += a[ii][jj][p];        
              c_b += b[ii][jj][p];        
              c_c += c[ii][jj][p];        
            }      
          }
          
          c_a /= 9.0;    
          c_b /= 9.0;    
          c_c /= 9.0;
          
          a[x ][ y ][ q] = constrain ( c_a + c_a * ( c_b - c_c ), 0, 1);    
          b[x ][ y ][ q] = constrain ( c_b + c_b * ( c_c - c_a ), 0, 1);    
          c[x ][ y ][ q] = constrain ( c_c + c_c * ( c_a - c_b ), 0, 1);
          
          //set(x,y, color(0.5 ,0.7 , a[x][y][q]));      
        }  
      }
        
      if (p == 0) {    
        p = 1; q = 0;    
      } else {    
        p = 0; q = 1;
      }
    }
    
    //interpolate between p and q to allow slowing things down
    pg.loadPixels();
    for (int x=0; x<width; x++) {
      for (int y=0; y<height; y++) {
        float a2 = a[x][y][p]*state/float(numStates) + a[x][y][q]*(numStates-state)/float(numStates);
        color c = getColor(int(a2*(getNumColors()-1)*settings.getParam("custom1"))); // 2% cpu
        pg.pixels[y*width + x] = c;
      }
    }
    pg.updatePixels();

    int[] xy = new int[2];
    for (int i=0; i<MAX_TOUCHES; i++) {
      if (isTouching(i, xy, 100)) {
        highDots(constrain(xy[0]-PRESS_RADIUS, 0, w), constrain(xy[1]-PRESS_RADIUS, 0, h), constrain(xy[0]+PRESS_RADIUS, 0, w), constrain(xy[1]+PRESS_RADIUS, 0, h));
      }
    }
      
    state++;
    if (state >= numStates) state = 0;
  }
  
  String getName() { return "Belousov-Zhabotinsky Reaction"; }

  void randomDots(float minx, float miny, float maxx, float maxy) {
    for (int y = int(miny); y < int(maxy); y++) {
      for (int x = int(minx); x < int(maxx); x++) {
        a[x][y][p] = random(0.0, 1.0);
        b[x][y][p] = random(0.0, 1.0);
        c[x][y][p] = random(0.0, 1.0);
      }
    }
  }

  void highDots(float minx, float miny, float maxx, float maxy) {
    for (int y = int(miny); y < int(maxy); y++) {
      for (int x = int(minx); x < int(maxx); x++) {
        a[x][y][p] = 1;
        b[x][y][p] = 1;
        c[x][y][p] = 1;
      }
    }
  }
}
