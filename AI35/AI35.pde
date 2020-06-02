/* @pjs font="/static/projects/Game_35/data/AmericanTypewriter.ttf"; */

PFont f;

Board35 board;
MonteCarlo mc;
int selX, selY, rows, cols;
boolean aiMove;

float x, y, w, h;

Board35[] stack;
int head;
float timeWaited;

int randNums = 0;

ArrayList<Indicator> indicators = new ArrayList<Indicator>();

PGraphics pg;

void setup() {
  float aR = 600.0/680.0;
  if (screenWidth / (screenHeight+0.0) > aR) { // pg.height is limiting
    size ((int)(screenHeight * 0.8 * aR), (int)(screenHeight * 0.8));
  } else {
    size ((int)(screenWidth * 0.8), (int)(screenWidth * 0.8 * 1.0/aR));
  }
  pg = createGraphics(600, 680);
  rows = 8;
  cols = 8;
  board = new Board35(rows, cols);
  selX = 0;
  selY = 0;
  x = 37.5;
  y = 65;
  w = 525;
  h = 525;
  aiMove = false;
  stack = new Board35[rows*cols];
  mc = null;
  head = 0;
  timeWaited = 0;
  f = createFont ("/static/projects/Game_35/data/AmericanTypewriter.ttf", 25);
  indicators = new ArrayList<Indicator>();
}

void draw() {
  pg.background(255);
  float startMillis = millis();
  drawText();
  drawButtons();
  if (board.winner() == -2) {
    if (aiMove && indicators.size() == 0) {
      board.draw(x, y, w, h);
      if (mc == null) {
        mc = new MonteCarlo(board, 1, 0.15);
        timeWaited = 0;
      }
      if (timeWaited < 30.0) {
        mc.simForTime(0.1);
        timeWaited += (millis()-startMillis)/1000.0;
      } else {
        Play bestMove = mc.bestPlay();
        board.makeMove(bestMove);
        board.spawnIndicators(bestMove);
        aiMove = false;
        mc = null;
        timeWaited = 0;
      }
    } else {
      board.draw(x, y, w, h);
      pg.textAlign(CENTER, CENTER);
      pg.textSize (35);
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          if (mousePressed && map(mouseX, 0, width, 0, pg.width) > x+col*(w/cols) && map(mouseX, 0, width, 0, pg.width) < x+(col+1)*(w/cols) && map(mouseY, 0, height, 0, pg.height) > y+row*(h/rows) && map(mouseY, 0, height, 0, pg.height) < y+(row+1)*(h/rows)) {
            selX = col; selY = row;
          }
        }
      }
      pg.strokeWeight(5);
      pg.stroke (0, 255, 255);
      pg.fill (0, 0, 0, 0);
      pg.rect (x+selX*(w/cols), y+selY*(h/rows), w/cols, h/rows);
      //println(board.numRed + " " + board.numBlue + " " + board.winner());
      //delay(10);
      //board.makeMove(new Play35((int)random(rows), (int)random(cols), (int)random(9)+1));
    }
  } else {
    board.draw(x, y, w, h);
  }
  ArrayList<Indicator> deletes = new ArrayList<Indicator>();
  for (Indicator i : indicators) {
      i.draw();
      if (i.opacity <= 0) {
        deletes.add(i);
      }
  }
  for (Indicator i : deletes) {
    indicators.remove(i);
  }
  image(pg, 0, 0, width, height);
}

void drawButtons() {
    drawButton(pg.width/2-160, pg.height-70, 150, 40, "Restart");
    drawButton(pg.width/2 + 10, pg.height-70, 150, 40, "Undo");
}

