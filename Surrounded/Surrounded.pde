/* @pjs preload="/static/projects/Surrounded/data/Bullet.png"; */
/* @pjs preload="/static/projects/Surrounded/data/CrawlFrame1.png"; */
/* @pjs preload="/static/projects/Surrounded/data/CrawlFrame2.png"; */
/* @pjs preload="/static/projects/Surrounded/data/CrawlFrame3.png"; */
/* @pjs preload="/static/projects/Surrounded/data/CrawlFrame4.png"; */
/* @pjs preload="/static/projects/Surrounded/data/Frame1.png"; */
/* @pjs preload="/static/projects/Surrounded/data/Frame2.png"; */
/* @pjs preload="/static/projects/Surrounded/data/planet.png"; */
/* @pjs preload="/static/projects/Surrounded/data/RunFrame1.png"; */
/* @pjs preload="/static/projects/Surrounded/data/RunFrame2.png"; */
/* @pjs preload="/static/projects/Surrounded/data/Still.png"; */

PImage planet;
PImage still;
PImage playerFrame1, playerFrame2;
PImage bullet;
PImage crawlFrame1, crawlFrame2, crawlFrame3, crawlFrame4;
PImage runFrame1, runFrame2;

float speed = 1.2;
boolean movingLeft;
boolean movingRight;
boolean facingLeft;
float playerHeight = 277;
float playerYv;

float playerRotation = 0;
float viewRotation = 0;
float viewSpeed = -0.3;
float prevViewScale = 1.0;
float lastViewMillis = 0;
float viewScale = 1.0;

ArrayList<Bullet> Bullets = new ArrayList<Bullet>();
float bulletSpeed = 5;

ArrayList<Zombie> Zombies = new ArrayList<Zombie>();
float zombieSpeed = 2;

ArrayList<BloodParticle> Blood = new ArrayList<BloodParticle>();

boolean playerAlive = true;

int spawnRate = 180;

int score = 0;
int prevMillis = 0;

ArrayList<Star> frontStars = new ArrayList<Star>();
ArrayList<Star> backStars = new ArrayList<Star>();
float starsXv = 0;
float starsYv = 0;

float sF;

void setup() {
  size (min(screenHeight, screenWidth)*0.85, min(screenHeight, screenWidth)*0.85, P2D);
  sF = width / 800.0;
  planet = loadImage ("/static/projects/Surrounded/data/planet.png");
  still = loadImage ("/static/projects/Surrounded/data/Still.png");
  playerFrame1 = loadImage ("/static/projects/Surrounded/data/Frame1.png");
  playerFrame2 = loadImage ("/static/projects/Surrounded/data/Frame2.png");
  bullet = loadImage ("/static/projects/Surrounded/data/Bullet.png");
  crawlFrame1 = loadImage ("/static/projects/Surrounded/data/CrawlFrame1.png");
  crawlFrame2 = loadImage ("/static/projects/Surrounded/data/CrawlFrame2.png");
  crawlFrame3 = loadImage ("/static/projects/Surrounded/data/CrawlFrame3.png");
  crawlFrame4 = loadImage ("/static/projects/Surrounded/data/CrawlFrame4.png");
  runFrame1 = loadImage ("/static/projects/Surrounded/data/RunFrame1.png");
  runFrame2 = loadImage ("/static/projects/Surrounded/data/RunFrame2.png");
  spawnRate = 180;
  viewScale = 1.1;
  prevViewScale = 1.1;
  playerRotation = 0;
  viewRotation = 0;
  playerHeight = 277;
  playerYv = 0;
  score = 0;
  prevMillis = millis();
  playerAlive = true;
  viewSpeed = 0;
  Bullets = new ArrayList<Bullet>();
  Zombies = new ArrayList<Zombie>();
  Blood = new ArrayList<BloodParticle>();
  frontStars = new ArrayList<Star>();
  backStars = new ArrayList<Star>();
  int numFrontStars = 800;
  for (int i = 0; i < numFrontStars; i++) {
    color frontCol = color (random(-50, 255), random(-50, 255), random(-50, 255));
    frontStars.add(new Star (random(-800.0*1.5, 800.0*1.5), random(-800.00*1.5, 800.00*1.5), random (2, 7), frontCol));
  }
}

