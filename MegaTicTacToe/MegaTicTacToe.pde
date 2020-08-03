

MegaTTTBoard board;
boolean waited;
MonteCarlo mc;
float timeWaited;

void setup() {
  float aR = 600.0/630.0;
  if (screenWidth / (screenHeight+0.0) > aR) { // height is limiting
    size (screenHeight * 0.8 * aR, screenHeight * 0.8);
  } else {
    size (screenWidth * 0.8, screenWidth * 0.8 * 1.0/aR);
  }
  pg = createGraphics(600, 630);
  board = new MegaTTTBoard();
  //println (board.checkWinner());
  //println((TTTMove)Minimax.bestMove(board));
}

void draw() {
  float startMillis = millis();
  pg.background(250);
  pg.fill(0);
  pg.textSize(30);
  pg.textAlign(CENTER, CENTER);
  if (board.winner() != -2) {
    if (board.winner() == -1) {
      pg.text("Computer wins", pg.width/2, 40);
    }
    if (board.winner() == 1) {
      pg.text("Player wins", pg.width/2, 40);
    }
    if (board.winner() == 0) {
      pg.text("Tie", pg.width/2, 40);
    }
  } else {
    if (board.currentPlayer() == 1) {
      pg.text("Player turn", pg.width/2, 40);
    } else {
      pg.text("Computer thinking (" + int(20-timeWaited) + "s)", pg.width/2, 40);
    }
  }
  
  boolean playerMove = false;
  if (board.currentPlayer() == 1) {
    playerMove = true;
  }
  
  board.draw(55, 70, 490, 490, playerMove);
  
  pg.fill(0, 0, 0, 0);
  pg.stroke(0,0,0,0);
  if (map(mouseX, 0, width, 0, pg.width) > pg.width/2 - 60 && map(mouseX, 0, width, 0, pg.width) < pg.width/2 + 60 && map(mouseY, 0, height, 0, pg.height) > pg.height-50 && map(mouseY, 0, height, 0, pg.height) < pg.height-50+35) {
    pg.stroke(170);
  }
  pg.strokeWeight(2);
  pg.rect(pg.width/2 - 60, pg.height-50, 120, 35, 1);
  pg.fill(100);
  pg.textSize(25);
  pg.textAlign(CENTER, CENTER);
  pg.text ("Restart", pg.width/2, pg.height-33);
  
  if (!playerMove && board.winner() == -2) {
    if (waited) {
      if (mc == null) {
        mc = new MonteCarlo(board, 1, 0.5);
        timeWaited = 0;
      }
      if (timeWaited < 20) {
        mc.simForTime(0.1);
        timeWaited += (millis()-startMillis)/1000.0;
      } else {
        Play bestMove = mc.bestPlay();
        board.makeMove(bestMove);
        waited = false;
        mc = null;
      }
    } else {
      waited = true;
    }
  }
  image(pg, 0, 0, width, height);
}