void mousePressed() {
    if (map(mouseX, 0, width, 0, pg.width) > pg.width/2-160 && map(mouseX, 0, width, 0, pg.width) < pg.width/2-10 && map(mouseY, 0, height, 0, pg.height) > pg.height-70 && map(mouseY, 0, height, 0, pg.height) < pg.height-30) {
        setup();
    }
    if (map(mouseX, 0, width, 0, pg.width) > pg.width/2+10 && map(mouseX, 0, width, 0, pg.width) < pg.width/2+160 && map(mouseY, 0, height, 0, pg.height) > pg.height-70 && map(mouseY, 0, height, 0, pg.height) < pg.height-30) {
        popStack();
        if (aiMove) {
            aiMove = false;
            timeWaited = 0;
        }
    }
}

void drawButton(float x, float y, float w, float h, String mess) {
    pg.fill(0, 0, 0, 0);
  pg.stroke(0,0,0,0);
  if (map(mouseX, 0, width, 0, pg.width) > x && map(mouseX, 0, width, 0, pg.width) < x+w && map(mouseY, 0, height, 0, pg.height) > y && map(mouseY, 0, height, 0, pg.height) < y+h) {
    pg.stroke(170);
  }
  pg.strokeWeight(2);
  pg.rect(x, y, w, h, 1);
  pg.fill(100);
  pg.textSize(30);
  pg.textAlign(CENTER, CENTER);
  pg.text (mess, x+w/2.0, y+h/2.0);
}

void drawText() {
    pg.textFont (f);
    pg.textAlign (LEFT);
    pg.textSize (35);
    if (board.winner() == -2) {
    if (board.currentPlayer() == 1) {
      String mytext = "Player turn.";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 6) {
          pg.fill (255, 0, 0);
        }
        pg.text (mytext.charAt(i), x, 35);
        x += pg.textWidth (mytext.charAt(i));
      }
    } else {
      String mytext = "Computer thinking (" + int(30-timeWaited) + "s)";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 8) {
          pg.fill (0, 0, 255);
        }
        pg.text (mytext.charAt(i), x, 35);
        x += pg.textWidth (mytext.charAt(i));
      }
    }
  } else {
    if (board.winner() == 1) {
      String mytext = "Red wins!";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 3) {
          pg.fill (255, 0, 0);
        }
        pg.text (mytext.charAt(i), x, 35);
        x += pg.textWidth (mytext.charAt(i));
      }
    } else if (board.winner() == -1) {
      String mytext = "Blue wins!";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 4) {
          pg.fill (0, 0, 255);
        }
        pg.text (mytext.charAt(i), x, 35);
        x += pg.textWidth (mytext.charAt(i));
      }
    } else {
      String mytext = "Tie.";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        pg.text (mytext.charAt(i), x, 35);
        x += pg.textWidth (mytext.charAt(i));
      }
    }
}
}

void keyPressed() {
  if (!aiMove && int(key) > 48 && int(key) < 58) {
    if (board.cells[selY][selX] == 0) {
      addStack();
      Play35 move = new Play35(selY, selX, int(key) - 48);
      board.makeMove(move);
      board.spawnIndicators(move);
      pg.background(255);
      board.draw(x, y, w, h);
      aiMove = true;
    }
  }
  if (!aiMove && key == 'a'){
    aiMove = true;
  }
  if (keyCode == LEFT) {
    popStack();
    if (aiMove) {
        aiMove = false;
        timeWaited = 0;
    }
  }
}

void addStack() {
  if (head < stack.length) {
    stack[head] = (Board35)(board.clone());
    head++;
  }
}

void popStack() {
  if (head > 0) {
    head--;
    board = stack[head];
  }
}

class Play35 extends Play {
  int row, col, val;
  Play35 (int row, int col, int val) {
    this.row = row;
    this.col = col;
    this.val = val;
  }
}

class Board35 extends Board {
  
  int[][] sums;
  int[][] cells;
  int[][] sides;
  int numEmpty, numRed, numBlue;
  int currPlayer;
  
  int randSeed;
  
