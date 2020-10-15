
import java.lang.*;
import java.io.*;
import java.util.*;

// note: fine-tuning runs indefinitely. The network is automatically saved when the program is halted.

class AE {
    
    // Hyper-parameters
    public static double LEARNING_RATE = 0.0003;
    public static double MOMENTUM = 0.9;
    public static double REGULARIZER = 0.1;
    public static boolean supervised = false;
    public static int BATCH_SIZE = 10;
    
    public static int NUM_INSTANCES = 60000;

    // increase this for longer pre-training and usually better performance
    public static int PRETRAIN_STEPS = 5000;

    // paths to MNIST dataset on drive, I got them from http://yann.lecun.com/exdb/mnist
    public static String imagesPath = "train-images.idx3-ubyte";
    // I think the labels path only matters if supervised == true
    public static String labelsPath = "train-labels.idx1-ubyte";

    // whether to load a pre-trained network and jump to fine-tuning, plus the path if true
    public static boolean loadFromFile = false;
    public static String fileName = System.getProperty ("user.home") + "Cluster.neuralnet";

    // Layer structure if not loading from a file (all layers are FC with ReLU units, this can be changed around lines 65-75)
    public static int[] layers = {784, 300, 100, 50, 30};

    // where to save the network after training is finished or stopped
    public static String savePath = "Cluster.neuralnet";
    
