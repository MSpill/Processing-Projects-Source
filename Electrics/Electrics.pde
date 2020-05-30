/* @pjs preload="/static/projects/Electrics/data/rotate.png"; */

boolean panelOpen = true;

boolean paused;

float simSpeed = 1;

boolean simulating = false;

boolean placeWires = true;

boolean menu = true;
boolean exitConfirm = false;
boolean errorResetting = false;
boolean changedCircuit;
int iters;

float timeSinceMoved = 0;

String simSetup = "";
int exitMenu = 0;
int resetStatus = 0;

PImage rotateImg;
PGraphics rotateG;

float menuY = 100;
float bGap = 110;

static abstract class PlaceMode {
  static final int wire = 0;
  static final int button = 1;
  static final int switchy = 2;
  static final int light = 3;
  static final int andGate = 4;
  static final int orGate = 5;
  static final int notGate = 6;
  static final int upNode = 7;
  static final int downNode = 8;
  static final int deleteMode = 9;
}

int gateDir = Direction.right;

int placeMode = PlaceMode.wire;

int numX, numY;

float prevMouseX;
float prevMouseY;

int widthX = 15;
int widthY = 15;

int cZ = 5;

Node[][][] Nodes;

void setup() {
  size ((int) max(screenWidth * 0.8, 980), (int) max(screenWidth * 0.8 * 0.6, 980 * 0.6), P2D);
  if (width < 1000) {
    widthX = (int)(15 * (width/1000.0));
    widthY = (int)(15 * (width/1000.0));
  }
  //frameRate(5);
  rotateImg = loadImage("/static/projects/Electrics/data/rotate.png");
  rotateG = createGraphics(rotateImg.width, rotateImg.height, P2D);
  rotateG.beginDraw();
  rotateG.image(rotateImg, 0, 0);
  rotateG.endDraw();
  rotateG.loadPixels();
  for (int i = 0; i < rotateG.pixels.length; i++) {
    rotateG.pixels[i] = color(40,40,40,255-red(rotateImg.pixels[i]));
  }
  rotateG.updatePixels();
  iters = 0;
  changedCircuit = false;
}

