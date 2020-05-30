
Input[][] net1;
Input[][] net2;
float[] leftImage1;
float[] rightImage1;
float[] leftImage2;
float[] rightImage2;

float penRadius = 9;
float penStrength = 0.7;
float gridSize = 7.5;
float blendCount = 10;

float button1X;
float button2X;
float buttonY;
float buttonW;
float buttonH;

float vertGap = 330;

String netPath1 = "/static/projects/AE3/data/Cluster.neuralnet";
String netPath2 = "/static/projects/AE3/data/Cluster2.neuralnet";

boolean redraw = false;

PGraphics pg;

void setup() {
  
  size (screenHeight*0.8*(710.0/670.0), screenHeight*0.8, P2D);
  pg = createGraphics (710, 670, P2D);
  net1 = LOAD_NETWORK (netPath1);
  net2 = LOAD_NETWORK (netPath2);
  leftImage1 = new float[784];
  rightImage1 = new float[784];
  leftImage2 = new float[784];
  rightImage2 = new float[784];
  //println(sigmoid(0));
  pg.beginDraw();
  pg.background(255);
  pg.endDraw();
  button1X = 60;
  button2X = 50+gridSize*14+10;
  buttonY = 70+gridSize*28+10;
  buttonW = gridSize*14-20;
  buttonH = 32;
}