  Board35(int rows, int cols) {
    this.sums = new int[rows][cols];
    this.cells = new int[rows][cols];
    this.sides = new int[rows][cols];
    this.numEmpty = rows * cols;
    this.numRed = 0;
    this.numBlue = 0;
    this.currPlayer = 1;
    this.randSeed = (int)random(999999);
  }
  
  void spawnIndicators(Play p) {
    Play35 rP = (Play35)p;
    int[][] neighbors = getNeighbors(rP.row, rP.col);
    for (int[] pos : neighbors) {
      int row = pos[0];
      int col = pos[1];
      if (sums[row][col] == 35) {
        Indicator i = new Indicator(col, row);
        indicators.add(i);
      }
    }
  }
  
  void makeMove(Play p) {
    
    Play35 rP = (Play35)p;
    if (cells[rP.row][rP.col] != 0) {
      //println("Serious error during makeMove");
      return;
    }
    int[][] neighbors = getNeighbors(rP.row, rP.col);
    boolean red35 = false, blue35 = false;
    
    cells[rP.row][rP.col] = rP.val;
    if (sides[rP.row][rP.col] == 0) {
      sides[rP.row][rP.col] = currPlayer;
      if (currPlayer == 1) numRed++;
      else numBlue++;
    }
    if (sums[rP.row][rP.col] == 35) {
      if (sides[rP.row][rP.col] == 1) red35 = true;
      else blue35 = true;
    }
    
    numEmpty--;
    currPlayer *= -1;
    
    for (int[] pos : neighbors) {
      int row = pos[0];
      int col = pos[1];
      sums[row][col] += rP.val;
      if (sums[row][col] == 35 && cells[row][col] != 0) {
        if (sides[row][col] == 1) red35 = true;
        else if (sides[row][col] == -1) blue35 = true;
      }
    }
    
    if (red35 && blue35) return;
    
    for (int[] pos : neighbors) {
      int row = pos[0];
      int col = pos[1];
      if (sums[row][col] == 35 && cells[row][col] != 0) {
        claim(row, col);
      }
    }
    
    if (sums[rP.row][rP.col] == 35) {
      claim(rP.row, rP.col);
    }
  }
  
  Play[] legalPlays() {
    
    Play[] ret = new Play[numEmpty * 9];
    int i = 0;
    for (int row = 0; row < cells.length; row++) {
      for (int col = 0; col < cells[row].length; col++) {
        if (cells[row][col] == 0) {
          for (int n = 1; n <= 9; n++) {
            ret[i] = new Play35(row, col, n);
            i++;
          }
        }
      }
    }
    return ret;
    
  }
  
  int numLegalPlays() {
    return numEmpty * 9;
  }
  
  Play playAtIndex(int i) {
    int n = 0;
    for (int row = 0; row < cells.length; row++) {
      for (int col = 0; col < cells[row].length; col++) {
        if (cells[row][col] == 0) {
          if (i-n >= 9) n += 9;
          else return new Play35(row, col, i-n + 1);
        }
      }
    }
    return null;
  }
  
  void randomRollout() { // runs in O(n) time where n is cells in board
    // Find every empty cell and pop it onto a stack O(n)
    int[][] stack = new int[numEmpty][2];
    int head = 0;
    for (int row = 0; row < cells.length; row++) {
      for (int col = 0; col < cells[0].length; col++) {
        if (cells[row][col] == 0) {
          stack[head][0] = row;
          stack[head][1] = col;
          head++;
          if (head >= numEmpty) { // break the loop
            row = cells.length;
            col = cells[0].length;
          }
        }
      }
    }
    
    // Shuffle the stack O(n)
    for (int i = stack.length-1; i >= 1; i--) {
      int j = randomInt();
      if (j < 0) j = -j;
      j = j % (i + 1);
      int[] temp = stack[i];
      stack[i] = stack[j];
      stack[j] = temp;
    }
    
    // call makeMove O(1) for every element in the stack O(n)
    while (head > 0) {
      int val = randomInt();
      if (val < 0) val = -val;
      val = (val % 9) + 1;
      int[] coords = stack[head-1];
      head--;
      makeMove(new Play35(coords[0], coords[1], val));
    }
    
    stack = null;
    
  }

