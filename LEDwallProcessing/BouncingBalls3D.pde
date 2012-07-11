// Visualization of bouncing balls in 3D: needs some work to get it going again.

import toxi.geom.*;

class BouncingBalls3D extends Drawer {
  int NUM_DIMS = 3;
  ball3D[] balls = new ball3D[2];
  int depth = 40, maxRadius = 9, minRadius = 3;
  Bbox3D bbox;
  float startMomentum = 30;
  float maxMass = 4/3*maxRadius*maxRadius*maxRadius;
  Vec3D gravity = new Vec3D(0, 0.006, 0);
  
  BouncingBalls3D(Pixels p, Settings s) {
    super(p, s, P3D);
  }
  
  String getName() { return "BouncingBalls3D"; }

  void setup() {
    colorMode(HSB, 1.0);
    pg.colorMode(HSB, 1.0);
    pg.smooth();
    bbox = new Bbox3D(new Vec3D(width, height, depth));
    
    for(int i=0; i<balls.length;i++){
      float radius = (int) random(minRadius, maxRadius);
      float mass = 4 / 3 * radius*radius*radius;
      color col = color(mass/maxMass, 0.5, 1.0);
      
      Vec3D pos = new Vec3D(random(0,bbox.getDims().x), random(0,bbox.getDims().y), 2.0/3*bbox.getDims().z);
      Vec3D dpos = new Vec3D(random(-1, 1), random(-1, 1), random(-1, 1));
      dpos = dpos.normalizeTo(startMomentum/mass);
      balls[i] = new ball3D(bbox, pos, dpos, radius, col, mass);
    }
  }
  
  void draw() {
    for(int i=0; i< balls.length;i++){
      balls[i].update(gravity);
    }
    checkForCollisions();

    pg.beginDraw();
    pg.lights();
    pg.pointLight(255, 255, 255, -width/2, -height/2, depth/2);
    pg.background(0);
    pg.translate(0, 0,  -depth);
    //pg.rotateX(mouseY*.1);
    //pg.rotateY(mouseX*.1);

    bbox.draw(pg);
    
    pg.noStroke();    
    for (int i=0; i<balls.length; i++) {
      balls[i].draw(pg);
    }
  }
  
  void checkForCollisions() {
    for (int i=0; i<balls.length; i++) {
      for (int j=i+1; j<balls.length; j++) {
        balls[i].checkForCollision(balls[j]);
      }
    }
  }
}

class ball3D {
  Vec3D pos, dpos;
  Bbox3D bbox;
  color col;
  float radius, mass, startMomentum;

  ball3D(Bbox3D bbox, Vec3D pos, Vec3D dpos, float radius, color col, float mass) {
    this.pos = pos;
    this.dpos = dpos;
    this.radius = radius;
    this.mass = mass;
    this.col = col;
    this.startMomentum = getMomentum();
    updateColor();
    this.bbox = bbox;  
  }
  
  void updateColor() {
    colorMode(HSB, 1.0);    
    this.col = color(random(1.0), 1.0, 1.0);
  }
  
  float getMomentum() {
    return mass * dpos.magnitude();
  }
  
  void update(Vec3D gravity) {
    dpos.addSelf(gravity.scale(0.5));    
    for (int i=0; i<NUM_DIMS; i++) {
      if(pos.getComponent(i) >= bbox.getDims().getComponent(i) - radius && dpos.getComponent(i) > 0) {
        dpos.setComponent(i, -abs(dpos.getComponent(i)));
        //if (i != 1) col = color((hue(col)+0.1)%1.0, 1.0, 1.0);
        bbox.changeWallColor(i, 1);
        //pos.setComponent(i, bbox.getComponent(i)-1);
      }
      if(pos.getComponent(i) <= radius  && dpos.getComponent(i) < 0) {
        dpos.setComponent(i, abs(dpos.getComponent(i)));
        //col = color((hue(col)+0.1)%1.0, 1.0, 1.0);
        bbox.changeWallColor(i, 0);
        //pos.setComponent(i, 0);
      }
    }

    dpos.addSelf(gravity.scale(0.5));
    pos.addSelf(dpos);    
  }
  
  void checkForCollision(ball3D b) {
    Vec3D diffPos = this.pos.sub(b.pos);
    float d = diffPos.magnitude() - this.radius - b.radius;
    if (d <= 0) {
      //println("collision");
      Vec3D norml = diffPos.getNormalized();
      float aci = this.dpos.dot(norml);
      float bci = b.dpos.dot(norml);
      
      float acf = bci;
      float bcf = aci;
      
      this.dpos.addSelf(norml.scale(acf-aci));
      b.dpos.addSelf(norml.scale(bcf-bci));
      
      this.pos.addSelf(diffPos.scale(-d/2));
      b.pos.addSelf(diffPos.scale(d/2));
      
      // change color
      updateColor();
      b.updateColor();
    }
  }

  void draw(PGraphics pg) {
    pg.translate(pos.x, pos.y, pos.z);
    pg.fill(col);
    //pg.point(pos.x, pos.y, pos.z);
    pg.sphere(radius);
    pg.translate(-pos.x, -pos.y, -pos.z);
  }    
}

class Bbox3D {
  Vec3D dims;
  color[][] wallColors;
  
  Bbox3D(Vec3D dims) {
    colorMode(HSB, 1.0);

    this.dims = dims;
    wallColors = new color[3][2];
    
    for (int i=0; i<3; i++) {
      for (int j=0; j<2; j++) {
        color col = color(random(1.0), 1.0, 0.2);
        wallColors[i][j] = col;
      }
    }
  }
  
  void changeWallColor(int dim, int num) {
    colorMode(HSB, 1.0);
    color col = color(random(1.0), 1.0, 0.2);
    wallColors[dim][num] = col;
  }
  
  void draw(PGraphics pg) {
    //pg.noFill();
    //pg.stroke(100);
    //pg.translate(dims.x/2, dims.y/2, dims.z/2);
    //pg.box(dims.x, dims.y, dims.z);
    //pg.translate(-dims.x/2, -dims.y/2, -dims.z/2);
    
    pg.fill(wallColors[0][0]); pg.beginShape(); pg.vertex(0,0,0); pg.vertex(0,0,dims.z); pg.vertex(0,dims.y,dims.z); pg.vertex(0,dims.y,0); pg.endShape(CLOSE);
    pg.fill(wallColors[0][1]); pg.beginShape(); pg.vertex(dims.x,0,0); pg.vertex(dims.x,0,dims.z); pg.vertex(dims.x,dims.y,dims.z); pg.vertex(dims.x,dims.y,0); pg.endShape(CLOSE);

    pg.fill(wallColors[1][0]); pg.beginShape(); pg.vertex(0,0,0); pg.vertex(0,0,dims.z); pg.vertex(dims.x,0,dims.z); pg.vertex(dims.x,0,0); pg.endShape(CLOSE);
    pg.fill(wallColors[1][0]); pg.beginShape(); pg.vertex(0,dims.y,0); pg.vertex(0,dims.y,dims.z); pg.vertex(dims.x,dims.y,dims.z); pg.vertex(dims.x,dims.y,0); pg.endShape(CLOSE);

    pg.fill(wallColors[2][0]); pg.beginShape(); pg.vertex(0,0,0); pg.vertex(0,dims.y,0); pg.vertex(dims.x,dims.y,0); pg.vertex(dims.x,0,0); pg.endShape(CLOSE);
  }
  
  Vec3D getDims() { return dims; }
}
