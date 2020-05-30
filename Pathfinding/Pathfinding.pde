/* @pjs preload="/static/projects/Pathfinding/data/rotate.png"; */

Dropdown algoDrop, genDrop, sizeDrop, speedDrop;
Button genButton, playButton, resetButton, clearButton, advancedButton, cancelButton, OKButton;
SelectGroup editMode;
boolean advancedOpen;
ArrayList<UIElement> elements;

String mapSize;
String searchSpeed;

boolean paused;
boolean placeTiles;

PImage resetImg;
PGraphics resetG;

int steps = 0;
int timeSinceMoved = 0;

int nodeRows = 30;
int nodeCols = 34;
float nodeW, screenNW;
float nodeH, screenNH;

color grassCol, forestCol, waterCol, wallCol;

PGraphics map;

NavNode[][] nodes;

int startRow, startCol;
int endRow, endCol;

int dragging;

void setup() {
  size ((int)(330 + max(screenHeight * 0.8,600) * (34.0/30.0)), (int)(max(screenHeight * 0.8,600)));
  map = createGraphics(1010-330, 600);
  grassCol = color(#99D89E);
  forestCol = color(#638E25);
  waterCol = color(#6DBBEA);
  wallCol = color(50);
  startRow = 10;
  startCol = 10;
  endRow = 15;
  endCol = 25;
  loadImages();
  createUI();
  setupNodes();
  drawMap();
  setupSearches();
  paused = true;
  placeTiles = true;
  currentObstacles = "";
  dragging = 0;
}

void draw() {
  background(255);
  image (map, 330, 0, width-330, height);
  buttonFunctions();
  handleDrawing();
  drawEndpoints();
  dragEndpoints();
  drawPanel();
  executeSearch();
  generateObstacles();
  timeSinceMoved++;
}

void mousePressed() {
  for (UIElement e : elements) {
    e.mousePressed();
  }
  if (advancedOpen && !mouseIn(advancedX, advancedY, advancedW, advancedH, 1) && !advancedButton.beingPressed && speedDrop.inFocus == 0 && sizeDrop.inFocus == 0) {
    advancedOpen = false;
    OKButton.active = false;
    updateSizeAndSpeed();
  }
  checkDragging();
}

void mouseReleased() {
  for (UIElement e : elements) {
    e.mouseReleased();
  }
  dragging = 0;
  placeTiles = true;
}

void mouseMoved() {
  timeSinceMoved = 0;
}

String currentObstacles;
void generateObstacles() {
  if (!currentObstacles.equals("")) {
    int iters = 1;
    if (currentObstacles.equals("Maze")) {
      iters = 10 * (nodeRows/30) * (nodeCols/34);
    } else if (currentObstacles.equals("Random Walls")) {
      iters = 40 * (nodeRows/30) * (nodeCols/34);
    } else if (currentObstacles.equals("River")) {
      iters = (nodeCols/34);
    } else if (currentObstacles.equals("Forests + River")) {
      iters = (nodeCols/34);
    }
    executeGenAlgorithm(currentObstacles, iters);
  }
}

void executeGenAlgorithm(String name, int iters) {
  map.beginDraw();
  for (int i = 0; i < iters; i++) {
    if (currentObstacles.equals(name)) {
      if (name.equals("Maze")) {
        stepWilsons();
      } else if (name.equals("Forests")) {
        stepForests();
      } else if (name.equals("River")) {
        stepRiver();
      } else if (name.equals("Forests + River")) {
        stepForestsAndRiver();
      } else if (name.equals("Random Walls")) {
        stepRandomWalls();
      }
    }
  }
  map.endDraw();
}

String currentSearch;
void executeSearch() {
  int speedMult = 1;
  int speedMod = 1;
  if (searchSpeed.equals("Slow")) {
    speedMod = 5;
  } else if (searchSpeed.equals("Fast")) {
    speedMult = 4;
  } else if (searchSpeed.equals("Very Fast")) {
    speedMult = 16;
  }
  if (frameCount % speedMod == 0) {
    for (int i = 0; i < speedMult; i++) {
      if (!paused) {
        if (walkingPath == 0) {
          if (currentSearch.equals("A* (A-star)")) {
            stepAStar();
          } else if (currentSearch.equals("Dijkstra's Algorithm")) {
            stepAStar();
          } else if (currentSearch.equals("Greedy Search")) {
            stepGreedy();
          } else if (currentSearch.equals("Depth-First Search")) {
            stepDFS();
          } else if (currentSearch.equals("Breadth-First Search")) {
            stepBFS();
          } else if (currentSearch.equals("Colorful BFS")) {
            stepColorfulBFS();
          }
        }
      }
    }
  }
  if (paused && walkingPath == 1) {
    speedMult = 1;
    speedMod = 1;
    if (searchSpeed.equals("Fast")) {
      speedMult = 2;
    } else if (searchSpeed.equals("Very Fast")) {
      speedMult = 4;
    }
    for (int i = 0; i < speedMult; i++) {
      walkPath();
    }
  }
}

void checkDragging() {
  if (dist(mouseX-330,mouseY,startCol*screenNW+screenNW/2, startRow*screenNH+screenNH/2) < max(3,screenNW/2) && !(advancedOpen && mouseIn(advancedX, advancedY, advancedW, advancedH, 1))) {
    dragging = 1;
  }
  if (dist(mouseX-330,mouseY,endCol*screenNW+screenNW/2, endRow*screenNH+screenNH/2) < max(3,nodeW/2) && !(advancedOpen && mouseIn(advancedX, advancedY, advancedW, advancedH, 1))) {
    dragging = 2;
  }
}

void dragEndpoints() {
  if (dragging == 1) {
    int row = (int)clamp(mouseY / screenNH, 0, nodes.length-1);
    int col = (int)clamp((mouseX-330) / screenNW, 0, nodes[0].length-1);
    if (nodes[row][col] != null && !(row == endRow && col == endCol)) {
      if ((startRow != row || startCol != col) && steps != 0) {
        reset();
      }
      startRow = row;
      startCol = col;
    }
  } else if (dragging == 2) {
    int row = (int)clamp(mouseY / screenNH, 0, nodes.length-1);
    int col = (int)clamp((mouseX-330) / screenNW, 0, nodes[0].length-1);
    if (nodes[row][col] != null && !(row == startRow && col == startCol)) {
      if ((endRow != row || endCol != col) && steps != 0) {
        reset();
      }
      endRow = row;
      endCol = col;
    }
  }
}

void drawEndpoints() {
  noStroke();
  fill (0, 0, 255);
  if ((dist(mouseX-330,mouseY,startCol*screenNW+screenNW/2, startRow*screenNH+screenNH/2) < max(3,screenNW/2) && !mousePressed && !(advancedOpen && mouseIn(advancedX, advancedY, advancedW, advancedH, 1))) || dragging == 1) {
    fill (100, 100, 255);
    int drawCol = startCol;
    int drawRow = startRow;
    if (dragging == 1) {
      drawCol = (int)((mouseX - 330)/screenNW);
      drawRow = (int)(mouseY/screenNH);
    }
    rect (330 + drawCol * screenNW - 5, drawRow * screenNH - 5, screenNW + 10, screenNH + 10, 5);
    if (dragging == 0) {
      quickTooltip ("Click and drag to move", 0, 0, width, height, 170, 30);
    }
  } else {
    rect (330 + startCol * screenNW - 2, startRow * screenNH - 2, screenNW + 4, screenNH + 4, 5);
  }
  fill (255, 0, 0);
  if ((dist(mouseX-330,mouseY,endCol*screenNW+screenNW/2, endRow*screenNH+screenNH/2) < max(3,screenNW/2) && !mousePressed && !(advancedOpen && mouseIn(advancedX, advancedY, advancedW, advancedH, 1))) || dragging == 2) {
    fill (255, 100, 100);
    int drawCol = endCol;
    int drawRow = endRow;
    if (dragging == 2) {
      drawCol = (int)((mouseX - 330)/screenNW);
      drawRow = (int)(mouseY/screenNH);
    }
    rect (330 + drawCol * screenNW - 5, drawRow * screenNH - 5, screenNW + 10, screenNH + 10, 5);
    if (dragging == 0) {
      quickTooltip ("Click and drag to move", 0, 0, width, height, 170, 30);
    }
  } else {
    rect (330 + endCol * screenNW - 2, endRow * screenNH - 2, screenNW + 4, screenNH + 4, 5);
  }
}

void buttonFunctions() {
  if (playButton.active && currentObstacles.equals("")) {
    paused = !paused;
    if (!paused) {
      if (steps == 0) {
        setupAlgorithm();
      }
      if (walkingPath != 0 || (steps != 0 && walkingPath == 0 && !currentSearch.equals(algoDrop.value))) {
        reset();
        paused = false;
        setupAlgorithm();
      }
    }
  }
  
  if (resetButton.active) {
    reset();
  }
  
  if (clearButton.active) {
    reset();
    setupNodes();
    drawMap();
    if (!currentObstacles.equals("")) {
      genCleanup();
    }
  }
  
  if (genButton.active) {
    if (genButton.buttonText.equals("Generate Obstacles")) {
      reset();
      genButton.buttonText = "Cancel";
      currentObstacles = genDrop.value;
      if (genDrop.value.equals("Maze")) {
        setupWilsons();
      } else if (genDrop.value.equals("Forests")) {
        setupForests();
      } else if (genDrop.value.equals("River")) {
        setupRiver();
      } else if (genDrop.value.equals("Forests + River")) {
        setupForestsAndRiver();
      } else if (genDrop.value.equals("Random Walls")) {
        setupRandomWalls();
      }
    } else {
      // generation cancelled
      genCleanup();
      if (nodes[startRow][startCol] == null) {
        nodes[startRow][startCol] = new NavNode(startCol * nodeW, startRow * nodeH, 1);
      }
      if (nodes[endRow][endCol] == null) {
        nodes[endRow][endCol] = new NavNode(endCol * nodeW, endRow * nodeH, 1);
      }
    }
  }
  
  if (advancedButton.active) {
    advancedOpen = !advancedOpen;
    mapSize = sizeDrop.value;
    searchSpeed = speedDrop.value;
  }
  
  if (cancelButton.active) {
    cancelAdvanced();
  }
  
  if (OKButton.active) {
    advancedOpen = false;
    OKButton.active = false;
    updateSizeAndSpeed();
  }
}

void cancelAdvanced() {
  advancedOpen = false;
  cancelButton.active = false;
  sizeDrop.value = mapSize;
  speedDrop.value = searchSpeed;
}

void updateSizeAndSpeed() {
  if (!sizeDrop.value.equals(mapSize)) {
    genCleanup();
    reset();
    int sizeMult = 1;
    if (sizeDrop.value.equals("Large")) {
      sizeMult = 2;
    } else if (sizeDrop.value.equals("Huge")) {
      sizeMult = 4;
    } else if (sizeDrop.value.equals("Huger (Not Recommended)")) {
      sizeMult = 10;
    }
    nodeRows = 30 * sizeMult;
    nodeCols = 34 * sizeMult;
    setupNodes();
    drawMap();
    startRow = (int)clamp(startRow, 0, nodes.length-2);
    startCol = (int)clamp(startCol, 0, nodes[0].length-2);
    endRow = (int)clamp(endRow, 0, nodes.length-1);
    endCol = (int)clamp(endCol, 0, nodes[0].length-1);
  }
  mapSize = sizeDrop.value;
  searchSpeed = speedDrop.value;
}

void setupAlgorithm() {
  currentSearch = algoDrop.value;
  if (algoDrop.value.equals("A* (A-star)")) {
    setupAStar();
  } else if (algoDrop.value.equals("Dijkstra's Algorithm")) {
    setupAStar(); // uses h(n) = 0
  } else if (algoDrop.value.equals("Greedy Search")) {
    setupGreedy();
  } else if (algoDrop.value.equals("Depth-First Search")) {
    setupDFS(true);
  } else if (algoDrop.value.equals("Breadth-First Search")) {
    setupBFS();
  } else if (algoDrop.value.equals("Colorful BFS")) {
    setupColorfulBFS();
  }
}

void reset() {
  if (steps != 0 && walkingPath == 0) {
    restoreWeights();
  }
  steps = 0;
  walkingPath = 0;
  drawMap();
  paused = true;
}

void drawMap() {
  map.beginDraw();
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[row].length; col++) {
      if (nodes[row][col] != null) {
        nodes[row][col].draw(nodeW, nodeH);
      } else {
        map.fill(wallCol);
        map.noStroke();
        map.rect(col*nodeW, row*nodeH, nodeW, nodeH);
      }
    }
  }
  map.endDraw();
}

void handleDrawing() {
  if (mouseX > 330 && (steps == 0 || walkingPath != 0) && currentObstacles.equals("") && !(advancedOpen && mouseIn(advancedX, advancedY, advancedW, advancedH, 1)) && placeTiles) {
    float mapX = mouseX - 330;
    float floorX = 330 + mapX - (mapX % screenNW);
    float floorY = mouseY - (mouseY % screenNH);
    fill (0, 0, 0, 50);
    noStroke();
    rect (floorX, floorY, screenNW, screenNH);
    String modeLabel = editMode.getSelected().label;
    float weightAssign = 0;
    if (modeLabel.equals("Grass")) {
      weightAssign = 1;
    } else if (modeLabel.equals("Forest")) {
      weightAssign = 2;
    } else if (modeLabel.equals("Water")) {
      weightAssign = 5;
    } else {
      weightAssign = -1;
    }
    if (mousePressed && dragging == 0) {
      if (steps != 0) {
        reset();
      }
      map.beginDraw();
      for (float a = 0; a < 1; a += 0.03) {
        float newX = a*mouseX + (1-a)*pmouseX;
        float newY = a*mouseY + (1-a)*pmouseY;
        int row = (int)(newY / screenNH);
        int col = (int)((newX - 330) / screenNW);
        if (row >= 0 && col >= 0 && row < nodes.length && col < nodes[0].length && !(row == startRow && col == startCol) && !(row == endRow && col == endCol)) {
          newX = myMap(newX-330, 0, width-330, 0, map.width);
          newY = myMap(newY, 0, height, 0, map.height);
          floorX = newX - (newX % nodeW);
          floorY = newY - (newY % nodeH);
          boolean changed = false;
          if (nodes[row][col] == null) {
            if (weightAssign != -1) {
              nodes[row][col] = new NavNode(floorX, floorY, weightAssign);
              changed = true;
            }
          } else if (nodes[row][col].weight != weightAssign) {
            if (weightAssign != -1) {
              nodes[row][col].weight = weightAssign;
            } else {
              nodes[row][col] = null;
            }
            changed = true;
          }
          if (changed) {
            if (nodes[row][col] != null) {
              nodes[row][col].draw(nodeW, nodeH);
            } else {
              map.noStroke();
              map.fill(wallCol);
              map.rect(floorX, floorY, nodeW, nodeH);
            }
          }
        }
      }
      map.endDraw();
    }
  }
}

void drawPanel() {
  stroke(0);
  strokeWeight(1);
  fill (230);
  rect (-1, -1, 330 + 1, height+1);
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(30);
  text("Settings", 330/2.0, 23);
  textSize(16);
  textAlign(LEFT, CENTER);
  text("Search algorithm:", 15, 65);
  text("Add obstacles:", 15, 105);
  textAlign(CENTER, BOTTOM);
  fill(0);
  textSize(20);
  float stepsY = 340;
  if (!currentObstacles.equals("")) {
    if (currentObstacles.equals("Maze")) {
      text ("Generating Maze...", 330/2.0, stepsY);
    } else if (currentObstacles.equals("Forests")) {
      text ("Generating Forests...", 330/2.0, stepsY);
    } else if (currentObstacles.equals("River")) {
      text ("Generating River...", 330/2.0, stepsY);
    } else if (currentObstacles.equals("Forests + River")) {
      text ("Generating Forests + River...", 330/2.0, stepsY);
    } else if (currentObstacles.equals("Random Walls")) {
      text ("Generating Random Walls...", 330/2.0, stepsY);
    }
  } else {
    if (walkingPath == 0) {
      text ("Steps: " + steps, 330/2.0, stepsY);
    } else {
      if (!searchFailed) {
        if (currentSearch.equals("A* (A-star)") || currentSearch.equals("Dijkstra's Algorithm")) {
          text ("Shortest path in " + steps + " steps.", 330/2.0, stepsY);
        } else if (currentSearch.equals("Breadth-First Search") || currentSearch.equals("Colorful BFS")) {
          textSize(16);
          text ("Unweighted shortest path in " + steps + " steps.", 330/2.0, stepsY);
        } else {
          textSize(18);
          text ("Non-shortest path in " + steps + " steps.", 330/2.0, stepsY);
        }
      } else {
        text ("Search failed.", 330/2.0, stepsY);
      }
    }
  }
  if (advancedOpen && mouseIn(advancedX, advancedY, advancedW, advancedH, 1)) {
    genButton.inFocus = 0;
    clearButton.inFocus = 0;
    clearButton.beingPressed = false;
    resetButton.inFocus = 0;
    playButton.inFocus = 0;
    algoDrop.inFocus = 0;
    algoDrop.dropped = false;
    genDrop.inFocus = 0;
    genDrop.dropped = false;
  }
  genButton.draw();
  clearButton.draw();
  resetButton.draw();
  playButton.draw();
  advancedButton.draw();
  if (steps != 0 && walkingPath == 0 && !paused) {
    algoDrop.inFocus = 0;
    algoDrop.dropped = false;
  }
  genDrop.draw();
  algoDrop.draw();
  if (steps != 0 && walkingPath == 0 && !paused) {
    quickTooltip ("Algorithm cannot be changed during search.", algoDrop.x, algoDrop.y, algoDrop.w, algoDrop.h, 170, 55);
  }
  if (!advancedOpen && algoDrop.inFocus == 0 && genDrop.inFocus == 0) {
    quickTooltip ("Clear search", resetButton.x, resetButton.y, resetButton.w, resetButton.h, 110, 30);
  }
  strokeWeight(1);
  stroke(100);
  line(15, 348, 315, 348);
  fill(0);
  textSize(20);
  textAlign(CENTER, TOP);
  text ("Edit Map", 330/2.0, 358);
  editMode.draw();
  if (advancedOpen) {
    stroke(0);
    strokeWeight(1);
    fill (230);
    rect (advancedX, advancedY, advancedW, advancedH);
    fill(0);
    textSize(16);
    textAlign(RIGHT, CENTER);
    text("Map size:", sizeDrop.x - 10, sizeDrop.y + 15);
    text("Search speed:", speedDrop.x - 10, speedDrop.y + 15);
    cancelButton.draw();
    OKButton.draw();
    speedDrop.draw();
    sizeDrop.draw();
  }
  
}

float advancedX, advancedY, advancedW, advancedH;
void createUI() {
  elements = new ArrayList<UIElement>();
  String[] algorithms = {"Dijkstra's Algorithm", "A* (A-star)", "Greedy Search", "Breadth-First Search", "Depth-First Search", "Colorful BFS"};
  algoDrop = new Dropdown (160, 50, 160, algorithms, algorithms[1]);
  String[] obstacleGens = {"Maze", "Forests", "River", "Forests + River", "Random Walls"};
  genDrop = new Dropdown (160, 90, 160, obstacleGens, obstacleGens[0]);
  genButton = new Button ("Generate Obstacles", 15, 130, 185, 30);
  clearButton = new Button ("Erase Map", 210, 130, 110, 30);
  float buf = 15;
  float bSize = 98;
  playButton = new Button ("!!!Play", 15+152.5-bSize-buf/2.0, 210, bSize, bSize);
  resetButton = new Button ("!!!Reset", 15+152.5+buf/2, 210, bSize, bSize);
  advancedButton = new Button("Advanced Settings", 330/2.0 - 90, 170, 180, 30);
  advancedOpen = false;
  advancedX = 330/2.0 + 90 + 10;
  advancedY = 185 - 80;
  advancedW = 270;
  advancedH = 140;
  String[] mapSizes = {"Normal", "Large", "Huge", "Huger (Not Recommended)"};
  sizeDrop = new Dropdown (advancedX + advancedW - 140, advancedY + 15, 125, mapSizes, mapSizes[0]);
  String[] speeds = {"Slow", "Normal", "Fast", "Very Fast"};
  speedDrop = new Dropdown (advancedX + advancedW - 140, advancedY + 55, 125, speeds, speeds[1]);
  cancelButton = new Button("Cancel", advancedX + advancedW/2.0 - 100, advancedY + 95, 90, 30);
  OKButton = new Button("OK", advancedX + advancedW/2.0 + 10, advancedY + 95, 90, 30);
  mapSize = "Normal";
  searchSpeed = "Normal";
  
  editMode = new SelectGroup();
  float startY = 385;
  float modeSize = 100;
  float xBuf = 30;
  float yBuf = 5;
  SelectOption grassMode = new SelectOption (330/2 - modeSize - xBuf/2.0, startY, modeSize, grassCol, "Grass");
  grassMode.addTooltip("Easy to move through.\nWeight: 1", 180, 55);
  SelectOption forestMode = new SelectOption (330/2 + xBuf/2.0, startY, modeSize, forestCol, "Forest");
  forestMode.addTooltip("Hard to move through.\nWeight: 2", 180, 55);
  SelectOption waterMode = new SelectOption (330/2 - modeSize - xBuf/2.0, startY + modeSize + yBuf, modeSize, waterCol, "Water");
  waterMode.addTooltip("Very hard to move through.\nWeight: 5", 200, 55);
  SelectOption wallMode = new SelectOption (330/2 + xBuf/2.0, startY + modeSize + yBuf, modeSize, wallCol, "Wall");
  wallMode.addTooltip("Blocks movement.", 150, 35);
  editMode.addOption(grassMode);
  editMode.addOption(forestMode);
  editMode.addOption(waterMode);
  editMode.addOption(wallMode);
  editMode.setSelected(wallMode);
}

void loadImages() {
  resetImg = loadImage("/static/projects/Pathfinding/data/rotate.png");
  resetImg.resize (100, 100);
  resetG = createGraphics(resetImg.width, resetImg.height);
  resetG.beginDraw();
  resetG.image(resetImg, 0, 0);
  resetG.endDraw();
  resetG.loadPixels();
  for (int i = 0; i < resetG.pixels.length; i++) {
    resetG.pixels[i] = color(135,135,135,255-red(resetImg.pixels[i]));
  }
  resetG.updatePixels();
}

void setupNodes() {
  nodes = new NavNode[nodeRows][nodeCols];
  nodeW = map.width / nodeCols;
  nodeH = map.height / nodeRows;
  screenNW = (width-330.0) / nodeCols;
  screenNH = height / nodeRows;
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[row].length; col++) {
      nodes[row][col] = new NavNode(col * nodeW, row * nodeH, 1);
    }
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

void quickTooltip (String message, float rX, float rY, float rW, float rH, float tW, float tH) {
  if (mouseIn(rX, rY, rW, rH,1) && timeSinceMoved > 10) {
    fill (0, 0, 0, 200);
    noStroke();
    float posX = mouseX - tW/2;
    float posY = mouseY - tH - 2;
    rect(posX, posY, tW, tH);
    fill (255);
    textSize(15);
    textAlign(CENTER, CENTER);
    text(message, posX, posY-4, tW, tH);
  }
}

float clamp (float val, float minVal, float maxVal) {
  return max(min(val, maxVal),minVal);
}

float myMap (float val, float min1, float max1, float min2, float max2) {
    float perc = (val - min1) / (max1-min1);
    float ret = min2 + perc * (max2-min2);
    return ret;
}

MinHeap heap;
NavNode[][] cameFrom;
int walkingPath;
boolean searchFailed;

void setupSearches() {
  heap = new MinHeap (nodeRows * nodeCols);
  walkingPath = 0;
  pathWaitTime = 0;
  pathStack = null;
  searchFailed = false;
}

void setupAStar() {
  pathStack = null;
  searchFailed = false;
  darkenMap();
  nodes[startRow][startCol].distFromStart = 0;
  nodes[startRow][startCol].hDist = heuristic(nodes[startRow][startCol]);
  heap = new MinHeap (nodeRows * nodeCols);
  heap.insert(nodes[startRow][startCol]);
}

void stepAStar() {
  map.beginDraw();
  map.noStroke();
  NavNode goal = nodes[endRow][endCol];
  if (heap.heapSize == 0) {
    failSearch();
    return;
  }
  NavNode current = heap.peek();
  //println();
  //heap.print();
  if (current == goal) {
    walkingPath = 1;
    paused = true;
    restoreWeights();
  } else {
    steps++;
    heap.remove();
    for (NavNode neighbor : current.neighbors()) {
      float tentDist = current.distFromStart + neighbor.weight;
      if (tentDist < neighbor.distFromStart) {
        neighbor.distFromStart = tentDist;
        cameFrom[neighbor.getRow()][neighbor.getCol()] = current;
        float newHDist = neighbor.distFromStart + heuristic(neighbor);
        if (!heap.contains(neighbor)) {
          neighbor.hDist = newHDist;
          heap.insert(neighbor);
          neighbor.draw(nodeW, nodeH);
          map.fill (0, 0, 0, 75);
          map.rect (neighbor.x, neighbor.y, nodeW, nodeH);
        } else if (newHDist < neighbor.hDist) {
          heap.decreaseKey (heap.getIndex(neighbor), newHDist);
        }
      }
    }
    current.draw(nodeW, nodeH);
  }
  map.endDraw();
}

int[][] knownStatus;

void setupGreedy() {
  pathStack = null;
  searchFailed = false;
  knownStatus = new int[nodeRows][nodeCols];
  darkenMap();
  nodes[startRow][startCol].distFromStart = 0;
  nodes[startRow][startCol].hDist = heuristic(nodes[startRow][startCol]);
  knownStatus[startRow][startCol] = 1;
  heap = new MinHeap (nodeRows * nodeCols);
  heap.insert(nodes[startRow][startCol]);
}

void stepGreedy() {
  map.beginDraw();
  map.noStroke();
  if (heap.heapSize == 0) {
    failSearch();
    return;
  }
  NavNode goal = nodes[endRow][endCol];
  NavNode current = heap.peek();
  for (int i = 1; i < heap.heapSize; i++) {
    if (heap.arr[i].hDist < current.hDist) {
    }
  }
  if (current == goal) {
    walkingPath = 1;
    paused = true;
    restoreWeights();
  } else {
    steps++;
    heap.remove();
    for (NavNode neighbor : current.neighbors()) {
      if (knownStatus[neighbor.getRow()][neighbor.getCol()] == 0) {
        knownStatus[neighbor.getRow()][neighbor.getCol()] = 1;
        neighbor.hDist = heuristic(neighbor);
        neighbor.distFromStart = current.distFromStart + neighbor.weight;
        cameFrom[neighbor.getRow()][neighbor.getCol()] = current;
        if (!heap.contains(neighbor)) {
          heap.insert(neighbor);
          neighbor.draw(nodeW, nodeH);
          map.fill (0, 0, 0, 75);
          map.rect (neighbor.x, neighbor.y, nodeW, nodeH);
        }
      }
    }
    current.draw(nodeW, nodeH);
    knownStatus[current.getRow()][current.getCol()] = 2;
  }
  map.endDraw();
}

Stack DFSStack;

Stack DFSStack;
boolean randomized;
// make sure it's unweighted
void setupDFS(boolean stochastic) {
  pathStack = null;
  searchFailed = false;
  darkenMap();
  DFSStack = new Stack (nodeRows * nodeCols);
  knownStatus = new int[nodeRows][nodeCols];
  knownStatus[startRow][startCol] = 1;
  DFSStack.push(nodes[startRow][startCol]);
  randomized = stochastic;
}

void stepDFS() {
  if (DFSStack.isEmpty()) {
    failSearch();
    return;
  }
  NavNode current = DFSStack.peek();
  if (current == nodes[endRow][endCol]) {
    walkingPath = 1;
    paused = true;
    restoreWeights();
  } else {
    steps++;
    NavNode previous = cameFrom[current.getRow()][current.getCol()];
    map.beginDraw();
    map.fill (0, 0, 0, 75);
    float buf = 1;
    if (nodeW <= 2) {
      buf = 0;
    }
    if (previous != null) {
      if (current.x > previous.x) {
        current.x-=buf; current.y+=buf;
        color prevWeight = current.weight;
        current.weight = 1;
        current.draw(nodeW, nodeH-2*buf);
        current.weight = prevWeight;
        current.x+=buf; current.y-=buf;
      }
      if (current.x < previous.x) {
        current.x+=buf; current.y+=buf;
        color prevWeight = current.weight;
        current.weight = 1;
        current.draw(nodeW, nodeH-2*buf);
        current.weight = prevWeight;
        current.x-=buf; current.y-=buf;
      }
      if (current.y > previous.y) {
        current.y-=buf; current.x+=buf;
        color prevWeight = current.weight;
        current.weight = 1;
        current.draw(nodeW-2*buf, nodeH);
        current.weight = prevWeight;
        current.y+=buf; current.x-=buf;
      }
      if (current.y < previous.y) {
        current.y+=buf; current.x+=buf;
        color prevWeight = current.weight;
        current.weight = 1;
        current.draw(nodeW-2*buf, nodeH);
        current.weight = prevWeight;
        current.y-=buf; current.x-=buf;
      }
    } else {
      current.draw(nodeW, nodeH);
      map.rect (current.x, current.y, nodeW, nodeH);
    }
    map.endDraw();
    int numOptions = 0;
    for (NavNode neighbor : current.neighbors()) {
      int row = neighbor.getRow();
      int col = neighbor.getCol();
      if (knownStatus[row][col] == 0) {
        if (!randomized) {
          knownStatus[row][col] = 1;
          cameFrom[row][col] = current;
          DFSStack.push(neighbor);
          return;
        }
        numOptions++;
      }
    }
    NavNode[] options = new NavNode[numOptions];
    if (numOptions > 0) {
      int index = 0;
      for (NavNode neighbor : current.neighbors()) {
        int row = neighbor.getRow();
        int col = neighbor.getCol();
        if (knownStatus[row][col] == 0) {
          options[index] = neighbor;
          index++;
        }
      }
      int pickIndex = int(random(numOptions));
      NavNode picked = options[pickIndex];
      int row = picked.getRow();
      int col = picked.getCol();
      knownStatus[row][col] = 1;
      cameFrom[row][col] = current;
      DFSStack.push(picked);
      return;
    }
    DFSStack.pop();
    map.beginDraw();
    map.fill(200, 50, 50);
    if (previous != null) {
      if (current.x > previous.x) {
        map.rect(current.x-buf, current.y + buf, nodeW, nodeH-2*buf);
      }
      if (current.x < previous.x) {
        map.rect(current.x+buf, current.y + buf, nodeW, nodeH-2*buf);
      }
      if (current.y > previous.y) {
        map.rect(current.x + buf, current.y - buf, nodeW - 2*buf, nodeH);
      }
      if (current.y < previous.y) {
        map.rect(current.x + buf, current.y + buf, nodeW - 2*buf, nodeH);
      }
    } else {
      map.rect(current.x, current.y, nodeW, nodeH);
    }
    map.endDraw();
  }
}

Queue BFSQueue;

void setupBFS() {
  pathStack = null;
  searchFailed = false;
  darkenMap();
  BFSQueue = new Queue (nodeRows * nodeCols);
  knownStatus = new int[nodeRows][nodeCols];
  knownStatus[startRow][startCol] = 1;
  BFSQueue.enqueue(nodes[startRow][startCol]);
}

void stepBFS() {
  if (BFSQueue.isEmpty()) {
    failSearch();
    return;
  }
  NavNode current = BFSQueue.peek();
  if (current == nodes[endRow][endCol]) {
    walkingPath = 1;
    paused = true;
    restoreWeights();
  } else {
    map.beginDraw();
    steps++;
    for (NavNode neighbor : current.neighbors()) {
      int row = neighbor.getRow();
      int col = neighbor.getCol();
      if (knownStatus[row][col] == 0) {
        knownStatus[row][col] = 1;
        cameFrom[row][col] = current;
        BFSQueue.enqueue(neighbor);
        neighbor.draw(nodeW, nodeH);
        map.fill (0, 0, 0, 75);
        map.rect (neighbor.x, neighbor.y, nodeW, nodeH);
      }
    }
    BFSQueue.dequeue();
    current.draw(nodeW, nodeH);
    map.endDraw();
  }
}

void setupColorfulBFS() {
  setupBFS();
  nodes[startRow][startCol].distFromStart = 0;
}

void stepColorfulBFS() {
  if (BFSQueue.isEmpty()) {
    failSearch();
    return;
  }
  NavNode current = BFSQueue.peek();
  float hueMult = 255.0/nodeRows / 3.0;
  if (current == nodes[endRow][endCol]) {
    walkingPath = 1;
    paused = true;
    restoreWeights();
  } else {
    map.beginDraw();
    map.colorMode(HSB);
    steps++;
    for (NavNode neighbor : current.neighbors()) {
      int row = neighbor.getRow();
      int col = neighbor.getCol();
      if (knownStatus[row][col] == 0) {
        knownStatus[row][col] = 1;
        cameFrom[row][col] = current;
        neighbor.distFromStart = current.distFromStart + 1;
        BFSQueue.enqueue(neighbor);
        map.fill ((neighbor.distFromStart * hueMult) % 255, 255, 255);
        map.rect (neighbor.x, neighbor.y, nodeW, nodeH);
      }
    }
    BFSQueue.dequeue();
    map.colorMode(RGB);
    map.endDraw();
  }
}

void restoreWeights() {
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[0].length; col++) {
      if (nodes[row][col] != null) {
        nodes[row][col].weight = prevWeights[row][col];
      }
    }
  }
}