    public static void main (String[] args) {

        // Input and output array
        double[][] input = new double[NUM_INSTANCES][784];
        
        byte[] b = null;
        byte[] b1 = null;
        byte[] image = new byte[28*28];
        try {
            File testImages = new File (imagesPath);
            image = new byte[28*28];
            File testLabels = new File (labelsPath);
            DataInputStream dis = new DataInputStream(new FileInputStream(testImages)); //to read the file
            b = new byte[(int)testImages.length()]; //to store the bytes
            DataInputStream dis1 = new DataInputStream(new FileInputStream(testLabels));
            b1 = new byte[(int)testLabels.length()];
            dis.read(b); //stores the bytes in b
            dis.close();
            dis1.read(b1);
            dis1.close();
        } catch (Exception e) {
        	System.out.println(e);
        }
        for (int i = 0; i < NUM_INSTANCES; i++) {
            int imageNum = i+1;
            int startIndex = 16+(28*28)*(imageNum-1);
            for (int n = startIndex; n < 16+(28*28)*(imageNum); n++) {
                image[n-startIndex] = b[n];
            }
            byte label = b1[7+imageNum];
            for (int n = 0; n < input[0].length; n++) {
                input[i][n] = ((double)(image[n] & 0xff))/255.0;
            }
        }
        
        Input[][] NETWORK;
        
        if (!loadFromFile) {
            NETWORK = createNetwork(layers, "RELU");
            // Add decoding side to the network
            NETWORK = Arrays.copyOf (NETWORK, NETWORK.length*2-1);
            for (int l = (NETWORK.length+1)/2; l < NETWORK.length; l++) {
                NETWORK[l] = new Perceptron[NETWORK[(NETWORK.length-1)/2-(l-(NETWORK.length-1)/2)].length];
                for (int x = 0; x < NETWORK[l].length; x++) {
                    Perceptron p = new Perceptron (NETWORK[l-1], generateWeights (NETWORK[l-1].length), "RELU");
                    NETWORK[l][x] = p;
                }
            }
        } else {
            NETWORK = LOAD_NETWORK (fileName);
        }
        
        
        Runnable r = new exit(NETWORK);
        Runtime.getRuntime().addShutdownHook(new Thread(r));
        if (!loadFromFile) {
        // Begin layer-wise pre-training
        for (int s = 0; s < (NETWORK.length+1)/2-1; s++) {
            int thisEpoch = 0;
            int these_epochs = PRETRAIN_STEPS;
            float globalError = 0;
            // Create a forward pass network for this RBM
            int[] forwardLayers = {NETWORK[s].length, NETWORK[s+1].length};
            Input[][] FORWARD_NETWORK = createNetwork(forwardLayers, "RELU");
            for (int x = 0; x < FORWARD_NETWORK[1].length; x++) {
                for (int w = 0; w < FORWARD_NETWORK[1][x].weights.length; w++) {
                    FORWARD_NETWORK[1][x].weights[w] = NETWORK[s+1][x].weights[w];
                }
            }
            // Create a backward pass network for this RBM
            int[] backwardLayers = {NETWORK[s+1].length, NETWORK[s].length};
            Input[][] BACK_NETWORK = createNetwork(backwardLayers, "RELU");
            for (int l = 1; l < BACK_NETWORK.length; l++) {
                for (int x = 0; x < BACK_NETWORK[l].length; x++) {
                    for (int w = 0; w < BACK_NETWORK[l][x].weights.length; w++) {
                        BACK_NETWORK[l][x].weights[w] = FORWARD_NETWORK[FORWARD_NETWORK.length-l][w].weights[x];
                    }
                }
            }
            System.out.println (BACK_NETWORK[1].length);
            double prevGlobalError = globalError;
            double[][][] prevChangeWeights = nullWeights(FORWARD_NETWORK);
            double[][] prevChangeBiases = nullBias(FORWARD_NETWORK);
            double[][] prevChangeBiasesBack = nullBias(BACK_NETWORK);
            do {
                // Make back network weights the same as the forward network weights
                for (int l = 1; l < BACK_NETWORK.length; l++) {
                    for (int x = 0; x < BACK_NETWORK[l].length; x++) {
                        for (int w = 0; w < BACK_NETWORK[l][x].weights.length; w++) {
                            BACK_NETWORK[l][x].weights[w] = FORWARD_NETWORK[FORWARD_NETWORK.length-l][w].weights[x];
                        }
                    }
                }
                // Reset error variable
                globalError = 0;
                // Arrays to save weight/bias changes to update at the end of this training set
                double[][][] changeWeights = nullWeights(FORWARD_NETWORK);
                double[][] changeBiases = nullBias(FORWARD_NETWORK);
                double[][] changeBiasesBack = nullBias(BACK_NETWORK);
                for (int i = (int)(new Random().nextDouble()*(NUM_INSTANCES/BATCH_SIZE)); i < NUM_INSTANCES; i+=(NUM_INSTANCES/BATCH_SIZE)) {
                    for (int l = 0; l < FORWARD_NETWORK.length; l++) {
                        for (int x = 0; x < FORWARD_NETWORK[l].length; x++) {
                            FORWARD_NETWORK[l][x].resetValues();
                        }
                    }
                    for (int l = 0; l < BACK_NETWORK.length; l++) {
                        for (int x = 0; x < BACK_NETWORK[l].length; x++) {
                            BACK_NETWORK[l][x].resetValues();
                        }
                    }
                    for (int l = 0; l < NETWORK.length; l++) {
                        for (int x = 0; x < NETWORK[l].length; x++) {
                            NETWORK[l][x].resetValues();
                        }
                    }
                    // Change feedforward inputs to reflect this training data
                    double[] vi = new double[FORWARD_NETWORK[0].length];
                    for (int x = 0; x < NETWORK[0].length; x++) {
                        NETWORK[0][x].value = input[i][x];
                        NETWORK[0][x].calculateOutput();
                    }
                    for (int x = 0; x < FORWARD_NETWORK[0].length; x++) {
                        NETWORK[s][x].calculateOutput();
                    }
                    for (int x = 0; x < FORWARD_NETWORK[0].length; x++) {
                        FORWARD_NETWORK[0][x].value = NETWORK[s][x].output;
                        FORWARD_NETWORK[0][x].calculateOutput();
                        vi[x] = FORWARD_NETWORK[0][x].output;
                    }
                    double[] hj = new double[FORWARD_NETWORK[1].length];
                    // Calculate outputs from forward pass
                    for (int x = 0; x < FORWARD_NETWORK[FORWARD_NETWORK.length-1].length; x++) {
                        FORWARD_NETWORK[FORWARD_NETWORK.length-1][x].calculateOutput();
                    }
                    // Feed forward pass outputs into reconstruction network
                    for (int x = 0; x < BACK_NETWORK[0].length; x++) {
                        BACK_NETWORK[0][x].value = FORWARD_NETWORK[FORWARD_NETWORK.length-1][x].output;
                        hj[x] = BACK_NETWORK[0][x].value;
                    }
                    // Calculate reconstructions
                    double[] vihat = new double[BACK_NETWORK[1].length];
                    for (int x = 0; x < BACK_NETWORK[BACK_NETWORK.length-1].length; x++) {
                        BACK_NETWORK[BACK_NETWORK.length-1][x].calculateOutput();
                        vihat[x] = BACK_NETWORK[BACK_NETWORK.length-1][x].output;
                    }
                    double[] hjhat = new double[FORWARD_NETWORK[1].length];
                    // Change feedforward inputs to reconstruction
                    for (int x = 0; x < FORWARD_NETWORK[0].length; x++) {
                        FORWARD_NETWORK[0][x].value = vihat[x];
                    }
                    for (int x = 0; x < FORWARD_NETWORK[FORWARD_NETWORK.length-1].length; x++) {
                        FORWARD_NETWORK[FORWARD_NETWORK.length-1][x].calculateOutput();
                        hjhat[x] = FORWARD_NETWORK[FORWARD_NETWORK.length-1][x].output;
                    }
                    // Calculate error
                    for (int x = 0; x < FORWARD_NETWORK[0].length; x++) {
                        double actual = vihat[x];
                        double target = vi[x];
                        double localError = actual-target;
                        globalError += (localError*localError);
                    }
                    // Calculate gradients
                    for (int l = 1; l < FORWARD_NETWORK.length; l++) {
                        for (int x = 0; x < FORWARD_NETWORK[l].length; x++) {
                            for (int w = 0; w < FORWARD_NETWORK[l][x].weights.length; w++) {
                                changeWeights[l][x][w] += LEARNING_RATE * (vi[w]*hj[x]-vihat[w]*hjhat[x]) - (REGULARIZER/input.length)*FORWARD_NETWORK[l][x].weights[w];
                            }
                            changeBiases[l][x] += LEARNING_RATE * (hj[x]-hjhat[x]) - (REGULARIZER/input.length)*FORWARD_NETWORK[l][x].bias;
                        }
                    }
                    for (int l = 1; l < BACK_NETWORK.length; l++) {
                        for  (int x = 0; x < BACK_NETWORK[l].length; x++) {
                            changeBiasesBack[l][x] += LEARNING_RATE * (vi[x]-vihat[x]) - (REGULARIZER/input.length)*BACK_NETWORK[l][x].bias;
                        }
                    }
                }
                // Update weights and biases
                for (int l = 1; l < FORWARD_NETWORK.length; l++) {
                    for (int x = 0; x < FORWARD_NETWORK[l].length; x++) {
                        for (int w = 0; w < FORWARD_NETWORK[l][x].weights.length; w++) {
                            FORWARD_NETWORK[l][x].weights[w] += changeWeights[l][x][w] + (MOMENTUM*prevChangeWeights[l][x][w]);
                            prevChangeWeights[l][x][w] = changeWeights[l][x][w];
                        }
                        FORWARD_NETWORK[l][x].bias += changeBiases[l][x] + (MOMENTUM*prevChangeBiases[l][x]);
                        prevChangeBiases[l][x] = changeBiases[l][x];
                    }
                }
                for (int l = 1; l < BACK_NETWORK.length; l++) {
                    for  (int x = 0; x < BACK_NETWORK[l].length; x++) {
                        BACK_NETWORK[l][x].bias += changeBiasesBack[l][x] + (MOMENTUM*prevChangeBiasesBack[l][x]);
                        prevChangeBiasesBack[l][x] = changeBiasesBack[l][x];
                    }
                }
                System.out.println ("Error for RBM " + (s+1) + ":   " + globalError / FORWARD_NETWORK[0].length);
                thisEpoch += 1;
            } while (thisEpoch < these_epochs);
            // Apply changes to the actual network
            for (int x = 0; x < NETWORK[s+1].length; x++) {
                for (int w = 0; w < NETWORK[s+1][x].weights.length; w++) {
                    NETWORK[s+1][x].weights[w] = FORWARD_NETWORK[1][x].weights[w];
                }
                NETWORK[s+1][x].bias = FORWARD_NETWORK[1][x].bias;
            }
            int n = (NETWORK.length-1)/2+((NETWORK.length-1)/2-s);
            for (int x = 0; x < NETWORK[n].length; x++) {
                for (int w = 0; w < NETWORK[n][x].weights.length; w++) {
                    NETWORK[n][x].weights[w] = BACK_NETWORK[1][x].weights[w];
                }
                NETWORK[n][x].bias = BACK_NETWORK[1][x].bias;
            }
        }
        }
        
        double globalError = 0;
        double localError = 0;
        int totalCorrect = 0;
        double[][][] prevChangeWeights = nullWeights(NETWORK);
        double[][] prevChangeBiases = nullBias(NETWORK);
        
        LEARNING_RATE = 0.0003;
        BATCH_SIZE = 10;
        System.out.println ("Beginning fine-tuning");
        // Begin fine-tuning
        do {
        
            globalError = 0;
            totalCorrect = 0;
            double[][][] changeWeights = nullWeights(NETWORK);
            double[][] changeBiases = nullBias(NETWORK);
            for (int i = (int)(new Random().nextDouble()*(NUM_INSTANCES/BATCH_SIZE)); i < NUM_INSTANCES; i+=(NUM_INSTANCES/BATCH_SIZE)) {
                for (int l = NETWORK.length-1; l >= 0; l--) {
                    for (int x = 0; x < NETWORK[l].length; x++) {
                        NETWORK[l][x].resetValues();
                    }
                }
                // Set network inputs to this training example
                for (int x = 0; x < NETWORK[0].length; x++) {
                    NETWORK[0][x].value = input[i][x];
                }
                // Get output from network
                for (int o = 0; o < input[0].length; o++) {
                    NETWORK[NETWORK.length-1][o].calculateOutput();
                    double actual = NETWORK[NETWORK.length-1][o].output;
                    localError = input[i][o] - actual;
                    globalError += (localError*localError);
                }
                // Calculate gradients
                for (int l = NETWORK.length-1; l > 0; l--) { // Loop through every layer
                    for (int x = 0; x < NETWORK[l].length; x++) { // Loop through every node in layer l
                        for (int w = 0; w < NETWORK[l][x].weights.length; w++) { // Loop through every weight input to node x
                            double changeW = -(LEARNING_RATE * calculateDelta (x, l, i, NETWORK, input) * NETWORK[l-1][w].output);
                            changeWeights[l][x][w] += changeW;
                        }
                        double changeB = -(LEARNING_RATE*calculateDelta (x, l, i, NETWORK, input));
                        changeBiases[l][x] += changeB;
                    }
                }
            }
            for (int l = NETWORK.length-1; l > 0; l--) {
                for (int x = 0; x < NETWORK[l].length; x++) {
                    for (int w = 0; w < NETWORK[l][x].weights.length; w++) {
                        NETWORK[l][x].weights[w] += changeWeights[l][x][w] + (MOMENTUM*prevChangeWeights[l][x][w]);
                        prevChangeWeights[l][x][w] = changeWeights[l][x][w];
                    }
                    NETWORK[l][x].bias += changeBiases[l][x] + (MOMENTUM*prevChangeBiases[l][x]);
                    prevChangeBiases[l][x] = changeBiases[l][x];
                }
            }
            System.out.println ("Average error is " + globalError); // Values in the range 50-100 are pretty good for batch size 10
        } while (true);
    }
    
