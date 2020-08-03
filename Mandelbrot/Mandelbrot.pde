/*

Mandelbrot visualization.
Press 'r' to reset the bounds.
Press 'g' to switch between CPU and GPU versions.
CPU is higher precision, slower, and less pretty.

*/



PShader stringShader;
PGraphics mpg;

double xMin = -2;
double xMax = 1;
double yMin = -1.5;
double yMax = 1.5;

double nXMin, nXMax, nYMin, nYMax;

int maxIterations = 1000;
int itersPerFrame = 500 * 1100 * 8;
int CPU = 1;

int panelWidth = 285, panelH = 205+30+15;

ArrayList<UIElement> elements;

Dropdown colorDrop, iterDrop, orderDrop;
Button zoomInButton, zoomOutButton, backButton, resetButton, collapseButton;

boolean draggingRect = false;
int drawCount = 0;

Stack bounds;

boolean panelOpen;

boolean isMobile;
int touchCooldown1, touchCooldown2;

void setup() {
  isMobile = false;
  touchCooldown1 = 0;
  touchCooldown2 = 0;
  float aR = 1100.0/650.0;
  if (screenWidth / (screenHeight+0.0) > aR) { // height is limiting
    size ((int)(screenHeight * 0.8 * aR), (int)(screenHeight * 0.8));
  } else {
    size ((int)(screenWidth * 0.8), (int)(screenWidth * 0.8 * 1.0/aR));
  }
  setupGraphics();
  //stringShader = new PShader(this, "vert.glsl", "strings.glsl");
  setupRect();
  bounds = new Stack(1000);
  setupUI();
  updateBrot();
}

void draw() {
  touchCooldown1--;
  touchCooldown2--;
  background(0);
  drawBrot();
  handleZooming();
  handleButtons();
  drawPanel();
}

void touchStart(TouchEvent e) {
  if (touchCooldown1 <= 0) {
    //document.getElementById("sketch").removeEventListener('touchmove', touchMove);
    mouseX = e.touches[0].offsetX;
    mouseY = e.touches[0].offsetY;
    pmouseX = mouseX;
    pmouseY = mouseY;
    isMobile = false;
    mousePressed();
    isMobile = true;
    touchCooldown1 = 5;
    mousePressed = true;
  }
}

void touchEnd(TouchEvent e) {
  if (touchCooldown2 <= 0) {
    isMobile = false;
    mouseReleased();
    isMobile = true;
    touchCooldown2 = 5;
    mouseX = 0;
    mouseY = 0;
    pmouseX = mouseX;
    pmouseY = mouseY;
    mousePressed = false;
  }
}

void touchMove(TouchEvent e) {
  mouseX = e.touches[0].offsetX;
  mouseY = e.touches[0].offsetY;
  pmouseX = mouseX;
  pmouseY = mouseY;
}

void mousePressed() {
  if (!isMobile) {
    if (!(panelOpen && mouseIn(0, 0, panelWidth, panelH, 1)) && !elementsInFocus() && !collapseButton.hoveredOver()) {
      nXMin = map(mouseX, 0, width, xMin, xMax);
      nYMax = map(mouseY, 0, height, yMax, yMin);
      draggingRect = true;
    }
    for (UIElement e : elements) {
      e.mousePressed();
    }
  }
}

void mouseReleased() {
  if (!isMobile) {
    if (draggingRect) {
      nXMax = map(mouseX, 0, width, xMin, xMax);
      nYMin = nYMax - ((nXMax - nXMin) * ((mpg.height+0.0)/mpg.width));
      bounds.push(new double[]{xMin, xMax, yMin, yMax});
      if (nXMax != nXMin && nYMax != nYMin) {
        xMin = nXMin; xMax = nXMax;
        yMin = nYMin; yMax = nYMax;
        clearBrot();
        updateBrot();
      } else {
        double newWidth = (xMax-xMin) * 0.25;
        double newHeight = (yMax-yMin) * 0.25;
        xMin = nXMin - newWidth/2.0;
        xMax = nXMin + newWidth/2.0;
        yMin = nYMin - newHeight/2.0;
        yMax = nYMin + newHeight/2.0;
        clearBrot();
      }
      draggingRect = false;
    }
    for (UIElement e : elements) {
      e.mouseReleased();
    }
  }
}