void draw() {
  pg.beginDraw();
  pg.fill(255);
  pg.noStroke();
  pg.rect(pg.width/2-400, -10, 800, 75);
  pg.rect(pg.width/2-400, -10+vertGap, 800, 75);
  pg.fill(0);
  pg.textAlign(CENTER, BOTTOM);
  pg.textSize(35);
  pg.text("2 Dimensions", pg.width/2, 63);
  pg.text("30 Dimensions", pg.width/2, 63+vertGap);
  drawSpaces(net1, leftImage1, rightImage1, 50, 70);
  drawSpaces(net2, leftImage2, rightImage2, 50, 70+vertGap);
  
  pg.fill(200);
  pg.stroke(100);
  pg.strokeWeight(2);
  // 2D buttons
  pg.rect(button1X, buttonY, buttonW, buttonH, 3);
  pg.rect(button2X, buttonY, buttonW, buttonH, 3);
  pg.rect(button1X + 400, buttonY, buttonW, buttonH, 3);
  // 30D buttons
  pg.rect(button1X, buttonY+vertGap, buttonW, buttonH, 3);
  pg.rect(button2X, buttonY+vertGap, buttonW, buttonH, 3);
  pg.rect(button1X + 400, buttonY+vertGap, buttonW, buttonH, 3);
  pg.rect(button2X + 400, buttonY+vertGap, buttonW, buttonH, 3);
  pg.fill(0);
  pg.textAlign(CENTER, CENTER);
  pg.textSize(15);
  pg.text("Clear", button1X + buttonW/2, buttonY + buttonH/2);
  pg.text("Clear", button1X + buttonW/2, buttonY + vertGap + buttonH/2);
  pg.text("Copy to left", button1X + buttonW/2 + 400, buttonY + buttonH/2);
  pg.text("Copy to left", button1X + buttonW/2 + 400, buttonY + vertGap + buttonH/2);
  pg.text("Add noise", button2X + buttonW/2, buttonY + buttonH/2);
  pg.text("Add noise", button2X + buttonW/2, buttonY + vertGap + buttonH/2);
  pg.text("Redraw", button2X + buttonW/2 + 400, buttonY + vertGap + buttonH/2);
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

void mousePressed() {
  // clear buttons
  if (map(mouseX,0,width,0,pg.width) > button1X && map(mouseX,0,width,0,pg.width) < button1X+buttonW && map(mouseY,0,height,0,pg.height) > buttonY && map(mouseY,0,height,0,pg.height) < buttonY+buttonH) {
    for (int n = 0; n < leftImage1.length; n++) {
      leftImage1[n] = 0;
    }
  }
  if (map(mouseX,0,width,0,pg.width) > button1X && map(mouseX,0,width,0,pg.width) < button1X+buttonW && map(mouseY,0,height,0,pg.height) > buttonY+vertGap && map(mouseY,0,height,0,pg.height) < buttonY+vertGap+buttonH) {
    for (int n = 0; n < leftImage2.length; n++) {
      leftImage2[n] = 0;
    }
  }
  
  // Add noise buttons
  if (map(mouseX,0,width,0,pg.width) > button2X && map(mouseX,0,width,0,pg.width) < button2X+buttonW && map(mouseY,0,height,0,pg.height) > buttonY && map(mouseY,0,height,0,pg.height) < buttonY+buttonH) {
    for (int n = 0; n < leftImage1.length; n++) {
      leftImage1[n] = min(1, max(0, leftImage1[n]+random(-0.2, 0.2)));
    }
  }
  if (map(mouseX,0,width,0,pg.width) > button2X && map(mouseX,0,width,0,pg.width) < button2X+buttonW && map(mouseY,0,height,0,pg.height) > buttonY+vertGap && map(mouseY,0,height,0,pg.height) < buttonY+vertGap+buttonH) {
    for (int n = 0; n < leftImage2.length; n++) {
      leftImage2[n] = min(1, max(0, leftImage2[n]+random(-0.2, 0.2)));
    }
  }

  // Copy to left buttons
  if (map(mouseX,0,width,0,pg.width) > button1X+400 && map(mouseX,0,width,0,pg.width) < button1X+buttonW+400 && map(mouseY,0,height,0,pg.height) > buttonY && map(mouseY,0,height,0,pg.height) < buttonY+buttonH) {
    for (int n = 0; n < leftImage1.length; n++) {
      leftImage1[n] = max(min(rightImage1[n], 1), 0);
    }
  }
  if (map(mouseX,0,width,0,pg.width) > button1X+400 && map(mouseX,0,width,0,pg.width) < button1X+buttonW+400 && map(mouseY,0,height,0,pg.height) > buttonY+vertGap && map(mouseY,0,height,0,pg.height) < buttonY+vertGap+buttonH) {
    for (int n = 0; n < leftImage2.length; n++) {
      leftImage2[n] = max(min(rightImage2[n], 1), 0);
    }
  }

  // redraw button
  if (map(mouseX,0,width,0,pg.width) > button2X + 400 && map(mouseX,0,width,0,pg.width) < button2X+buttonW + 400 && map(mouseY,0,height,0,pg.height) > buttonY+vertGap && map(mouseY,0,height,0,pg.height) < buttonY+vertGap+buttonH) {
    redraw = true;
  }

  frameCount = 11;
}

void drawSpaces(Input[][] network, float[] leftImage, float[] rightImage, float posX, float posY) {
  if (frameCount < 2 || (mousePressed && map(mouseX,0,width,0,pg.width) > posX && map(mouseX,0,width,0,pg.width) < posX+28*gridSize+400 && map(mouseY,0,height,0,pg.height) > posY && map(mouseY,0,height,0,pg.height) < posY+gridSize*28+100)) {
    pg.noStroke();
    boolean empty = true;
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        float realX = x*gridSize+posX;
        float realY = y*gridSize+posY;
        pg.fill(255-leftImage[y*28+x]*255);
        pg.rect(realX, realY, gridSize, gridSize);
        if (leftImage[y*28+x] != 0) {
          empty = false;
        }
        if (mousePressed) {
          for (int i = 0; i < blendCount; i++) {
            float currmouseX = map (i+1, 0, blendCount, map(pmouseX,0,width,0,pg.width), map(mouseX,0,width,0,pg.width));
            float currmouseY = map (i+1, 0, blendCount, map(pmouseY,0,height,0,pg.height), map(mouseY,0,height,0,pg.height));
            float horizontalOverlap = min(max(0, penRadius - abs(currmouseX-(realX+gridSize/2)) + gridSize/2), gridSize);
            float verticalOverlap = min(max(0, penRadius - abs(currmouseY-(realY+gridSize/2)) + gridSize/2), gridSize);
            float addOrDel = (mouseButton == LEFT) ? 1 : -1;
            float increase = (60.0/frameRate) * addOrDel * penStrength * horizontalOverlap * verticalOverlap / (gridSize*gridSize*blendCount);
            leftImage[y*28+x] += increase;
            leftImage[y*28+x] = max(min(1, leftImage[y*28+x]), 0);
          }
        }
      }
    }
    if (empty) {
      pg.textAlign(CENTER, CENTER);
      pg.fill(150);
      pg.textSize(20);
      pg.text ("Draw here!\nRight click to erase.", posX + 14*gridSize, posY + 14 * gridSize);
    }
    pg.strokeWeight(1);
    pg.stroke(0);
    pg.fill(0, 0, 0, 0);
    pg.rect(posX, posY, 28*gridSize, 28*gridSize);
  }
  
  if (frameCount < 2 || (network[4].length == 2 && frameCount%3 == 0 && mousePressed && map(mouseX,0,width,0,pg.width) > posX && map(mouseX,0,width,0,pg.width) < posX+28*gridSize+400 && map(mouseY,0,height,0,pg.height) > posY) || redraw) {
    for (int l = 0; l < network.length; l++) {
      for (int n = 0; n < network[l].length; n++) {
        network[l][n].resetValues();
      }
    }
    for (int n = 0; n < network[0].length; n++) {
      network[0][n].value = leftImage[n];
    }
    for (int n = 0; n < network[network.length-1].length; n++) {
      network[network.length-1][n].calculateOutput();
      rightImage[n] = network[network.length-1][n].output;
    }
    pg.noStroke();
    for (int y = 0; y < 28; y++) {
      for (int x = 0; x < 28; x++) {
        float realX = x*gridSize+posX+400;
        float realY = y*gridSize+posY;
        pg.fill(min(max(255-rightImage[y*28+x]*255, 0),255));
        pg.rect(realX, realY, gridSize, gridSize);
      }
    }
    
    pg.strokeWeight(1);
    pg.stroke(0);
    pg.fill(0, 0, 0, 0);
    pg.rect(posX+400, posY, 28*gridSize, 28*gridSize);
    
    // Draw arrows and compressed form
    pg.fill(255);
    pg.noStroke();
    pg.rect (posX + gridSize*28 + 1, posY, 398 - gridSize * 28, gridSize * 28);
    pg.fill(150);
    pg.triangle (posX + gridSize*28 + 10, posY + (1.0/5)*gridSize*28, posX + gridSize*28 + 10, posY + (4.0/5)*gridSize*28, posX + gridSize*28+60, posY + gridSize*14);
    pg.triangle (posX + 390, posY + (1.0/5)*gridSize*28, posX + 390, posY + (4.0/5)*gridSize*28, posX + 340, posY + gridSize*14);
    pg.fill(255);
    //rect(posX + gridSize*28 + 10, posY + (3.5/5)*gridSize*28 + 15, 70, 40);
    pg.textSize(16);
    pg.textAlign(LEFT, TOP);
    pg.fill(100);
    pg.text ("Encode", posX + gridSize*28 + 10, posY + (4.0/5)*gridSize*28 + 15);
    pg.fill(255);
    //rect(posX + gridSize*28 + 100, posY + (3.5/5)*gridSize*28 + 15, 80, 40);
    pg.textSize(16);
    pg.textAlign(RIGHT, TOP);
    pg.fill(100);
    pg.text ("Decode", posX + 390, posY + (4.0/5)*gridSize*28 + 15);
    if (network[4].length == 2) {
      color col1 = fillBall(network[4][0].output);
      color col2 = fillBall(network[4][1].output);
      pg.fill(col1);
      pg.ellipse(posX + 0.5*(gridSize*28+400), posY + gridSize*14-16, 25, 25);
      pg.fill(col2);
      pg.ellipse(posX + 0.5*(gridSize*28+400), posY + gridSize*14+16, 25, 25);
    } else {
      for (int col = 0; col < 3; col++) {
        for (int row = 0; row < 10; row++) {
          color fillCol = fillBall(network[5][col*6+row].output*4);
          float ellipseX = posX + 0.5*(gridSize*28+400) + map(col, 0, 2, -15, 15);
          float ellipseY = posY + gridSize*14 + map(row, 0, 9, -55, 55);
          pg.fill(fillCol);
          pg.ellipse (ellipseX, ellipseY, 10, 10);
        }
      }
    }
    if (redraw && network[4].length != 2) {
      redraw = false;
    }
  }
}