Stack pathStack;
int pathWaitTime;
NavNode lastNode;

void walkPath() {
  if (pathStack == null) {
    // setup
    pathWaitTime = 0;
    lastNode = null;
    pathStack = new Stack (nodeRows * nodeCols);
    NavNode nextNode = nodes[endRow][endCol];
    while (nextNode != nodes[startRow][startCol]) {
      pathStack.push(nextNode);
      nextNode = cameFrom[nextNode.getRow()][nextNode.getCol()];
    }
  } else {
    if (!pathStack.isEmpty()) {
      NavNode n = pathStack.peek();
      float threshold = n.weight * 2;
      if (currentSearch.equals("Depth-First Search")) {
        threshold = 1;
      } else if (currentSearch.equals("Breadth-First Search")) {
        threshold = 2;
      }
      if (pathWaitTime >= threshold) {
        pathStack.pop();
        map.beginDraw();
        map.fill(255, 255, 0);
        float buf = 1;
        if (nodeW <= 2) {
          buf = 0;
        }
        map.rect(n.x + buf, n.y + buf, nodeW - buf*2, nodeH - buf*2);
        if (lastNode != null) {
          if (n.x > lastNode.x) {
            map.rect (lastNode.x + 1, lastNode.y + 1, nodeW, nodeH - 2);
          }
          if (n.x < lastNode.x) {
            map.rect (lastNode.x + 1, lastNode.y + 1, -nodeW, nodeH - 2);
          }
          if (n.y > lastNode.y) {
            map.rect (lastNode.x + 1, lastNode.y + 1, nodeW - 2, nodeH);
          }
          if (n.y < lastNode.y) {
            map.rect (lastNode.x + 1, lastNode.y + 1, nodeW - 2, -nodeH);
          }
        }
        map.endDraw();
        pathWaitTime = 1;
        lastNode = n;
      } else {
        pathWaitTime++;
      }
    } else {
      walkingPath = 2;
      pathStack = null;
    }
  }
}

