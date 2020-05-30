/*

 Breadth First Search - Matthew Spillman
 
 */

PGraphics pg;

color white = color(255,255,255);
color gray = color(160,160,160);
color black = color(0,0,0);  

Graph graph;
BreadthFirstSearch BFS;

final int NUM_NODES = 15;
final int NUM_EDGES = 17;

void setup() {
  size ((int)(screenWidth*0.7), (int)(screenWidth*0.7*0.6));
  pg = createGraphics(1000, 600);
  pg.beginDraw();
  pg.background(white);
  graph = new Graph();
  initializeGraph(NUM_NODES);
  createEdges(NUM_EDGES);
  
  BFS = new BreadthFirstSearch(graph);
  BFS.setupSearch(graph.nodes.get(0));
  pg.endDraw();
}

void draw() {
  pg.beginDraw();
  pg.background(230, 230, 230);
  graph.drawGraph();
  pg.stroke(black);
  pg.strokeWeight(5);
  pg.line (pg.width/2, 0, pg.width/2, pg.height);
  pg.fill(0);
  pg.textAlign(TOP, LEFT);
  Node selected = ((Node)(BFS.grayVertices.peek()));
  if (selected != null) {
    pg.text("Currently exploring from: " + selected.value, 10, 20);
  } else {
    pg.text("Search complete! Press 'r' to restart.", 10, 20);
  }
  pg.textAlign(CENTER, TOP);
  pg.text ("Breadth-First Tree", pg.width*3./4, 20);
  pg.text ("(Click to advance)", pg.width*3./4, 50);
  if (BFS.source != null) {
    BFS.drawBreadthFirstTree(pg.width/2+40, 100, pg.width/2-80, pg.height);
  }
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

void keyPressed() {
  if (key == 'r') {
    setup();
  }
}

void initializeGraph(int numNodes) {
  graph.nodeSize = 60;
  for (int i = 0; i < numNodes; i++) {
    int rand = int(random(100));
    boolean intersecting = true;
    Node newNode = null;
    while (intersecting) {
      float x = random(.05*pg.width,.45*pg.width);
      float y = random(.1*pg.height, .9*pg.height);
      newNode = new Node(rand, x, y);
      intersecting = false;
      for (Node other : graph.nodes) {
        if (dist(other.x, other.y, x, y) < graph.nodeSize+10) {
          intersecting = true;
        }
      }
    }
    graph.addNode(newNode);
  }
}

void createEdges(int numEdges) {
  for (int i = 0; i < numEdges; i++) {
    Node u = graph.getRandomNode();
    Node v;
    do {
      v = graph.getRandomNode();
    } while (v == u || graph.edgeExists(u,v));
    graph.addEdge(u,v);
  }
}

void mousePressed() {
  BFS.oneStep();
}

class Queue {
  Object[] array;
  
  int head, tail;
  boolean full;
  
  Queue (int queueSize) {
    array = new Object[queueSize];
    full = false;
  }
  
  void enqueue(Object o) {
    array[tail] = o;
    tail = (tail+1)%array.length;
    if (tail == head) {
      full = true;
    }
  }
  
  Object dequeue() {
    if (head == tail && full == false) {
    }
    Object ret = array[head];
    head = (head+1)%array.length;
    if (full) {
      full = false;
    }
    return ret;
  }
  
  Object peek() {
    if (head == tail && full == false) {
      return null;
    }
    return array[head];
  }
  
  boolean isEmpty() {
    return head == tail && !full;
  }
}

class BreadthFirstSearch {
  
  Graph graph;
  Queue grayVertices;
  Node source;
  
  BreadthFirstSearch(Graph graph) {
    this.graph = graph;
    grayVertices = new Queue(graph.nodes.size());
    source = null;
  }
  
  void setupSearch(Node source) {
    this.source = source;
    for (Node n : graph.nodes) {
      n.col = white;
      n.parent = null;
      n.children = new ArrayList<Node>();
    }
    grayVertices = new Queue(graph.nodes.size());
    source.col = gray;
    grayVertices.enqueue(source);
  }
  
  void oneStep() {
    if (!grayVertices.isEmpty()) {
      Node current = (Node)(grayVertices.dequeue());
      for (Node neighbor : current.neighbors) {
        if (neighbor.col == white) {
          neighbor.col = gray;
          neighbor.parent = current;
          current.children.add(neighbor);
          grayVertices.enqueue(neighbor);
        }
      }
      current.col = black;
      
      Node sel = ((Node)(grayVertices.peek()));
      if (sel != null) {
        sel.selected = true;
        for (Node other : graph.nodes){
          if (other != sel)
          other.selected = false;
        }
      }
    }
  }
  
  void performSearch(Node source) {
    setupSearch(source);
    while (!grayVertices.isEmpty()) {
      oneStep();
    }
  }
  
  void drawBreadthFirstTree(float x, float y, float w, float h) {
    source.drawBreadthFirstTree(x, y, w, h);
  }
  
}

class Graph {
  
  ArrayList<Node> nodes;
  float nodeSize;
  
  Graph() {
    nodes = new ArrayList<Node>();
  }
  
  void addNode(Node node) {
    nodes.add(node);
  }
  
  Node getRandomNode() {
    int rand = (int)random(nodes.size());
    return nodes.get(rand);
  }
  
  void addEdge(Node n1, Node n2) {
    if (!n1.neighbors.contains(n2)) {
      n1.neighbors.add(n2);
    }
    if (!n2.neighbors.contains(n1)) {
      n2.neighbors.add(n1);
    }
  }
  
  boolean edgeExists(Node n1, Node n2) {
    return n1.neighbors.contains(n2) && n2.neighbors.contains(n1);
  }
  
  void drawGraph() {
    for (Node n : nodes) {
      n.drawEdges();
    }
    for (Node n : nodes) {
      n.draw(n.x, n.y, nodeSize);
    }
  }
  
}

class Node {
  
  int value;
  color col;
  ArrayList<Node> neighbors;
  float x, y;
  Node parent;
  ArrayList<Node> children;
  boolean selected;
  
  Node (int value) {
    this.value = value;
    col = white;
    neighbors = new ArrayList<Node>();
    children = new ArrayList<Node>();
    
    x = random(.1*pg.width, .9*pg.width);
    y = random(.1*pg.width, .9*pg.width);
    parent = null;
    selected = false;
  }
  
  Node (int value, float x, float y) {
    this(value);
    this.x = x;
    this.y = y;
  }
  
  void draw(float x, float y, float size) {
    pg.strokeWeight(3);
    pg.stroke(black);
    if (selected) {
      pg.strokeWeight(4);
      pg.stroke(50, 50, 255);
    }
    pg.fill(col);
    pg.ellipse (x, y, size, size);
    
    pg.fill(255, 0, 0);
    pg.textAlign (CENTER, CENTER);
    pg.textSize (20);
    pg.text(value, x, y);
  }
  
  void drawEdges() {
    pg.strokeWeight(2);
    pg.stroke(black);
    for (Node n : neighbors) {
      if (n.parent != this) {
        pg.line(x, y, n.x, n.y);
      }
    }
    if (parent != null) {
      pg.strokeWeight(5);
      pg.stroke(0, 0, 255);
      pg.line(x, y, parent.x, parent.y);
    }
  }
  
  void drawBreadthFirstTree(float x, float y, float w, float h) {
    float treeWidth = getTreeWidth(50);
    float subTreeX = x;
    float realNodeSize = 50*(w/treeWidth);
    for (Node child : children) {
      float childWidth = child.getTreeWidth(realNodeSize);
      pg.stroke(0, 0, 255);
      pg.strokeWeight(2);
      pg.line (x+w/2, y+min(50,realNodeSize)/2, subTreeX+childWidth/2, y+70+min(50,realNodeSize)/2);
      child.drawBreadthFirstTree(subTreeX, y+70, childWidth, h-70);
      subTreeX += childWidth+realNodeSize/3.;
    }
    this.draw(x+w/2, y+min(50,realNodeSize)/2, min(50,realNodeSize));
  }
  
  float getTreeWidth(float nodeSize) {
    if (children.size() == 0) {
      return nodeSize;
    } else {
      float w = -nodeSize/3.;
      for (Node child : children) {
        w += child.getTreeWidth(nodeSize)+nodeSize/3.;
      }
      return w;
    }
  }
  
}
