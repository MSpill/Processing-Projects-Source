
ArrayList<UIElement> elements;

PerlinNoiseGenerator png;

int panelW = 330;

MultiSlider colorPaletteSlider;
Slider mapScaleSlider, octavesSlider, persistenceSlider, lacunaritySlider, heightScaleSlider, heightOffsetSlider;
Slider degreeSlider, baseSlider, coefficientSlider, maxValSlider, growthSlider;
Button newSeedButton;
Button resetButton;
Dropdown transformDrop, gradientOffsetDrop;
Checkbox islandCheckbox;

int step;
int drawX, drawY;
void setup() {
  size ((int)(330 + max(screenHeight * 0.75,560) * (34.0/30.0)), (int)(max(screenHeight * 0.75,560)));
  //mp = createGraphics(width-panelW,height);
  elements = new ArrayList<UIElement>();
  createPanel();
  step = (int)((width-panelW) / 42);
  drawX = panelW;
  drawY = 0;
}

void draw() {
  if (png == null) {
    png = new PerlinNoiseGenerator(int(random(999999)));
  }
  handleUI();
  drawMap();
  //image (mp, panelW, 0, width-panelW, height);
  drawPanel();
}

void handleUI() {
  boolean needReset = false;
  for (UIElement e : elements) {
    if (e instanceof Slider && ((Slider)e).getVal() != ((Slider)e).prevVal && e.inFocus != 0) {
      needReset = true;
    }
    if (e instanceof Button && ((Button)e).active) {
      needReset = true;
    }
    if (e instanceof Dropdown && e.inFocus == 2) {
      needReset = true;
    }
    if (e instanceof Checkbox && e.inFocus == 1) {
      needReset = true;
    }
    if (e instanceof MultiSlider && ((MultiSlider)e).changed && e.inFocus != 0) {
      needReset = true;
    }
  }
  if (needReset) {
    step = (int)((width-panelW) / 42);
    drawX = panelW;
    drawY = 0;
  }
  if (newSeedButton.active) {
    png = new PerlinNoiseGenerator(int(random(99999)));
  }
  if (transformDrop.inFocus == 2) {
    degreeSlider.onScreen = false;
    baseSlider.onScreen = false;
    coefficientSlider.onScreen = false;
    maxValSlider.onScreen = false;
    growthSlider.onScreen = false;
    if (transformDrop.value.equals("Polynomial")) {
      degreeSlider.onScreen = true;
    } else if (transformDrop.value.equals("Exponential")) {
      baseSlider.onScreen = true;
      coefficientSlider.onScreen = true;
    } else if (transformDrop.value.equals("Polynomial")) {
      maxValSlider.onScreen = true;
      growthSlider.onScreen = true;
    }
  }
  if (resetButton.active) {
    setup();
  }
}

void mousePressed() {
  for (UIElement e : elements) {
    e.mousePressed();
  }
}

void mouseReleased() {
  for (UIElement e : elements) {
    e.mouseReleased();
  }
}