    static double[][][] nullWeights (Input[][] NETWORK) {
        double[][][] ret = new double[NETWORK.length][0][0];
        for (int l = 0; l < NETWORK.length; l++) {
            ret[l] = Arrays.copyOf (ret[l], NETWORK[l].length);
            for (int x = 0; x < NETWORK[l].length; x++) {
                if (l != 0) {
                    ret[l][x] = new double[NETWORK[l][x].weights.length];
                } else {
                    ret[l][x] = new double[0];
                }
                for (int w = 0; w < ret[l][x].length; w++) {
                    ret[l][x][w] = 0;
                }
            }
        }
        return ret;
    }
                                    
    static double[][] nullBias (Input[][] NETWORK) {
        double[][] ret = new double[NETWORK.length][0];
        for (int l = 0; l < ret.length; l++) {
            ret[l] = Arrays.copyOf (ret[l], NETWORK[l].length);
            for (int x = 0; x < ret[l].length; x++) {
                ret[l][x] = 0;
            }
        }
        return ret;
    }
    
    // Evaluate delta expression of x perceptron in layer l, given training instance i.
    static double calculateDelta(int x, int l, int i, Input[][] NETWORK, double[][] outputs) {
        if (Double.isNaN(NETWORK[l][x].delta)) {
            if (l == NETWORK.length-1) { // If this perceptron is an output node
                double target = outputs[i][x];
                double actual = NETWORK[l][x].output;
                int derivative = 0;
                if (actual > 0) {
                    derivative = 1;
                }
                NETWORK[l][x].delta = derivative*(actual-target);
                //System.out.println (x + ": " + NETWORK[l][x].delta);
            } else { // Otherwise
                double sumForward = 0;
                for (int k = 0; k < NETWORK[l+1].length; k++) {
                    sumForward += NETWORK[l+1][k].weights[x] * calculateDelta (k, l+1, i, NETWORK, outputs);
                }
                double actual = NETWORK[l][x].output;
                int derivative = 0;
                if (actual > 0) {
                    derivative = 1;
                }
                NETWORK[l][x].delta = derivative*sumForward;
            }
        }
        return NETWORK[l][x].delta;
    }
    
