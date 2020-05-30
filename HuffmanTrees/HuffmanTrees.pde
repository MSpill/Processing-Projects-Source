/* @pjs globalKeyEvents="true"; */

String string = "Type to edit this text and watch how its Huffman tree evolves! If the backspace key doesn't work, use the left arrow key.";
PriorityQueue queue;

PGraphics pg;

void setup() {
  size ((int)(min(screenWidth,1440)*0.7), (int)(min(screenWidth,1440)*0.7*2.0/3.0));
  pg=createGraphics(1200, 800);
  buildTree();
  
  //((Node)queue.peek()).printCodes("");
  
}

void draw() {
  pg.beginDraw();
  pg.background(230);
  pg.fill (0);
  pg.textSize(35);
  pg.text(string, 0, 0, pg.width, 180);
  pg.stroke(0);
  pg.strokeWeight(2);
  pg.line (0, 180, pg.width, 180);
  if (queue.peek() != null) {
    float w = pg.width-60;
    float leafSize = 0;
    while (((Node)queue.peek()).calculateTreeWidth(leafSize) < w) {
      leafSize+=0.1;
    }
    leafSize = min(leafSize, 50);
    float treeW = ((Node)queue.peek()).calculateTreeWidth(leafSize);
    ((Node)queue.peek()).draw(pg.width/2.0 - treeW/2.0, 200, w, pg.height-240);
  }
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

void keyPressed() {
  if (keyCode == BACKSPACE || keyCode == DELETE || keyCode == LEFT) {
    if (string.length() > 0) {
      string = string.substring(0, string.length()-1);
    }
  } else if (key != CODED && key != ESC && key != ENTER && key != RETURN && key != TAB) {
    string += key.toString();
  }
  buildTree();
}

void buildTree() {
  queue = new PriorityQueue();
  
  for (int i = 0; i < string.length(); i++) {
    boolean present = false;
    for (WeightedObject n : queue.list) {
      if (((Node)n).character == string.charAt(i)) {
        present = true;
      }
    }
    if (!present) {
      queue.insert(new Node(string.charAt(i), -ocurrencesOf(string, string.charAt(i))));
    }
  }
  
  for (WeightedObject n : queue.list) {
    //println (((Node)n).character + " " + ((Node)n).weight);
  }
  
  while (queue.list.size() > 1) {
    Node n1 = (Node)queue.get();
    Node n2 = (Node)queue.get();
    Node newNode = new Node ('\\', n1.weight+n2.weight);
    newNode.addChild(n1); newNode.addChild(n2);
    queue.insert(newNode);
  }
}

int ocurrencesOf (String word, char guess) {
  int num = 0;
  int index = word.indexOf(guess);
  while(index >= 0) {
     num++;
     index = word.indexOf(guess, index+1);
  }
  return num;
}

class PriorityQueue {
  ArrayList<WeightedObject> list;
  
  PriorityQueue() {
    list = new ArrayList<WeightedObject>();
  }
  
  void insert(WeightedObject myobj) {
    int lowIndex = 0;
    int highIndex = list.size()-1;
    int midIndex = -1;
    while (lowIndex <= highIndex) {
      midIndex = (int)((highIndex+lowIndex)/2);
      WeightedObject atMid = list.get(midIndex);
      if (atMid.weight < myobj.weight) {
        lowIndex = midIndex+1;
        midIndex = lowIndex;
      } else if (atMid.weight > myobj.weight) {
        highIndex = midIndex-1;
      } else {
        lowIndex = highIndex+1;
      }
    }
    if (list.size() == 0) midIndex = 0;
    list.add(midIndex, myobj);
  }
  
  WeightedObject peek() {
    if (list.size() != 0) {
      return list.get(list.size()-1);
    } else {
      //println("Tried to peek empty queue");
      return null;
    }
  }
  
  WeightedObject get() {
    WeightedObject myobj = list.get(list.size()-1);
    list.remove(list.size()-1);
    return myobj;
  }
  
}

class WeightedObject {
  int weight;
  WeightedObject (int weight) {
    this.weight = weight;
  }
}

class Node extends WeightedObject {
  
  char character;
  ArrayList<Node> children;
  Node parent;
  
  Node (char character, int weight) {
    super(weight);
    this.character = character;
    children = new ArrayList<Node>();
    parent = null;
  }
  
  Node (char character, int weight, ArrayList<Node> newChildren) {
    super(weight);
    this.character = character;
    children = new ArrayList<Node>();
    for (Node n : newChildren) {
      addChild(n);
    }
  }
  
  float calculateTreeWidth(float leafSize) {
    if (children.size() == 0) {
      return leafSize;
    } else {
      float ret = -leafSize/2;
      for (Node n : children) {
        ret += n.calculateTreeWidth(leafSize)+leafSize/2;
      }
      return ret;
    }
  }
  
  int treeDepth() {
    int max = 1;
    for (Node n : children) {
      if (n.treeDepth()+1 > max) {
        max = n.treeDepth()+1;
      }
    }
    return max;
  }
  
  void draw(float x, float y, float w, float h) {
    pg.fill(0, 0, 0, 20);
    float leafSize = 0;
    while (calculateTreeWidth(leafSize) < w) {
      leafSize+=0.1;
    }
    leafSize = min(leafSize, 50);
    float yDiff = (h-leafSize)/(treeDepth()-1);
    //rect (x, y-35, calculateTreeWidth(), 70);
    if (children.size() == 0) {
      pg.fill(0);
      pg.ellipse (x+leafSize/2, y+leafSize/2, leafSize, leafSize);
      pg.fill(255);
      pg.textAlign(CENTER, CENTER);
      pg.textSize(35*(leafSize/50));
      pg.text (character, x+leafSize/2, y+leafSize/2);
    } else {
      float drawX = x;
      int index = 0;
      pg.fill(0);
      while (index < children.size()) {
        pg.line (x+calculateTreeWidth(leafSize)/2, y+leafSize/2, drawX+children.get(index).calculateTreeWidth(leafSize)/2, y+yDiff+leafSize/2);
        children.get(index).draw(drawX, y+yDiff, children.get(index).calculateTreeWidth(leafSize), (h-(yDiff*(treeDepth()-children.get(index).treeDepth()))));
        drawX += children.get(index).calculateTreeWidth(leafSize)+leafSize/2;
        index++;
      }
      pg.fill(255);
      pg.ellipse (x+calculateTreeWidth(leafSize)/2, y+leafSize/2, leafSize, leafSize);
      pg.fill(0);
      pg.textAlign(CENTER, CENTER);
      pg.textSize(20*(leafSize/50));
      pg.text (-weight, x+calculateTreeWidth(leafSize)/2, y+leafSize/2);
    }
  }
  
  void addChild(Node n) {
    if (n.parent == null) {
      children.add(n);
      n.parent = this;
    }
  }
  
}