color fillBall(float value) {
  float val = sigmoid(value/3);
  if (val < 0.5) {
    return color(230, map(val, 0, 0.5, 0, 230), 0);
  } else {
    return color(map(val, 0.5, 1, 230, 0), 230, 0);
  }
}

float sigmoid(float value) {
  return 2*(1/(1+exp(-value))-0.5);
}

Input[][] LOAD_NETWORK (String FILENAME) {
  String[] layers = null;
  Input[][] NETWORK = null;
  try {
    String[] lines = loadStrings(FILENAME);
    int numLines = 0;
    int currentLayer = -1;
    int currentNeuron = -1;
    float[] weights = null;
    while (numLines < lines.length) {
      String line = lines[numLines];
      if (numLines == 0) {
        layers = split (line, " ");
        currentLayer = 1;
        currentNeuron = 0;
        NETWORK = new Input[layers.length-1][0];
        for (int l = 0; l < layers.length-1; l++) {
          NETWORK[l] = new Input[int(layers[l])];
        }
        for (int x = 0; x < NETWORK[0].length; x++) {
          NETWORK[0][x] = new Input(0);
        }
      } else {
        if (numLines % 2 == 1) {
          String[] weightsString = split(line, " ");
          weights = new float[weightsString.length-1];
          for (int w = 0; w < weights.length; w++) {
            weights[w] = float(weightsString[w]);
          }
        } else {
          float bias = float(split(line, " ")[0]);
          NETWORK[currentLayer][currentNeuron] = new Perceptron (NETWORK[currentLayer-1], weights, "RELU");
          NETWORK[currentLayer][currentNeuron].bias = bias;
          currentNeuron += 1;
        }
        if (currentNeuron > int(layers[currentLayer])-1) {
          currentLayer += 1;
          currentNeuron = 0;
        }
        if (currentLayer > layers.length-2) {
          break;
        }
      }
      numLines += 1;
    }
  } catch (Exception e) {}
  return NETWORK;
}

