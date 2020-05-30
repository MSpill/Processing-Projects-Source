
MegaTTTBoard board;
PGraphics pg;
boolean waited = false;

void setup() {
  size ((int)(min(screenWidth, screenHeight)*0.8), (int)(min(screenWidth, screenHeight)*0.8*(630.0/600.0)));
  pg = createGraphics(600, 630);
  board = new MegaTTTBoard();
  //println (board.checkWinner());
  //println((TTTMove)Minimax.bestMove(board));
}

void draw() {
  pg.beginDraw();
  pg.background(255);
  pg.fill(0);
  pg.textSize(30);
  pg.textAlign(CENTER, CENTER);
  if (board.checkWinner() != -2) {
    if (board.checkWinner() == -1) {
      pg.text("Computer wins", pg.width/2, 40);
    }
    if (board.checkWinner() == 1) {
      pg.text("Player wins", pg.width/2, 40);
    }
    if (board.checkWinner() == 0) {
      pg.text("Tie", pg.width/2, 40);
    }
  } else {
    if (board.currentTurn() == 1) {
      pg.text("Player turn", pg.width/2, 40);
    } else {
      pg.text("Computer thinking...", pg.width/2, 40);
    }
  }
  
  boolean playerMove = false;
  if (board.currentTurn() == 1) {
    playerMove = true;
  }
  
  board.draw(50, 80, 500, 500, playerMove);

  pg.fill(0, 0, 0, 0);
  pg.stroke(0,0,0,0);
  if (map(mouseX,0,width,0,pg.width) > pg.width/2 - 60 && map(mouseX,0,width,0,pg.width) < pg.width/2 + 60 && map(mouseY,0,height,0,pg.height) > pg.height-50 && map(mouseY,0,height,0,pg.height) < pg.height-50+35) {
    pg.stroke(170);
  }
  pg.strokeWeight(2);
  pg.rect(pg.width/2 - 60, pg.height-50, 120, 35, 1);
  pg.fill(100);
  pg.textSize(25);
  pg.textAlign(CENTER, CENTER);
  pg.text ("Restart", pg.width/2, pg.height-32);
  
  if (!playerMove) {
    if (waited) {
    int depth = 6;
    int numMoves = board.getMoves().length;
    MegaTTTHeuristic heuristic = new MegaTTTHeuristic();
    if (numMoves > 9) {
      depth = 5;
    }
    Object[] nextMove = Minimax.minimax(board, 0, depth, heuristic);
    //println ("Value: " + nextMove[1]);
    board = (MegaTTTBoard)board.nextState((MegaTTTMove)nextMove[0]);
    waited = false;
    } else {
      waited = true;
    }
  }
  
  pg.endDraw();
  image (pg, 0, 0, width, height);
}

void mousePressed() {
  if (map(mouseX,0,width,0,pg.width) > pg.width/2 - 60 && map(mouseX,0,width,0,pg.width) < pg.width/2 + 60 && map(mouseY,0,height,0,pg.height) > pg.height-50 && map(mouseY,0,height,0,pg.height) < pg.height-50+35) {
    setup();
  }
}

static class Minimax {
  
  static Move bestMove (Board board, int maxDepth, Heuristic analyzer) {
    return (Move)(minimax(board, 0, maxDepth, analyzer)[0]);
  }
  
  private static Object[] minimax (Board board, int depth, int maxDepth, Heuristic analyzer) {
    
    // Check if base case
    int winner = board.checkWinner();
    // 1 is red win, -1 is blue win, 0 is tie, -2 is ongoing
    if (winner != -2) {
      //println ("winner " + winner);
      Object[] ret = {null, (float)winner};
      return ret;
    }
    
    // Check if max depth reached
    if (depth == maxDepth) {
      Object[] ret = {null, analyzer.evaluate(board)};
      return ret;
    }
    
    // Evaluate moves
    Move[] moves = board.getMoves();
    float[] values = new float[moves.length];
    int turn = board.currentTurn(); // 1 is red's turn, -1 is blue's turn
    float max = -999; 
    int index = -1;
    for (int i = 0; i < moves.length; i++) {
      values[i] = (float)minimax(board.nextState(moves[i]), depth+1, maxDepth, analyzer)[1] * turn;
      if (values[i] > max) {
        max = values[i];
        index = i;
      }
    }
    
    // {which move is best, value of this position}
    Object[] ret = {moves[index], values[index] * turn};
    return ret;
  }
  
}

class MegaTTTBoard extends Board {
  int[][][][] data;
  int[][] bigData; // keeps track of macro game
  MegaTTTMove lastMove; // keeps track of last move
  
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
  
