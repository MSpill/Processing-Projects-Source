ArrayList<Ball> Balls;
float gravity;
float elasticity;
boolean menu;
String simSetup;
float buttonX, buttonY, buttonW, buttonH, buttonGap;

void setup() {
  size (1000, 600, P2D);
  Balls = new ArrayList<Ball>();
  menu = true;
  buttonX = width/2 - 150;
  buttonY = 120;
  buttonW = 300;
  buttonGap = 90;
  buttonH = 70;
  colorMode(HSB);
}

void draw() {
  if (menu) {
    background(230);
    textAlign(CENTER, CENTER);
    textSize(40);
    fill(0);
    text("Pick a simulation setup", width/2, 60);
    textSize(30);
    drawButton(buttonX, buttonY, buttonW, buttonH, "Gas Mixing");
    drawButton(buttonX, buttonY+buttonGap, buttonW, buttonH, "Newton's Cradle");
    drawButton(buttonX, buttonY+buttonGap*2, buttonW, buttonH, "Gravity - Elastic");
    drawButton(buttonX, buttonY+buttonGap*3, buttonW, buttonH, "Gravity - Inelastic");
  } else {
    background (255);
    for (Ball b : Balls) {
      b.update();
    }
    for (Ball b : Balls) {
      b.draw();
    }
    textSize(16);
    drawButton(width-120, 15, 100, 35, "Reset");
    drawButton(width-120, 60, 100, 35, "Main menu");
  }
}

void mousePressed() {
  
  if (menu) {
    String[] strings = {"Gas Mixing", "Newton's Cradle", "Gravity - Elastic", "Gravity - Inelastic"};
    boolean oneClicked = false;
    for (int i = 0; i < strings.length; i++) {
      if (mouseX > buttonX && mouseX < buttonX+buttonW && mouseY > buttonY+buttonGap*i && mouseY < buttonY+buttonGap*i+buttonH) {
        setupBalls(strings[i]);
        oneClicked = true;
      }
    }
    if (oneClicked) {
      menu = false;
    }
  } else {
    color col = color (random(255), 255, 200);
    Balls.add(new Ball (new PVector(mouseX, mouseY), new PVector(random(-2.5, 2.5), random(-2.5, 2.5)), random(600, 1200), col, 1));
    if (mouseX > width-120 && mouseX < width-120+100 && mouseY > 15 && mouseY < 15+35) {
      setupBalls(simSetup);
    }
    if (mouseX > width-120 && mouseX < width-120+100 && mouseY > 60 && mouseY < 60+35) {
      setup();
    }
  }
}

void drawButton(float x, float y, float w, float h, String myText) {
  colorMode(RGB);
  fill(170);
  stroke(100);
  strokeWeight(3);
  rect(x, y, w, h, 3);
  fill(0);
  textAlign(CENTER, CENTER);
  text(myText, x+w/2, y+h/2);
  colorMode(HSB);
}

void setupBalls(String setupName) {
  simSetup = setupName;
  Balls = new ArrayList<Ball>();
  if (setupName.equals("Gas Mixing")) {
    gravity = 0;
    elasticity = 1;
    for (int i = 0; i < 500; i++) {
      float x = random(width);
      color col;
      if (x < width/2) {
        col = color(255, 255, 255);
      } else {
        col = color(255*(240.0/360), 255, 255);
      }
      //col = color (random(255), random(255), random(255));
      Balls.add(new Ball (new PVector(x, random(height)), new PVector(random(-1, 1), random(-1, 1)), 80, col, 1));
    }
  } else if (setupName.equals("Newton's Cradle")) {
    gravity = 0;
    elasticity = 1;
    for (int i = 0; i < 15; i++) {
      float x = 200+i*40;
      color col = color(random(255), 255, 200);
      Balls.add(new Ball (new PVector(x, height/2), new PVector(0, 0), 950, col, 1));
    }
    Balls.add(new Ball(new PVector(20, height/2), new PVector(3, 0), 950, color(255,255,255), 1));
  } else if (setupName.equals("Gravity - Elastic")) {
    elasticity = 1;
    gravity = 0.3;
  } else if (setupName.equals("Gravity - Inelastic")) {
    elasticity = 0.95;
    gravity = 0.3;
  }
}

class Ball {
  PVector position;
  PVector velocity;
  float mass;
  float radius;
  int index;
  color col;
  Ball (PVector position, PVector velocity, float mass, color col, float density) {
    this.position = position;
    this.velocity = velocity;
    this.mass = mass*density;
    this.radius = sqrt(mass/PI);
    index = Balls.size();
    this.col = col;
  }
  void draw() {
    noStroke();
    fill (col);
    ellipse (position.x, position.y, radius*2, radius*2);
    fill (255);
    textAlign(CENTER, CENTER);
    textSize (radius);
    //text (index, position.x, position.y);
  }
  void update() {
    for (int x = 0; x < 1; x++) {
      for (int i = index+1; i < Balls.size(); i++) {
        Ball other = Balls.get(i);
        if (PVector.sub(position, (other.position)).magSq() <= pow(radius+other.radius, 2)) {
          PVector n = PVector.sub(position,(other.position));
          PVector penetration = PVector.mult(n, (radius+other.radius-n.mag())/(2.01*n.mag()));
          float m1 = mass;
          float m2 = other.mass;
          PVector v1 = velocity;
          PVector v2 = other.velocity;
          float j = (-2*m2*n.dot(PVector.sub(v1,v2)))/(n.dot(n)*(m2+m1));
          float k = (-2*m1*n.dot(PVector.sub(v1,v2)))/(n.dot(n)*(m2+m1));
          velocity.add(PVector.mult(n, j));
          velocity.mult(elasticity);
          other.velocity.sub(PVector.mult(n, k));
          other.velocity.mult(elasticity);
          position.add (penetration);
          other.position.sub(penetration);
        }
      }
      position.add(PVector.div(velocity, 1));
      if (position.x < radius || position.x > width-radius) {
        velocity.x *= -elasticity;
        if (position.x < radius) {
          position.x = radius;
        } else {
          position.x = width-radius;
        }
      }
      if (position.y < radius || position.y > height-radius) {
        velocity.y *= -elasticity;
        if (position.y < radius) {
          position.y = radius;
        } else {
          position.y = height-radius;
        }
      }
      velocity.add (0, gravity);
    }
  }
}