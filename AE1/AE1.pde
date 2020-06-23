int NUM_INSTANCES = 1;

Input[][] net;

boolean netLoaded;
boolean drawnGrid;

float xMin = -1.5;
float xMax = 8;
float yMin = -1.5;
float yMax = 11;

String netPath = "/static/projects/AE3/data/Cluster.neuralnet";
String datasetPath = "/static/projects/AE1/data";

byte[] b;
byte[] b1;
int numDrawn = 0;
PGraphics legend;
PGraphics pg;

void setup() {
  float aR = 5.0/3.0;
  if (screenWidth / (screenHeight+0.0) > aR) { // height is limiting
    size (screenHeight * 0.7 * aR, screenHeight * 0.7);
  } else {
    size (screenWidth * 0.7, screenWidth * 0.7 * 1.0/aR);
  }
  pg = createGraphics(1000, 600);
  legend = createGraphics(150, 150);
  drawLegend();
  netLoaded = false;
  drawnGrid = false;
  loadStuff();
}

// x ranges from 0.65 to 1.13
// y ranges from 0.75 to 1.01666

float lastPosX = -1;
float lastPosY = -1;

void draw() {
  pg.beginDraw();
  if (frameCount <= 2) {
    pg.background(255);
    pg.fill(0);
    pg.textSize(40);
    pg.textAlign(CENTER, CENTER);
    pg.text("Loading...", pg.width/2, pg.height/2);
  } else if (frameCount == 3) {
    pg.background(255);
  } else if (numDrawn < 10000) {
    byte[] imageBytes = new byte[784];
    for (int thisNum = 0; thisNum < 2; thisNum++) {
      int i = numDrawn;
      int imageNum = i+1;
      int startIndex = 16+(28*28)*(imageNum-1);
      float[] inputs = new float[784];
      float[] outputs = new float[2];
      int labels = -1;
      for (int n = startIndex; n < 16+(28*28)*(imageNum); n++) {
          imageBytes[n-startIndex] = b[n];
      }
      //console.log(image);
      byte label = b1[7+imageNum];
      labels = int(label);
      for (int n = 0; n < 784; n++) {
          //console.log(int(image[n] & 0xff));
          inputs[n] = ((float)(imageBytes[n] & 0xff))/255.0;
      }
      /*for (int x = 0; x < 784; x++) {
        int pixX = x%28;
        int pixY = (int)(x/28);
        fill(255-255*inputs[x]);
        //console.log(inputs[x]);
        strokeWeight(0);
        stroke(0);
        rect(10+pixX*2, 10+pixY*2, 2, 2);
      }*/
      for (int l = 0; l < net.length; l++) {
        for (int x = 0; x < net[l].length; x++) {
          net[l][x].resetValues();
        }
      }
      for (int x = 0; x < inputs.length; x++) {
        net[0][x].value = inputs[x];
      }
      for (int x = 0; x < net[4].length; x++) {
        net[4][x].calculateOutput();
      }
      for (int x = 0; x < net[4].length; x++) {
        outputs[x] = net[4][x].output;
      }

      pg.fill (0, 0, 0, 0);
      pg.noStroke();
      if ((int)label == 0) {
        pg.fill (0);
      } else if ((int)label == 1) {
        pg.fill (255, 0, 0);
      } else if ((int)label == 2) {
        pg.fill (0, 255, 0);
      } else if ((int)label == 3) {
        pg.fill (0, 0, 255);
      } else if ((int)label == 4) {
        pg.fill (255, 255, 0);
      } else if ((int)label == 5) {
        pg.fill (255, 0, 255);
      } else if ((int)label == 6) {
        pg.fill (0, 255, 255);
      } else if ((int)label == 7) {
        pg.fill (255, 165, 0);
      } else if ((int)label == 8) {
        pg.fill (138,43,226);
      } else {
        pg.fill (222,184,135);
      }
      //ellipse (outputs[i][0]*3000-1950, outputs[i][1]*3000-2250, 3, 3);
      pg.ellipse (map(outputs[0], -1.5, 5, 0, pg.width), map(outputs[1], -2, 5, 0, pg.height), 6, 6);
      numDrawn++;
    }
    pg.image(legend, 0, 0, legend.width, legend.height);
  }
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

void drawLegend() {
  legend.beginDraw();
  legend.background(255);
  for (int label = 0; label < 10; label++) {
      if ((int)label == 0) {
        legend.fill (0);
      } else if ((int)label == 1) {
        legend.fill (255, 0, 0);
      } else if ((int)label == 2) {
        legend.fill (0, 255, 0);
      } else if ((int)label == 3) {
        legend.fill (0, 0, 255);
      } else if ((int)label == 4) {
        legend.fill (255, 255, 0);
      } else if ((int)label == 5) {
        legend.fill (255, 0, 255);
      } else if ((int)label == 6) {
        legend.fill (0, 255, 255);
      } else if ((int)label == 7) {
        legend.fill (255, 165, 0);
      } else if ((int)label == 8) {
        legend.fill (138,43,226);
      } else {
        legend.fill (222,184,135);
      }
      legend.noStroke();
      float x = 20 + label % 3 * 50;
      float y = 50 + (int)(label / 3) * 30;
      legend.ellipse(x, y, 14, 14);
      legend.fill(0);
      legend.textSize(20);
      legend.textAlign(CENTER, CENTER);
      legend.text(label, x+20, y);
    }
    legend.textSize(25);
    legend.text("Legend", 75, 20);
    legend.endDraw();
}

float distSq(float x1, float y1, float x2, float y2) {
  return pow((x1-x2), 2) + pow((y1-y2), 2);
}

void mousePressed() {
}

void setupDream(float posx, float posy) {
  for (int l = 0; l < net.length; l++) {
    for (int x = 0; x < net[l].length; x++) {
      net[l][x].resetValues();
    }
  }
  net[4][0].output = posx;
  net[4][1].output = posy;
  for (int x = 0; x < net[net.length-1].length; x++) {
    net[net.length-1][x].calculateOutput();
  }
  lastPosX = map(posx, xMin,xMax, 0, pg.width);
  lastPosY = map(posy, yMin,yMax, 0, pg.height);
}

void loadStuff() {
  net = LOAD_NETWORK (netPath);
  net[4][0].ACTIVATION_FUNCTION = "SQRT";
  net[4][1].ACTIVATION_FUNCTION = "SQRT";
  netLoaded = true;
  b = loadBytes(datasetPath + "/t10k-images.idx3-ubyte");
  b1 = loadBytes(datasetPath + "/t10k-labels.idx1-ubyte");
  // 254 --> 198 causes byte loss in first image
  //console.log(b.length);
  //println (b1.length);
  //println (net[4].length + " " + net[5].length + " " + net[6].length + " " + net[7].length + " " + net[8].length);
  // Begin classifying test cases
  /*for (int i = 0; i < NUM_INSTANCES; i++) {
    for (int l = 0; l < net.length; l++) {
      for (int x = 0; x < net[l].length; x++) {
        net[l][x].resetValues();
      }
    }
    for (int x = 0; x < inputs[i].length; x++) {
      net[0][x].value = inputs[i][x];
    }
    for (int x = 0; x < net[4].length; x++) {
      net[4][x].calculateOutput();
    }
    outputs = Arrays.copyOf (outputs, outputs.length+1);
    outputs[i] = new float[2];
    for (int x = 0; x < net[4].length; x++) {
      outputs[i][x] = net[4][x].output;
    }
    if (i%100 == 0) {
      println ((float)i/NUM_INSTANCES*100 + "%");
    }
  }*/
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
        } else if (ACTIVATION_FUNCTION.equals("SQRT")) {
            output = (sum > 0) ? log(sum+1) : -log(-sum+1);
        } else {
            //System.out.println ("NO ACTIVATION FUNCTION");
            output = 0;
        }
        }
    }
    
    void resetValues () {output = NaN;}
    
}

static class Arrays {
  
  static float[][] copyOf(float[][] arr, int newLength) {
    float[][] newArr = new float[newLength][0];
    for (int i = 0; i < min(arr.length, newLength); i++) {
      newArr[i] = arr[i];
    }
    return newArr;
  }
  
  static int[] copyOf(int[] arr, int newLength) {
    int[] newArr = new int[newLength];
    for (int i = 0; i < min(arr.length, newLength); i++) {
      newArr[i] = arr[i];
    }
    return newArr;
  }
  
}