float[][] prevWeights;

void darkenMap() {
  map.beginDraw();
  prevWeights = new float[nodeRows][nodeCols];
  cameFrom = new NavNode[nodeRows][nodeCols];
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[0].length; col++) {
      if (nodes[row][col] != null) {
        nodes[row][col].distFromStart = 999999;
        nodes[row][col].hDist = 999999;
        prevWeights[row][col] = nodes[row][col].weight;
        nodes[row][col].draw(nodeW, nodeH);
        map.fill(0, 0, 0, 150);
        map.rect(nodes[row][col].x, nodes[row][col].y, nodeW, nodeH);
      }
    }
  }
  map.endDraw();
}

void failSearch() {
  walkingPath = 2;
  restoreWeights();
  searchFailed = true;
  paused = true;
}

float heuristic(NavNode n) {
  if (currentSearch.equals("A* (A-star)") || currentSearch.equals("Greedy Search")) {
    return dist (n.getRow(), n.getCol(), endRow, endCol);
  } else {
    return 0;
  }
}

class Button extends UIElement {
  float x, y, w, h;
  String buttonText;
  boolean active, beingPressed;
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
  }
  
  void draw() {
    stroke(0);
    strokeWeight(1);
    fill(255);
    if (!othersFocus() && mouseIn(x, y, w, h, 1)) {
      fill (240);
      if (beingPressed) {
        fill (220);
      }
    }
    rect(x, y, w, h, 5);
    if (buttonText.equals("!!!Play")) {
      noStroke();
      if (paused) {
        fill (120, 180, 120);
        float triX = x + w * 1.33 / 5.0;
        float triY = y + h * 1.1 / 6.0;
        float triW = w * 2.6 / 5.0;
        float triH = h * 3.8 / 6.0;
        triangle(triX, triY, triX+triW, triY+triH/2.0, triX, triY+triH);
      } else {
        fill (135);
        float pW = w * 0.9/5.0;
        float pH = h * 2.7/5.0;
        float pGap = w * 0.8/5.0;
        rect(x + w/2 - pGap/2.0 - pW, y + h/2 - pH/2, pW, pH, 5);
        rect(x + w/2 + pGap/2.0, y + h/2 - pH/2, pW, pH, 5);
      }
    } else if (buttonText.equals("!!!Reset")) {
      image (resetG, x + w*(0.5/5.0), y + h*(0.4/5.0), w * (4.3/5.0), h * (4.3/5.0));
    } else {
      fill(50);
      textSize(h * (16.0/30.0));
      if (buttonText.equals("Advanced Settings")) {
        strokeWeight(3);
        stroke (180);
        if (mouseIn (x, y, w, h, 1)) {
          stroke (100);
        }
        float arrowW = 6;
        float arrowH = 12;
        float arrowX = x+w-15;
        float arrowY = y+10;
        line (arrowX, arrowY, arrowX+arrowW, arrowY+arrowH/2.0);
        line (arrowX+arrowW, arrowY+arrowH/2.0, arrowX, arrowY+arrowH);
        textAlign(LEFT, CENTER);
        text(buttonText, x + 10, y + h/2 + 1);
      } else {
        textAlign(CENTER, CENTER);
        text(buttonText, x + w/2, y + h/2 + 1);
      }
    }
    if (active) {
      active = false;
    }
  }
  
  void mousePressed() {
    if (mouseIn(x, y, w, h, 1)) {
      if (!othersFocus()) {
        beingPressed = true;
      }
    }
  }
  
  void mouseReleased() {
    if (mouseIn(x, y, w, h, 1)) {
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
        if (mouseIn (x, currY, maxWidth + 20, h, 1)) {
          value = options[i];
          dropped = false;
          placeTiles = false;
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
  
  void mouseReleased() {}
  
  void drawOption(String opText, float opX, float opY, float opW, float opH) {
    noStroke();
    fill (255);
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

class MinHeap {
  
  int heapSize;
  NavNode[] arr;
  
  MinHeap(int arrLength) {
    arr = new NavNode[arrLength+1];
  }
  
  
  void maxHeapify(int index) {
    int l = left(index);
    int r = right(index);
    int largest = index;
    if (l <= heapSize && arr[l].hDist < arr[largest].hDist) {
      largest = l;
    }
    if (r <= heapSize && arr[r].hDist < arr[largest].hDist) {
      largest = r;
    }
    if (largest != index) {
      swap (index, largest);
      maxHeapify(largest);
    }
  }
  
  NavNode peek() {
    return arr[1];
  }
  
  NavNode remove() {
    NavNode ret = arr[1];
    arr[1] = arr[heapSize];
    heapSize--;
    maxHeapify(1);
    return ret;
  }
  
  void decreaseKey(int i, float newVal) {
    if (newVal > arr[i].hDist) {
    }
    arr[i].hDist = newVal;
    while (i > 1 && arr[parent(i)].hDist > arr[i].hDist) {
      swap(i, parent(i));
      i = parent(i);
    }
  }
  
  void insert(NavNode newNode) {
    heapSize++;
    float newKey = newNode.hDist;
    arr[heapSize] = newNode;
    newNode.hDist = 999999;
    decreaseKey(heapSize, newKey);
  }
  
  int getIndex(NavNode n) {
    for (int i = 1; i <= heapSize; i++) {
      if (arr[i] == n) {
        return i;
      }
    }
    return -1;
  }
  
  boolean contains(NavNode n) {
    for (int i = 1; i <= heapSize; i++) {
      if (arr[i] == n) {
        return true;
      }
    }
    return false;
  }
  
  void swap (int i1, int i2) {
    NavNode tmp = arr[i1];
    arr[i1] = arr[i2];
    arr[i2] = tmp;
  }
  
  int parent(int i) {
    return (int)(i/2);
  }
  
  int left(int i) {
    return 2 * i;
  }
  
  int right(int i ) {
    return 2 * i + 1;
  }
  
}

public class Stack {
   private int maxSize;
   private NavNode[] stackArray;
   private int top;
   
   public Stack(int s) {
      maxSize = s;
      stackArray = new NavNode[maxSize];
      top = -1;
   }
   public void push(NavNode j) {
      stackArray[++top] = j;
   }
   public NavNode pop() {
      return stackArray[top--];
   }
   public NavNode peek() {
      return stackArray[top];
   }
   public boolean isEmpty() {
      return (top == -1);
   }
   public boolean isFull() {
      return (top == maxSize - 1);
   }
}

// Class for queue
class Queue 
{
  private NavNode[] arr;         // array to store queue elements
  private int front;         // front points to front element in the queue
  private int rear;          // rear points to last element in the queue
  private int capacity;      // maximum capacity of the queue
  private int count;         // current size of the queue
  
  // Constructor to initialize queue
  Queue(int size)
  {
    arr = new NavNode[size];
    capacity = size;
    front = 0;
    rear = -1;
    count = 0;
  }

  // Utility function to remove front element from the queue
  public void dequeue()
  {
    // check for queue underflow
    if (isEmpty())
    {
    }

    front = (front + 1) % capacity;
    count--;
  }

  // Utility function to add an item to the queue
  public void enqueue(NavNode item)
  {
    // check for queue overflow
    if (isFull())
    {
    }

    rear = (rear + 1) % capacity;
    arr[rear] = item;
    count++;
  }

  // Utility function to return front element in the queue
  public NavNode peek()
  {
    if (isEmpty()) 
    {
    }
    return arr[front];
  }

  // Utility function to return the size of the queue
  public int size()
  {
    return count;
  }

  // Utility function to check if the queue is empty or not
  public boolean isEmpty()
  {
    return (size() == 0);
  }

  // Utility function to check if the queue is empty or not
  public boolean isFull()
  {
    return (size() == capacity);
  }
}

class NavNode {
  
  float x, y, weight;
  float distFromStart;
  float hDist;
  
  NavNode (float x, float y) {
    this.x = x;
    this.y = y;
    this.distFromStart = -1;
  }
  
  NavNode (float x, float y, float weight) {
    this (x, y);
    this.weight = weight;
  }
  
  void draw(float w, float h) {
    map.noStroke();
    if (weight == 1) {
      map.fill (grassCol);
    } else if (weight == 2) {
      map.fill (forestCol);
    } else if (weight == 5) {
      map.fill (waterCol);
    } else {
      map.fill(255, 0, 255);
    }
    map.rect (x, y, w, h);
  }
  
  int getRow() {
    return (int)(y / nodeH);
  }
  
  int getCol() {
    return (int)(x / nodeW);
  }
  
  NavNode[] neighbors() {
    int row = getRow();
    int col = getCol();
    NavNode[] ret;
    int arrSize = 0;
    if (row > 0 && nodes[row-1][col] != null) arrSize++;
    if (row < nodes.length-1 && nodes[row+1][col] != null) arrSize++;
    if (col > 0 && nodes[row][col-1] != null) arrSize++;
    if (col < nodes[0].length-1 && nodes[row][col+1] != null) arrSize++;
    ret = new NavNode[arrSize];
    int i = 0;
    if (row > 0 && nodes[row-1][col] != null) {
      ret[i] = nodes[row-1][col];
      i++;
    }
    if (col < nodes[0].length-1 && nodes[row][col+1] != null) {
      ret[i] = nodes[row][col+1];
      i++;
    }
    if (row < nodes.length-1 && nodes[row+1][col] != null) {
      ret[i] = nodes[row+1][col];
      i++;
    }
    if (col > 0 && nodes[row][col-1] != null) {
      ret[i] = nodes[row][col-1];
      i++;
    }
    return ret;
    /*if ((row == 0 || row == nodes.length-1) && (col == 0 || col == nodes[0].length-1)) {
      ret = new NavNode[3];
    } else if ((row == 0 || row == nodes.length-1) ^ (col == 0 || col == nodes[0].length-1)) {
      ret = new NavNode[5];
    } else {
      ret = new NavNode[8];
    }
    int i = 0;
    if (row > 0 && col > 0) {
      ret[i] = nodes[row-1][col-1];
      i++;
    }
    if (row > 0) {
      ret[i] = nodes[row-1][col];
      i++;
    }
    if (row > 0 && col < nodes[0].length-1) {
      ret[i] = nodes[row-1][col+1];
      i++;
    }
    
    if (row < nodes.length-1 && col > 0) {
      ret[i] = nodes[row+1][col-1];
      i++;
    }
    if (row < nodes.length-1) {
      ret[i] = nodes[row+1][col];
      i++;
    }
    if (row < nodes.length-1 && col < nodes[0].length-1) {
      ret[i] = nodes[row+1][col+1];
      i++;
    }
    
    if (col > 0) {
      ret[i] = nodes[row][col-1];
      i++;
    }
    if (col < nodes[0].length-1) {
      ret[i] = nodes[row][col+1];
      i++;
    }
    return ret;*/
  }
  
  public String toString() {
    return "NavNode in row " + getRow() + " and column " + getCol();
  }
}

int[][] mazeStatus; // 2 = part of maze, 1 = part of this path
float[][] prevMazeWeights;
NavNode currentMazeNode;

void setupWilsons() {
  prevMazeWeights = new float[nodeRows][nodeCols];
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[0].length; col++) {
      if (nodes[row][col] != null) {
        prevMazeWeights[row][col] = nodes[row][col].weight;
      } else {
        prevMazeWeights[row][col] = 1;
      }
    }
  }
  nodes = new NavNode[nodeRows][nodeCols];
  reset();
  cameFrom = new NavNode[nodeRows][nodeCols];
  mazeStatus = new int[nodeRows][nodeCols];
  int[] mazeSrc = {16, 16};
  nodes[mazeSrc[0]][mazeSrc[1]] = new NavNode(mazeSrc[1] * nodeW, mazeSrc[0] * nodeH, prevMazeWeights[mazeSrc[0]][mazeSrc[1]]);
  mazeStatus[mazeSrc[0]][mazeSrc[0]] = 2;
  int[] pathSrc = {16, 14};
  nodes[pathSrc[0]][pathSrc[1]] = new NavNode(pathSrc[1] * nodeW, pathSrc[0] * nodeH, prevMazeWeights[mazeSrc[0]][mazeSrc[1]]);
  mazeStatus[pathSrc[0]][pathSrc[1]] = 1;
  currentMazeNode = nodes[pathSrc[0]][pathSrc[1]];
  drawMap();
}

void stepWilsons() {
  // random walk from current node
  
  // select next position
  
  int[][] nextOptions = getNextOptions(currentMazeNode.getRow(), currentMazeNode.getCol());
  int randNum = (int)random(nextOptions.length);
  int[] nextPos = nextOptions[randNum];
  
  // check if it's part of the maze
  if (mazeStatus[nextPos[0]][nextPos[1]] == 2) {
    // Add in-between node
    int avgRow = (currentMazeNode.getRow() + nextPos[0])/2;
    int avgCol = (currentMazeNode.getCol() + nextPos[1])/2;
    nodes[avgRow][avgCol] = new NavNode(avgCol * nodeW, avgRow * nodeH, prevMazeWeights[avgRow][avgCol]);
    nodes[avgRow][avgCol].draw(nodeW, nodeH);
    // add all this stuff to the maze
    NavNode current = currentMazeNode;
    while (mazeStatus[current.getRow()][current.getCol()] == 1) {
      mazeStatus[current.getRow()][current.getCol()] = 2;
      if (cameFrom[current.getRow()][current.getCol()] != null) {
        current = cameFrom[current.getRow()][current.getCol()];
      }
    }
    
    // pick another start point
    for (int row = 0; row < nodes.length; row += 2) {
      for (int col = 0; col < nodes[row].length; col += 2) {
        if (mazeStatus[row][col] == 0) {
          nodes[row][col] = new NavNode(col * nodeW, row * nodeH, prevMazeWeights[row][col]);
          nodes[row][col].draw(nodeW, nodeH);
          mazeStatus[row][col] = 1;
          currentMazeNode = nodes[row][col];
          return;
        }
      }
    }
    
    // no start points are left available, maze is complete
    // make sure endpoints aren't on walls
    nodes[startRow][startCol] = new NavNode(startCol * nodeW, startRow * nodeH, prevMazeWeights[startRow][startCol]);
    nodes[endRow][endCol] = new NavNode(endCol * nodeW, endRow * nodeH, prevMazeWeights[endRow][endCol]);
    genCleanup();
  }
  
  // check if it's met up with the path
  if (mazeStatus[nextPos[0]][nextPos[1]] == 1) {
    // remove the loop
    NavNode loopEnd = nodes[nextPos[0]][nextPos[1]];
    while (currentMazeNode != loopEnd && cameFrom[currentMazeNode.getRow()][currentMazeNode.getCol()] != null) {
      map.fill(wallCol);
      map.noStroke();
      int row = currentMazeNode.getRow();
      int col = currentMazeNode.getCol();
      mazeStatus[row][col] = 0;
      int avgRow = (row + cameFrom[row][col].getRow())/2;
      int avgCol = (col + cameFrom[row][col].getCol())/2;
      nodes[avgRow][avgCol] = null;
      map.rect(avgCol * nodeW, avgRow * nodeH, nodeW, nodeH);
      currentMazeNode = cameFrom[row][col];
      cameFrom[row][col] = null;
      nodes[row][col] = null;
      map.rect(col * nodeW, row * nodeH, nodeW, nodeH);
    }
    return;
  }
  
  // otherwise, add this point to the path
  mazeStatus[nextPos[0]][nextPos[1]] = 1;
  
  // and set up the next one
  // handle in between
  int avgRow = (currentMazeNode.getRow() + nextPos[0])/2;
  int avgCol = (currentMazeNode.getCol() + nextPos[1])/2;
  nodes[avgRow][avgCol] = new NavNode(avgCol * nodeW, avgRow * nodeH, prevMazeWeights[avgRow][avgCol]);
  nodes[avgRow][avgCol].draw(nodeW, nodeH);
  nodes[nextPos[0]][nextPos[1]] = new NavNode(nextPos[1] * nodeW, nextPos[0] * nodeH, prevMazeWeights[nextPos[0]][nextPos[1]]);
  nodes[nextPos[0]][nextPos[1]].draw(nodeW, nodeH);
  cameFrom[nextPos[0]][nextPos[1]] = currentMazeNode;
  currentMazeNode = nodes[nextPos[0]][nextPos[1]];
}

int[][] getNextOptions (int row, int col) {
  int retSize = 0;
  if (row >= 2) retSize++;
  if (col >= 2) retSize++;
  if (row < nodes.length-2) retSize++;
  if (col < nodes[0].length-2) retSize++;
  int[][] ret = new int[retSize][2];
  int index = 0;
  if (row >= 2) {
    ret[index][0] = row-2;
    ret[index][1] = col;
    index++;
  }
  if (col >= 2) {
    ret[index][0] = row;
    ret[index][1] = col-2;
    index++;
  }
  if (row < nodes.length-2) {
    ret[index][0] = row+2;
    ret[index][1] = col;
    index++;
  }
  if (col < nodes[0].length-2) {
    ret[index][0] = row;
    ret[index][1] = col+2;
    index++;
  }
  return ret;
}

int fRow;
int fCol;
int numForests;
int maxForests;
void setupForests() {
  fRow = (int)random(nodes.length);
  fCol = (int)random(nodes[fRow].length);
  numForests = 0;
  maxForests = 20;
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[row].length; col++) {
      if (nodes[row][col] != null) {
        if (nodes[row][col].weight == 2) {
          nodes[row][col].weight = 1;
        }
      }
    }
  }
  drawMap();
}