void draw() {
  if (menu) {
    background(255);
    textSize(50);
    textAlign(CENTER, CENTER);
    fill(0);
    text("Choose a starting template", width/2, menuY);
    fill (230);
    strokeWeight(2);
    stroke(150);
    rect (width/2-175, menuY+70, 350, 80, 5);
    rect (width/2-175, menuY+70+bGap, 350, 80, 5);
    rect (width/2-175, menuY+70+bGap*2, 350, 80, 5);
    fill(0);
    textSize(40);
    text("Empty", width/2, menuY+70+40);
    text("Basic Setup", width/2, menuY+70+40+bGap);
    text("4-bit Addition", width/2, menuY+70+40+bGap*2);
    if (exitMenu == 1) {
      setupNodes(simSetup);
      menu = false;
      changedCircuit = false;
      exitMenu = 0;
      cZ = 5;
      paused = true;
    }
    if (exitMenu == 2) {
      fill(0);
      textSize(40);
      textAlign(CENTER, CENTER);
      text("Loading...", width/2, height-60);
      exitMenu--;
    }
  } else {
    background (255);
    strokeWeight (1);
    stroke (170);
    textSize(12);
    for (int i = 0; i < width; i += widthX) {
      line (i, 0, i, height);
    }
    for (int i = 0; i < height; i += widthY) {
      line (0, i, width, i);
    }
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 2; y < Nodes[z].length-2; y++) {
        for (int x = 2; x < Nodes[z][y].length-2; x++) {
          Nodes[z][y][x].draw();
          if (!paused) {
            Nodes[z][y][x].update();
          }
          if (cZ == z) {
            if (mouseIn (x*widthX-widthX*0, y*widthY-widthY*0, widthX*1, widthY*1,0.03) && !(panelOpen && x*widthX <= 200) && !mouseIn(width-100,20,80,305,1) && !exitConfirm && !errorResetting) {
              if ((keyPressed && key == 'd') || (mousePressed && placeMode == PlaceMode.deleteMode)) {
                if (Nodes[z][y][x] instanceof WireNode) {
                  if (((WireNode)Nodes[z][y][x]).father == null) {
                    boolean updateUp = false;boolean updateDown = false;
                    if (Nodes[z][y][x] instanceof UpNode) {
                      Nodes[z+1][y][x] = new Node (x*widthX, y*widthY, z+1); updateUp = true;
                    } else if (Nodes[z][y][x] instanceof DownNode) {
                      Nodes[z-1][y][x] = new Node (x*widthX, y*widthY, z-1); updateDown = true;
                    }
                    Nodes[z][y][x] = new Node (x*widthX, y*widthY, z);
                    if (updateUp) {updateNear (x, y, z+1);}
                    if (updateDown) {updateNear (x, y, z-1);}
                    updateNear (x, y, z);
                  } else {
                    int x1 = (int)(((WireNode)Nodes[z][y][x]).father.x-widthX/2.0)/widthX;
                    int y1 = (int)(((WireNode)Nodes[z][y][x]).father.y-widthY/2.0)/widthY;
                    Gate fatherGate = ((WireNode)Nodes[z][y][x]).father;
                    if (fatherGate instanceof TwoGate) { // here be errors
                      deleteTwoGateAt (x1, y1, z);
                    } else {
                      deleteNotGateAt (x1, y1, z);
                    }
                  }
                } else if (Nodes[z][y][x] instanceof TwoGate) {
                  deleteTwoGateAt (x, y, z);
                } else if (Nodes[z][y][x] instanceof NotGate) {
                  deleteNotGateAt (x, y, z);
                } else {
                  Nodes[z][y][x] = new Node (x*widthX, y*widthY, z);
                  updateNear (x, y, z);
                }
                changedCircuit = true;
              }
              if (mousePressed) {
                if (placeMode == PlaceMode.wire && placeWires) {
                  if (!(Nodes[z][y][x] instanceof WireNode || Nodes[z][y][x] instanceof Button) && mouseButton == LEFT && !keyPressed && !isGate(Nodes[z][y][x]) && !isGateWire(Nodes[z][y][x])) {
                    Nodes[z][y][x] = new WireNode (x*widthX, y*widthY, z);
                    updateNear (x, y, z);
                    changedCircuit = true;
                  }
                }
              } else {
                noStroke();
                if (placeMode == PlaceMode.wire || placeMode == PlaceMode.upNode || placeMode == PlaceMode.downNode || placeMode == PlaceMode.deleteMode) {
                  fill (0, 0, 0, 50);
                  rect (x*widthX,y*widthY, widthX, widthY);
                } else if (placeMode == PlaceMode.button) {
                  fill (0, 0, 255, 50);
                  rect (x*widthX,y*widthY, widthX, widthY);
                } else if (placeMode == PlaceMode.switchy) {
                  fill (255, 0, 0, 50);
                  rect (x*widthX,y*widthY, widthX/2.0, widthY);
                  fill (0, 255, 0, 50);
                  rect (x*widthX+widthX/2.0,y*widthY, widthX/2.0, widthY);
                } else if ((placeMode == PlaceMode.andGate || placeMode == PlaceMode.orGate) && x > 2 && x < Nodes[z][y].length-3 && y > 2 && y < Nodes[z].length-3) {
                  fill (0, 0, 0, 75);
                  if (gateDir == Direction.right) {
                    triangle ((x+2)*widthX, y*widthY+widthY/2.0, (x-1)*widthX, (y-1)*widthY, (x-1)*widthX, (y+2)*widthY);
                  } else if (gateDir == Direction.left) {
                    triangle ((x-1)*widthX, y*widthY+widthY/2.0, (x+2)*widthX, (y-1)*widthY, (x+2)*widthX, (y+2)*widthY);
                  } else if (gateDir == Direction.down) {
                    triangle ((x)*widthX+widthX/2, (y+2)*widthY, (x-1)*widthX, (y-1)*widthY, (x+2)*widthX, (y-1)*widthY);
                  } else {
                    triangle ((x)*widthX+widthX/2, (y-1)*widthY, (x-1)*widthX, (y+2)*widthY, (x+2)*widthX, (y+2)*widthY);
                  }
                } else if (placeMode == PlaceMode.notGate && x > 2 && x < Nodes[z][y].length-3 && y > 2 && y < Nodes[z].length-3) {
                  fill (0, 0, 0, 75);
                  if (gateDir == Direction.right) {
                    rect ((x-0.75)*widthX, (y-0.25)*widthY, widthX*1.25, widthY*1.5);
                    triangle ((x+0.5)*widthX, (y-0.25)*widthY, (x+0.5)*widthX, (y+1.25)*widthY, (x+2)*widthX, (y+0.5)*widthY);
                  } else if (gateDir == Direction.left) {
                    rect ((x+0.5)*widthX, (y-0.25)*widthY, widthX*1.25, widthY*1.5);
                    triangle ((x+0.5)*widthX, (y-0.25)*widthY, (x+0.5)*widthX, (y+1.25)*widthY, (x-1)*widthX, (y+0.5)*widthY);
                  } else if (gateDir == Direction.down) {
                    rect ((x-0.25)*widthX, (y-0.75)*widthY, widthX*1.5, widthY*1.25);
                    triangle ((x-0.25)*widthX, (y+0.5)*widthY, (x+1.25)*widthX, (y+0.5)*widthY, (x+0.5)*widthX, (y+2)*widthY);
                  } else {
                    rect ((x-0.25)*widthX, (y+0.5)*widthY, widthX*1.5, widthY*1.25);
                    triangle ((x-0.25)*widthX, (y+0.5)*widthY, (x+1.25)*widthX, (y+0.5)*widthY, (x+0.5)*widthX, (y-1)*widthY);
                  }
                } else if (placeMode == PlaceMode.light) {
                  fill (150, 150, 0, 100);
                  rect (x*widthX, y*widthY, widthX, widthY);
                }
              }
            }
          }
        }
      }
    }
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 1; y < Nodes[z].length-1; y++) {
        for (int x = 1; x < Nodes[z][y].length-1; x++) {
          if (!paused) {
            Nodes[z][y][x].updateValues();
          }
          Nodes[z][y][x].secondDraw();
        }
      }
    }
    if (!paused) {
      iters++;
    }
    if (resetStatus > 1) {
      fill (255, 255, 255, 200);
      noStroke();
      rect(0, 0, width, height);
      fill(0);
      textSize(50);
      textAlign(CENTER, CENTER);
      text ("Preparing...", width/2, height/2);
      resetStatus--;
    } else if (resetStatus == 1) {
      //boolean prevPaused = paused;
      paused = true;
      simulate();
      resetStatus = 0;
    }
    stroke (150);
    strokeWeight(2);
    fill (230, 230, 230, 150);
    if (mouseIn(width-100, 20, 80, 80,1)) {
      fill(180, 180, 180, 150);
      if (mousePressed) {
        fill(145, 145, 145, 150);
      }
    }
    rect (width-100, 20, 80, 80,4);
    tint(255, 255, 255, 170);
    image(rotateG, width-100, 20, 80, 80);
    tooltip(width-100, 20, 80, 80, 60, 27, "Reset");
    stroke (150);
    strokeWeight(2);
    tint(255, 255, 255, 255);
    fill (230, 230, 230, 150);
    if (mouseIn(width-100, 115, 80, 80,1)) {
      fill(180, 180, 180, 150);
      if (mousePressed) {
        fill(145, 145, 145, 150);
      }
    }
    rect(width-100, 115, 80, 80,4);
    if (paused) {
      noStroke();
      fill (0, 0, 0, 125);
      triangle (width-100+18, 115+15, width-100+18, 115+65, width-100+68, 115+40);
    } else {
      noStroke();
      fill (0, 0, 0, 125);
      rect (width-100+16+1, 115+15, 16, 50, 2);
      rect (width-100+3*16-1, 115+15, 16, 50, 2);
    }
    fill (230, 230, 230, 150);
    stroke (150);
    strokeWeight(2);
    rect (width-100, 210, 80, 70, 4);
    fill (0);
    textSize (18);
    textAlign(CENTER, CENTER);
    text ("Layer " + (cZ-5), width-100+40, 230);
    strokeWeight(3);
    line (width-100, 250, width-20, 250);
    line (width-100+40, 250, width-100+40, 280);
    noStroke();
    if (cZ == 0) {
      fill (180, 180, 180);
    } else {
      if (mouseIn(width-100, 250, 40, 30,1)) {
        noStroke();
        fill (165, 165, 165, 150);
        if (mousePressed) {
          fill (130, 130, 130, 150);
        }
        rect(width-100,250,40,30,1);
      }
      fill (120, 120, 120);
    }
    rect (width-100+11, 250+12, 18, 6);
    if (cZ == Nodes.length-1) {
      fill (180, 180, 180);
    } else {
      if (mouseIn(width-100+40, 250, 40, 30,1)) {
        noStroke();
        fill (160, 160, 160, 150);
        if (mousePressed) {
          fill (130, 130, 130, 150);
        }
        rect(width-100+40,250,40,30,1);
      }
      fill (120, 120, 120);
    }
    rect (width-100+40+11, 250+12, 18, 6);
    rect (width-100+40+17, 250+6, 6, 18);
    stroke (150);
    strokeWeight(2);
    fill (230, 230, 230, 150);
    if (mouseIn(width-90, 295, 60, 30,1)) {
      fill(180, 180, 180, 150);
      if (mousePressed) {
        fill(145, 145, 145, 150);
      }
    }
    rect(width-90, 295, 60, 30,4);
    fill(0);
    textSize(18);
    textAlign(CENTER, CENTER);
    text ("Exit", width-90+30, 295+15);
    if (exitConfirm) {
      strokeWeight (2);
      stroke (150);
      fill (200);
      rectMode(CORNER);
      rect (width/2-155, height/2-90, 310, 180, 4);
      textAlign(CENTER, CENTER);
      fill(0);
      textSize(25);
      text("Return to Menu", width/2, height/2-60);
      textSize(17);
      text("Are you sure you want to return to the menu? All work in the current window will be lost.", width/2-150, height/2-80-5, 300, 160);
      fill (240);
      rect (width/2-100, height/2+50, 90, 30, 4);
      rect (width/2+10, height/2+50, 90, 30, 4);
      fill (0);
      text("Cancel", width/2-100+45, height/2+50+15);
      text("OK", width/2+10+45, height/2+50+15);
    }
    if (errorResetting) {
      strokeWeight (2);
      stroke (150);
      fill (200);
      rectMode(CORNER);
      rect (width/2-155, height/2-90, 310, 220, 4);
      textAlign(CENTER, CENTER);
      fill(0);
      textSize(25);
      text("Simulation Error", width/2, height/2-65);
      textSize(17);
      text("The simulation could not be started properly. This is likely because the circuit has a loop containing multiple NOT gates. This will cause NOT gates to behave erratically.", width/2-150, height/2-65-5, 300, 170);
      fill (240);
      rect (width/2-45, height/2+95, 90, 30, 4);
      fill (0);
      text("OK", width/2, height/2+95+15);
      paused = true;
    }
    if (panelOpen) {
      drawPanel();
    } else {
      strokeWeight (2);
      stroke (150);
      fill (210);
      if (mouseIn(0, 5, 30, 60,0.03)) {
        fill (170);
      }
      rect (0, 5, 30, 60);
      fill (100);
      noStroke();
      triangle (7, 13, 7, 57, 25, 35);
    }
  }
  prevMouseX = mouseX;
  prevMouseY = mouseY;
  timeSinceMoved++;
}

void mouseMoved() {
  timeSinceMoved = 0;
}

void deleteTwoGateAt (int x, int y, int z) {
  TwoGate g = (TwoGate)Nodes[z][y][x];
  Nodes[z][y+g.y1][x+g.x1] = new Node ((x+g.x1)*widthX, (y+g.y1)*widthY, z);
  Nodes[z][y+g.y2][x+g.x2] = new Node ((x+g.x2)*widthX, (y+g.y2)*widthY, z);
  Nodes[z][y+g.y3][x+g.x3] = new Node ((x+g.x3)*widthX, (y+g.y3)*widthY, z);
  Nodes[z][y][x] = new Node ((x)*widthX, (y)*widthY, z);
  updateNear (x, y, z);
  updateNear (x+g.x1, y+g.y1, z);
  updateNear (x+g.x2, y+g.y2, z);
  updateNear (x+g.x3, y+g.y3, z);
}

void deleteNotGateAt (int x, int y, int z) {
  NotGate g = (NotGate)Nodes[z][y][x];
  Nodes[z][y+g.y1][x+g.x1] = new Node ((x+g.x1)*widthX, (y+g.y1)*widthY, z);
  Nodes[z][y+g.y2][x+g.x2] = new Node ((x+g.x2)*widthX, (y+g.y2)*widthY, z);
  Nodes[z][y][x] = new Node ((x)*widthX, (y)*widthY, z);
  updateNear (x, y, z);
  updateNear (x+g.x1, y+g.y1, z);
  updateNear (x+g.x2, y+g.y2, z);
}