/*static class Arrays {
  
  static Object[] copyOf(Object[] arr, int newLength) {
    Object[] newArr = new Object[newLength];
    for (int i = 0; i < min(arr.length, newLength); i++) {
      newArr[i] = arr[i];
    }
    return newArr;
  }
  
}*/

// Class for input into network
class Input {
    float value;
    Input[] inputs;
    float[] weights;
    float bias;
    String ACTIVATION_FUNCTION;
    float output = NaN;
    Input (float value) {
        this.value = value;
    }
    void calculateOutput(){output = value;}
    void resetValues(){}
}

// Perceptron/Sigmoid neuron class; extends Input so that a perceptron can take input from inputs and other perceptrons
class Perceptron extends Input {
    
    Perceptron (Input[] inputs, float[] weights, String ACTIVATION_FUNCTION) {
        super (0);
        this.inputs = inputs;
        this.weights = weights;
        this.ACTIVATION_FUNCTION = ACTIVATION_FUNCTION;
        output = NaN;
        bias = 0;
    }
    
    // Function to calculate perceptron output; will be recursive back to inputs, so calling this function on any node will get its output
    void calculateOutput() {
        if (output != output) { // check for NaN
        float sum = bias;
        for (int i = 0; i < weights.length; i++) {
            inputs[i].calculateOutput();
            sum += inputs[i].output*weights[i];
        }
        if (ACTIVATION_FUNCTION.equals ("THRESHOLDED")) {
            output = (sum > 0) ? 1 : 0;
        } else if (ACTIVATION_FUNCTION.equals ("SIGMOID")) {
            output = 1.0/(1.0+exp(-sum));
        } else if (ACTIVATION_FUNCTION.equals("RELU")) {
            output = max(0, sum);
        } else if (ACTIVATION_FUNCTION.equals("LINEAR")) {
            output = sum;
        } else {
            //System.out.println ("NO ACTIVATION FUNCTION");
            output = 0;
        }
        }
    }
    
    void resetValues () {output = NaN;}
    
}