void stepForests() {
  if (numForests >= maxForests) {
    genCleanup();
    return;
  }
  int fRadius = (int)random(2, 4) * (nodeRows/30);
  for (int row = fRow - fRadius; row < fRow + fRadius + 1; row++) {
    for (int col = fCol - fRadius; col < fCol + fRadius + 1; col++) {
      int realRow = (int)clamp(row, 0, nodes.length-1);
      int realCol = (int)clamp(col, 0, nodes[0].length-1);
      if (dist(fCol, fRow, col, row) <= fRadius && nodes[realRow][realCol] != null) {
        if (nodes[realRow][realCol].weight != 5) {
          nodes[realRow][realCol].weight = 2;
          nodes[realRow][realCol].draw(nodeW, nodeH);
        }
      }
    }
  }
  numForests++;
  fRow = (int)random(nodes.length);
  fCol = (int)random(nodes[fRow].length);
}

int riverCol;
float riverRow;
float riverWidth;
void setupRiver() {
  riverCol = 0;
  riverWidth = nodeRows / 4.0;
  riverRow = nodeRows / 2.0 - riverWidth / 2.0;
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[row].length; col++) {
      if (nodes[row][col] != null) {
        if (nodes[row][col].weight == 5) {
          nodes[row][col].weight = 1;
        }
      }
    }
  }
  drawMap();
}