void drawPanel() {
  strokeWeight (2);
  stroke (150);
  fill (200);
  rect (0, 0, 240, height);
  fill (210);
  if (mouseIn(240, 5, 20, 60,0.03)) {
    fill (170);
  }
  rect (240, 5, 20, 60);
  fill (100);
  noStroke();
  triangle (253, 13, 253, 57, 243, 35);
  fill (255, 255, 255, 150);
  if (placeMode == PlaceMode.wire) {
    rect (20, 20, 90, 90);
  } else if (placeMode == PlaceMode.button) {
    rect (130, 20, 90, 90);
  } /*else if (placeMode == PlaceMode.Switch) {
    rect (20, 130, 90, 90);
  }*/ else if (placeMode == PlaceMode.light) {
    rect (130, 130, 90, 90);
  } else if (placeMode == PlaceMode.andGate) {
    rect (20, 130, 90, 90);
  } else if (placeMode == PlaceMode.orGate) {
    rect (20+110, 240, 90, 90);
  } else if (placeMode == PlaceMode.notGate) {
    rect (20, 240, 90, 90);
  } else if (placeMode == PlaceMode.upNode) {
    rect (20+110, 350, 90, 90);
  } else if (placeMode == PlaceMode.downNode) {
    rect (20, 350, 90, 90);
  } else if (placeMode == PlaceMode.deleteMode) {
    rect (20+40, 550, 120, 40);
  }
  fill (255, 255, 255, 50);
  if (mouseIn (20, 20, 90, 90,1)) {
    rect (20, 20, 90, 90);
  } else if (mouseIn (130, 20, 90, 90,1)) {
    rect (130, 20, 90, 90);
  } else if (mouseIn (20, 130, 90, 90,1)) {
    rect (20, 130, 90, 90);
  } else if (mouseIn (130, 130, 90, 90,1)) {
    rect (130, 130, 90, 90);
  } else if (mouseIn (20, 240, 90, 90,1)) {
    rect (20, 240, 90, 90);
  } else if (mouseIn (20+110, 240, 90, 90,1)) {
    rect (20+110, 240, 90, 90);
  } else if (mouseIn (20, 350, 90, 90,1)) {
    rect (20, 350, 90, 90);
  } else if (mouseIn(20+110, 350, 90, 90,1)) {
    rect (20+110, 350, 90, 90);
  } else if (mouseIn (20, 460, 90, 90,1)) {
    if (mousePressed) {
      fill(255, 255, 255, 150);
    }
    rect (20, 460, 90, 90);
  } else if (mouseIn(20+110, 460, 90, 90,1)) {
    if (mousePressed) {
      fill(255, 255, 255, 150);
    }
    rect (20+110, 460, 90, 90);
  } else if (mouseIn(20+40, 550, 120, 40,1)) {
    rect (20+40, 550, 120, 40);
  }
  textAlign (CENTER);
  // Wire art
  textSize (12);
  fill (100, 70, 70);
  rect (40, 50, 50, 20, 2);
  fill (0);
  text ("Wire", 65, 100);
  // Button art
  fill (0, 0, 200);
  rect (155, 40, 40, 40, 3);
  fill (0);
  text ("Button", 175, 100);
  // Switch art
  /*fill (255, 0, 0);
  rect (45, 150, 20, 40, 3);
  fill (0, 255, 0);
  rect (65, 150, 20, 40, 3);
  fill (0);
  text ("Switch", 65, 210);*/
  // Light art
  fill (200, 200, 0);
  rect (45+110, 150, 40, 40, 3);
  fill (0);
  text ("Light", 65+110, 210);
  // AND gate art
  fill (50);
  triangle (93, 275-110, 45, 250-110, 45, 300-110);
  fill (255);
  textSize (18);
  textAlign (CENTER, CENTER);
  text ("A", 60, 270-110);
  textSize (12);
  textAlign (CENTER);
  fill (0);
  text ("AND gate", 65, 320-110);
  // OR gate art
  fill (50);
  triangle (93+110, 275, 45+110, 250, 45+110, 300);
  fill (255);
  textSize (18);
  textAlign (CENTER, CENTER);
  text ("O", 60+110, 270);
  textSize (12);
  textAlign (CENTER);
  fill (0);
  text ("OR gate", 65+110, 320);
  // NOT gate art
  fill (50);
  triangle (93, 275, 45, 250, 45, 300);
  fill (255);
  textSize (18);
  textAlign (CENTER, CENTER);
  text ("N", 60, 270);
  textSize (12);
  textAlign (CENTER);
  fill (0);
  text ("NOT gate", 65, 320);
  // UpNode art
  fill (100, 70, 70);
  rect (155, 40+110*3, 40, 40, 3);
  stroke (255);
  strokeWeight(3);
  line (175, 45+110*3, 175, 75+110*3);
  line (175, 45+110*3, 165, 55+110*3);
  line (175, 45+110*3, 185, 55+110*3);
  fill (0);
  text ("Up wire", 175, 100+110*3);
  tooltip(20+110, 350, 90, 90, 135, 50, "Wire connection to higher layer");
  // DownNode art
  noStroke();
  fill (100, 70, 70);
  rect (45, 40+110*3, 40, 40, 3);
  stroke (255);
  strokeWeight(3);
  line (65, 45+110*3, 65, 75+110*3);
  line (65, 75+110*3, 55, 65+110*3);
  line (65, 75+110*3, 75, 65+110*3);
  fill (0);
  textSize(12);
  textAlign(CENTER);
  text ("Down wire", 65, 100+110*3);
  tooltip(20, 350, 90, 90, 135, 50, "Wire connection to lower layer");
  // CCW rotate button
  image (rotateG, 25, 465, 80, 80);
  tooltip(25, 465, 80, 80, 95, 27, "Rotate CCW");
  // CW rotate button
  pushMatrix();
  scale(-1,1);
  image (rotateG, -25-110, 465, -80, 80);
  popMatrix();
  tooltip(25+110, 465, 80, 80, 110, 27, "Rotate CW (r)");
  // Delete mode
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(17);
  text("Delete mode", 20+45+55, 550+20);
  tooltip(20+40, 550, 120, 40, 130, 27, "Delete items (d)");
}