void draw() {
  if (playerAlive) {
  background (#000000);
  viewRotation += viewSpeed;
  if (frameCount % spawnRate == 0) {
    for (int n = int(random(1, 4)); n < 4; n++) {
      for (int i = 0; i < 1000; i++) {
        float rand = random(360);
        float thatRot = (playerRotation+360000)%360;
        float dist = 0;
        if (abs(rand-thatRot) < 180) {
          dist = abs(rand-thatRot);
        } else {
          dist = (360 - max(rand, thatRot)) + min (rand, thatRot);
        }
        boolean intersectsOthers = false;
        for (int z = 0; z < Zombies.size(); z++) {
          float thaRot = (Zombies.get(z).rotation+360000)%360;
          float dis = 0;
          if (abs(rand-thaRot) < 180) {
            dis = abs(rand-thaRot);
          } else {
            dis = (360 - max(rand, thaRot)) + min (rand, thaRot);
          }
          if (dis < 25 && Zombies.get(z).alive) {
            intersectsOthers = true;
          }
        }
        if (dist > 90 && !intersectsOthers) {
          Zombies.add(new Zombie (rand, zombieSpeed));
          break;
        }
      }
    }
    viewSpeed = random (-1, 1);
    if (spawnRate > 70) {
      spawnRate -= 6;
    }
  }
  if (frameCount % 120 == 0) {
    prevViewScale = lerp(lerp(prevViewScale, viewScale, min(((float)millis()-lastViewMillis)/300.0, 1)), viewScale, min(((float)millis()-lastViewMillis)/300.0, 1));
    lastViewMillis = millis();
    viewScale = random (0.95, 1.1);
  }
  pushMatrix();
  translate (800.0/2 * sF, (800.00/2+50) * sF);
  for (int i = 0; i < 1000; i++) {
    float prevXv = starsXv;
    float prevYv = starsYv;
    starsXv += random (-0.03, 0.03);
    starsYv += random (-0.03, 0.03);
    if (dist (0, 0, starsXv, starsYv) < 0.6) {
      break;
    } else {
      starsXv = prevXv;
      starsYv = prevYv;
    }
  }
  for (int i = 0; i < frontStars.size(); i++) {
    pushMatrix();
    Star s = frontStars.get(i);
    float otherScale = lerp(lerp(prevViewScale, viewScale, min(((float)millis()-lastViewMillis)/300.0, 1)), viewScale, min(((float)millis()-lastViewMillis)/300.0, 1));
    scale ((1+(otherScale-1)*(s.size/28)) * sF);
    s.x += starsXv*s.size/7;
    s.y += starsYv*s.size/7;
    s.draw();
    popMatrix();
  }
  popMatrix();
  pushMatrix();
  translate (800.0/2 * sF, (800.00/2+50)*sF);
  scale (lerp(lerp(prevViewScale, viewScale, min(((float)millis()-lastViewMillis)/300.0, 1)), viewScale, min(((float)millis()-lastViewMillis)/300.0, 1)) * sF);
  rotate (radians(viewRotation));
  translate (-800.0/2 * sF, (-800.00/2-50) * sF);
  imageMode (CENTER);
  //tint (180);
  image (planet, 800.0/2 * sF, (800.00/2+50) * sF, 500*sF, 500*sF);
  //tint (255);
  updatePlayer();
  for (int i = 0; i < Blood.size(); i++) {
    Blood.get(i).update();
    Blood.get(i).draw();
  }
  pushMatrix();
  translate (800.0/2 * sF, (800.00/2+50) * sF);
  rotate (radians(playerRotation));
  if (facingLeft) {
    scale (-1, 1);
  }
  PImage currentFrame;
  if (!movingLeft && !movingRight) {
    currentFrame = still;
  } else {
    if (frameCount % 20 <= 10) {
      currentFrame = playerFrame1;
    } else {
      currentFrame = playerFrame2;
    }
  }
  image (currentFrame, 5 * sF, -playerHeight * sF, 19*3 * sF, 27*3 * sF);
  popMatrix();
  for (int i = 0; i < Bullets.size(); i++) {
    Bullets.get(i).update();
    Bullets.get(i).draw();
  }
  for (int i = 0; i < Zombies.size(); i++) {
    Zombies.get(i).update();
    Zombies.get(i).draw();
  }
  popMatrix();
  fill(255);
  textSize(40 * sF);
  textAlign(LEFT, TOP);
  text(score, 10 * sF, 10 * sF);
  prevMillis = millis();
  } else {
    background (#952323);
    fill (0);
    textAlign (CENTER);
    textSize (50 * sF);
    text ("Score: " + score, 800.0/2 * sF, 800.00/2 * sF);
    if (frameCount % 60 == 0) {
      frameCount = 0;
      setup();
    }
  }
}

void updatePlayer () {
  if (movingLeft) {
    playerRotation -= speed;
  } else if (movingRight) {
    playerRotation += speed;
  }
  playerYv -= 1;
  playerHeight += playerYv;
  if (playerHeight < 277) {
    playerHeight = 277;
  }
}

void keyPressed() {
  if (key == ' ') {
    if (facingLeft) {
      Bullets.add(new Bullet (playerRotation-5.5, playerHeight + 16, -bulletSpeed));
    } else {
      Bullets.add(new Bullet (playerRotation+5.5, playerHeight + 16, bulletSpeed));
    }
  }
  if (keyCode == LEFT) {
    movingLeft = true;
    facingLeft = true;
    movingRight = false;
  } else if (keyCode == RIGHT) {
    movingRight = true;
    facingLeft = false;
    movingLeft = false;
  } else if (keyCode == UP && playerHeight <= 277) {
    playerYv = 15;
  }
}

void keyReleased() {
  if (keyCode == LEFT) {
    movingLeft = false;
  } else if (keyCode == RIGHT) {
    movingRight = false;
  }
}

class BloodParticle {
  float rotation, h, xv, yv;
  boolean hitGround = false;
  color groundCol;
  boolean showGround = false;
  int life;
  BloodParticle (float rotation, float h, float xv, float yv) {
    this.rotation = rotation;
    this.h = h;
    this.xv = xv;
    this.yv = yv;
    life = 180;
    groundCol = color (random(120, 170), random(50), random(50));
  }
  void draw() {
    if (showGround || !hitGround) {
      pushMatrix();
      translate (800.0/2 * sF, (800.00/2+50) * sF);
      rotate (radians(rotation));
      if (hitGround) {
        fill (groundCol);
      } else {
        fill (#DA1111);
      }
      noStroke();
      rect (0, -h * sF, 6*sF, 6*sF);
      popMatrix();
      life--;
      if (life <= 0) {
        showGround = false;
      }
    }
  }
  void update() {
    if (!hitGround) {
      float x, y, rot;
      rot = (rotation+90+360000)%360;
      x = revAngleX (rot, h);
      y = revAngleY (rot, h);
      float gravStrength = 50000.0/pow(h, 2);
      xv -= revAngleX (rot, gravStrength);
      yv -= revAngleY (rot, gravStrength);
      x += xv;
      y += yv;
      float newRot = Angle (0, 0, x, y);
      rotation = (newRot-90+360000)%360;
      h = dist (0, 0, x, y);
      if (h < 260) {
        hitGround = true;
        if (random(1) < 0.2) {
          showGround = true;
        }
        h -= random(random(random(60)));
      }
    }
  }
}

class Bullet {
  float rotation, h, speed;
  boolean alive;
  Bullet (float rotation, float h, float speed) {
    this.rotation = rotation;
    this.h = h;
    this.speed = speed;
    alive = true;
  }
  void draw() {
    if (alive) {
    pushMatrix();
    translate (800.0/2 * sF, (800.00/2+50) * sF);
    rotate (radians(rotation));
    if (speed <= 0) {
      scale (-1, 1);
    }
    image (bullet, 11 * sF, -h * sF, 22*2 * sF, 7*2 * sF);
    popMatrix();
    }
  }
  void update() {
    if (alive) {
      for (int i = 0; i < 10; i++) {
        rotation += speed/10;
        float thisRot = (rotation+360000)%360;
        float thatRot = (playerRotation+360000)%360;
        if (abs(thisRot-thatRot) < 4 && h < playerHeight+27*1.5 && h > playerHeight-27*1.5 && alive) {
          playerAlive = false;
          frameCount = 0;
          alive = false;
        }
        for (int n = 0; n < Zombies.size(); n++) {
          Zombie zombie = Zombies.get(n);
          float thiRot = (rotation+360000)%360;
          float thaRot = (zombie.rotation+360000)%360;
          if (abs(thiRot-thaRot) < 4 && zombie.alive && h < 277+26*1.5 && zombie.life > zombie.animLength*0.75 && alive) {
            zombie.alive = false;
            score++;
            for (int x = 0; x < 75; x++) {
              float bloodAngle = 0;
              if (speed > 0) {
                bloodAngle = (rotation+180-random(random(random(-20, 70)))+360000)%360;
              } else {
                bloodAngle = (rotation+random(random(random(-20, 70)))+360000)%360;
              }
              float speedRot = 0;
              if (speed > 0) {
                speedRot = (rotation+180+360000)%360;
              } else {
                speedRot = (rotation+360000)%360;
              }
              float bloodSpeed = random (6, findAngle(speedRot, bloodAngle)/2000+12);
              Blood.add(new BloodParticle (zombie.rotation, h, revAngleX (bloodAngle, bloodSpeed), revAngleY (bloodAngle, bloodSpeed)));
            }
            alive = false;
          }
        }
      }
    }
  }
}

class Star {
  float x, y, size;
  color col;
  Star (float x, float y, float size, color col) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.col = col;
  }
  void draw() {
    noStroke();
    fill (col);
    noStroke();
    rect (x * sF, y * sF, size * sF, size * sF);
    if (x > 800.0*1.5) {
      x = -800.0*1.5;
    } else if (x < -800.0*1.5) {
      x = 800.0*1.5;
    }
    if (y > 800.00*1.5) {
      y = -800.00*1.5;
    } else if (y < -800.00*1.5) {
      y = 800.00*1.5;
    }
  }
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

class Zombie {
  float rotation, speed, life, animLength, Xv;
  boolean alive;
  Zombie (float rotation, float speed) {
    this.rotation = rotation;
    this.speed = speed;
    animLength = 30;
    alive = true;
  }
  void draw() {
    if (alive) {
    pushMatrix();
    translate (800.0/2 * sF, (800.00/2+50) * sF);
    rotate (radians(rotation));
    if (life < animLength) {
      if (life < animLength*0.25) {
        image (crawlFrame1, 5 * sF, -277 * sF, 16*3 * sF, 26*3 * sF);
      } else if (life < animLength*0.5) {
        image (crawlFrame2, 5 * sF, -277 * sF, 16*3 * sF, 26*3 * sF);
      } else if (life < animLength*0.75) {
        image (crawlFrame3, 5 * sF, -277 * sF, 16*3 * sF, 26*3 * sF);
      } else {
        image (crawlFrame4, 5 * sF, -277 * sF, 16*3 * sF, 26*3 * sF);
      }
    } else {
      if (Xv <= 0) {
        scale (-1, 1);
      }
      PImage currentFrame;
      if (frameCount % 20 <= 10) {
        currentFrame = runFrame1;
      } else {
        currentFrame = runFrame2;
      }
      image (currentFrame, 7 * sF, -277 * sF, 20*3 * sF, 26*3 * sF);
    }
    popMatrix();
    }
  }
  void update() {
    if (alive) {
    life += 1;
    if (life > animLength) {
      float thisRot = (rotation+360000)%360;
      float thatRot = (playerRotation+360000)%360;
      if (playerHeight <= 277) {
        if (abs(thisRot-thatRot) < 180) {
          if (thisRot < thatRot) {
            Xv = speed;
          } else {
            Xv = -speed;
          }
        } else {
          if (thisRot < thatRot) {
            Xv = -speed;
          } else {
            Xv = speed;
          }
        }
      }
      rotation += Xv;
      float thiRot = (rotation+360000)%360;
      float thaRot = (playerRotation+360000)%360;
      if (abs(thiRot-thaRot) < 4 && 277 < playerHeight+27*1.5 && 277 > playerHeight-27*1.5) {
        playerAlive = false;
        frameCount = 0;
        alive = false;
      }
    }
    }
  }
}
