// Visualization to allow painting on the LEDwall as if it were a canvas.
// Custom1: zero is the basic drawing mode; values greater than zero specify a disappearing tail

class Paint extends Drawer {
  int MAX_TAIL_LENGTH = 100;
  int[][] canvas;
  int[][] tailX, tailY;
  int tailInd;
  
  Paint(Pixels p, Settings s) {
    super(p ,s);
    canvas = new int[width][height];
    tailX = new int[MAX_TAIL_LENGTH][MAX_TOUCHES];
    tailY = new int[MAX_TAIL_LENGTH][MAX_TOUCHES];
    for (int i=0; i<MAX_TOUCHES; i++) {
      for (int j=0; j<MAX_TAIL_LENGTH; j++) {
        tailX[j][i] = tailY[j][i] = -1;
      }
    }
    tailInd = 0;
  }
  
  String getName() { return "Paint"; }
  
  void setup() {
     settings.setParam("brightness", 0.8); // set brightness to 80%    
     settings.setParam("custom1", 0);
  }

  void reset() {
    clear();
  }  
  
  void draw() { 
    //if (int(getParam(2) + 0.5) == 1) clear();
    pg.background(0);
    int tailLength = round(settings.getParam("custom1")*MAX_TAIL_LENGTH);
    
    for (int i=0; i<MAX_TOUCHES; i++) {
      tailX[tailInd][i] = -1;
      tailY[tailInd][i] = -1;

      int[] xy = new int[2];
      if (isTouching(i, xy, 100)) {
        if (tailLength == 0) {
          canvas[xy[0]][xy[1]] = (frameCount + i * getNumColors() / MAX_TOUCHES) % (getNumColors() - 1) + 1;
        } else {
          tailX[tailInd][i] = xy[0];
          tailY[tailInd][i] = xy[1];
        //println(xy[0] + " " + xy[1] + " " + canvas[xy[0]][xy[1]]);
        }
      }
    }
     
    if (tailLength == 0) {
      for (int x=0; x<width; x++) {
        for (int y=0; y<height; y++) {
          pg.set(x, y, getColor(canvas[x][y]));
        }
      }
    } else {
      for (int i=0; i<MAX_TOUCHES; i++) {
        for (int j=0; j<tailLength; j++) {
          int ind = (tailInd - j + MAX_TAIL_LENGTH) % MAX_TAIL_LENGTH;
          int x = tailX[ind][i];
          int y = tailY[ind][i];
          if (x != -1 && y != -1) {
            pg.set(x,y, getColor((frameCount + i * getNumColors() / MAX_TOUCHES) % (getNumColors() - 1) + 1));
          }
        }
      }
    }
    tailInd = (tailInd + 1) % MAX_TAIL_LENGTH;
  }

  void clear() {
    for (int x=0; x<width; x++) {
      for (int y=0; y<height; y++) {
        canvas[x][y] = 0;
      }
    }
  }
  
  color getColor(int index) {
    if (index == 0) return color(0,0,0);
    else return super.getColor(index);
  }

}