    // Function to save a network to a file
    static void saveToFile (Input[][] NETWORK, String FILENAME) {
        try {
            BufferedWriter writer = new BufferedWriter (new FileWriter(FILENAME));
            for (int l = 0; l < NETWORK.length; l++) {
                writer.write (NETWORK[l].length + " ");
            }
            writer.write ("\n");
            for (int l = 1; l < NETWORK.length; l++) {
                for (int x = 0; x < NETWORK[l].length; x++) {
                    for (int w = 0; w < NETWORK[l][x].weights.length; w++) {
                        writer.write ((float)NETWORK[l][x].weights[w] + " ");
                    }
                    writer.write ("\n");
                    writer.write ((float)NETWORK[l][x].bias + " ");
                    writer.write ("\n");
                }
            }
            writer.close();
        } catch (Exception e) {e.printStackTrace();}
        
    }
    
    // Function to load a network from a file
    static Input[][] LOAD_NETWORK (String FILENAME) {
        String[] layers = null;
        Input[][] NETWORK = null;
        try {
            BufferedReader r = new BufferedReader(new FileReader(FILENAME));
            String line = "";
            int numLines = 0;
            int currentLayer = -1;
            int currentNeuron = -1;
            double[] weights = null;
            while ((line = r.readLine()) != null) {
                if (numLines == 0) {
                    layers = line.split(" ");
                    currentLayer = 1;
                    currentNeuron = 0;
                    NETWORK = new Input[layers.length][0];
                    for (int l = 0; l < layers.length; l++) {
                        NETWORK[l] = Arrays.copyOf (NETWORK[l], Integer.parseInt(layers[l]));
                    }
                    for (int x = 0; x < NETWORK[0].length; x++) {
                        NETWORK[0][x] = new Input(0);
                    }
                } else {
                    if (numLines % 2 == 1) {
                        String[] weightsString = line.split(" ");
                        weights = new double[weightsString.length];
                        for (int w = 0; w < weights.length; w++) {
                            weights[w] = Double.parseDouble(weightsString[w]);
                        }
                    } else {
                        double bias = Double.parseDouble(line.split(" ")[0]);
                        NETWORK[currentLayer][currentNeuron] = new Perceptron (NETWORK[currentLayer-1], weights, "RELU");
                        NETWORK[currentLayer][currentNeuron].bias = bias;
                        currentNeuron += 1;
                    }
                    if (currentNeuron > Integer.parseInt(layers[currentLayer])-1) {
                        currentLayer += 1;
                        currentNeuron = 0;
                    }
                    if (currentLayer > layers.length-1) {
                        break;
                    }
                }
                numLines += 1;
            }
            r.close();
        } catch (Exception e) {e.printStackTrace();}
        return NETWORK;
    }
    
