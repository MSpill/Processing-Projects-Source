
float gravity = 3;
float time = 0.1;
ArrayList<Grav> gravObs;
PGraphics pg;
PGraphics pg2;
int numBodies;

float scaleFactor = 1.5;

void setup()
{
  size (screenWidth * 0.8, screenWidth * 0.8 * 0.6, P2D);
  pg = createGraphics(screenWidth * 0.8, screenWidth * 0.8 * 0.6, P2D);
  pg2 = createGraphics(pg.width, pg.height, P2D);
  scaleFactor = pg.width / 1000.0;
  pg.colorMode(HSB);
  pg2.colorMode(HSB);
  frameCount = 0;
  gravObs = new ArrayList<Grav>();
  pg.background (255);
  pg2.background (255);
  numBodies = (int)random(20,20);
  float maxMass = random(300,400)/(numBodies/20.0);
  for (int i = 0; i < numBodies; i++) {
    float[] col = {random(255), random(170, 255), random(150, 255)};
    gravObs.add(new Grav (random(100,900), random(100,500), random(-2, 2), random(-2, 2), random(maxMass/2.0, maxMass*1.5), col, false));
  }
};
void draw()
{
  pg.beginDraw();
  pg.noStroke();
  pg.fill(255, 0, 255, 10);
  pg.rect(0, 0, pg.width, pg.height);
  if (frameCount < 15*60) {
    for (int v = 0; v < 1; v++) {
      for (int i = 0; i < gravObs.size(); i++){
        gravObs.get(i).update();
        gravObs.get(i).draw();
      }
    }
    pg.fill (0);
    image(pg, 0, 0, width, height);
  } else if (frameCount > 22*60) {
    setup();
  } else {
    image(pg2, 0, 0, width, height);
  }
  pg.endDraw();
};
void mousePressed() {
  float maxMass = random(500,600)/(numBodies/20.0);
  float[] col = {random(255), random(170, 255), random(150, 255)};
  gravObs.add(new Grav (map(mouseX, 0, width, 0, 1000), map(mouseY, 0, height, 0, 600), random(-2, 2), random(-2, 2), random(maxMass/2.0, maxMass*1.5), col, false));
}

float Angle(float x, float y, float endx, float endy)
{
  float Angle = 0;
  float angle = (degrees(acos((endx - x)/dist(x, y, endx, endy))));
  if (angle <= 90 && endy <= y)
  {
    Angle = 90 - angle;
  }
  if (angle > 90 && endy <= y)
  {
    Angle = 450 - angle;
  }
  if (endy > y)
  {
    Angle = angle + 90;
  }
  return Angle;
};
float findAngle (float angle1, float angle2)
{
  if (max (angle1, angle2) - min (angle1, angle2) <= 180)
  {
    return max (angle1, angle2) - min (angle1, angle2);
  } else {return 360 - max (angle1, angle2) + min (angle1, angle2);}
};
float revAngleX (float Angle, float length)
{
  if (Angle < 90 && Angle >= 0)
  {
    return cos(radians(-(Angle - 90))) * length;
  }
  if (Angle < 180 && Angle >= 90)
  {
    return cos(radians(Angle - 90)) * length;
  }
  if (Angle < 270 && Angle >= 180)
  {
    return cos(radians(Angle - 90)) * length;
  }
  if (Angle < 360 && Angle >= 270)
  {
    return cos(radians(-(Angle - 450))) * length;
  }else {return 0;}
};
float revAngleY (float Angle, float length)
{
  float y =  sqrt(sq (length) - sq (revAngleX (Angle, length)));
  if ((Angle > 270 && Angle <= 360) || (Angle > 0 && Angle <=90))
  {
    return -y;
  } else {return y;}
}