  Board nextState (Move abstractMove) {
    
    MegaTTTMove move = (MegaTTTMove)abstractMove;
    MegaTTTBoard ret = new MegaTTTBoard();
    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            ret.data[bigRow][bigCol][row][col] = data[bigRow][bigCol][row][col];
          }
        }
      }
    }
    
    int turn = this.currentTurn();
    ret.data[move.bigRow][move.bigColumn][move.row][move.column] = turn;
    ret.checkGames();
    ret.lastMove = move;
    return ret;
  }
  
  // Specific to this class, changes this instance
  void updateState (MegaTTTMove move) {
    int turn = this.currentTurn();
    data[move.bigRow][move.bigColumn][move.row][move.column] = turn;
    checkGames();
    lastMove = move;
  }
  
  int currentTurn() {
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
  int checkWinner() {
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
  Move[] getMoves() {
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
      Move[] ret = new Move[numMoves];
      for (int bigRow = 0; bigRow < 3; bigRow++) {
        for (int bigCol = 0; bigCol < 3; bigCol++) {
          for (int row = 0; row < 3; row++) {
            for (int col = 0; col < 3; col++) {
              if (data[bigRow][bigCol][row][col] == 0 && bigData[bigRow][bigCol] == -2) {
                ret[index] = new MegaTTTMove(bigRow, bigCol, row, col);
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
      Move[] ret = new Move[numMoves];
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          if (data[bigRow][bigCol][row][col] == 0) {
            ret[index] = new MegaTTTMove(bigRow, bigCol, row, col);
            index++;
          }
        }
      }
      return ret;
    }
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
    Move[] moves = this.getMoves();
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
            MegaTTTMove thisMove = null;
            for (Move abstractMove : moves) {
              MegaTTTMove move = (MegaTTTMove)abstractMove;
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
              if (mousePressed && map(mouseX,0,width,0,pg.width) > rectX && map(mouseY,0,height,0,pg.height) > rectY && map(mouseX,0,width,0,pg.width) < rectX+rectW && map(mouseY,0,height,0,pg.height) < rectY+rectH && thisMove != null && playerCanMove) {
                this.updateState(thisMove);
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
  
  public String toString() {
    String ret = "";
    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int row = 0; row < 3; row++) {
        for (int bigCol = 0; bigCol < 3; bigCol++) {
          for (int col = 0; col < 3; col++) {
            if (data[bigRow][bigCol][row][col] == 0) {
              ret += " 0 ";
            } else if (data[bigRow][bigCol][row][col] == 1) {
              ret += " 1 ";
            } else {
              ret += "-1 ";
            }
          }
          ret += " ";
        }
        ret += "\n";
      }
      ret += "\n";
    }
    return ret;
  }
  
  public String bigData() {
    String ret = "";
    for (int bigR = 0; bigR < 3; bigR++) {
      for (int bigC = 0; bigC < 3; bigC++) {
        if (bigData[bigR][bigC] == 0) {
          ret += " 0 ";
        } else if (bigData[bigR][bigC] == 1) {
          ret += " 1 ";
        } else if (bigData[bigR][bigC] == -1) {
          ret += "-1 ";
        } else {
          ret += "-2 ";
        }
      }
      ret += "\n";
    }
    return ret;
  }
  
}

class MegaTTTHeuristic extends Heuristic {
  
  float evaluate (Board abstractBoard) {
    MegaTTTBoard b = (MegaTTTBoard)abstractBoard;
    float[][] bigGame = new float[3][3];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        if (b.bigData[row][col] == 0) { // game is over in a tie
          bigGame[row][col] = -2; // meaning nobody will win it
        } else if (b.bigData[row][col] == -2) { // game is ongoing
          bigGame[row][col] = evaluateGame(b.data[row][col]); // so estimate its outcome
        } else {
          bigGame[row][col] = b.bigData[row][col];
        }
      }
    }
    return evaluateGame(bigGame);
  }
  
  float evaluateGame (int[][] data) {
    
    float[][] newArr = new float[3][3];
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        newArr[row][col] = data[row][col];
      }
    }
    return evaluateGame(newArr);
  }
  
  float evaluateGame (float[][] data) {
    
    // Add probabilities of winning each lane if all tiles were chosen probabilistically
    float redScore = 0;
    float blueScore = 0;
    for (int row = 0; row < 3; row++) {
      redScore += (rp(data[row][0]) * rp(data[row][1]) * rp(data[row][2]));
      blueScore += (bp(data[row][0]) * bp(data[row][1]) * bp(data[row][2]));
    }
    for (int col = 0; col < 3; col++) {
      redScore += (rp(data[0][col]) * rp(data[1][col]) * rp(data[2][col]));
      blueScore += (bp(data[0][col]) * bp(data[1][col]) * bp(data[2][col]));
    }
    
    // Diagonals
    redScore += (rp(data[0][0]) * rp(data[1][1]) * rp(data[2][2]));
    blueScore += (bp(data[0][0]) * bp(data[1][1]) * bp(data[2][2]));
    redScore += (rp(data[0][2]) * rp(data[1][1]) * rp(data[2][0]));
    blueScore += (bp(data[0][2]) * bp(data[1][1]) * bp(data[2][0]));
    float total = redScore + blueScore;
    if (total == 0) {
      return 0;
    }
    
    return (redScore/total)*2 - 1;
  }
  
  // Turns score from -1 to 1 (-2 goes to nobody) into a probability of red winning from 0 to 1
  float rp(float score) {
    if (score == -2) {
      return 0;
    }
    return (score+1)/2;
  }
  
  // Same thing but for blue
  float bp(float score) {
    if (score == -2) {
      return 0;
    }
    return 1 - (score+1)/2;
  }
  
}

class MegaTTTMove extends Move {
  int bigRow, bigColumn, row, column;
  MegaTTTMove (int bigRow, int bigColumn, int row, int column) {
    this.bigRow = bigRow;
    this.bigColumn = bigColumn;
    this.row = row;
    this.column = column;
  }
  
  public String toString() {
    return bigRow + " " + bigColumn + " " + row + " " + column;
  }
}


abstract class Board {
  
  abstract Move[] getMoves();
  
  abstract Board nextState (Move move);
  
  abstract int checkWinner();
  
  // 1 is red, -1 is blue
  abstract int currentTurn();
  
}

abstract class Heuristic {
  
  abstract float evaluate (Board board);
  
}

abstract class Move {
  
}