    public static double random (double start, double end) {
        return new Random().nextDouble()*(end-start)+start;
    }
    
    // Function to create a 2D input array to use as a network
    static Input[][] createNetwork(int[] list, String ACTIVATION_FUNCTION) {
        Input[][] NETWORK = new Input[0][0];
        for (int l = 0; l < list.length; l++) {
            Input[] thisLayer = new Input[0];
            NETWORK = Arrays.copyOf (NETWORK, NETWORK.length+1);
            NETWORK[NETWORK.length-1] = thisLayer;
            for (int x = 0; x < list[l]; x++) {
                if (l == 0) {
                    Input input = new Input (0);
                    NETWORK[l] = Arrays.copyOf (NETWORK[l], NETWORK[l].length+1);
                    NETWORK[l][NETWORK[l].length-1] = input;
                } else {
                    Perceptron p = new Perceptron (NETWORK[l-1], generateWeights (NETWORK[l-1].length), ACTIVATION_FUNCTION);
                    NETWORK[l] = Arrays.copyOf (NETWORK[l], NETWORK[l].length+1);
                    NETWORK[l][NETWORK[l].length-1] = p;
                }
            }
        }
        return NETWORK;
    }
    
    // Create an array of random gaussian weights
    static double[] generateWeights (int number) {
        double[] ret = new double[number];
        for (int i = 0; i < number; i++) {
            ret[i] = new Random().nextGaussian()*0.01;
        }
        return ret;
    }
    