void tooltip(float rX, float rY, float rW, float rH, float tW, float tH, String tipText) {
  if (mouseIn(rX, rY, rW, rH,1) && timeSinceMoved > 5) {
    fill (0, 0, 0, 200);
    noStroke();
    float posX = mouseX - tW/2;
    float posY = mouseY - tH - 2;
    rect(posX, posY, tW, tH);
    fill (255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text(tipText, posX, posY-3, tW, tH);
  }
}

void updateNear(int x, int y, int z) {
  Nodes[z][y][x].nearNodes = new Node[0];
  if (Nodes[z][y][x] instanceof UpNode) {
    Nodes[z][y][x].nearNodes = copyOf(Nodes[z][y][x].nearNodes, Nodes[z][y][x].nearNodes.length+1);
    Nodes[z][y][x].nearNodes[0] = Nodes[z+1][y][x];
  } else if (Nodes[z][y][x] instanceof DownNode) {
    Nodes[z][y][x].nearNodes = copyOf(Nodes[z][y][x].nearNodes, Nodes[z][y][x].nearNodes.length+1);
    Nodes[z][y][x].nearNodes[0] = Nodes[z-1][y][x];
  }
  for (int y1 = y-1; y1 < y+2; y1++) {
    for (int x1 = x-1; x1 < x+2; x1++) {
      if ((x1 != x || y1 != y) && !(x1 != x && y1 != y)) {
        Nodes[z][y][x].nearNodes = copyOf (Nodes[z][y][x].nearNodes, Nodes[z][y][x].nearNodes.length+1);
        Nodes[z][y][x].nearNodes[Nodes[z][y][x].nearNodes.length-1] = Nodes[z][y1][x1];
        Nodes[z][y1][x1].nearNodes = new Node[0];
        if (Nodes[z][y1][x1] instanceof UpNode) {
          Nodes[z][y1][x1].nearNodes = copyOf(Nodes[z][y1][x1].nearNodes, Nodes[z][y1][x1].nearNodes.length+1);
          Nodes[z][y1][x1].nearNodes[0] = Nodes[z+1][y1][x1];
        } else if (Nodes[z][y1][x1] instanceof DownNode) {
          Nodes[z][y1][x1].nearNodes = copyOf(Nodes[z][y1][x1].nearNodes, Nodes[z][y1][x1].nearNodes.length+1);
          Nodes[z][y1][x1].nearNodes[0] = Nodes[z-1][y1][x1];
        }
        for (int y2 = y1-1; y2 < y1+2; y2++) {
          for (int x2 = x1-1; x2 < x1+2; x2++) {
            if ((x2 != x1 || y2 != y1) && !(x2 != x1 && y2 != y1)) {
              Nodes[z][y1][x1].nearNodes = copyOf (Nodes[z][y1][x1].nearNodes, Nodes[z][y1][x1].nearNodes.length+1);
              Nodes[z][y1][x1].nearNodes[Nodes[z][y1][x1].nearNodes.length-1] = Nodes[z][y2][x2];
            }  
          }
        }
      }
    }
  }
}

void reset() {
  iters = 0;
  for (int z = 0; z < Nodes.length; z++) {
    for (int y = 0; y < Nodes[z].length; y++) {
      for (int x = 0; x < Nodes[z][y].length; x++) {
        if (Nodes[z][y][x] instanceof WireNode) {
          ((WireNode)Nodes[z][y][x]).active = false;
          ((WireNode)Nodes[z][y][x]).gateHistory = new ArrayList<Gate>();
          ((WireNode)Nodes[z][y][x]).timeSinceActive = 999;
          ((WireNode)Nodes[z][y][x]).timeActive = 0;
        } else if (Nodes[z][y][x] instanceof AndGate) {
          ((AndGate)Nodes[z][y][x]).primedTop = false; ((AndGate)Nodes[z][y][x]).primedBottom = false; ((AndGate)Nodes[z][y][x]).done = false;
        } else if (Nodes[z][y][x] instanceof OrGate) {
          ((OrGate)Nodes[z][y][x]).reachedTop = false; ((OrGate)Nodes[z][y][x]).reachedBottom = false; ((OrGate)Nodes[z][y][x]).done = false; ((OrGate)Nodes[z][y][x]).primed = false;
        } else if (Nodes[z][y][x] instanceof Button) {
          ((Button)Nodes[z][y][x]).active = false;
          ((Button)Nodes[z][y][x]).timeActive = 1;
        } else if (Nodes[z][y][x] instanceof Light) {
          ((Light)Nodes[z][y][x]).active = false;
        } else if (Nodes[z][y][x] instanceof NotGate) {
          NotGate n = (NotGate)Nodes[z][y][x];
          n.framesPassed = 0; n.done = false;
        }
      }
    }
  }
}

void keyPressed() {
  if (key == 'm') {
    panelOpen = !panelOpen;
  }
  if ((key == '=' || key == '+') && cZ < Nodes.length-1) {cZ++;}
  if (key == '-' && cZ > 0) {cZ--;}
  if (key == 'p' || key == ' ') {paused = !paused;}
  if (key == 'r') {
    rotateClockwise();
  }
}

void rotateClockwise() {
  if (gateDir == Direction.right) {
    gateDir = Direction.down;
  } else if (gateDir == Direction.down) {
    gateDir = Direction.left;
  } else if (gateDir == Direction.left) {
    gateDir = Direction.up;
  } else if (gateDir == Direction.up) {
    gateDir = Direction.right;
  }
}

void rotateCounter() {
  if (gateDir == Direction.right) {
    gateDir = Direction.up;
  } else if (gateDir == Direction.down) {
    gateDir = Direction.right;
  } else if (gateDir == Direction.left) {
    gateDir = Direction.down;
  } else if (gateDir == Direction.up) {
    gateDir = Direction.left;
  }
}

void mousePressed() {
  if (menu) {
    if (mouseIn(width/2-175, menuY+70, 350, 80, 1)) {
      simSetup = "Empty";
      paused = true;
      exitMenu = 2;
    }
    if (mouseIn(width/2-175, menuY+70+bGap, 350, 80, 1)) {
      simSetup = "Basic Setup";
      paused = true;
      exitMenu = 2;
    }
    if (mouseIn(width/2-175, menuY+70+bGap*2, 350, 80, 1)) {
      simSetup = "4-bit Addition";
      paused = true;
      exitMenu = 2;
    }
    placeWires = false;
  } else if (exitConfirm) {
    if (mouseIn(width/2-100, height/2+50, 90, 30, 1)) {
      exitConfirm = false;
      placeWires = false;
    }
    if (mouseIn(width/2+10, height/2+50, 90, 30, 1)) {
      exitConfirm = false;
      menu = true;
    }
  } else if (errorResetting) {
    if (mouseIn(width/2-45, height/2+95, 90, 30, 1)) {
      errorResetting = false;
      placeWires = false;
      paused = true;
    }
  } else {
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 2; y < Nodes[z].length-2; y++) {
        for (int x = 2; x < Nodes[z][y].length-2; x++) {
          if (mouseIn (x*widthX-widthX*0, y*widthY-widthY*0, widthX*1, widthY*1,0.03) && !(panelOpen && (x*widthX <= 200 || mouseIn(240,5,20,60,1))) && !(!panelOpen && mouseIn(0,5,30,60,1))  && cZ == z && !isGate(Nodes[z][y][x]) && !isGateWire(Nodes[z][y][x]) && !mouseIn(width-100,20,80,305,1)) {
            if (!keyPressed) {
              if (Nodes[z][y][x] instanceof Button) {
                ((Button)Nodes[z][y][x]).active = !((Button)Nodes[z][y][x]).active;
              } else if (Nodes[z][y][x] instanceof Switch) {
                ((Switch)Nodes[z][y][x]).active = !((Switch)Nodes[z][y][x]).active;
              } else if (Nodes[z][y][x] instanceof Light) {
                ((Light)Nodes[z][y][x]).active = !((Light)Nodes[z][y][x]).active;
              }
            }
            if (placeMode == PlaceMode.button) {
              if (!(Nodes[z][y][x] instanceof Button || Nodes[z][y][x] instanceof UpNode || Nodes[z][y][x] instanceof DownNode) && mouseButton == LEFT && !keyPressed) {
                Nodes[z][y][x] = new Button (x*widthX, y*widthY, z);
                updateNear (x, y, z);
                changedCircuit = true;
              }
            } else if (placeMode == PlaceMode.switchy) {
              if (!(Nodes[z][y][x] instanceof Switch  || Nodes[z][y][x] instanceof UpNode || Nodes[z][y][x] instanceof DownNode || Nodes[z][y][x] instanceof Button) && mouseButton == LEFT && !keyPressed) {
                Nodes[z][y][x] = new Switch (x*widthX, y*widthY, z);
                updateNear (x, y, z);
                changedCircuit = true;
              }
            } else if (placeMode == PlaceMode.light) {
              if (!(Nodes[z][y][x] instanceof Light  || Nodes[z][y][x] instanceof UpNode || Nodes[z][y][x] instanceof DownNode || Nodes[z][y][x] instanceof Button) && mouseButton == LEFT && !keyPressed) {
                Nodes[z][y][x] = new Light (x*widthX, y*widthY, z);
                updateNear (x, y, z);
                changedCircuit = true;
              }
            } else if (placeMode == PlaceMode.upNode) {
              if (!(Nodes[z][y][x] instanceof UpNode || Nodes[z][y][x] instanceof DownNode || Nodes[z+1][y][x] instanceof UpNode || Nodes[z][y][x] instanceof Button) && mouseButton == LEFT && !keyPressed) {
                Nodes[z][y][x] = new UpNode (x*widthX, y*widthY, z);
                Nodes[z+1][y][x] = new DownNode (x*widthX, y*widthY, z+1);
                updateNear (x, y, z);
                updateNear (x, y, z+1);
                changedCircuit = true;
              }
            } else if (placeMode == PlaceMode.downNode) {
              if (!(Nodes[z][y][x] instanceof DownNode || Nodes[z][y][x] instanceof UpNode || Nodes[z-1][y][x] instanceof DownNode || Nodes[z][y][x] instanceof Button) && mouseButton == LEFT && !keyPressed) {
                Nodes[z][y][x] = new DownNode (x*widthX, y*widthY, z);
                Nodes[z-1][y][x] = new UpNode (x*widthX, y*widthY, z-1);
                updateNear (x, y, z);
                updateNear (x, y, z-1);
                changedCircuit = true;
              }
            } else if (placeMode == PlaceMode.andGate && mouseIn (x*widthX-widthX*0, y*widthY-widthY*0, widthX*1, widthY*1,1) && x > 2 && x < Nodes[z][y].length-3 && y > 2 && y < Nodes[z].length-3) {
              //Nodes[z][y][x] = new AndGate (x*widthX+widthX/2.0, y*widthY+widthY/2.0, z, gateDir);
              setupTwoGate(x,y,z,new AndGate (x*widthX+widthX/2.0, y*widthY+widthY/2.0, z, gateDir));
              changedCircuit = true;
            } else if (placeMode == PlaceMode.orGate && mouseIn (x*widthX-widthX*0, y*widthY-widthY*0, widthX*1, widthY*1,1) && x > 2 && x < Nodes[z][y].length-3 && y > 2 && y < Nodes[z].length-3) {
              //Nodes[z][y][x] = new OrGate (x*widthX+widthX/2.0, y*widthY+widthY/2.0, z, gateDir);
              setupTwoGate(x,y,z,new OrGate (x*widthX+widthX/2.0, y*widthY+widthY/2.0, z, gateDir));
              changedCircuit = true;
            } else if (placeMode == PlaceMode.notGate && mouseIn (x*widthX-widthX*0, y*widthY-widthY*0, widthX*1, widthY*1,1) && x > 2 && x < Nodes[z][y].length-3 && y > 2 && y < Nodes[z].length-3) {
              setupNotGate(x,y,z,new NotGate (x*widthX+widthX/2.0, y*widthY+widthY/2.0, z, gateDir));
              changedCircuit = true;
            }
          }
        }
      }
    }
    if (panelOpen) {
      if (mouseIn (20, 20, 90, 90,1)) {
        placeMode = PlaceMode.wire;
      } else if (mouseIn (130, 20, 90, 90,1)) {
        placeMode = PlaceMode.button;
      } else if (mouseIn (20, 130, 90, 90,1)) {
        placeMode = PlaceMode.andGate;
      } else if (mouseIn (130, 130, 90, 90,1)) {
        placeMode = PlaceMode.light;
      } else if (mouseIn (20, 240, 90, 90,1)) {
        placeMode = PlaceMode.notGate;
      } else if (mouseIn (20+110, 240, 90, 90,1)) {
        placeMode = PlaceMode.orGate;
      } else if (mouseIn (20, 350, 90, 90,1)) {
        placeMode = PlaceMode.downNode;
      } else if (mouseIn (20+110, 350, 90, 90,1)) {
        placeMode = PlaceMode.upNode;
      } else if (mouseIn (20, 460, 90, 90,1)) {
        rotateCounter();
      } else if (mouseIn (20+110, 460, 90, 90,1)) {
        rotateClockwise();
      } else if (mouseIn(20+40, 550, 120, 40,1)) {
        placeMode = PlaceMode.deleteMode;
      } else if (mouseIn (240, 5, 20, 60,1)) { // close panel
        panelOpen = false;
        placeWires = false;
      }
    } else {
      if (mouseIn (0, 5, 30, 60,1)) { // open panel
        panelOpen = true;
        placeWires = false;
      }
    }
    if (mouseIn(width-100, 20, 80, 80,1) && resetStatus == 0) {
      reset();
      paused = true;
    }
    if (mouseIn(width-100, 115, 80, 80,1)) {
      if (changedCircuit && iters == 0 && areNotGates()) {
        resetStatus = 3;
        changedCircuit = false;
      } else {
        paused = !paused;
      }
    }
    if (mouseIn(width-100, 250, 40, 30,1) && cZ != 0) {
      cZ--;
    }
    if (mouseIn(width-100+40, 250, 40, 30,1) && cZ != Nodes.length-1) {
      cZ++;
    }
    if (mouseIn(width-90, 295, 60, 30,1)) {
      exitConfirm = true;
    }
  }
}