void keyPressed() {
  if (key == 'r') {
    setupRect();
    updateBrot();
  } else if (key == 'g') {
    CPU = (CPU+1) % 2;
    setupGraphics();
    updateBrot();
  }
}

void handleButtons() {
  if (resetButton.active) {
    setupRect();
    clearBrot();
  }
  if (backButton.active) {
    if (!bounds.isEmpty()) {
      double[] newBounds = bounds.pop();
      xMin = newBounds[0];
      xMax = newBounds[1];
      yMin = newBounds[2];
      yMax = newBounds[3];
      clearBrot();
    }
  }
  if (zoomInButton.active) {
    bounds.push(new double[]{xMin, xMax, yMin, yMax});
    double midX = xMin + (xMax-xMin)/2.0;
    double midY = yMin + (yMax-yMin)/2.0;
    double newWidth = (xMax-xMin) * 0.25;
    double newHeight = (yMax-yMin) * 0.25;
    xMin = midX - newWidth/2.0;
    xMax = midX + newWidth/2.0;
    yMin = midY - newHeight/2.0;
    yMax = midY + newHeight/2.0;
    clearBrot();
  }
  if (zoomOutButton.active) {
    bounds.push(new double[]{xMin, xMax, yMin, yMax});
    double midX = xMin + (xMax-xMin)/2.0;
    double midY = yMin + (yMax-yMin)/2.0;
    double newWidth = (xMax-xMin) * 4;
    double newHeight = (yMax-yMin) * 4;
    xMin = midX - newWidth/2.0;
    xMax = midX + newWidth/2.0;
    yMin = midY - newHeight/2.0;
    yMax = midY + newHeight/2.0;
    clearBrot();
  }
  if (collapseButton.active) {
    if (panelOpen) {
      closePanel();
    } else {
      openPanel();
    }
  }
  if (iterDrop.inFocus == 2) {
    clearBrot();
    maxIterations = int(iterDrop.value);
  }
  if (colorDrop.inFocus == 2) {
    clearBrot();
  }
  if (orderDrop.inFocus == 2) {
    clearBrot();
  }
}

void openPanel() {
  panelOpen = true;
  collapseButton.x = panelWidth;
}

void closePanel() {
  panelOpen = false;
  for (UIElement e : elements) {
    if (e != collapseButton) {
      e.onScreen = false;
    }
  }
  collapseButton.x = 0;
}

void drawPanel() {
  collapseButton.draw();
  
  if (panelOpen) {
    stroke(0);
    strokeWeight(1);
    fill (230);
    rect (-10, -10, panelWidth + 11, panelH+11, 7);
    fill(0);
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(25);
    text("Settings", panelWidth/2.0, 20);
    textSize(16);
    textAlign(RIGHT, CENTER);
    text("Iterations:", 130, 60);
    text("Color scheme:", 130, 100);
    text("Drawing order:", 130, 140);
    
    zoomInButton.draw();
    zoomOutButton.draw();
    backButton.draw();
    resetButton.draw();
    
    orderDrop.draw();
    colorDrop.draw();
    iterDrop.draw();
  }
}