void stepRiver() {
  if (riverCol > nodes[0].length-1) {
    genCleanup();
    return;
  }
  for (int row = (int)riverRow; row < riverRow + riverWidth; row++) {
    if (nodes[row][riverCol] != null) {
      nodes[row][riverCol] = new NavNode(riverCol * nodeW, row * nodeH, 5);
      nodes[row][riverCol].draw(nodeW, nodeH);
    }
  }
  riverRow += random(-1, 1);
  riverRow = clamp(riverRow, 0, nodes.length);
  riverWidth += random(-1, 1);
  riverWidth = clamp(riverWidth, nodeRows / 10, nodeRows / 4);
  riverCol++;
}

boolean doingRiver;
void setupForestsAndRiver() {
  setupRiver();
  doingRiver = true;
}

void stepForestsAndRiver() {
  if (doingRiver) {
    if (riverCol <= nodes[0].length-1) {
      stepRiver();
    } else {
      doingRiver = false;
      setupForests();
    }
  } else {
    stepForests();
  }
}

int randomRow;
int randomCol;
void setupRandomWalls() {
  randomRow = 0;
  randomCol = 0;
  for (int row = 0; row < nodes.length; row++) {
    for (int col = 0; col < nodes[row].length; col++) {
      if (nodes[row][col] == null) {
        nodes[row][col] = new NavNode (col * nodeW, row * nodeH, 1);
      }
    }
  }
  drawMap();
}