void mouseReleased() {
  placeWires = true;
}

void setupTwoGate (int x, int y, int z, TwoGate g) {
  if (!empty(Nodes[z][y+g.y1][x+g.x1]) || !empty(Nodes[z][y+g.y2][x+g.x2]) || !empty(Nodes[z][y+g.y3][x+g.x3]) || !empty(Nodes[z][y][x])) {
    return;
  }
  Nodes[z][y][x] = g;
  Nodes[z][y+g.y1][x+g.x1] = new WireNode ((x+g.x1)*widthX, (y+g.y1)*widthY, z); ((WireNode)Nodes[z][y+g.y1][x+g.x1]).father = (TwoGate)Nodes[z][y][x];
  Nodes[z][y+g.y2][x+g.x2] = new WireNode ((x+g.x2)*widthX, (y+g.y2)*widthY, z); ((WireNode)Nodes[z][y+g.y2][x+g.x2]).father = (TwoGate)Nodes[z][y][x];
  Nodes[z][y+g.y3][x+g.x3] = new WireNode ((x+g.x3)*widthX, (y+g.y3)*widthY, z); ((WireNode)Nodes[z][y+g.y3][x+g.x3]).father = (TwoGate)Nodes[z][y][x];
  ((TwoGate)Nodes[z][y][x]).inputs = copyOf (((TwoGate)Nodes[z][y][x]).inputs, 2);
  ((TwoGate)Nodes[z][y][x]).inputs[0] = (WireNode)Nodes[z][y+g.y3][x+g.x3];
  ((TwoGate)Nodes[z][y][x]).inputs[1] = (WireNode)Nodes[z][y+g.y2][x+g.x2];
  ((TwoGate)Nodes[z][y][x]).output = (WireNode)Nodes[z][y+g.y1][x+g.x1];
  updateNear (x, y, z);
  updateNear (x+g.x1, y+g.y1, z);
  updateNear (x+g.x2, y+g.y2, z);
  updateNear (x+g.x3, y+g.y3, z);
}

boolean empty(Node n) {
  return !(n instanceof Gate || n instanceof WireNode || n instanceof Button || n instanceof Light || n instanceof Switch);
}

boolean isGate(Node n) {
  return n instanceof Gate;
}

boolean isGateWire(Node n) {
  return (n instanceof WireNode && ((WireNode)n).father != null);
}

void setupNotGate(int x, int y, int z, NotGate g) {
  if (!empty(Nodes[z][y+g.y1][x+g.x1]) || !empty(Nodes[z][y+g.y2][x+g.x2]) || !empty(Nodes[z][y][x])) {
    return;
  }
  Nodes[z][y][x] = g;
  Nodes[z][y+g.y1][x+g.x1] = new WireNode ((x+g.x1)*widthX, (y+g.y1)*widthY, z); ((WireNode)Nodes[z][y+g.y1][x+g.x1]).father = (NotGate)Nodes[z][y][x];
  Nodes[z][y+g.y2][x+g.x2] = new WireNode ((x+g.x2)*widthX, (y+g.y2)*widthY, z); ((WireNode)Nodes[z][y+g.y2][x+g.x2]).father = (NotGate)Nodes[z][y][x];
  ((NotGate)Nodes[z][y][x]).output = (WireNode)Nodes[z][y+g.y2][x+g.x2];
  ((NotGate)Nodes[z][y][x]).input = (WireNode)Nodes[z][y+g.y1][x+g.x1];
  updateNear (x, y, z);
  updateNear (x+g.x1, y+g.y1, z);
  updateNear (x+g.x2, y+g.y2, z);
}

boolean areNotGates() {
  boolean ret = false;
  ArrayList<Boolean> buttonStats = new ArrayList<Boolean>();
  for (int z = 0; z < Nodes.length; z++) {
    for (int y = 0; y < Nodes[z].length; y++) {
      for (int x = 0; x < Nodes[z][y].length; x++) {
        if (Nodes[z][y][x] instanceof NotGate) {
          ret = true;
        }
      }
    }
  }
  return ret;
}