  int maxMovesLeft() {
    return numEmpty;
  }
  
  int winner() {
    if (numEmpty != 0) {
      return -2;
    } else {
      if (numRed > numBlue) return 1;
      else if (numBlue > numRed) return -1;
      else return 0;
    }
  }
  
  int currentPlayer() {
    return currPlayer;
  }
  
  Board clone() {
    Board35 ret = new Board35(cells.length, cells[0].length);
    ret.numRed = this.numRed;
    ret.numBlue = this.numBlue;
    ret.numEmpty = this.numEmpty;
    ret.currPlayer = this.currPlayer;
    for (int row = 0; row < cells.length; row++) {
      for (int col = 0; col < cells[0].length; col++) {
        ret.cells[row][col] = this.cells[row][col];
        ret.sides[row][col] = this.sides[row][col];
        ret.sums[row][col] = this.sums[row][col];
      }
    }
    return ret;
  }
  
  private void claim(int row, int col) {
    
    int[][] neighbors = getNeighbors(row, col);
    for (int[] pos : neighbors) {
      if (sides[row][col] == 1 && sides[pos[0]][pos[1]] != 1) {
        numRed++;
        if (sides[pos[0]][pos[1]] == -1) numBlue--;
      }
      if (sides[row][col] == -1 && sides[pos[0]][pos[1]] != -1) {
        numBlue++;
        if (sides[pos[0]][pos[1]] == 1) numRed--;
      }
      sides[pos[0]][pos[1]] = sides[row][col];
    }
    
  }
  
  // returns array of [row, col] pairs
  private int[][] getNeighbors(int row, int col) {
    int[][] ret = new int[numNeighbors(row, col)][2];
    int i = 0;
    if (row > 0) {
      ret[i][0] = row-1;
      ret[i][1] = col;
      i++;
    }
    if (row < cells.length-1) {
      ret[i][0] = row+1;
      ret[i][1] = col;
      i++;
    }
    if (col > 0) {
      ret[i][0] = row;
      ret[i][1] = col-1;
      i++;
    }
    if (col < cells[0].length-1) {
      ret[i][0] = row;
      ret[i][1] = col+1;
      i++;
    }
    if (row > 0 && col > 0) {
      ret[i][0] = row-1;
      ret[i][1] = col-1;
      i++;
    }
    if (row > 0 && col < cells[0].length-1) {
      ret[i][0] = row-1;
      ret[i][1] = col+1;
      i++;
    }
    if (row < cells.length-1 && col > 0) {
      ret[i][0] = row+1;
      ret[i][1] = col-1;
      i++;
    }
    if (row < cells.length-1 && col < cells[0].length-1) {
      ret[i][0] = row+1;
      ret[i][1] = col+1;
      i++;
    }
    if (i != ret.length) {
      //println("Error in getNeighbors");
    }
    return ret;
  }
  
  private int numNeighbors(int row, int col) {
    boolean rowsGood = row > 0 && row < cells.length-1;
    boolean colsGood = col > 0 && col < cells[0].length-1;
    if (rowsGood && colsGood) {
      return 8;
    } else if (rowsGood ^ colsGood) {
      return 5;
    } else {
      return 3;
    }
  }
  
  private int randomInt() {
    long x = randSeed;
    x ^= (x << 21);
    x ^= (x >>> 35);
    x ^= (x << 4);
    randSeed++;
    randNums++;
    return (int)x;
  }
  