class Grav
{
  float x;
  float y;
  float xv;
  float yv;
  float mass;
  float radius;
  boolean alive = true;
  boolean coll = true;
  boolean fragment;
  int life = 0;
  float[] col;
  int index;
  Grav (float x, float y, float xv, float yv, float mass, float[] col, boolean fragment) {
    this.x = x;
    this.y = y;
    this.xv = xv;
    this.yv = yv;
    this.mass = mass;
    this.col = col;
    this.fragment = fragment;
    radius = sqrt(mass/3.14);
    index = gravObs.size();
  }
  void update() {
    if (alive){
      life += 10*time;
      if (coll) {
        coll = false;
        for (int i = 0; i < gravObs.size(); i++) {
          Grav g = gravObs.get(i);
          float d = dist (x, y, g.x, g.y);
          if (i != index && d <= radius + g.radius) {
            coll = true;
          }
        }
        if (life > 5) {
          coll = false;
        }
      }
      if (life > 60/time) {
         fragment = false;
      }
      for (int i = index+1; i < gravObs.size(); i++){
        Grav g = gravObs.get(i);
        if (g.alive && alive) {
          float d = dist (x, y, g.x, g.y);
          float force = gravity*((mass*g.mass)/(d*d))*time;
          xv += force*((g.x-x)/d)/mass;
          yv += force*((g.y-y)/d)/mass;    
          g.xv += force*((x-g.x)/d)/g.mass;
          g.yv += force*((y-g.y)/d)/g.mass;
          if (d <= (radius + g.radius) && coll == false && g.coll == false && (fragment == false || g.fragment == false)) {
            if (g.mass < mass) {
              g.alive = false;
              if (g.mass > 3) {
                for (int n = 0; n < 7; n++) {
                  boolean frag = true;
                  if (g.mass/7 > 10000) {
                    frag = false;
                  }
                  float[] newCol = {g.col[0]+random(-12, 12),g.col[1]+random(-12, 12),g.col[2]+random(-12, 12)};
                  gravObs.add(new Grav(random(g.x-g.radius/2.5, g.x+g.radius/2.5), random(g.y-g.radius/2.5, g.y+g.radius/2.5), random(-2.5, 2.5) + xv, random(-2.5, 2.5) + yv, g.mass/7, newCol, frag));
                }
              } else {
                mass += g.mass;
              }
            } else {
              alive = false;
              if (mass > 3) {
                for (int n = 0; n < 7; n++) {
                  boolean frag = true;
                  if (mass/7 > 10000) {
                    frag = false;
                  }
                  float[] newCol = {col[0]+random(-12, 12),col[1]+random(-12, 12),col[2]+random(-12, 12)};
                  gravObs.add(new Grav(random(x-radius/2.5, x+radius/2.5), random(y-radius/2.5, y+radius/2.5), random(-2.5, 2.5) + g.xv, random(-2.5, 2.5) + g.yv, mass/7, newCol, frag));
                }
              } else {
                g.mass += mass;
              }
            }
          }
        }
      }
      x += xv*time;
      y += yv*time;
      life += 1;
      if (int(life/600) == life/600) {
        radius = sqrt(mass/3.14);
      }
      if (x < radius/2 || x > 1000-radius/2) {
        xv *= -0.2;
        if (x < radius/2) {
          x = radius/2;
        } else {
          x = 1000-radius/2;
        }
      }
      if (y < radius/2 || y > 600-radius/2) {
        yv *= -0.2;
        if (y < radius/2) {
          y = radius/2;
        } else {
          y = 600-radius/2;
        }
      }
    }
    if (dist(0, 0, xv, yv) > 100) {
      alive = false;
    }
  }
  void draw() {
    if (alive) {
      pg.fill (max(min(col[0],255),0), max(min(col[1],255),0), max(min(col[2],255),0), 255);
      pg.stroke(max(min(col[0],255),0), max(min(col[1],255),0), max(min(col[2],255),0), 255);
      pg.ellipse (x * scaleFactor, y * scaleFactor, radius*2*scaleFactor, radius*2*scaleFactor);
      pg2.fill (max(min(col[0],255),0), max(min(col[1],255),0), max(min(col[2],255),0), 255);
      pg2.stroke(max(min(col[0],255),0), max(min(col[1],255),0), max(min(col[2],255),0), 255);
      pg2.ellipse (x * scaleFactor, y * scaleFactor, radius*2*scaleFactor, radius*2*scaleFactor);
    }
  };
};