void simulate() {
  ArrayList<Boolean> buttonStats = new ArrayList<Boolean>();
  for (int z = 0; z < Nodes.length; z++) {
    for (int y = 0; y < Nodes[z].length; y++) {
      for (int x = 0; x < Nodes[z][y].length; x++) {
        if (Nodes[z][y][x] instanceof Button) {
          buttonStats.add(((Button)Nodes[z][y][x]).active);
        }
      }
    }
  }
  if (paused && areNotGates()) {
    reset();
    simulating = true;
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 0; y < Nodes[z].length; y++) {
        for (int x = 0; x < Nodes[z][y].length; x++) {
          if (Nodes[z][y][x] instanceof NotGate) {
            NotGate n = (NotGate)Nodes[z][y][x];
            n.framesToReach = 0; n.framesPassed = 0; n.done = false;
          }
        }
      }
    }
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 0; y < Nodes[z].length; y++) {
        for (int x = 0; x < Nodes[z][y].length; x++) {
          if (Nodes[z][y][x] instanceof Button) {
            Button n = (Button)Nodes[z][y][x];
            n.active = true;
          }
        }
      }
    }
    boolean stillActive = true;
    int iterations = 0;
    do {
      for (int z = 0; z < Nodes.length; z++) {
        for (int y = 0; y < Nodes[z].length; y++) {
          for (int x = 0; x < Nodes[z][y].length; x++) {
            Nodes[z][y][x].update();
          }
        }
      }
      for (int z = 0; z < Nodes.length; z++) {
        for (int y = 0; y < Nodes[z].length; y++) {
          for (int x = 0; x < Nodes[z][y].length; x++) {
            Nodes[z][y][x].updateValues();
          }
        }
      }
      if (iterations > 1) {
        stillActive = false;
        for (int z = 0; z < Nodes.length; z++) {
          for (int y = 0; y < Nodes[z].length; y++) {
            for (int x = 0; x < Nodes[z][y].length; x++) {
              if (Nodes[z][y][x] instanceof WireNode) {
                if (((WireNode)Nodes[z][y][x]).active) {
                  stillActive = true;
                }
              }
            }
          }
        }
      }
      iterations += 1;
    } while (stillActive && iterations < 2500 && !errorResetting);
    if (stillActive) {
      errorResetting = true;
    }
    simulating = false;
    reset();
    paused = false;
    int index = 0;
  }
  for (int z = 0; z < Nodes.length; z++) {
      for (int y = 0; y < Nodes[z].length; y++) {
        for (int x = 0; x < Nodes[z][y].length; x++) {
          if (Nodes[z][y][x] instanceof Button) {
            ((Button)Nodes[z][y][x]).active = buttonStats.get(index);
            index++;
          }
        }
      }
    }
}

boolean mouseIn (float x, float y, float w, float h, float iter) {
  for (float a = 0; a < 1; a+=iter) {
    float mx = a*mouseX+(1-a)*prevMouseX;
    float my = a*mouseY+(1-a)*prevMouseY;
    if (mx > x && my > y && mx < x+w && my < y+h) {
      return true;
    }
  }
  return false;
}

Node[] copyOf (Node[] arr, int newL) {
  Node[] out = new Node[newL];
  for (int i = 0; i < arr.length; i++) {
    out[i] = arr[i];
  }
  return out;
}

WireNode[] copyOf (WireNode[] arr, int newL) {
  WireNode[] out = new WireNode[newL];
  for (int i = 0; i < arr.length; i++) {
    out[i] = arr[i];
  }
  return out;
}

static abstract class Direction {
  static final int left = 0; 
  static final int right = 1; 
  static final int up = 2; 
  static final int down = 3;
}

class Gate extends Node {
  Gate (float x, float y, float z) {
    super (x, y, z);
  }
}

class TwoGate extends Gate {
  WireNode[] inputs = new WireNode[2];
  WireNode output;
  int dir;
  int x1, y1, x2, y2, x3, y3;
  TwoGate (float x, float y, float z, int dir) {
    super (x, y, z);
    this.dir = dir;
    if (dir == Direction.right) {
      x1 = 1; y1 = 0; x2 = -1; y2 = -1; x3 = -1; y3 = 1;
    } else if (dir == Direction.left) {
      x1 = -1; y1 = 0; x2 = 1; y2 = -1; x3 = 1; y3 = 1;
    } else if (dir == Direction.down) {
      x1 = 0; y1 = 1; x2 = -1; y2 = -1; x3 = 1; y3 = -1;
    } else if (dir == Direction.up) {
      x1 = 0; y1 = -1; x2 = -1; y2 = 1; x3 = 1; y3 = 1;
    }
  }
}

class AndGate extends TwoGate {
  boolean primedTop = false;
  boolean primedBottom = false;
  boolean done = false;
  AndGate (float x, float y, float z, int dir) {
    super (x, y, z, dir);
  }
  void updateValues() {
    if (simulating) {
      if (inputs[0].active || inputs[1].active) {
        ArrayList<Gate> newHistory = new ArrayList<Gate>();
        if (inputs[0].active) {
          for (Gate g : inputs[0].gateHistory) {
            newHistory.add(g);
          }
        }
        if (inputs[1].active) {
          for (Gate g : inputs[1].gateHistory) {
            newHistory.add(g);
          }
        }
        output.active = true;
        output.gateHistory = newHistory;
      }
    } else if (!done) {
      if (inputs[0].active || inputs[1].active && !(inputs[0].active && inputs[1].active)) {
        if (inputs[0].active && !primedTop) {
          if (primedBottom) {
            output.active = true;
            done = true;
            primedTop = false;
            primedBottom = false;
          } else {
            primedTop = true;
          }
        }
        if (inputs[1].active && !primedBottom) {
          if (primedTop) {
            output.active = true;
            done = true;
            primedTop = false;
            primedBottom = false;
          } else {
            primedBottom = true;
          }
        }
      } else if (inputs[0].active && inputs[1].active) {
        output.active = true;
        done = true;
        primedTop = false;
        primedBottom = false;
      }
    }
  }
  void secondDraw() {
    if (cZ == z) {
      fill (0);
      if (primedTop || primedBottom) {
        fill (150, 150, 0);
      } else if (done) {
        fill (150, 0, 0);
      }
      textAlign (CENTER, CENTER);
      textSize(12);
      if (dir == Direction.right) {
        triangle (x+widthX*1.5, y, x-widthX*1.5, y-widthY*1.5, x-widthX*1.5, y+widthY*1.5);
        fill (255);
        text ("A", x-widthX/1.5, y-widthY/3.0);
      } else if (dir == Direction.left) {
        triangle (x-widthX*1.5, y, x+widthX*1.5, y-widthY*1.5, x+widthX*1.5, y+widthY*1.5);
        fill (255);
        text ("A", x+widthX/1.5, y-widthY/3.0);
      } else if (dir == Direction.down) {
        triangle (x, y+widthY*1.5, x-widthX*1.5, y-widthY*1.5, x+widthX*1.5, y-widthY*1.5);
        fill (255);
        text ("A", x, y-widthY/1.5);
      } else if (dir == Direction.up) {
        triangle (x, y-widthY*1.5, x-widthX*1.5, y+widthY*1.5, x+widthX*1.5, y+widthY*1.5);
        fill (255);
        text ("A", x, y+widthY/1.5);
      }
    }
  }
}

class OrGate extends TwoGate {
  boolean reachedTop, reachedBottom, done, primed;
  OrGate (float x, float y, float z, int dir) {
    super (x, y, z, dir);
    reachedTop = false;
    reachedBottom = false;
    primed = false;
    done = false;
  }
  void updateValues() {
    if (simulating) {
      if (inputs[0].active || inputs[1].active) {
        ArrayList<Gate> newHistory = new ArrayList<Gate>();
        if (inputs[0].active) {
          for (Gate g : inputs[0].gateHistory) {
            newHistory.add(g);
          }
        }
        if (inputs[1].active) {
          for (Gate g : inputs[1].gateHistory) {
            newHistory.add(g);
          }
        }
        output.active = true;
        output.gateHistory = newHistory;
      }
    } else if (!done) {
      if (inputs[0].active && !reachedTop) {
        reachedTop = true;
        done = true;
        output.active = true;
      }
      if (inputs[1].active && !reachedBottom) {
        reachedBottom = true;
        done = true;
        output.active = true;
      }
    }
  }
  void secondDraw() {
    if (cZ == z) {
      if (!done) {
        fill (0);
      } else {
        fill (150, 0, 0);
      }
      textSize(12);
      textAlign (CENTER, CENTER);
      if (dir == Direction.right) {
        triangle (x+widthX*1.5, y, x-widthX*1.5, y-widthY*1.5, x-widthX*1.5, y+widthY*1.5);
        fill (255);
        text ("O", x-widthX/1.5, y-widthY/3.0);
      } else if (dir == Direction.left) {
        triangle (x-widthX*1.5, y, x+widthX*1.5, y-widthY*1.5, x+widthX*1.5, y+widthY*1.5);
        fill (255);
        text ("O", x+widthX/1.5, y-widthY/3.0);
      } else if (dir == Direction.down) {
        triangle (x, y+widthY*1.5, x-widthX*1.5, y-widthY*1.5, x+widthX*1.5, y-widthY*1.5);
        fill (255);
        text ("O", x, y-widthY/1.5);
      } else if (dir == Direction.up) {
        triangle (x, y-widthY*1.5, x-widthX*1.5, y+widthY*1.5, x+widthX*1.5, y+widthY*1.5);
        fill (255);
        text ("O", x, y+widthY/1.5);
      }
    }
  }
}