  void draw(float x, float y, float w, float h) {
    pg.textAlign(CENTER, CENTER);
    pg.textSize (40);
    for (int c = 0; c < cells[0].length; c++) {
      pg.stroke(0);
      pg.strokeWeight(5);
      pg.line (x+c*(w/cells.length), y, x+c*(w/cells.length), y+h);
      pg.line (x+(c+1)*(w/cells.length), y, x+(c+1)*(w/cells.length), y+h);
    }
    for (int r = 0; r < cells.length; r++) {
      pg.stroke(0);
      pg.strokeWeight(5);
      pg.line (x, y+r*(h/cells.length), x+w, y+r*(h/cells.length));
      pg.line (x, y+(r+1)*(h/cells.length), x+w, y+(r+1)*(h/cells.length));
      for (int c = 0; c < cells[r].length; c++) {
        if (cells[r][c] > 0) {
          pg.fill (255, 0, 0);
          if (sides[r][c] < 0) {
            pg.fill (0, 0, 255);
          }
          pg.text (cells[r][c], x+(c+0.5)*(w/cells[r].length), y+(r+0.5)*(h/cells.length));
        } else if (sides[r][c] != 0) {
          pg.fill (255, 0, 0, 100);
          if (sides[r][c] == -1) pg.fill (0, 0, 255, 100);
          pg.noStroke();
          pg.rect (x+c*(w/cells[c].length), y+r*(h/cells.length), w/cells[c].length, h/cells.length);
        }
        
      }
    }
  }
  
}
abstract class Play {
}

abstract class Board {
  
  abstract void makeMove(Play p);
  
  abstract Play[] legalPlays();
  int numLegalPlays() {
    return legalPlays().length;
  }
  Play playAtIndex(int i) {
    return legalPlays()[i];
  }
  Play randomPlay() {
    Play[] available = legalPlays();
    return available[(int)random(available.length)];
  }
  // can override if more efficient implementation is possible
  void randomRollout() {
    while (winner() == -2) {
      makeMove(randomPlay());
    }
  }
  
  abstract int maxMovesLeft();
  
  abstract int winner(); // 1 is red, 0 is tie, -1 is blue, -2 is ongoing
  abstract int currentPlayer();
  
  abstract Board clone();
  
}

class Node {
  
  int numChildren;
  Node[] children;
  Play play;
  
  int currentPlayer; // who's turn is it after play has been made
  
  int visits;
  float wins;
  
  Node(Board b, Play p) { // board b after making play p
    this.play = p;
    int maxChildren = b.numLegalPlays();
    this.children = new Node[maxChildren];
    this.numChildren = 0;
    this.visits = 0;
    this.wins = 0;
    this.currentPlayer = b.currentPlayer();
  }
  
}

class MonteCarlo {
  
  Board b;
  Node parentNode;
  float exploreFactor;
  int playoutSims;
  MonteCarlo(Board b, int playoutSims, float exploreFactor) {
    parentNode = new Node(b, null);
    this.b = b;
    this.playoutSims = playoutSims;
    this.exploreFactor = exploreFactor;
  }
  
  void simForTime(float time) {
    float startTime = millis();
    while ((millis()-startTime)/1000.0 < time) {
      simulate(parentNode, b, playoutSims, exploreFactor);
    }
  }
  
  Play bestPlay() {
    float maxVisits = -1;
    int maxIndex = -1;
    for (int i = 0; i < parentNode.children.length; i++) {
      Node child = parentNode.children[i];
      if (child.visits > maxVisits) {
        maxVisits = child.visits;
        maxIndex = i;
      }
    }
    
    //println ((parentNode.children[maxIndex]).wins/(parentNode.children[maxIndex]).visits*100 + "%" + "  " + (parentNode.children[maxIndex]).visits + "  " + parentNode.visits);
    parentNode = null;
    return b.playAtIndex(maxIndex);
  }
  