void mousePressed() {
  if (map(mouseX, 0, width, 0, pg.width) > pg.width/2 - 60 && map(mouseX, 0, width, 0, pg.width) < pg.width/2 + 60 && map(mouseY, 0, height, 0, pg.height) > pg.height-50 && map(mouseY, 0, height, 0, pg.height) < pg.height-50+35) {
    setup();
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

class MegaTTTBoard extends Board {
  int[][][][] data;
  int[][] bigData; // keeps track of macro game
  MegaTTTPlay lastMove; // keeps track of last move
  
  MegaTTTBoard() {
    data = new int[3][3][3][3]; // big row, big column, small row, small column
    bigData = new int[3][3]; // keep track of macro game
    lastMove = null;
    for (int bigR = 0; bigR < 3; bigR++) {
      for (int bigC = 0; bigC < 3; bigC++) {
        bigData[bigR][bigC] = -2;
      }
    }
  }
  
  int maxMovesLeft() {
    return 81;
  }
  
  void makeMove (Play abstractPlay) {
    
    MegaTTTPlay move = (MegaTTTPlay)abstractPlay;
    
    int turn = currentPlayer();
    data[move.bigRow][move.bigColumn][move.row][move.column] = turn;
    checkGames();
    lastMove = move;
  }
  
  Board clone() {
    MegaTTTBoard ret = new MegaTTTBoard();
    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            ret.data[bigRow][bigCol][row][col] = data[bigRow][bigCol][row][col];
          }
        }
        ret.bigData[bigRow][bigCol] = bigData[bigRow][bigCol];
      }
    }
    ret.lastMove = lastMove;
    return ret;
  }
  
  int currentPlayer() {
    int numRed = 0, numBlue = 0;
    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            if (data[bigRow][bigCol][row][col] == 1) {
              numRed++;
            } else if (data[bigRow][bigCol][row][col] == -1) {
              numBlue++;
            }
          }
        }
      }
    }
    if (numRed > numBlue) {
      return -1;
    } else if (numRed == numBlue) {
      return 1;
    } else {
      //println ("Error: unable to determine turn");
      return 0;
    }
  }
  
  // Assumes checkGames() has been called/bigData is correct
  int winner() {
    int numRed = 0, numBlue = 0, numEmptyBig = 0;
    for (int row = 0; row < 3; row++) {
      for (int column = 0; column < 3; column++) {
        if (bigData[row][column] == 1) {
          numRed++;
        } else if (bigData[row][column] == -1) {
          numBlue++;
        } else if (bigData[row][column] == -2) {
          numEmptyBig++;
        }
      }
    }
    
    if (numEmptyBig == 0) {
      if (numRed > numBlue) {
        return 1;
      } else if (numRed < numBlue) {
        return -1;
      } else {
        return 0;
      }
    }
    
    for (int row = 0; row < 3; row++) {
      if (bigData[row][0] == bigData[row][1] && bigData[row][1] == bigData[row][2] && bigData[row][0] != 0) {
        return bigData[row][0];
      }
    }
    for (int col = 0; col < 3; col++) {
      if (bigData[0][col] == bigData[1][col] && bigData[1][col] == bigData[2][col] && bigData[0][col] != 0) {
        return bigData[0][col];
      }
    }
    
    if (bigData[0][0] == bigData[1][1] && bigData[1][1] == bigData[2][2] && bigData[0][0] != 0) {
      return bigData[0][0];
    }
    if (bigData[0][2] == bigData[1][1] && bigData[1][1] == bigData[2][0] && bigData[0][2] != 0) {
      return bigData[0][2];
    }
    
    return -2;
  }
  
  // Assumes bigData is correct
  Play[] legalPlays() {
    int numMoves = 0;
    int index = 0;
    if (lastMove == null || bigData[lastMove.row][lastMove.column] != -2) {
      for (int bigRow = 0; bigRow < 3; bigRow++) {
        for (int bigCol = 0; bigCol < 3; bigCol++) {
          for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
              if (data[bigRow][bigCol][row][col] == 0 && bigData[bigRow][bigCol] == -2) {
                numMoves++;
              }
            }
          }
        }
      }
      Play[] ret = new Play[numMoves];
      for (int bigRow = 0; bigRow < 3; bigRow++) {
        for (int bigCol = 0; bigCol < 3; bigCol++) {
          for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
              if (data[bigRow][bigCol][row][col] == 0 && bigData[bigRow][bigCol] == -2) {
                ret[index] = new MegaTTTPlay(bigRow, bigCol, row, col);
                index++;
              }
            }
          }
        }
      }
      return ret;
    } else {
      int bigRow = lastMove.row;
      int bigCol = lastMove.column;
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          if (data[bigRow][bigCol][row][col] == 0) {
            numMoves++;
          }
        }
      }
      Play[] ret = new Play[numMoves];
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          if (data[bigRow][bigCol][row][col] == 0) {
            ret[index] = new MegaTTTPlay(bigRow, bigCol, row, col);
            index++;
          }
        }
      }
      return ret;
    }
  }
  
  public Play randomPlay() {
    Play[] available = legalPlays();
    return available[(int)random(available.length)];
  }
  
  // Check all the minigames for winners
  private void checkGames() {
    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        this.checkGame(bigRow, bigCol);
      }
    }
  }
  
  // Check a minigame for a winner
  private void checkGame(int bigR, int bigC) {
    if (bigData[bigR][bigC] == -2) {
      for (int row = 0; row < 3; row++) {
        if (data[bigR][bigC][row][0] == data[bigR][bigC][row][1] && data[bigR][bigC][row][1] == data[bigR][bigC][row][2] && data[bigR][bigC][row][0] != 0) {
          bigData[bigR][bigC] = data[bigR][bigC][row][0];
          return;
        }
      }
      for (int col = 0; col < 3; col++) {
        if (data[bigR][bigC][0][col] == data[bigR][bigC][1][col] && data[bigR][bigC][1][col] == data[bigR][bigC][2][col] && data[bigR][bigC][0][col] != 0) {
          bigData[bigR][bigC] = data[bigR][bigC][0][col];
          return;
        }
      }
      
      if (data[bigR][bigC][0][0] == data[bigR][bigC][1][1] && data[bigR][bigC][1][1] == data[bigR][bigC][2][2] && data[bigR][bigC][0][0] != 0) {
        bigData[bigR][bigC]= data[bigR][bigC][0][0];
        return;
      }
      if (data[bigR][bigC][0][2] == data[bigR][bigC][1][1] && data[bigR][bigC][1][1] == data[bigR][bigC][2][0] && data[bigR][bigC][0][2] != 0) {
        bigData[bigR][bigC] = data[bigR][bigC][0][2];
        return;
      }
      
      for (int row = 0; row < 3; row++) {
        for (int column = 0; column < 3; column++) {
          if (data[bigR][bigC][row][column] == 0) {
            bigData[bigR][bigC] = -2;
            return;
          }
        }
      }
      
      bigData[bigR][bigC] = 0;
    }
  }
  
  // Draw this board
  void draw(float x, float y, float w, float h, boolean playerCanMove) {
    Play[] moves = this.legalPlays();
    for (int bigR = 0; bigR < 3; bigR++) {
      for (int bigC = 0; bigC < 3; bigC++) {
        float buffer = 0.03;
        float hatchX = x+(buffer+bigC/3.)*w;
        float hatchY = y+(buffer+bigR/3.)*h;
        float hatchW = w/3-w*2*buffer;
        float hatchH = h/3-h*2*buffer;
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            pg.noStroke();
            pg.fill (255, 0, 0);
            if (data[bigR][bigC][row][col] == -1) {
              pg.fill (0, 0, 255);
            }
            boolean isMove = false;
            MegaTTTPlay thisMove = null;
            for (Play abstractMove : moves) {
              MegaTTTPlay move = (MegaTTTPlay)abstractMove;
              if (move.bigRow == bigR && move.bigColumn == bigC && move.row == row && move.column == col) {
                isMove = true;
                thisMove = move;
              }
            }
            float rectBuffer = 0.05;
            if (isMove) {
              rectBuffer = 0;
            }
            float rectX = hatchX+(rectBuffer+col/3.)*hatchW;
            float rectY = hatchY+(rectBuffer+row/3.)*hatchH;
            float rectW = hatchW/3-hatchW*2*rectBuffer;
            float rectH = hatchH/3-hatchH*2*rectBuffer;
            if (data[bigR][bigC][row][col] != 0) {
              pg.rect (rectX, rectY, rectW, rectH, 2);
            }
            if (isMove) {
              pg.fill (255, 255, 0, 255*(1.2+sin(millis()/300.))/2.);
              pg.rect (rectX, rectY, rectW, rectH, 2);
              if (mousePressed && map(mouseX, 0, width, 0, pg.width) > rectX && map(mouseY, 0, height, 0, pg.height) > rectY && map(mouseX, 0, width, 0, pg.width) < rectX+rectW && map(mouseY, 0, height, 0, pg.height) < rectY+rectH && thisMove != null && playerCanMove) {
                this.makeMove(thisMove);
              }
            }
          }
        }
        pg.strokeWeight(2);
        pg.stroke(0);
        drawHatch(hatchX, hatchY, hatchW, hatchH);
        pg.strokeWeight(0);
        pg.fill (255, 0, 0, 50);
        if (bigData[bigR][bigC] == -1) {
          pg.fill (0, 0, 255, 50);
        }
        if (bigData[bigR][bigC] == 0) {
          pg.fill (100, 100, 100, 50);
        }
        if (bigData[bigR][bigC] != -2) {
          pg.rect (x+bigC/3.*w, y+bigR/3.*h, w/3., h/3.);
        }
      }
    }
    pg.stroke(0);
    pg.strokeWeight(4);
    drawHatch(x, y, w, h);
  }
  
  void drawHatch(float x, float y, float w, float h) {
    pg.line (x+w/3, y, x+w/3, y+h);
    pg.line (x+2*w/3, y, x+2*w/3, y+h);
    pg.line (x, y+h/3, x+w, y+h/3);
    pg.line (x, y+2*h/3, x+w, y+2*h/3);
  }
  
}

class MegaTTTPlay extends Play {
  int bigRow, bigColumn, row, column;
  MegaTTTPlay (int bigRow, int bigColumn, int row, int column) {
    this.bigRow = bigRow;
    this.bigColumn = bigColumn;
    this.row = row;
    this.column = column;
  }
  
  public String toString() {
    return bigRow + " " + bigColumn + " " + row + " " + column;
  }
}