void stepRandomWalls() {
  float randNum = random(1);
  if (randNum > 0.7) {
    nodes[randomRow][randomCol] = null;
    map.fill(wallCol);
    map.noStroke();
    map.rect(randomCol * nodeW, randomRow * nodeH, nodeW, nodeH);
  }
  randomCol++;
  if (randomCol > nodes[0].length-1) {
    randomCol = 0;
    randomRow++;
  }
  if (randomRow > nodes.length-1) {
    nodes[startRow][startCol] = new NavNode(startCol * nodeW, startRow * nodeH, 1);
    nodes[endRow][endCol] = new NavNode(endCol * nodeW, endRow * nodeH, 1);
    genCleanup();
  }
}

void genCleanup() {
  currentObstacles = "";
  genButton.buttonText = "Generate Obstacles";
  reset();
}

class SelectGroup extends UIElement {
  ArrayList<SelectOption> options;
  
  SelectGroup() {
    options = new ArrayList<SelectOption>();
    elements.add(this);
  }
  
  void addOption(SelectOption o) {
    o.parent = this;
    options.add(o);
  }
  
  void setSelected(SelectOption o) {
    for (SelectOption option : options) {
      if (o == option) {
        option.selected = true;
      } else {
        option.selected = false;
      }
    }
  }
  