void setupUI() {
  elements = new ArrayList<UIElement>();
  panelOpen = true;
  String[] iterOptions = {"10", "50", "100", "250", "1000", "2000", "5000", "10000"};
  iterDrop = new Dropdown (140, 45, 130, iterOptions, iterOptions[4]);
  String[] colorOptions = {"Vibrant", "Black and White"};
  colorDrop = new Dropdown (140, 85, 130, colorOptions, colorOptions[0]);
  String[] orderOptions = {"Staggered", "Middle Out", "Top to Bottom", "Left to Right", };
  orderDrop = new Dropdown (140, 125, 130, orderOptions, orderOptions[1]);
  zoomInButton = new Button ("Zoom In", 15, 165, panelWidth/2.0 - 15 - 5, 30);
  zoomOutButton = new Button ("Zoom Out", panelWidth/2.0 + 5, 165, panelWidth/2.0 - 15 - 5, 30);
  backButton = new Button ("Go Back", 15, 205, panelWidth/2.0 - 15 - 5, 30);
  resetButton = new Button ("Reset Bounds", panelWidth/2.0 + 5, 205, panelWidth/2.0 - 15 - 5, 30);
  collapseButton = new Button ("", panelWidth, 0, 20, 60);
  collapseButton.setRounding(0);
}

void drawBrot() {
  if (CPU != 0 && !elementsInFocus()) {
    updateBrot();
  }
  image(mpg, 0, 0, width, height);
}

void handleZooming() {
  if (mousePressed && draggingRect) {
    stroke(255);
    strokeWeight(1);
    fill(0,0,0,0);
    double rectX = map(nXMin, xMin, xMax, 0, width);
    double rectY = map(nYMax, yMin, yMax, height, 0);
    rect((float)rectX, (float)rectY, (float)(mouseX-rectX), (float)(mouseX-rectX)*((height+0.0)/width));
  }
}

void mouseOut() {
  draggingRect = false;
}

void updateBrot() {
  if (CPU == 1) {
    updateCPU();
  } else {
    updateGPU();
  }
  drawCount++;
}

void updateCPU() {
  mpg.beginDraw();
  mpg.loadPixels();
  /*for (int x = 0; x < mpg.width; x++) {
      int yStart = drawCount % mpg.height;
      int numRows = 8;
      int yJump = (int)(mpg.height/numRows);
      int y = yStart;
      for (int i = 0; i < numRows; i++) {*/
      int itersThisFrame = 0;
      int[] nextPixelCoords;
      while (itersThisFrame < itersPerFrame && (nextPixelCoords = nextPixel()) != null) {
        int x = nextPixelCoords[0];
        int y = nextPixelCoords[1];
        double cR = map((x+0.0)/mpg.width, 0, 1, xMin, xMax);
        double cI = map(1.0-(y+0.0)/mpg.height, 0, 1, yMin, yMax);
        double pointR = 0;
        double pointI = 0;
        int index = 0;
        while (pointR*pointR + pointI*pointI < 4 && index < maxIterations) {
            double newPointR = (pointR*pointR-pointI*pointI) + cR;
            double newPointI = (2*pointR*pointI) + cI;
            pointR = newPointR;
            pointI = newPointI;
            index = index + 1;
            itersThisFrame++;
        }
        color col = color(0);
        if (index < maxIterations) {
            double colNum = 50*(index+0.0)/15000.0;
            //int newCols = HSBtoRGB((float)colNum, 1, 1);
            //col = color(128*sin((float)colNum) + 128);
            if (colorDrop.value.equals("Black and White")) {
              col = color(128*sin((float)colNum*6.0) + 127);
            } else {
              col = hsvToRgb((float)(colNum%1), 1, 1);
            }
        }
        mpg.pixels[mpg.width * y + x % mpg.width] = col;
        //y = (y+yJump) % mpg.height;
      }
  mpg.updatePixels();
  mpg.endDraw();
}

