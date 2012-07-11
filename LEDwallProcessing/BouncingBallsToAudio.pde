// Visualization of balls synchronized to bounce with the audio beat; mostly for testing.

class BouncingBallsToAudio extends BouncingBalls2D {  
  BouncingBallsToAudio(Pixels p, Settings s) {
    super(p, s);    

    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    bbox = new Bbox(new Vec2D(width, height));
    for (int i=0; i<3; i++) {
      float radius = 3;
      float mass = radius*radius;
      color col = color(0, 1.0, 1.0);
      
      Vec2D pos = new Vec2D((i+1)*bbox.getDims().x/4.0, 1.0/3*bbox.getDims().y);
      Vec2D dpos = new Vec2D(0,0);
      balls.add(new ball(bbox, pos, dpos, radius, col, mass));
    }      
  }
  
  void addBall() {
  }
  
  void reset() {
  }
  
  // y = y0 + 1/2*a*t*t
  // y1 = y0 + 1/2*a*0.5*0.5; a = (y1-y0)*8
  float getYPos(float radius, float t) {
    float y0 = 1.0/3.0*bbox.getDims().y;
    float y1 = bbox.getDims().y - radius;
    float a = (y1-y0)*8;
    
    if (t > 0.5) t = 1 - t;
    return y0 + 1.0/2.0*a*t*t;
  }    
  
  void setup() {
  }

  void draw() {
    for(int i=0; i< balls.size();i++) {    
      balls.get(i).pos.y = getYPos(balls.get(i).radius, settings.beatPosSimple(i));
    }

    pg.background(0);
    pg.noStroke();    
    for (int i=0; i<balls.size(); i++) {
      balls.get(i).draw(pg);
    }
  }
}