    static int binaryProb (double prob) {
        double rand = new Random().nextDouble();
        if (rand > prob) {
            return 0;
        } else {
            return 1;
        }
    }
    static class exit implements Runnable {
        Input[][] NETWORK;
        exit (Input[][] NETWORK) {
            this.NETWORK = NETWORK;
        }
        public void run() {
            //Save net to file
            saveToFile (NETWORK, savePath);
        }
    }
}


// Class for input into network
class Input {
    double value;
    Input[] inputs;
    double[] weights;
    double bias;
    String ACTIVATION_FUNCTION;
    double output = Double.NaN;
    double delta = Double.NaN;
    Input (double value) {
        this.value = value;
    }
    void calculateOutput(){output = value;}
    void resetValues(){output = Double.NaN; delta = Double.NaN;}
}

// Perceptron/Sigmoid neuron class; extends Input so that a perceptron can take input from inputs and other perceptrons
class Perceptron extends Input {
    
    Perceptron (Input[] inputs, double[] weights, String ACTIVATION_FUNCTION) {
        super (0);
        this.inputs = inputs;
        this.weights = weights;
        this.ACTIVATION_FUNCTION = ACTIVATION_FUNCTION;
        output = Double.NaN;
        bias = 0;
    }
    
    // Function to calculate perceptron output; will be recursive back to inputs, so calling this function on any node will get its output
    void calculateOutput() {
        if (Double.isNaN(output)) {
        double sum = bias;
        /*if (DBN.supervised) {
            //System.out.println ("Calculating my output " + inputs.length);
        }*/
        for (int i = 0; i < weights.length; i++) {
            inputs[i].calculateOutput();
            sum += inputs[i].output*weights[i];
        }
        if (ACTIVATION_FUNCTION.equals ("THRESHOLDED")) {
            output = (sum > 0) ? 1 : 0;
        } else if (ACTIVATION_FUNCTION.equals ("SIGMOID")) {
            output = (double)(1.0/(1.0+Math.exp(-sum)));
        } else if (ACTIVATION_FUNCTION.equals("RELU")) {
            output = Math.max (0, sum);
        } else if (ACTIVATION_FUNCTION.equals("LINEAR")) {
            output = sum;
        } else {
            System.out.println ("NO ACTIVATION FUNCTION");
            output = 0;
        }
        }
    }
    void resetValues() {
        output = Double.NaN;
        delta = Double.NaN;
    }
    
}