int[] lastCoords;
int pixelsDrawn;
int lastStartY;
int[] nextPixel() {
  if (pixelsDrawn >= mpg.width * mpg.height) {
    return null;
  }
  if (orderDrop.value.equals("Staggered")) {
    if (lastCoords == null) {
      lastCoords = new int[]{0, 0};
      pixelsDrawn = 1;
      lastStartY = 0;
      return lastCoords;
    } else {
      int numRows = 30;
      int yJump = (int)(mpg.height/numRows);
      int[] nextCoords = {lastCoords[0]+1, lastCoords[1]};
      if (nextCoords[0] >= mpg.width) {
        nextCoords[0] = 0;
        nextCoords[1] += yJump;
        if (nextCoords[1] >= mpg.height) {
          nextCoords[1] = ++lastStartY;
        }
      }
      lastCoords = nextCoords;
      pixelsDrawn++;
      return nextCoords;
    }
  } else if (orderDrop.value.equals("Top to Bottom")) {
    if (lastCoords == null) {
      lastCoords = new int[]{0, 0};
      pixelsDrawn = 1;
      return lastCoords;
    } else {
      int[] nextCoords = {lastCoords[0]+1, lastCoords[1]};
      if (nextCoords[0] >= mpg.width) {
        nextCoords[0] = 0;
        nextCoords[1] += 1;
      }
      lastCoords = nextCoords;
      pixelsDrawn++;
      return nextCoords;
    }
  } else if (orderDrop.value.equals("Left to Right")) {
    if (lastCoords == null) {
      lastCoords = new int[]{0, 0};
      pixelsDrawn = 1;
      return lastCoords;
    } else {
      int[] nextCoords = {lastCoords[0], lastCoords[1]+1};
      if (nextCoords[1] >= mpg.height) {
        nextCoords[1] = 0;
        nextCoords[0] += 1;
      }
      lastCoords = nextCoords;
      pixelsDrawn++;
      return nextCoords;
    }
  } else {
    int midX = (int)(mpg.width/2);
    int midY = (int)(mpg.height/2);
    if (lastCoords == null) {
      lastCoords = new int[]{midX, midY};
      pixelsDrawn = 1;
      return lastCoords;
    } else {
      int lastX = lastCoords[0];
      int lastY = lastCoords[1];
      int[] nextCoords = {-1,-1};
      if (lastX-midX == lastY-midY && lastX <= midX) { // reached the end of one ring
        nextCoords = new int[]{lastX, lastY-1}; // send it up
      } else {
        if (lastY < midY && abs(lastY-midY) > abs(lastX-midX)) {
          nextCoords = new int[]{lastX+1, lastY};
        } else if (lastX > midX && abs(lastX-midX) >= abs(lastY-midY) && !(lastX-midX == lastY-midY)) {
          nextCoords = new int[]{lastX, lastY+1};
        } else if (lastY > midY && abs(lastY-midY) >= abs(lastX-midX) && !(lastY-midY == midX-lastX)) {
          nextCoords = new int[]{lastX-1, lastY};
        } else {
          nextCoords = new int[]{lastX, lastY-1};
        }
      }
      if (nextCoords[1] < 0) {
        nextCoords = new int[] {midX + (midX - nextCoords[0]) + 1, nextCoords[1] + 1};
      } else if (nextCoords[1] >= mpg.height) {
        nextCoords = new int[] {midX - (nextCoords[0]-midX), nextCoords[1] - 1};
      }
      lastCoords = nextCoords;
      pixelsDrawn++;
      return nextCoords;
    }
  }
}

void updateGPU() {
  /*stringShader.set("xMinSmall", (float)(xMin % 0.0000001) * 1000000);
  stringShader.set("xMaxSmall", (float)(xMax % 0.0000001) * 1000000);
  stringShader.set("yMinSmall", (float)(yMin % 0.0000001) * 1000000);
  stringShader.set("yMaxSmall", (float)(yMax % 0.0000001) * 1000000);*/
  
  stringShader.set("xMinBig", (float)xMin);
  stringShader.set("xMaxBig", (float)xMax);
  stringShader.set("yMinBig", (float)yMin);
  stringShader.set("yMaxBig", (float)yMax);
  stringShader.set("iterations", maxIterations);
  mfilter(stringShader);
}

void setupRect() {
  xMin = -2.5;
  xMax = 1.5;
  yMin = -2 * ((mpg.height+0.0)/mpg.width);
  yMax = 2 * ((mpg.height+0.0)/mpg.width);
  bounds = new Stack(1000);
}

void setupGraphics() {
  mpg = createGraphics(width, height);
}

