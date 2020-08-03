
class Slider {
  
  float x, y, w, h;
  float pos;
  boolean pMousePressed;
  boolean clickedOn = false;
  
  Slider (float x, float y, float w, float h, float pos) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.pos = pos;
  }
  
  void draw() {
    fill (150);
    strokeWeight(1);
    stroke (100);
    rect (x, y + h/2-4, w, 6, 1.5);
    fill (200);
    if (clickedOn) fill(170);
    stroke (120);
    rect (x + pos*w - 7, y, 14, h, 1.5);
  }
  
  void update() {
    if (mousePressed && !pMousePressed) {
      if (mouseX > x + pos*w - 7 && mouseY > y && mouseX < x + pos*w +7 && mouseY < y+h) {
        clickedOn = true;
      }
    }
    if (!mousePressed && pMousePressed) {
      clickedOn = false;
    }
    if (clickedOn) {
      pos = min(max((mouseX-x)/w, 0), 1);
    }
    pMousePressed = mousePressed;
  }
  
}

// Variables
float LR = 0.003;

float demand = 1.5, supply = 9, price = 1;
float cost = 1, income = 1001;
float priceTrend = 0;
float trendEffect = 40;
float valueFactor = 5;
float saveFactor = 0.5;

float momentum = 1;
int lastDir = 0;
int stillFrames = 0;

PGraphics pg, pg2; // External drawing surfaces for graphs

Slider costSlider, incomeSlider, valueSlider;

void setup() {
  size (1200, 600, P2D);
  
  // Setup drawing surfaces
  pg = createGraphics(width, height);
  pg2 = createGraphics(width, height);
  pg.beginDraw();
  pg.endDraw();
  pg2.beginDraw();
  pg2.endDraw();
  
  // Setup UI
  costSlider = new Slider (width-350/2.-100, 300, 200, 40, 0.5);
  incomeSlider = new Slider (width-350/2.-100, 385, 200, 40, 0.5);
  valueSlider = new Slider (width-350/2.-100, 385+85, 200, 40, 0.5);
}