  Play bestPlay(float time) {
    
    parentNode = new Node(b, null);
    //((Board35)b).genHamiltonians(50);
    
    int numRun = 0;
    float startTime = millis();
    
    while ((millis()-startTime)/1000.0 < time) {
      simulate(parentNode, b, playoutSims, exploreFactor);
      numRun++;
    }
    
    float maxVisits = -1;
    int maxIndex = -1;
    for (int i = 0; i < parentNode.children.length; i++) {
      Node child = parentNode.children[i];
      if (child.visits > maxVisits) {
        maxVisits = child.visits;
        maxIndex = i;
      }
    }
    
    //println ((parentNode.children[maxIndex]).wins/(parentNode.children[maxIndex]).visits*100 + "%" + "  " + (parentNode.children[maxIndex]).visits + "  " + parentNode.visits + "  " + numRun);
    parentNode = null;
    return b.playAtIndex(maxIndex);
    
  }
  
  private void simulate(Node parent, Board b, int sims, float exploreFactor) {
    
    Node cN = parent;
    Board cB = b.clone();
    
    Node[] visited = new Node[b.maxMovesLeft()+1];
    visited[0] = cN;
    int visitHead = 1;
    
    // selection
    while (cN.numChildren == cN.children.length && cB.winner() == -2) {
      // UCB1 selection
      float maxUCB = -9999;
      int maxIndex = -1;
      for (int i = 0; i < cN.children.length; i++) {
        Node child = cN.children[i];
        float winRate = (child.wins+0.)/child.visits;
        float explore = log(cN.visits)/child.visits;
        float UCB = winRate + exploreFactor*sqrt(explore);
        if (UCB > maxUCB) {
          maxUCB = UCB;
          maxIndex = i;
        }
      }
      cN = cN.children[maxIndex];
      cB.makeMove(cN.play);
      //currentNode = (MCTSNode)currentNode.children[int(random(currentNode.children.length))]; // RANDOM SELECTION
      visited[visitHead] = cN;
      visitHead++;
    }
    
    // Expansion
    if (cB.winner() == -2) {
      Play newPlay = cB.playAtIndex(cN.numChildren);
      cB.makeMove(newPlay);
      Node newNode = new Node(cB, newPlay);
      cN.children[cN.numChildren] = newNode;
      cN.numChildren++;
      cN = newNode;
      visited[visitHead] = cN;
      visitHead++;
    }
    
    // Simulation
    int[] winners = new int[sims];
    for (int i = 0; i < sims; i++) {
      Board newCB;
      if (i < sims-1) {
        newCB = cB.clone();
        //newCB = cB;
      } else {
        newCB = cB;
      }
      newCB.randomRollout();
      int winner = newCB.winner();
      if (winner == -2) {
        //println("Serious simulation error");
      }
      winners[i] = winner;
    }
    
    // Backpropagation
    //println("backprop");
    for (int i = visitHead-1; i >= 0; i--) {
      visited[i].visits++;
      float addAmt = 0;
      for (int n = 0; n < sims; n++) {
        if (winners[n] == 0) {
          addAmt += 0.25;
        } else if (visited[i].currentPlayer == -winners[n]) { // be careful here
          addAmt++;
        }
      }
      addAmt /= sims;
      visited[i].wins += addAmt;
    }
    
    cN = null;
    cB = null;
    visited = null;
    
  }
  
}

class Indicator {
  int xp, yp;
  float myW = 700;
  float opacity = 1;
  boolean reachedSquare = false;
  Indicator (int xp, int yp) {
    this.xp = xp;
    this.yp = yp;
  }
  void draw() {
      float cellW = w/(cols+0.0);
    if (opacity >= 0) {
      myW -= 30;
      pg.fill (0, 0, 0, 0);
      pg.strokeWeight (5);
      pg.stroke (0, 255, 0, opacity);
      pg.rectMode (CENTER);
      if (myW < cellW) {
        myW = cellW;
        opacity -= 10;
        if (!reachedSquare) {
          opacity = 500;
          reachedSquare = true;
        }
      } else {
        opacity += 20;
      }
      pg.rect (xp*cellW+x+cellW/2, y+(yp+1)*cellW-cellW/2.0, myW, myW);
      pg.rectMode (0);
    }
  }
}