void clearBrot() {
  mpg.beginDraw();
  mpg.background(10);
  mpg.endDraw();
  lastCoords = null;
  pixelsDrawn = 0;
}

double map (double val, double min1, double max1, double min2, double max2) {
    double perc = (val - min1) / (max1-min1);
    double ret = min2 + perc * (max2-min2);
    return ret;
}

boolean elementsInFocus() {
  for (UIElement e : elements) {
    if (e instanceof Dropdown) {
      if (e.inFocus != 0) {
        return true;
      }
    }
  }
  return false;
}

public color hsvToRgb(float hue, float saturation, float value) {

    int h = (int)(hue * 6);
    float f = hue * 6 - h;
    float p = value * (1 - saturation);
    float q = value * (1 - f * saturation);
    float t = value * (1 - (1 - f) * saturation);

    switch (h) {
      case 0: return color(value * 255, t * 255, p * 255);
      case 1: return color(q * 255, value * 255, p * 255);
      case 2: return color(p * 255, value * 255, t * 255);
      case 3: return color(p * 255, q * 255, value * 255);
      case 4: return color(t * 255, p * 255, value * 255);
      case 5: return color(value * 255, p * 255, q * 255);
      default: throw new RuntimeException("Something went wrong when converting from HSV to RGB. Input was " + hue + ", " + saturation + ", " + value);
    }
}

class Button extends UIElement {
  float x, y, w, h;
  String buttonText;
  boolean active, beingPressed;
  float rounding;
  Button() {
    elements.add(this);
    active = false;
  }
  Button (String bText, float x, float y, float w, float h) {
    this();
    this.buttonText = bText;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.rounding = 5;
  }
  
  void draw() {
    onScreen = true;
    stroke(0);
    strokeWeight(1);
    fill(255);
    if (!othersFocus() && mouseIn(x, y, w, h, 1)) {
      fill (240);
      if (beingPressed) {
        fill (220);
      }
    }
    rect(x, y, w, h, rounding);
    if (buttonText.equals("")) {
      float triW = -10;
      float triH = 40;
      float triX = x + w - (w + triW)/2.0;
      float triY = y + (h - triH)/2.0;
      if (x == 0) {
        triW = 10;
        triX = x + (w - triW)/2.0 + 1;
      }
      noStroke();
      fill(100);
      triangle(triX, triY, triX+triW, triY+triH/2.0, triX, triY+triH);
    } else {
      fill(50);
      textSize(h * (16.0/30.0));
      textAlign(CENTER, CENTER);
      text(buttonText, x + w/2, y + h/2);
    }
    if (active) {
      active = false;
    }
  }
  
  boolean hoveredOver() {
    return mouseIn(x, y, w, h, 1);
  }
  
  void setRounding(float newRound) {
    this.rounding = newRound;
  }
  
  void mousePressed() {
    if (mouseIn(x, y, w, h, 1) && onScreen) {
      if (!othersFocus()) {
        beingPressed = true;
      }
    }
  }
  
  void mouseReleased() {
    if (mouseIn(x, y, w, h, 1) && onScreen) {
      if (!othersFocus() && beingPressed) {
        active = true;
      }
    }
    beingPressed = false;
  }
  
  boolean othersFocus() {
    boolean ret = false;
    for (UIElement d : elements) {
      if (d.inFocus != 0 && !(d == this)) {
        ret = true;
      }
    }
    return ret;
  }
}

abstract class UIElement {
  int inFocus;
  boolean onScreen;
  abstract void mousePressed();
  abstract void mouseReleased();
}

class Dropdown extends UIElement {
  String[] options;
  String value;
  float x, y, w, h;
  boolean dropped;
  
  Dropdown(float x, float y, float w, String[] options, String defaultVal) {
    this.options = options;
    this.value = defaultVal;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = 30;
    dropped = false;
    inFocus = 0;
    elements.add(this);
  }
  