void drawMap() {
  //mp.beginDraw();
  noStroke();
  float mapSize = mapScaleSlider.getVal() * 0.001;
  int octaves = int(octavesSlider.getVal());
  float lacunarity = lacunaritySlider.getVal();
  float persistence = persistenceSlider.getVal();
  float heightScale = heightScaleSlider.getVal();
  float heightOffset = heightOffsetSlider.getVal();
  int n = 0;
  while (n < 1600) {
    float x = drawX-panelW;
    float y = drawY;
    float z = 0;
    for (int i = 0; i < octaves; i++) {
      z += png.noise2 (i*100 + (x+step/2.0) * pow(lacunarity, i) * mapSize, i * 100 + (y+step/2.0) * pow(lacunarity, i) * mapSize) * pow(persistence, -i);
    }
    z *= heightScale;
    z += heightOffset;
    //z = pow(z, frameCount*0.01 + 1.0);
    String transVal = transformDrop.value;
    if (transVal.equals("Polynomial")) {
      z = pow(z, int(degreeSlider.getVal()));
    } else if (transVal.equals("Exponential")) {
      z = coefficientSlider.getVal()*pow(baseSlider.getVal(), z);
    } else if (transVal.equals("Logistic")) {
      z = maxValSlider.getVal() / (1 + exp(-growthSlider.getVal() * z));
    }
    //z = pow(int(degreeSlider.getVal()), z);
    if (isNaN(z)) {
      z = 0;
    }
    if (islandCheckbox.active) {
      float mult = exp(-0.00003*pow(dist(x, y, (width-panelW)/2.0, height/2.0), 2));
      z *= clamp(mult, 0, 1);
    }
    if (z < 0) z = 0;
    color col;
    MultiSlider cps = colorPaletteSlider;
    float l1 = cps.getVal(0);
    float l2 = cps.getVal(1);
    float l3 = cps.getVal(2);
    float l4 = cps.getVal(3);
    float l5 = cps.getVal(4);
    float l6 = cps.getVal(5);
    float l7 = cps.getVal(6);
    if (z < l1) {
      color reallyDeepCol = color (#4E36DE);
      color deepCol = color (#6348FF);
      col = (lerpColor (reallyDeepCol, deepCol, z/l1));
    } else if (z < l2) {
      color deepCol = color (#6348FF);
      color shallowCol = color (#30E4FA);
      col = (lerpColor(deepCol, shallowCol, (z-l1)/(l2-l1)));
    } else if (z < l3) {
      color beachCol = color (#F4FAA4);
      color landCol = color (#6ED68C);
      col = (lerpColor(beachCol, landCol, (z-l2)/(l3-l2)));
    } else if (z < l4) {
      color landCol = color (#6ED68C);
      color darkLandCol = color (#51AA69);
      col = (lerpColor (landCol, darkLandCol, (z-l3)/(l4-l3)));
    } else if (z < l5) {
      color darkLandCol = color (#51AA69);
      color darkerLandCol = color (#488659);
      col = (lerpColor (darkLandCol, darkerLandCol, (z-l4)/(l5-l4)));
    } else if (z < l6) {
      color darkerLandCol = color (#488659);
      color greyCol = color (#797979);
      col = (lerpColor (darkerLandCol, greyCol, (z-l5)/(l6-l5)));
    } else if (z < l7) {
      color greyCol = color (#797979);
      color white = color(255);
      col = (lerpColor (greyCol, white, (z-l6)/(l7-l6)));
    } else {
      col = color(255);
    }
    fill (col);
    rect(x+panelW, y, step, step);
    drawX += step;
    if (drawX >= width) {
      drawX = panelW;
      drawY += step;
      if (drawY >= height) {
        if (step > 1) {
          step = step/2;
        }
        drawY = 0;
      }
    }
    n++;
  }
  //mp.endDraw();
}

void createPanel() {
  float midX = panelW/2;
  mapScaleSlider = new Slider (120, 60, 185, 0.5, 10, 5, true);
  float[] palette = {0.05, 0.2, 0.27, 0.4, 0.7, 0.95, 1.5};
  color[] cols = {color (#6348FF), color (#F4FAA4), color (#6ED68C), color (#51AA69), color (#488659), color (#797979), color(255)};
  colorPaletteSlider = new MultiSlider (25, 118, 280, 0, 1.5, palette, cols);
  octavesSlider = new Slider (125, 205, 180, 1, 10, 7, false);
  octavesSlider.rounded = true;
  persistenceSlider = new Slider (125, 235, 180, 0.5, 5, 1.9, true);
  lacunaritySlider = new Slider (125, 265, 180, 0.5, 5, 2.5, true);
  heightScaleSlider = new Slider (125, 295, 180, 0, 4, 1.3, true);
  heightOffsetSlider = new Slider (125, 325, 180, -1, 1, 0.55, true);
  islandCheckbox = new Checkbox (125, 345, 20, 20, true);
  String[] transformOptions = {"None", "Polynomial", "Exponential", "Logistic"};
  transformDrop = new Dropdown (160, 372, 145, transformOptions, "Polynomial");
  degreeSlider = new Slider (115, 423, 170, 1, 8, 2, false);
  degreeSlider.rounded = true;
  coefficientSlider = new Slider (115, 423, 170, 0, 1.5, 0.1, true);
  baseSlider = new Slider (115, 453, 170, 0.5, 10, 5, true);
  growthSlider = new Slider (115, 423, 170, 1, 8, 1, true);
  maxValSlider = new Slider (115, 453, 170, 0.1, 4, 1.5, true);
  resetButton = new Button ("Reset Settings", 15, 483, panelW/2.0-15-5, 30);
  newSeedButton = new Button ("New seed", panelW/2.0+5, 483, panelW/2.0-20, 30);
}

void drawPanel() {
  stroke(0);
  strokeWeight(1);
  fill (230);
  rect (-2, -2, panelW+1, height+3);
  fill(0);
  textSize(26);
  textAlign(CENTER, BOTTOM);
  text("Appearance", panelW/2.0, 39);
  textAlign(CENTER, TOP);
  text("Generation", panelW/2.0, 155);
  fill(50);
  textSize(18);
  textAlign(LEFT, CENTER);
  text("Map size: ", 15, 59);
  textAlign(CENTER, BOTTOM);
  text("Color layers:", panelW/2.0, 100);
  mapScaleSlider.draw();
  colorPaletteSlider.draw();
  stroke(100);
  strokeWeight(1);
  line (15, 145, panelW-15, 145);
  fill(50);
  textSize(18);
  textAlign(LEFT, CENTER);
  text("Octaves: ", 15, 204);
  text("Persistence: ", 15, 234);
  text("Lacunarity: ", 15, 264);
  text("Height mult: ", 15, 294);
  text("Offset: ", 15, 324);
  text("Island: ", 15, 354);
  text("Transformation: ", 15, 388);
  if (transformDrop.value.equals("Polynomial")) {
    text("Degree: ", 35, 422);
    degreeSlider.draw();
  } else if (transformDrop.value.equals("Exponential")) {
    text("Multiply: ", 35, 422);
    text("Base: ", 35, 452);
    coefficientSlider.draw();
    baseSlider.draw();
  } else if (transformDrop.value.equals("Logistic")) {
    text("Growth: ", 35, 422);
    text("Max val: ", 35, 452);
    growthSlider.draw();
    maxValSlider.draw();
  }
  octavesSlider.draw();
  persistenceSlider.draw();
  lacunaritySlider.draw();
  heightScaleSlider.draw();
  heightOffsetSlider.draw();
  newSeedButton.draw();
  resetButton.draw();
  islandCheckbox.draw();
  transformDrop.draw();
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
    fill(50);
    textSize(h * (16.0/30.0));
    textAlign(CENTER, CENTER);
    text(buttonText, x + w/2, y + h/2);
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
}

abstract class UIElement {
  int inFocus;
  boolean onScreen;
  abstract void mousePressed();
  abstract void mouseReleased();
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
      textSize(16);
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
        textSize(16);
        for (int i = 0; i < options.length; i++) {
          float thisW = textWidth(options[i]);
          maxWidth = max(maxWidth, thisW);
        }
        float currY = y+h+5;
        for (int i = 0; i < options.length; i++) {
          if (mouseIn (x, currY, maxWidth + 20, h, 1)) {
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
    textSize(17);
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

class Checkbox extends UIElement {
  
  float x, y, w, h;
  boolean pressed;
  boolean active;
  Checkbox (float x, float y, float w, float h, boolean active) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.active = active;
    elements.add(this);
  }
  
  void draw() {
    onScreen = true;
    fill (255);
    if (mouseIn (x, y, w, h, 1)) {
      fill (230);
      if (mousePressed) {
        fill (210);
      }
    }
    stroke(0);
    strokeWeight(1);
    rect (x, y, w, h, 3);
    if (active) {
      noStroke();
      fill (100);
      rect (x + 5, y + 5, w - 9, h - 9, 3);
    }
    if (inFocus == 1) {
      inFocus = 0;
    }
  }
  
  void mousePressed() {
    if (onScreen && !othersFocus()) {
      if (mouseIn(x, y, w, h, 1)) {
        pressed = true;
      }
    }
  }
  
  void mouseReleased() {
    if (onScreen && !othersFocus() && pressed) {
      if (mouseIn(x, y, w, h, 1)) {
        pressed = false;
        active = !active;
        inFocus = 1;
      }
    }
  }
  
}

class Slider extends UIElement {
  
  float x, y, w, vmin, vmax;
  float pos;
  float prevVal;
  float offset;
  boolean showVal, rounded;
  
  Slider (float x, float y, float w, float pos) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.pos = pos;
    elements.add(this);
  }
  
  Slider (float x, float y, float w, float vmin, float vmax, float pos, boolean show) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.vmin = vmin;
    this.vmax = vmax;
    this.pos = map(pos, vmin, vmax, 0, 1);
    this.showVal = show;
    elements.add(this);
  }
  
  void draw() {
    onScreen = true;
    prevVal = getVal();
    if (inFocus == 1) {
      setVal();
    }
    fill (190);
    strokeWeight(1);
    stroke (140);
    rect (x, y - 2, w, 4, 1.5);
    if (rounded) {
      stroke(120);
      strokeWeight(1);
      for (int i = (int)vmin; i <= (int)vmax; i++) {
        float lx = map (i, vmin, vmax, x, x+w);
        line (lx, y-4, lx, y+4);
      }
    }
    fill (255);
    if (inFocus == 1) {
      fill(215);
    } else if (mousedOver() != -9999) {
      fill (240);
    }
    stroke (120);
    if (!showVal) {
      ellipse (x + pos*w, y, 17, 17);
    } else {
      float rPos = map(pos, 0, 1, x+25, x+w-25);
      rect (rPos - 25, y - 10, 50, 20, 10);
      fill (0);
      textSize(15);
      textAlign(CENTER, CENTER);
      text (round(map(pos, 0, 1, vmin, vmax)*10)/10.0+"", rPos, y);
    }
  }
  
  void mousePressed() {
    if (onScreen && !othersFocus()) {
      float offset = mousedOver();
      if (offset != -9999) {
        inFocus = 1;
        this.offset = offset;
      } else if (mouseX > x && mouseX < x+w && mouseY > y-3 && mouseY < y + 3) {
        this.offset = 0;
        setVal();
        inFocus = 1;
      }
    }
  }
  
  void mouseReleased() {
    inFocus = 0;
  }
  
  float getVal() {
    return map(pos, 0, 1, vmin, vmax);
  }
  
  float mousedOver() {
    if (!showVal) {
      if (dist(mouseX, mouseY, x + pos*w, y) <= 10) {
        return x + pos*w - mouseX;
      } else {
        return -9999;
      }
    } else {
      float rPos = map(pos, 0, 1, x+25, x+w-25);
      if (mouseIn (rPos - 25, y- 10, 50, 20, 1)) {
        return rPos - mouseX;
      } else {
        return -9999;
      }
    }
  }
  
  void setVal() {
    if (!showVal) {
      pos = min(max((mouseX + offset -x)/w, 0), 1);
    } else {
      pos = map(clamp(mouseX + offset, x + 25, x+w - 25), x+25, x+w-25, 0, 1);
    }
    if (rounded) {
      pos = map(round(map(pos, 0, 1, vmin, vmax)), vmin, vmax, 0, 1);
    }
  }
}

class MultiSlider extends UIElement {
  float x, y, w, vmin, vmax;
  float[] pos;
  color[] cols;
  float offset;
  int selected;
  float lastRmx;
  boolean changed;
  private float rW = 4;
  MultiSlider(float x, float y, float w, float vmin, float vmax, float[] vals) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.vmin = vmin;
    this.vmax = vmax;
    pos = new float[vals.length];
    for (int i = 0; i < vals.length; i++) {
      pos[i] = map(vals[i], vmin, vmax, 0, 1);
    }
    cols = new color[pos.length];
    elements.add(this);
  }
  
  MultiSlider(float x, float y, float w, float vmin, float vmax, float[] vals, color[] cols) {
    this(x, y, w,vmin, vmax, vals);
    this.cols = cols;
  }
  
  void draw() {
    onScreen = true;
    if (inFocus == 1) {
      setVal();
    }
    fill (190);
    strokeWeight(1);
    stroke (140);
    rect (x, y - 2, w, 4, 1.5);
    for (int i = 0; i < pos.length; i++) {
      float mult = 1;
      if (inFocus == 1 && selected == i) {
        mult = 0.82;
      } else if (mouseIn(x + pos[i]*w - rW, y - 8, rW*2, 16, 1)) {
        mult = 0.95;
      }
      fill(lerpColor(color(0), cols[i], mult));
      stroke (120);
      rect (x + pos[i]*w - rW, y - 8, rW*2, 16);
    }
  }
  
  void mousePressed() {
    if (onScreen && !othersFocus()) {
      for (int i = 0; i < pos.length; i++) {
        if (mouseIn(x + pos[i]*w - rW, y - 8, rW*2, 16, 1)) {
          inFocus = 1;
          selected = i;
          offset = x + pos[i]*w - mouseX;
        }
      }
    }
  }
  
  void mouseReleased() {
    inFocus = 0;
    changed = false;
  }
  
  void setVal() {
    float rmx = clamp(mouseX + offset, x, x+w);
    if (selected > 0) {
      rmx = clamp(rmx, map(pos[selected-1], 0, 1, x, x+w) + rW*2, x+w);
    }
    if (selected < pos.length-1) {
      rmx = clamp(rmx, x, map(pos[selected+1], 0, 1, x, x+w) - rW*2);
    }
    if (rmx != lastRmx) {
      changed = true;
    } else {
      changed = false;
    }
    lastRmx = rmx;
    pos[selected] = map(rmx, x, x+w, 0, 1);
  }
  
  float getVal(int i) {
    return map(pos[i], 0, 1, vmin, vmax);
  }
  
}

float clamp(float val, float vmin, float vmax) {
  return min(max(val, vmin), vmax);
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

class Random {
  int seed;
  Random(int seed) {
    this.seed = seed;
  }
  
  int nextLong() {
    noiseSeed(seed);
    return (int)(random(2147483647));
  }
}

// This stuff all copied from https://mrl.nyu.edu/~perlin/experiments/packing/render/Noise.java
/**
 * Computes Perlin Noise for three dimensions.
 * <p>
 *
 * The result is a continuous function that interpolates a smooth path
 * along a series random points. The function is consitent, so given
 * the same parameters, it will always return the same value. The smoothing
 * function is based on the Improving Noise paper presented at Siggraph 2002.
 * <p>
 * Computing noise for one and two dimensions can make use of the 3D problem
 * space by just setting the un-needed dimensions to a fixed value.
 *
 * @author Justin Couch
 * @version $Revision: 1.4 $
 */
public class PerlinNoiseGenerator
{
    // Constants for setting up the Perlin-1 noise functions
    private static final int B = 0x1000;
    private static final int BM = 0xff;

    private static final int N = 0x1000;
    private static final int NP = 12;   /* 2^N */
    private static final int NM = 0xfff;

    /** Default seed to use for the random number generation */
    private static final int DEFAULT_SEED = 100;

    /** Default sample size to work with */
    private static final int DEFAULT_SAMPLE_SIZE = 256;

    /** The log of 1/2 constant. Used Everywhere */
    private final float LOG_HALF = (float)Math.log(0.5);

    /** Permutation array for the improved noise function */
    private int[] p_imp;

    /** P array for perline 1 noise */
    private int[] p;
    private float[][] g3;
    private float[][] g2;
    private float[] g1;


    /**
     * Create a new noise creator with the default seed value
     */
    public PerlinNoiseGenerator()
    {
        this(DEFAULT_SEED);
    }

    /**
     * Create a new noise creator with the given seed value for the randomness
     *
     * @param seed The seed value to use
     */
    public PerlinNoiseGenerator(int seed)
    {
        p_imp = new int[DEFAULT_SAMPLE_SIZE << 1];

        int i, j, k;
        Random rand = new Random(seed);

        // Calculate the table of psuedo-random coefficients.
        for(i = 0; i < DEFAULT_SAMPLE_SIZE; i++)
            p_imp[i] = i;

        // generate the psuedo-random permutation table.
        while(--i > 0)
        {
            k = p_imp[i];
            j = (int)(rand.nextLong() & DEFAULT_SAMPLE_SIZE);
            p_imp[i] = p_imp[j];
            p_imp[j] = k;
        }

        initPerlin1();
    }

    /**
     * Computes noise function for three dimensions at the point (x,y,z).
     *
     * @param x x dimension parameter
     * @param y y dimension parameter
     * @param z z dimension parameter
     * @return the noise value at the point (x, y, z)
     */
    public double improvedNoise(double x, double y, double z)
    {
        // Constraint the point to a unit cube
        int uc_x = (int)Math.floor(x) & 255;
        int uc_y = (int)Math.floor(y) & 255;
        int uc_z = (int)Math.floor(z) & 255;

        // Relative location of the point in the unit cube
        double xo = x - Math.floor(x);
        double yo = y - Math.floor(y);
        double zo = z - Math.floor(z);

        // Fade curves for x, y and z
        double u = fade(xo);
        double v = fade(yo);
        double w = fade(zo);

        // Generate a hash for each coordinate to find out where in the cube
        // it lies.
        int a =  p_imp[uc_x] + uc_y;
        int aa = p_imp[a] + uc_z;
        int ab = p_imp[a + 1] + uc_z;

        int b =  p_imp[uc_x + 1] + uc_y;
        int ba = p_imp[b] + uc_z;
        int bb = p_imp[b + 1] + uc_z;

        // blend results from the 8 corners based on the noise function
        double c1 = grad(p_imp[aa], xo, yo, zo);
        double c2 = grad(p_imp[ba], xo - 1, yo, zo);
        double c3 = grad(p_imp[ab], xo, yo - 1, zo);
        double c4 = grad(p_imp[bb], xo - 1, yo - 1, zo);
        double c5 = grad(p_imp[aa + 1], xo, yo, zo - 1);
        double c6 = grad(p_imp[ba + 1], xo - 1, yo, zo - 1);
        double c7 = grad(p_imp[ab + 1], xo, yo - 1, zo - 1);
        double c8 = grad(p_imp[bb + 1], xo - 1, yo - 1, zo - 1);

        return lerp(w, lerp(v, lerp(u, c1, c2), lerp(u, c3, c4)),
                       lerp(v, lerp(u, c5, c6), lerp(u, c7, c8)));
    }

    /**
     * 1-D noise generation function using the original perlin algorithm.
     *
     * @param x Seed for the noise function
     * @return The noisy output
     */
    public float noise1(float x)
    {
        float t = x + N;
        int bx0 = ((int) t) & BM;
        int bx1 = (bx0 + 1) & BM;
        float rx0 = t - (int) t;
        float rx1 = rx0 - 1;

        float sx = sCurve(rx0);

        float u = rx0 * g1[p[bx0]];
        float v = rx1 * g1[p[bx1]];

        return lerp(sx, u, v);
    }

    /**
     * Create noise in a 2D space using the orignal perlin noise algorithm.
     *
     * @param x The X coordinate of the location to sample
     * @param y The Y coordinate of the location to sample
     * @return A noisy value at the given position
     */
    public float noise2(float x, float y)
    {
        float t = x + N;
        int bx0 = ((int)t) & BM;
        int bx1 = (bx0 + 1) & BM;
        float rx0 = t - (int)t;
        float rx1 = rx0 - 1;

        t = y + N;
        int by0 = ((int)t) & BM;
        int by1 = (by0 + 1) & BM;
        float ry0 = t - (int)t;
        float ry1 = ry0 - 1;

        int i = p[bx0];
        int j = p[bx1];

        int b00 = p[i + by0];
        int b10 = p[j + by0];
        int b01 = p[i + by1];
        int b11 = p[j + by1];

        float sx = sCurve(rx0);
        float sy = sCurve(ry0);

        float[] q = g2[b00];
        float u = rx0 * q[0] + ry0 * q[1];
        q = g2[b10];
        float v = rx1 * q[0] + ry0 * q[1];
        float a = lerp(sx, u, v);

        q = g2[b01];
        u = rx0 * q[0] + ry1 * q[1];
        q = g2[b11];
        v = rx1 * q[0] + ry1 * q[1];
        float b = lerp(sx, u, v);

        return lerp(sy, a, b);
    }

    /**
     * Create noise in a 3D space using the orignal perlin noise algorithm.
     *
     * @param x The X coordinate of the location to sample
     * @param y The Y coordinate of the location to sample
     * @param z The Z coordinate of the location to sample
     * @return A noisy value at the given position
     */
    public float noise3(float x, float y, float z)
    {
      float t = x + (float)N;
        int bx0 = ((int)t) & BM;
        int bx1 = (bx0 + 1) & BM;
        float rx0 = (float)(t - (int)t);
        float rx1 = rx0 - 1;

        t = y + (float)N;
        int by0 = ((int)t) & BM;
        int by1 = (by0 + 1) & BM;
        float ry0 = (float)(t - (int)t);
        float ry1 = ry0 - 1;

        t = z + (float)N;
        int bz0 = ((int)t) & BM;
        int bz1 = (bz0 + 1) & BM;
        float rz0 = (float)(t - (int)t);
        float rz1 = rz0 - 1;

        int i = p[bx0];
        int j = p[bx1];

        int b00 = p[i + by0];
        int b10 = p[j + by0];
        int b01 = p[i + by1];
        int b11 = p[j + by1];

        t  = sCurve(rx0);
        float sy = sCurve(ry0);
        float sz = sCurve(rz0);

        float[] q = g3[b00 + bz0];
        float u = (rx0 * q[0] + ry0 * q[1] + rz0 * q[2]);
        q = g3[b10 + bz0];
        float v = (rx1 * q[0] + ry0 * q[1] + rz0 * q[2]);
        float a = lerp(t, u, v);

        q = g3[b01 + bz0];
        u = (rx0 * q[0] + ry1 * q[1] + rz0 * q[2]);
        q = g3[b11 + bz0];
        v = (rx1 * q[0] + ry1 * q[1] + rz0 * q[2]);
        float b = lerp(t, u, v);

        float c = lerp(sy, a, b);

        q = g3[b00 + bz1];
        u = (rx0 * q[0] + ry0 * q[1] + rz1 * q[2]);
        q = g3[b10 + bz1];
        v = (rx1 * q[0] + ry0 * q[1] + rz1 * q[2]);
        a = lerp(t, u, v);

        q = g3[b01 + bz1];
        u = (rx0 * q[0] + ry1 * q[1] + rz1 * q[2]);
        q = g3[b11 + bz1];
        v = (rx1 * q[0] + ry1 * q[1] + rz1 * q[2]);
        b = lerp(t, u, v);

        float d = lerp(sy, a, b);

        return lerp(sz, c, d);
    }

    /**
     * Create a turbulent noise output based on the core noise function. This
     * uses the noise as a base function and is suitable for creating clouds,
     * marble and explosion effects. For example, a typical marble effect would
     * set the colour to be:
     * <pre>
     *    sin(point + turbulence(point) * point.x);
     * </pre>
     */
    public double imporvedTurbulence(double x,
                                     double y,
                                     double z,
                                     float loF,
                                     float hiF)
    {
        double p_x = x + 123.456f;
        double p_y = y;
        double p_z = z;
        double t = 0;
        double f;

        for(f = loF; f < hiF; f *= 2)
        {
            t += Math.abs(improvedNoise(p_x, p_y, p_z)) / f;

            p_x *= 2;
            p_y *= 2;
            p_z *= 2;
        }

        return t - 0.3;
    }

    /**
     * Create a turbulance function in 2D using the original perlin noise
     * function.
     *
     * @param x The X coordinate of the location to sample
     * @param y The Y coordinate of the location to sample
     * @param freq The frequency of the turbluance to create
     * @return The value at the given coordinates
     */
    public float turbulence2(float x, float y, float freq)
    {
        float t = 0;

        do
        {
            t += noise2(freq * x, freq * y) / freq;
            freq *= 0.5f;
        }
        while (freq >= 1);

        return t;
    }

    /**
     * Create a turbulance function in 3D using the original perlin noise
     * function.
     *
     * @param x The X coordinate of the location to sample
     * @param y The Y coordinate of the location to sample
     * @param z The Z coordinate of the location to sample
     * @param freq The frequency of the turbluance to create
     * @return The value at the given coordinates
     */
    public float turbulence3(float x, float y, float z, float freq)
    {
        float t = 0;

        do
        {
            t += noise3(freq * x, freq * y, freq * z) / freq;
            freq *= 0.5f;
        }
        while (freq >= 1);

        return t;
    }

    /**
     * Create a 1D tileable noise function for the given width.
     *
     * @param x The X coordinate to generate the noise for
     * @param w The width of the tiled block
     * @return The value of the noise at the given coordinate
     */
    public float tileableNoise1(float x, float w)
    {
        return (noise1(x)     * (w - x) +
                noise1(x - w) *      x) / w;
    }

    /**
     * Create a 2D tileable noise function for the given width and height.
     *
     * @param x The X coordinate to generate the noise for
     * @param y The Y coordinate to generate the noise for
     * @param w The width of the tiled block
     * @param h The height of the tiled block
     * @return The value of the noise at the given coordinate
     */
    public float tileableNoise2(float x, float y, float w, float h)
    {
        return (noise2(x,     y)     * (w - x) * (h - y) +
                noise2(x - w, y)     *      x  * (h - y) +
                noise2(x,     y - h) * (w - x) *      y  +
                noise2(x - w, y - h) *      x  *      y) / (w * h);
    }

    /**
     * Create a 3D tileable noise function for the given width, height and
     * depth.
     *
     * @param x The X coordinate to generate the noise for
     * @param y The Y coordinate to generate the noise for
     * @param z The Z coordinate to generate the noise for
     * @param w The width of the tiled block
     * @param h The height of the tiled block
     * @param d The depth of the tiled block
     * @return The value of the noise at the given coordinate
     */
    public float tileableNoise3(float x,
                                float y,
                                float z,
                                float w,
                                float h,
                                float d)
    {
        return (noise3(x,     y,     z)     * (w - x) * (h - y) * (d - z) +
                noise3(x - w, y,     z)     *      x  * (h - y) * (d - z) +
                noise3(x,     y - h, z)     * (w - x) *      y  * (d - z) +
                noise3(x - w, y - h, z)     *      x  *      y  * (d - z) +
                noise3(x,     y,     z - d) * (w - x) * (h - y) *      z  +
                noise3(x - w, y,     z - d) *      x  * (h - y) *      z  +
                noise3(x,     y - h, z - d) * (w - x) *      y  *      z  +
                noise3(x - w, y - h, z - d) *      x  *      y  *      z) /
                (w * h * d);
    }

    /**
     * Create a turbulance function that can be tiled across a surface in 2D.
     *
     * @param x The X coordinate of the location to sample
     * @param y The Y coordinate of the location to sample
     * @param w The width to tile over
     * @param h The height to tile over
     * @param freq The frequency of the turbluance to create
     * @return The value at the given coordinates
     */
    public float tileableTurbulence2(float x,
                                     float y,
                                     float w,
                                     float h,
                                     float freq)
    {
        float t = 0;

        do
        {
            t += tileableNoise2(freq * x, freq * y, w * freq, h * freq) / freq;
            freq *= 0.5f;
        }
        while (freq >= 1);

        return t;
    }

    /**
     * Create a turbulance function that can be tiled across a surface in 3D.
     *
     * @param x The X coordinate of the location to sample
     * @param y The Y coordinate of the location to sample
     * @param z The Z coordinate of the location to sample
     * @param w The width to tile over
     * @param h The height to tile over
     * @param d The depth to tile over
     * @param freq The frequency of the turbluance to create
     * @return The value at the given coordinates
     */
    public float tileableTurbulence3(float x,
                                     float y,
                                     float z,
                                     float w,
                                     float h,
                                     float d,
                                     float freq)
    {
        float t = 0;

        do
        {
            t += tileableNoise3(freq * x,
                                freq * y,
                                freq * z,
                                w * freq,
                                h * freq,
                                d * freq) / freq;
            freq *= 0.5f;
        }
        while (freq >= 1);

        return t;
    }


    /**
     * Simple lerp function using doubles.
     */
    private double lerp(double t, double a, double b)
    {
        return a + t * (b - a);
    }

    /**
     * Simple lerp function using floats.
     */
    private float lerp(float t, float a, float b)
    {
        return a + t * (b - a);
    }

    /**
     * Fade curve calculation which is 6t^5 - 15t^4 + 10t^3. This is the new
     * algorithm, where the old one used to be 3t^2 - 2t^3.
     *
     * @param t The t parameter to calculate the fade for
     * @return the drop-off amount.
     */
    private double fade(double t)
    {
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    /**
     * Calculate the gradient function based on the hash code.
     */
    private double grad(int hash, double x, double y, double z)
    {
        // Convert low 4 bits of hash code into 12 gradient directions.
        int h = hash & 15;
        double u = (h < 8 || h == 12 || h == 13) ? x : y;
        double v = (h < 4 || h == 12 || h == 13) ? y : z;

        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
    }

    /**
     * Simple bias generator using exponents.
     */
    private float bias(float a, float b)
    {
        return (float)Math.pow(a, Math.log(b) / LOG_HALF);
    }


    /*
     * Gain generator that caps to the range of [0, 1].
     */
    private float gain(float a, float b)
    {
        if(a < 0.001f)
            return 0;
        else if (a > 0.999f)
            return 1.0f;

        double p = Math.log(1.0f - b) / LOG_HALF;

        if(a < 0.5f)
            return (float)(Math.pow(2 * a, p) / 2);
        else
            return 1 - (float)(Math.pow(2 * (1.0f - a), p) / 2);
    }

    /**
     * S-curve function for value distribution for Perlin-1 noise function.
     */
    private float sCurve(float t)
    {
        return (t * t * (3 - 2 * t));
    }

    /**
     * 2D-vector normalisation function.
     */
    private void normalize2(float[] v)
    {
        float s = (float)(1 / Math.sqrt(v[0] * v[0] + v[1] * v[1]));
        v[0] *= s;
        v[1] *= s;
    }

    /**
     * 3D-vector normalisation function.
     */
    private void normalize3(float[] v)
    {
        float s = (float)(1 / Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]));
        v[0] *= s;
        v[1] *= s;
        v[2] *= s;
    }

    /**
     * Initialise the lookup arrays used by Perlin 1 function.
     */
    private void initPerlin1()
    {
        p = new int[B + B + 2];
        g3 = new float[B + B + 2][3];
        g2 = new float[B + B + 2][2];
        g1 = new float[B + B + 2];
        int i, j, k;

        for(i = 0; i < B; i++)
        {
            p[i] = i;

            g1[i] = (float)(((Math.random() * 2147483647) % (B + B)) - B) / B;

            for(j = 0; j < 2; j++)
                g2[i][j] = (float)(((Math.random() * 2147483647) % (B + B)) - B) / B;
            normalize2(g2[i]);

            for(j = 0; j < 3; j++)
                g3[i][j] = (float)(((Math.random() * 2147483647) % (B + B)) - B) / B;
            normalize3(g3[i]);
        }

        while(--i > 0)
        {
            k = p[i];
            j = (int)((Math.random() * 2147483647) % B);
            p[i] = p[j];
            p[j] = k;
        }

        for(i = 0; i < B + 2; i++)
        {
            p[B + i] = p[i];
            g1[B + i] = g1[i];
            for(j = 0; j < 2; j++)
                g2[B + i][j] = g2[i][j];
            for(j = 0; j < 3; j++)
                g3[B + i][j] = g3[i][j];
        }
    }
}