class NotGate extends Gate {
  WireNode input, output;
  int dir;
  int x1, y1, x2, y2;
  int framesToReach, framesPassed;
  boolean done = false;
  NotGate (float x, float y, float z, int dir) {
    super (x, y, z);
    this.dir = dir;
    framesToReach = 0;
    if (dir == Direction.right) {
      x1 = -1; y1 = 0; x2 = 1; y2 = 0;
    } else if (dir == Direction.left) {
      x1 = 1; y1 = 0; x2 = -1; y2 = 0;
    } else if (dir == Direction.down) {
      x1 = 0; y1 = -1; x2 = 0; y2 = 1;
    } else {
      x1 = 0; y1 = 1; x2 = 0; y2 = -1;
    }
  }
  void update() {
    if (simulating) {
      framesPassed += 1;
      if (input.active) {
        if (input.gateHistory.contains(this)) {
          errorResetting = true;
        } else {
          ArrayList<Gate> newHistory = input.gateHistory;
          newHistory.add(this);
          output.active = true;
          output.gateHistory = newHistory;
          framesToReach = framesPassed;
        }
      }
    } else if (!done) {
      framesPassed += 1;
      if (input.active) {
        done = true;
      }
      if (framesPassed == framesToReach) {
        output.active = !input.active;
        done = true;
      }
    }
  }
  
  void secondDraw() {
    if (cZ == z) {
      fill (0);
      if (done) {
        fill (150, 0, 0);
      }
      textAlign (CENTER, CENTER);
      textSize(12);
      if (dir == Direction.right) {
        rect (x-widthX*1.25, y-widthY*0.75, widthX*1.25, widthY*1.5);
        triangle (x, y-widthY*0.75, x, y+widthY*0.75, x+widthX*1.5, y);
        fill (255);
        text ("N", x-widthX*0.25, y);
      } else if (dir == Direction.left) {
        rect (x+widthX*1.25, y-widthY*0.75, -widthX*1.25, widthY*1.5);
        triangle (x, y-widthY*0.75, x, y+widthY*0.75, x-widthX*1.5, y);
        fill (255);
        text ("N", x+widthX*0.25, y);
      } else if (dir == Direction.down) {
        rect (x-widthX*0.75, y-widthY*1.25, widthX*1.5, widthY*1.25);
        triangle (x-widthX*0.75, y, x+widthX*0.75, y, x, y+widthY*1.5);
        fill (255);
        text ("N", x, y-widthY*0.25);
      } else if (dir == Direction.up) {
        rect (x-widthX*0.75, y+widthY*1.25, widthX*1.5, -widthY*1.25);
        triangle (x-widthX*0.75, y, x+widthX*0.75, y, x, y-widthY*1.5);
        fill (255);
        text ("N", x, y+widthY*0.25);
      }
    }
  }
}

class Button extends Node {
  boolean active = false;
  float timeActive = 1;
  Button (float x, float y, float z) {
    super (x, y, z);
  }
  
  void draw() {
    if (cZ == z) {
      noStroke();
      fill (0, 0, 255);
      rect (x, y, widthX, widthY);
      if (active) {
        fill (150, 150, 255);
        rect (x-2, y-2, widthX+4, widthY+4, 2);
      }
      
    }
  }
  
  void update() {
    if (active && timeActive > 0.5) {
      float maxTime = 10*simSpeed;
      for (Node n : nearNodes) {
        if (n instanceof WireNode) {
          if (((WireNode)n).timeSinceActive >= maxTime && maxTime != 0) {
            ((WireNode)n).active = true;
          }
        }
      }
      active = false;
      timeActive = 0;
    }
  }
  void updateValues() {
    if (active && timeActive > 0.5) {
    } else if (active) {
      timeActive += simSpeed;
    }
  }
}

class Switch extends Node {
  boolean active = false;
  float timeActive = 0;
  Switch (float x, float y, float z) {
    super (x, y, z);
  }
  
  void draw() {
    if (cZ == z) {
      noStroke();
      fill (255, 0, 0);
      if (active) {
        fill (0, 255, 0);
      }
      rect (x, y, widthX, widthY);
    }
  }
  
  void update() {
    if (active && timeActive > 15) {
      float maxTime = 0*simSpeed;
      for (Node n : nearNodes) {
        if (n instanceof WireNode) {
          if (((WireNode)n).timeSinceActive >= maxTime) {
            ((WireNode)n).active = true;
          }
        }
      }
      timeActive = 0;
    }
  }
  void updateValues() {
     if (active) {
      timeActive += simSpeed;
    }
  }
}

class Light extends Node {
  boolean active = false;
  Light (float x, float y, float z) {
    super (x, y, z);
  }
  
  void update() {
    for (Node n : nearNodes) {
      if (n instanceof WireNode) {
        if (((WireNode)n).active) {
          active = !active;
        }
      }
    }
  }
  
  void secondDraw() {
    if (cZ == z) {
      noStroke();
      fill (150, 150, 0);
      if (active) {
        fill (200, 200, 50);
        ellipse (x+widthX/2.0, y+widthY/2.0, widthX*2, widthY*2);
      } else {
        rect (x, y, widthX, widthY);
      }
    }
  }
}

class Node {
  float x, y, z;
  Node[] nearNodes = new Node[0];
  Node (float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }
  void update() {}
  void updateValues() {}
  void draw() {}
  void secondDraw() {}
}

class WireNode extends Node {
 
  float timeActive = 0;
  float timeSinceActive = 0;
  boolean active = false;
  ArrayList<Gate> gateHistory;
  Gate father = null;
  WireNode (float x, float y, float z) {
    super (x, y, z);
    timeSinceActive = 999;
    timeActive = 0;
    gateHistory = new ArrayList<Gate>();
  }
  
  void draw() {
    if (cZ == z) {
      noStroke();
      if (!active) {
        fill (100);
      } else {
        fill (255, 255, 0);
      }
      rect (x, y, widthX, widthY);
    }
  }
  
  void update() {
    if (active && timeActive > 0.5) {
      float maxTime = 1.1*simSpeed;
      for (Node n : nearNodes) {
        if (n instanceof WireNode) {
          if (((WireNode)n).timeSinceActive >= maxTime) {
            ((WireNode)n).active = true;
            ((WireNode)n).gateHistory = this.gateHistory;
          }
        }
      }
      active = false;
      gateHistory = new ArrayList<Gate>();
      timeSinceActive = 0;
      timeActive = 0;
    }
  }
  void updateValues() {
    if (active && timeActive <= 0.5) {
      timeActive += simSpeed;
      timeSinceActive = 0;
    } else if (!active) {
      timeSinceActive += simSpeed;
    }
  }
}

class UpNode extends WireNode {
  UpNode (float x, float y, float z) {
    super (x, y, z);
  }
  void update() {super.update();}
  void updateValues() {super.updateValues();}
  void draw() {
    if (cZ == z) {
      super.draw();
      stroke (255);
      strokeWeight (1);
      line (x+widthX*0.5, y+widthY*0.25, x+widthX*0.5, y+widthY*0.9);
      line (x+widthX*0.5, y+widthY*0.25, x+widthX*0.25, y+widthY*0.4);
      line (x+widthX*0.5, y+widthY*0.25, x+widthX*0.75, y+widthY*0.4);
    }
  }
}

class DownNode extends WireNode {
  DownNode (float x, float y, float z) {
    super (x, y, z);
  }
  void update() {super.update();}
  void updateValues() {super.updateValues();}
  void draw() {
    if (cZ == z) {
      super.draw();
      stroke (255);
      strokeWeight(1);
      line (x+widthX*0.5, y+widthY*0.1, x+widthX*0.5, y+widthY*0.75);
      line (x+widthX*0.5, y+widthY*0.75, x+widthX*0.25, y+widthY*0.6);
      line (x+widthX*0.5, y+widthY*0.75, x+widthX*0.75, y+widthY*0.6);
    }
  }
}