  void draw() {
    onScreen = true;
    drawBackground();
    drawText();
    drawArrow();
    if (dropped) {
      float maxWidth = 0;
      textSize(15);
      for (int i = 0; i < options.length; i++) {
        float thisW = textWidth(options[i]);
        maxWidth = max(maxWidth, thisW);
      }
      float currY = y+h+5;
      for (int i = 0; i < options.length; i++) {
        drawOption(options[i], x, currY, maxWidth + 20, h);
        currY += h;
      }
    }
    if (inFocus == 2) {
      inFocus = 0;
    }
  }
  
  void mousePressed() {
    if (onScreen) {
      boolean othersFocus = false;
      for (UIElement d : elements) {
        if (d.inFocus != 0 && !(d == this)) {
          othersFocus = true;
        }
      }
      if (mouseIn (x, y, w, h, 1) && !othersFocus) {
        dropped = !dropped;
        if (dropped) inFocus = 1;
        else inFocus = 0;
      }
      if (dropped) {
        float maxWidth = 0;
        textSize(15);
        for (int i = 0; i < options.length; i++) {
          float thisW = textWidth(options[i]);
          maxWidth = max(maxWidth, thisW);
        }
        float currY = y+h+5;
        for (int i = 0; i < options.length; i++) {
          if (mouseIn (x, currY, max(maxWidth+20, 100), h, 1)) {
            value = options[i];
            dropped = false;
            inFocus = 2;
            return;
          }
          currY += h;
        }
        if (!mouseIn(x, y, w, h, 1)) {
          dropped = false;
          inFocus = 0;
        }
      }
    }
  }
  
  void mouseReleased() {}
  
  void drawOption(String opText, float opX, float opY, float opW, float opH) {
    noStroke();
    fill (255);
    opW = max(opW, 100);
    if (mouseIn (opX, opY, opW, opH, 1)) {
      fill (200);
    }
    rect (opX, opY, opW, opH);
    fill (50);
    textAlign(LEFT, CENTER);
    text(opText, opX+10, opY+opH/2.0);
  }
  
  void drawBackground() {
    stroke(0);
    strokeWeight(1);
    fill (255);
    rect (x, y, w, h, 5);
  }
  
  void drawText() {
    fill (50);
    textSize(16);
    textAlign(LEFT, CENTER);
    String display = "";
    float textW = textWidth("...");
    int index = 0;
    while (textW < w-10-29 && index < value.length()) {
      display += value.charAt(index);
      textW += textWidth(value.charAt(index));
      index++;
    }
    if (textW >= w-10-29) {
      if (index < value.length()) {
        display += "...";
      }
    }
    text(display, x+10, y+h/2.0);
  }
  
  void drawArrow() {
    noStroke();
    fill(255);
    rect(x+w-29, y+3, 27, h-5);
    strokeWeight(3);
    stroke (180);
    if (mouseIn (x, y, w, h, 1)) {
      stroke (100);
    }
    float arrowX = x+w-20;
    float arrowY = y+13;
    float arrowW = 12;
    float arrowH = 7+(h-5)/2.0-13;
    line (arrowX, arrowY, arrowX+arrowW/2.0, arrowY+arrowH);
    line (arrowX+arrowW/2.0, arrowY+arrowH, arrowX+arrowW, arrowY);
  }
}

boolean mouseIn(float x, float y, float w, float h, float precision) {
  for (float a = 0; a < 1; a += (1.0/precision)) {
    float ax = a*mouseX + (1-a)*pmouseX;
    float ay = a*mouseY + (1-a)*pmouseY;
    if (ax >= x && ax < x+w && ay >= y && ay < y+h) {
      return true;
    }
  }
  return false;
}

class Stack {
  
  double[][] arr;
  int size;
  
  Stack (int maxSize) {
    arr = new double[maxSize][4];
    size = 0;
  }
  
  void push(double[] x) {
    arr[size] = x;
    size++;
  }
  
  double[] pop() {
    size--;
    return arr[size];
  }
  
  double[] peek() {
    return arr[size-1];
  }
  
  boolean isEmpty() {
    return size <= 0;
  }
  
}