void draw() {
  background(255);
  
  // Read slider values
  valueFactor = valueSlider.pos*4+1;
  cost = costSlider.pos*4+1;
  income = incomeSlider.pos*8+2;
  
  // Draw graphs
  if (frameCount % (width*2) >= width) {
    pg.beginDraw();
    pg.strokeWeight(3);
    pg.stroke(0, 255, 0);
    pg.point((frameCount%width), height-height*(price/15));
    pg.stroke(255, 0, 0);
    pg.point(frameCount%width, height-height*(demand/15));
    pg.stroke(0, 0, 255);
    pg.point(frameCount%width, height-height*(supply/15));
    pg.endDraw();
  } else {
    pg2.beginDraw();
    pg2.strokeWeight(3);
    pg2.stroke(0, 255, 0);
    pg2.point(frameCount%width, height-height*(price/15));
    pg2.stroke(255, 0, 0);
    pg2.point(frameCount%width, height-height*(demand/15));
    pg2.stroke(0, 0, 255);
    pg2.point(frameCount%width, height-height*(supply/15));
    pg2.endDraw();
  }
  if (frameCount % (width*2) == width) {
    pg.beginDraw();
    pg.background(255);
    pg.endDraw();
  }
  if (frameCount % (width*2) == 0) {
    pg2.beginDraw();
    pg2.background(255);
    pg2.endDraw();
  }
  image(pg, width-((frameCount+width)%(width*2))-350, -50, width, height);
  image(pg2, width-(frameCount%(width*2))-350, -50, width, height);
  
  // Draw time axis
  stroke(80);
  strokeWeight(3);
  textSize(17);
  line (0, height-50, width, height-50);
  for (int x = 0; x < width; x++) {
    if (x % 100 == 0) {
      line (70+x-frameCount%100, height-50, 70+x-frameCount%100, height-45);
      fill (0);
      textAlign(CENTER, TOP);
      text (int(x/100 + frameCount/100), 70+x-frameCount%100, height-45);
    }
  }
  // Legend
  textAlign (LEFT, CENTER);
  stroke (0, 255, 0);
  line (90, 20, 110, 20);
  stroke (255, 0, 0);
  line (90, 40, 110, 40);
  stroke (0, 0, 255);
  line (90, 60, 110, 60);
  fill(0);
  text ("Price ($)", 120, 20);
  text ("Demand (units)", 120, 40);
  text ("Supply (units)", 120, 60);
  noStroke();
  fill(255);
  rect(0, 0, 70, height);
  stroke(80);
  strokeWeight(3);
  // Y axis
  for (int y = 0; y < height; y++) {
    if ((y+1) % (height/7.5) == 0) {
      line (70, height-50-y, 65, height-50-y);
      textAlign(RIGHT, CENTER);
      fill(0);
      text (round((y+0.)/height*15), 60, height-50-y);
    }
  }
  pushMatrix();
  rotate(-PI/2);
  textSize(18);
  text ("Amount", -height/2+50, 25);
  popMatrix();
  text ("Time", (width-350)/2+70, height-19);
  textAlign (LEFT, CENTER);
  line (70, 0, 70, height-50);
  
  incrementVariables();
  
  // UI tab on right side of screen
  strokeWeight(1);
  fill (220);
  rect (width-350, 0, 350, height);
  fill (0);
  textSize (17);
  float realUnits = min(supply, demand, income/price);
  float realProfit = price*realUnits-c(supply);
  text ("Cost of production: " + int(cost*10)/10., width-350/2.-100, 282);
  text ("Spending money: " + int(income*10)/10., width-350/2.-100, 282+85);
  text ("Base value of good: " + int(valueFactor*10)/10., width-350/2.-100, 282+85*2);
  text ("Price trend effect on demand: \n" + int(max(logFunc(priceTrend*trendEffect),0)*100)+"%", width-350/2.-100, 200);
  textSize (28);
  text ("Profit: " + int(realProfit*10)/10., width-350/2.-100, 100);
  costSlider.update();
  costSlider.draw();
  incomeSlider.update();
  incomeSlider.draw();
  valueSlider.update();
  valueSlider.draw();
  
  // Tooltips
  if (mouseX > costSlider.x && mouseX < costSlider.x+costSlider.w && mouseY > costSlider.y-35 && mouseY < costSlider.y+costSlider.h && stillFrames > 15) {
    fill (0, 0, 0, 200);
    noStroke();
    rect (mouseX, mouseY, 224, 78, 4);
    fill (255);
    textSize (13.5);
    textAlign (LEFT, TOP);
    text ("This quantity represents the seller's cost to produce one unit of the good.", mouseX+12, mouseY+12, 200, 100);
  }
  if (mouseX > incomeSlider.x && mouseX < incomeSlider.x+incomeSlider.w && mouseY > incomeSlider.y-35 && mouseY < incomeSlider.y+incomeSlider.h && stillFrames > 15) {
    fill (0, 0, 0, 200);
    noStroke();
    rect (mouseX, mouseY, 224, 78, 4);
    fill (255);
    textSize (13.5);
    textAlign (LEFT, TOP);
    text ("This quantity represents the amount of money the consumers have to spend.", mouseX+12, mouseY+12, 200, 100);
  }
  if (mouseX > valueSlider.x && mouseX < valueSlider.x+costSlider.w && mouseY > valueSlider.y-35 && mouseY < valueSlider.y+valueSlider.h && stillFrames > 15) {
    fill (0, 0, 0, 200);
    noStroke();
    rect (mouseX, mouseY, 224, 94, 4);
    fill (255);
    textSize (13.5);
    textAlign (LEFT, TOP);
    text ("This quantity represents how much consumers prefer buying this good instead of others.", mouseX+12, mouseY+12, 200, 100);
  }
  if (mouseX == pmouseX && mouseY == pmouseY) stillFrames++;
  else stillFrames = 0;
}

void incrementVariables() {
  // Determine how a change in price would affect profit
  demand += (optimalDemand(supply, price, income, true)-demand)/50;
  supply += (demand-supply)/50;
  float pastPrice = price;
  float currentDemand = optimalDemand(supply, price, income, false);
  float units = min(currentDemand, income/price);
  float currentProfit = price*units-c(units);
  
  float newPrice = price + 0.002;
  float newDemand = optimalDemand(supply, newPrice, income, false);
  float newUnits = min(newDemand, newDemand, income/newPrice);
  float newProfit = newPrice*newUnits-c(newUnits);
  
  // Increment price and momentum constant (momentum makes increments stronger with similar results frame after frame)
  if (newProfit > currentProfit) {
    if (lastDir == 1) momentum += 0.05;
    else momentum = 1;
    lastDir = 1;
  } else {
    if (lastDir == 0) momentum += 0.05;
    else momentum = 1;
    lastDir = 0;
  }
  price += momentum*10*(newProfit-currentProfit);
  priceTrend -= priceTrend/25;
  priceTrend += (price-pastPrice)/25;
}

// Calculates the demand that maximizes "happiness" considering all the variables
float optimalDemand (float s, float p, float i, boolean considerTrend) {
  float newPriceTrend = priceTrend;
  newPriceTrend -= newPriceTrend/25;
  newPriceTrend += (p-price)/25;
  if (considerTrend) {
    return pow(0.5*logFunc(newPriceTrend*trendEffect)*valueFactor/(saveFactor*p), 2);
  } else {
    return pow(0.5*valueFactor/(saveFactor*p), 2);
  }
}

// Happiness from spending money on something else
float valueS(float money) {
  return saveFactor*money;
}

// Happiness from buying units (used sqrt to simulate decreasing returns and to make optimal demand more complex)
float value(float units) {
  return (1+priceTrend*trendEffect)*valueFactor*sqrt(units);
}

float c(float units) {
  return units*cost;
}

float logFunc(float x) {
  return 4./(1+exp(-x))-1;
}