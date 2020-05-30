float[][] inputs = new float[0][0];
float[][] outputs = new float[0][0];
int[] labels = new int[0];
int NUM_INSTANCES = 60000;

Input[][] net;

boolean netLoaded;
boolean drawnGrid;

float xMin = -1;
float xMax = 8;
float yMin = -1.5;
float yMax = 11.8;
int numIters = 0;

String netPath = "/static/projects/AE3/data/Cluster.neuralnet";

PGraphics pg;

void setup() {
  
  size (screenWidth*0.7, screenWidth*0.7*0.6);
  pg = createGraphics(1000, 600);
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
    pg.text("Loading...\n(This may take 15-20 seconds)", pg.width/2, pg.height/2);
  }
  if (netLoaded && frameCount > 2) {
    if (!drawnGrid) {
      for (int posX = 0; posX < pg.width; posX+=56) {
        for (int posY = 0; posY < pg.height; posY+=56) {
          for (int l = 0; l < net.length; l++) {
            for (int x = 0; x < net[l].length; x++) {
              net[l][x].resetValues();
            }
          }
          net[4][0].output = map(posX, 0, pg.width, xMin, xMax);
          net[4][1].output = map(posY, 0, pg.height, yMin, yMax);
          for (int x = 0; x < net[8].length; x++) {
            net[8][x].calculateOutput();
            int pixX = x%28;
            int pixY = (int)(x/28);
            pg.fill(255-128*net[8][x].output);
            pg.noStroke();
            pg.rect(posX+pixX*2, posY+pixY*2, 2, 2);
          }
        }
      }
      drawnGrid = true;
      for (int x = 0; x < net[net.length-1].length; x++) {
        net[net.length-1][x].output = random(1);
      }
      setupDream(random(0, 7), random(0, 10.5));
    } else if (frameCount > 2){
      pg.stroke(random(100, 200), 0, 0);
      numIters++;
      for (int i = 0; i < 2; i++) {
        for (int l = 0; l < net.length-1; l++) {
          for (int x = 0; x < net[l].length; x++) {
            net[l][x].resetValues();
          }
        }
        for (int x = 0; x < net[0].length; x++) {
          net[0][x].value = net[net.length-1][x].output;
          net[net.length-1][x].resetValues();
        }
        for (int x = 0; x < net[net.length-1].length; x++) {
          net[net.length-1][x].calculateOutput();
        }
        float posX = map(net[4][0].output, xMin, xMax, 0, pg.width);
        float posY = map(net[4][1].output, yMin, yMax, 0, pg.height);
        if (lastPosX != -1 && lastPosY != -1) {
          pg.strokeWeight(2.5);
          pg.line(posX, posY, lastPosX, lastPosY);
          if (distSq(posX, posY, lastPosX, lastPosY) < 0.01 || numIters > 15) {
            pg.fill(0, 0, 255);
            pg.noStroke();
            if (numIters <= 15) {
              pg.ellipse(posX, posY, 15, 15);
            }
            i = 10000;
            numIters = 0;
            setupDream(random(0, 7), random(0, 10.5));
          } else {
            lastPosX = posX;
            lastPosY = posY;
          }
        }
      }
    }
  }
  pg.endDraw();
  image(pg, 0, 0, width, height);
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
  netLoaded = true;
  /*byte[] b = null;
            byte[] b1 = null;
            byte[] image = new byte[28*28];
            try {
                File testImages = new File (System.getProperty ("user.home") + "/Downloads/train-images.idx3-ubyte");
                image = new byte[28*28];
                File testLabels = new File (System.getProperty ("user.home") + "/Downloads/train-labels.idx1-ubyte");
                DataInputStream dis = new DataInputStream(new FileInputStream(testImages)); //to read the file
                b = new byte[(int)testImages.length()]; //to store the bytes
                DataInputStream dis1 = new DataInputStream(new FileInputStream(testLabels));
                b1 = new byte[(int)testLabels.length()];
                dis.read(b); //stores the bytes in b
                dis.close();
                dis1.read(b1);
                dis1.close();
            } catch (Exception e) {e.printStackTrace();}
            for (int i = 0; i < NUM_INSTANCES; i++) {
                int imageNum = i+1;
                int startIndex = 16+(28*28)*(imageNum-1);
                for (int n = startIndex; n < 16+(28*28)*(imageNum); n++) {
                    image[n-startIndex] = b[n];
                }
                byte label = b1[7+imageNum];
                inputs = Arrays.copyOf (inputs, inputs.length+1);
                inputs[inputs.length-1] = new float[784];
                labels = Arrays.copyOf (labels, labels.length+1);
                for (int n = 0; n < 784; n++) {
                    inputs[i][n] = ((float)(image[n] & 0xff))/255.0;
                    labels[i] = int(label);
                }
            }*/
  //println ("hello");
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
        } else {
            //System.out.println ("NO ACTIVATION FUNCTION");
            output = 0;
        }
        }
    }
    
    void resetValues () {output = NaN;}
    
}