  SelectOption getSelected() {
    for (SelectOption option : options) {
      if (option.selected) {
        return option;
      }
    }
    return null;
  }
  
  void draw() {
    for (SelectOption o : options) {
      o.draw();
    }
    for (SelectOption o : options) {
      o.drawTip();
    }
  }
  
  void mousePressed() {
  }
  
  void mouseReleased() {
  }
}

class SelectOption extends UIElement {
  
  float x, y, size;
  color col;
  String label;
  boolean selected, beingPressed;
  SelectGroup parent;
  
  Tooltip tooltip;
  
  SelectOption (float x, float y, float size, color col, String label) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.col = col;
    this.label = label;
    elements.add(this);
    selected = false;
  }
  
  void draw() {
    noStroke();
    if (selected || beingPressed) {
      fill (255, 255, 255, 170);
      rect(x, y, size, size);
    } else if (!othersFocus() && mouseIn(x, y, size, size, 1)) {
      fill (255, 255, 255, 100);
      rect(x, y, size, size);
    }
    fill(col);
    rect (x + size * 0.2, y + size * 0.1, size * 0.6, size * 0.6);
    fill(0);
    textSize(16);
    textAlign(CENTER, BOTTOM);
    text(label, x + size/2, y + size * 0.95);
  }
  
  void drawTip() {
    if (tooltip != null) {
      tooltip.draw();
    }
  }
  
  void addTooltip(String message, float tW, float tH) {
    tooltip = new Tooltip (message, x, y, size, size, tW, tH);
  }
  
  void mousePressed() {
    if (mouseIn(x, y, size, size, 1)) {
      if (!othersFocus()) {
        beingPressed = true;
      }
    }
  }
  
  void mouseReleased() {
    if (mouseIn(x, y, size, size, 1)) {
      if (!othersFocus()) {
        parent.setSelected(this);
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

class Tooltip {
  float rX, rY, rW, rH, tW, tH;
  String message;
  
  Tooltip (String message, float rX, float rY, float rW, float rH, float tW, float tH) {
    this.message = message;
    this.rX = rX;
    this.rY = rY;
    this.rW = rW;
    this.rH = rH;
    this.tW = tW;
    this.tH = tH;
  }
  
  void draw() {
    if (mouseIn(rX, rY, rW, rH,1) && timeSinceMoved > 10) {
      fill (0, 0, 0, 200);
      noStroke();
      float posX = mouseX - tW/2;
      float posY = mouseY - tH - 2;
      rect(posX, posY, tW, tH);
      fill (255);
      textSize(15);
      textAlign(CENTER, CENTER);
      text(message, posX, posY-4, tW, tH);
    }
  }
}