void setupNodes(String myStr) {
  if (myStr.equals("Empty")) {
    numX = width/widthX;
    numY = height/widthY;
    Nodes = new Node[11][numY][numX];
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 0; y < Nodes[z].length; y++) {
        for (int x = 0; x < Nodes[z][y].length; x++) {
          Nodes[z][y][x] = new Node (x*widthX, y*widthY, z);
        }
      }
    }
    for (int z = 0; z < Nodes.length; z++) {
      for (int y = 1; y < Nodes[z].length-1; y++) {
        for (int x = 1; x < Nodes[z][y].length-1; x++) {
          for (int y1 = y-1; y1 < y+2; y1++) {
            for (int x1 = x-1; x1 < x+2; x1++) {
              if ((x1 != x || y1 != y) && !(x1 != x && y1 != y)) {
                Nodes[z][y][x].nearNodes = copyOf (Nodes[z][y][x].nearNodes, Nodes[z][y][x].nearNodes.length+1);
                Nodes[z][y][x].nearNodes[Nodes[z][y][x].nearNodes.length-1] = Nodes[z][y1][x1];
              }
            }
          }
        }
      }
    }
  } else if (myStr.equals("Basic Setup")) {
    setupNodes("Empty");
    makeButton(19, 10, 5);
    makeButton(19, 12, 5);
    for (int n = 0; n < 8; n++) {
      makeWire(20+n, 10, 5);
      makeWire(20+n, 12, 5);
      makeWire(31+n, 11, 5);
      makeWire(20+n, 15, 5);
      makeWire(20+n, 17, 5);
      makeWire(31+n, 16, 5);
      makeWire(20+n, 20, 5);
      makeWire(31+n, 20, 5);
    }
    makeAndGate(29, 11, 5, Direction.right);
    makeLight(39, 11, 5);
    
    makeButton(19, 15, 5);
    makeButton(19, 17, 5);
    makeOrGate(29, 16, 5, Direction.right);
    makeLight(39, 16, 5);
    
    makeButton(19, 20, 5);
    makeNotGate(29, 20, 5, Direction.right);
    makeLight(39, 20, 5);
    
    for (int n = 0; n < 12; n++) {
      makeWire(34+n, 7, 5);
      makeWire(34+n, 14, 5);
      if (n < 5) makeWire(45,13-n,5);
      if (n < 4) makeWire(50+n, 8, 5);
    }
    makeNotGate(34, 9, 5, Direction.up);
    makeWire(34, 15, 5);
    makeWire(46, 7, 5);
    makeWire(46, 9, 5);
    makeAndGate(48, 8, 5, Direction.right);
    makeLight(54, 8, 5);
    
    for (int n = 0; n < 33; n++) {
      if (n < 11 || n >= 21) makeWire (20+n, 26, 5);
      if (n < 6 || n >= 26) makeWire (20+n, 32, 5);
      if (5 <= n && n <= 18) makeWire(20+n, 29, 5);
      if (10 <= n && n <= 21) makeWire (20+n, 32, 5);
      if (24 <= n && n <= 26) makeWire (20+n, 29, 5);
      if (n < 5) makeWire (41, 27+n, 5);
    }
    
    makeWire(25, 31, 5);
    makeWire(25, 30, 5);
    makeWire(46, 31, 5);
    makeWire(46, 30, 5);
    makeUpNode(30, 31, 5);
    makeUpNode(30, 27, 5);
    makeWire(30, 28, 6);
    makeWire(30, 29, 6);
    makeWire(30, 30, 6);
    makeDownNode(39, 29, 5);
    makeDownNode(43, 29, 5);
    makeWire(40, 29, 4);
    makeWire(41, 29, 4);
    makeWire(42, 29, 4);
    makeButton(19, 26, 5);
    makeButton(19, 32, 5);
    makeLight(53, 26, 5);
    makeLight(53, 32, 5);
  } else if (myStr.equals("4-bit Addition")) {
    setupNodes("Empty");
    halfAdder(50,4,5);
    fullAdder(40,4,5);
    fullAdder(30,4,5);
    fullAdder(20,4,5);
    makeWire(18,16,5);
    for (int n = 0; n < 19; n++) {
      makeWire(17,16+n,5);
    }
    makeLight(17,35,5);
    paused = true;
  }
  boolean prevPaused = paused;
  paused = true;
  simulate();
  simulate();
  paused = prevPaused;
}

void adderBegin(int x, int y, int z) {
  makeButton(x+3, y, z);
  makeButton(x+3, y+4, z);
  makeWire(x+3, y+1, z);
  for (int n = 0; n < 5; n++) {
    makeWire(x+n+1,y+2,z);
  }
  for (int n = 0; n < 5; n++) {
    makeWire(x+1,y+n+3,z);
    makeWire(x+5,y+n+3,z);
    if (n >= 2) makeWire(x+3,y+n+3,z);
  }
  makeWire(x,y+7,z);
  makeWire(x+6,y+7,z);
  for (int n = 0; n < 7; n++) {
    if (n != 1 && n != 5) makeWire(x+n,y+8,z);
  }
  makeWire(x,y+9,z);
  makeWire(x+2,y+9,z);
  makeOrGate(x+1,y+11,z,Direction.down);
  makeAndGate(x+5,y+10,z,Direction.down);
  makeWire(x+2,y+12,z);
  makeWire(x+2,y+13,z);
  makeWire(x+2,y+14,z);
  makeWire(x+5,y+12,z);
  makeNotGate(x+5,y+14,z,Direction.down);
  makeUpNode(x+6,y+12,z);
  makeAndGate(x+3,y+16,z,Direction.down);
}

void halfAdder(int x, int y, int z) {
  adderBegin(x, y, z);
  for (int n = 0; n < 13; n++) {
    makeWire(x+3,y+18+n,z);
  }
  makeLight(x+3,y+31,z);
  for (int n = 0; n < 6; n++) {
    makeWire(x+n,y+12,z+1);
  }
  makeUpNode(x-1,y+12,z);
}

void fullAdder(int x, int y, int z) {
  adderBegin(x,y,z);
  makeWire(x+1,y+17,z);
  makeWire(x+2,y+17,z);
  makeWire(x+4,y+17,z);
  makeWire(x+5,y+17,z);
  makeAndGate(x+7,y+16,z,Direction.up);
  makeUpNode(x+7,y+14,z);
  makeUpNode(x+9,y+17,z);
  for (int n = 0; n < 4; n++) {
    makeWire(x+9,y+13+n,z);
  }
  makeWire(x+1,y+18,z);
  makeWire(x,y+18,z);
  makeWire(x,y+19,z);
  makeWire(x,y+20,z);
  makeUpNode(x+2,y+19,z);
  makeWire(x+2,y+20,z);
  makeOrGate(x+1,y+22,z,Direction.down);
  makeWire(x+4,y+18,z);
  makeWire(x+4,y+19,z);
  makeWire(x+6,y+19,z);
  makeUpNode(x+7,y+19,z);
  makeAndGate(x+5,y+21,z,Direction.down);
  makeWire(x+2,y+23,z);
  makeWire(x+2,y+24,z);
  makeWire(x+2,y+25,z);
  makeWire(x+5,y+23,z);
  makeNotGate(x+5,y+25,z,Direction.down);
  makeAndGate(x+3,y+27,z,Direction.down);
  makeWire(x+3,y+29,z);
  makeWire(x+3,y+30,z);
  makeLight(x+3,y+31,z);
  makeUpNode(x-1,y+12,z);
  // top stuff
  for (int n = 0; n < 8; n++) {
    makeWire(x+2+n,y+18,z+1);
  }
  makeWire(x+6,y+14,z+1);
  makeOrGate(x+4,y+13,z+1,Direction.left);
  for (int n = 0; n < 4; n++) {
    makeWire(x+n,y+12,z+1);
  }
}

void makeAndGate(int x, int y, int z, int dir) {
  setupTwoGate(x, y, z, new AndGate(x*widthX+widthX/2.0,y*widthY+widthY/2.0, z, dir));
}

void makeOrGate(int x, int y, int z, int dir) {
  setupTwoGate(x, y, z, new OrGate(x*widthX+widthX/2.0,y*widthY+widthY/2.0, z, dir));
}

void makeNotGate(int x, int y, int z, int dir) {
  setupNotGate(x, y, z, new NotGate(x*widthX+widthX/2.0,y*widthY+widthY/2.0, z, dir));
}

void makeWire(int x, int y, int z) {
  Nodes[z][y][x] = new WireNode (x*widthX, y*widthY, z);
  updateNear (x, y, z);
}

void makeUpNode(int x, int y, int z) {
  Nodes[z][y][x] = new UpNode (x*widthX, y*widthY, z);
  Nodes[z+1][y][x] = new DownNode (x*widthX, y*widthY, z+1);
  updateNear (x, y, z);
  updateNear (x, y, z+1);
}

void makeDownNode(int x, int y, int z) {
  Nodes[z][y][x] = new DownNode (x*widthX, y*widthY, z);
  Nodes[z-1][y][x] = new UpNode (x*widthX, y*widthY, z-1);
  updateNear (x, y, z);
  updateNear (x, y, z-1);
}

void makeButton(int x, int y, int z) {
  Nodes[z][y][x] = new Button (x*widthX, y*widthY, z);
  updateNear (x, y, z);
}

void makeLight(int x, int y, int z) {
  Nodes[z][y][x] = new Light (x*widthX, y*widthY, z);
  updateNear (x, y, z);
}