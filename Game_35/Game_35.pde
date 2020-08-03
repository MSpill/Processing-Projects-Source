/* @pjs font="/static/projects/Game_35/data/AmericanTypewriter.ttf"; */

PFont f;

Cell[][] Cells = new Cell[8][8];
Indicator[] Indicators = new Indicator[9999];
int numIndicators = 0;

int turn;

boolean mouseIsPressed = false;

float ys = 50;

PGraphics pg;

void setup() {
  float aR = 650.0/590.0;
  if (screenWidth / (screenHeight+0.0) > aR) { // height is limiting
    size (screenHeight * 0.8 * aR, screenHeight * 0.8);
  } else {
    size (screenWidth * 0.8, screenWidth * 0.8 * 1.0/aR);
  }
  pg = createGraphics(650, 590);
  turn = Side.red;
  f = createFont ("/static/projects/Game_35/data/AmericanTypewriter.ttf", 25);
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      Cells[y][x] = new Cell (y, x);
    }
  }
}

void draw() {
  pg.beginDraw();
  pg.background (250);
  for (int y = 0; y < Cells.length; y++) {
    for (int x = 0; x < Cells[y].length; x++) {
      Cells[y][x].draw();
    }
  }
  pg.strokeWeight (5);
  pg.stroke (0);
  int numEmpty = 0, numRed = 0, numBlue = 0;
  for (int i = 0; i < 9; i++) {
    pg.line (i*61.25+80, pg.height-570+ys, i*61.25+80, pg.height-80+ys);
    pg.line (80, pg.height-i*61.25-80+ys, 570, pg.height-i*61.25-80+ys);
  }
  for (int y = 0; y < Cells.length; y++) {
    for (int x = 0; x < Cells[y].length; x++) {
      Cells[y][x].update();
      if (Cells[y][x].side == Side.neutral) {
        numEmpty++;
      } else if (Cells[y][x].side == Side.red) {
        numRed++;
      } else {
        numBlue++;
      }
    }
  }
  for (int i = 0; i < numIndicators; i++) {
    Indicators[i].draw();
  }
  pg.textFont (f);
  pg.textAlign (LEFT);
  pg.textSize (30);
  if (numEmpty != 0) {
    if (turn == Side.red) {
      String mytext = "Red turn.";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 3) {
          pg.fill (255, 0, 0);
        }
        pg.text (mytext.charAt(i), x, 50);
        x += pg.textWidth (mytext.charAt(i));
      }
    } else if (turn == Side.blue) {
      String mytext = "Blue turn.";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 4) {
          pg.fill (0, 0, 255);
        }
        pg.text (mytext.charAt(i), x, 50);
        x += pg.textWidth (mytext.charAt(i));
      }
    }
  } else {
    if (numRed > numBlue) {
      String mytext = "Red wins!";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 3) {
          pg.fill (255, 0, 0);
        }
        pg.text (mytext.charAt(i), x, 50);
        x += pg.textWidth (mytext.charAt(i));
      }
    } else if (numBlue > numRed) {
      String mytext = "Blue wins!";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        if (i < 4) {
          pg.fill (0, 0, 255);
        }
        pg.text (mytext.charAt(i), x, 50);
        x += pg.textWidth (mytext.charAt(i));
      }
    } else {
      String mytext = "Tie.";
      float x = pg.width/2-pg.textWidth(mytext)/2;
      for (int i = 0; i < mytext.length(); i++) {
        pg.fill (0);
        pg.text (mytext.charAt(i), x, 50);
        x += pg.textWidth (mytext.charAt(i));
      }
    }
  }
  mouseIsPressed = false;
  pg.endDraw();
  image(pg, 0, 0, width, height);
}

void mousePressed() {
  mouseIsPressed = true;
}

void keyPressed() {
  Cell selected = null;
  boolean cellSelected = false;
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      if (Cells[y][x].selected && Cells[y][x].number == 0) {
        selected = Cells[y][x];
        cellSelected = true;
      }
    }
  }
  if (cellSelected) {
    if (int(key) > 48 && int(key) < 58) {
      move (selected.x, selected.y, int(key)-48);
    }
  }
}

void move (int x, int y, int num) {
  Cell selected = Cells[x][y];
  selected.number = num;
  if (selected.highlight == Side.neutral) {
    selected.side = turn;
  } else {
    selected.side = selected.highlight;
  }
  if (turn == Side.red) {
    turn = Side.blue;
  } else {
    turn = Side.red;
  }
  updateGame();
}

void updateGame() {
  int[][] locations = new int[8*8][2];
  int numBlues = 0;
  int numReds = 0;
  for (int y = 0; y < 8; y++) {
    for (int x = 0; x < 8; x++) {
      if (y == 0) {
        if (x != 0 && x != 7) {
          int sumSurroundings = Cells[x-1][y].number+Cells[x+1][y].number+Cells[x-1][y+1].number+Cells[x][y+1].number+Cells[x+1][y+1].number;
          if (sumSurroundings == 35 && Cells[x][y].number != 0 && !Cells[x][y].reached35) { //<>//
            locations[numReds+numBlues][0] = x;locations[numReds+numBlues][1] = y;
            if (Cells[x][y].side == Side.red) {
              numReds += 1;
            } else {
              numBlues += 1;
            }
          }
        }
      } else if (y == 7) {
        if (x != 0 && x != 7) {
          int sumSurroundings = Cells[x-1][y].number+Cells[x+1][y].number+Cells[x-1][y-1].number+Cells[x][y-1].number+Cells[x+1][y-1].number;
          if (sumSurroundings == 35 && Cells[x][y].number != 0 && !Cells[x][y].reached35) {
            locations[numReds+numBlues][0] = x;locations[numReds+numBlues][1] = y;
            if (Cells[x][y].side == Side.red) {
              numReds += 1;
            } else {
              numBlues += 1;
            }
          }
        }
      } else if (x == 0) {
        if (y != 0 && y != 7) {
          int sumSurroundings = Cells[x][y-1].number+Cells[x][y+1].number+Cells[x+1][y-1].number+Cells[x+1][y].number+Cells[x+1][y+1].number;
          if (sumSurroundings == 35 && Cells[x][y].number != 0 && !Cells[x][y].reached35) {
            locations[numReds+numBlues][0] = x;locations[numReds+numBlues][1] = y;
            if (Cells[x][y].side == Side.red) {
              numReds += 1;
            } else {
              numBlues += 1;
            }
          }
        }
      } else if (x == 7) {
        if (y != 0 && y != 7) {
          int sumSurroundings = Cells[x][y-1].number+Cells[x][y+1].number+Cells[x-1][y-1].number+Cells[x-1][y].number+Cells[x-1][y+1].number;
          if (sumSurroundings == 35 && Cells[x][y].number != 0 && !Cells[x][y].reached35) {
            locations[numReds+numBlues][0] = x;locations[numReds+numBlues][1] = y;
            if (Cells[x][y].side == Side.red) {
              numReds += 1;
            } else {
              numBlues += 1;
            }
          }
        }
      } else {
        int sumSurroundings = Cells[x-1][y-1].number+Cells[x][y-1].number+Cells[x+1][y-1].number+Cells[x-1][y].number+Cells[x+1][y].number+Cells[x-1][y+1].number+Cells[x][y+1].number+Cells[x+1][y+1].number;
        if (sumSurroundings == 35 && Cells[x][y].number != 0 && !Cells[x][y].reached35) {
          locations[numReds+numBlues][0] = x;locations[numReds+numBlues][1] = y;
          if (Cells[x][y].side == Side.red) {
            numReds += 1;
          } else {
            numBlues += 1;
          }
        }
      }
    }
  }
  //println ("hello");
  if (numReds == 0 || numBlues == 0) {
    for (int i = 0; i < numReds+numBlues; i++) {
      int x = locations[i][0];
      int y = locations[i][1];
      if (y == 0) {
        Cells[x-1][y].side = Cells[x][y].side;Cells[x+1][y].side = Cells[x][y].side;Cells[x-1][y+1].side = Cells[x][y].side;Cells[x][y+1].side = Cells[x][y].side;Cells[x+1][y+1].side = Cells[x][y].side;
        Cells[x-1][y].highlight = Cells[x][y].side;Cells[x+1][y].highlight = Cells[x][y].side;Cells[x-1][y+1].highlight = Cells[x][y].side;Cells[x][y+1].highlight = Cells[x][y].side;Cells[x+1][y+1].highlight = Cells[x][y].side;
      } else if (y == 7) {
        Cells[x-1][y].side = Cells[x][y].side;Cells[x+1][y].side = Cells[x][y].side;Cells[x-1][y-1].side = Cells[x][y].side;Cells[x][y-1].side = Cells[x][y].side;Cells[x+1][y-1].side = Cells[x][y].side;
        Cells[x-1][y].highlight = Cells[x][y].side;Cells[x+1][y].highlight = Cells[x][y].side;Cells[x-1][y-1].highlight = Cells[x][y].side;Cells[x][y-1].highlight = Cells[x][y].side;Cells[x+1][y-1].highlight = Cells[x][y].side;
      } else if (x == 0) {
        Cells[x][y-1].side = Cells[x][y].side;Cells[x][y+1].side = Cells[x][y].side;Cells[x+1][y-1].side = Cells[x][y].side;Cells[x+1][y].side = Cells[x][y].side;Cells[x+1][y+1].side = Cells[x][y].side;
        Cells[x][y-1].highlight = Cells[x][y].side;Cells[x][y+1].highlight = Cells[x][y].side;Cells[x+1][y-1].highlight = Cells[x][y].side;Cells[x+1][y].highlight = Cells[x][y].side;Cells[x+1][y+1].highlight = Cells[x][y].side;
      } else if (x == 7) {
        Cells[x][y-1].side = Cells[x][y].side;Cells[x][y+1].side = Cells[x][y].side;Cells[x-1][y-1].side = Cells[x][y].side;Cells[x-1][y].side = Cells[x][y].side;Cells[x-1][y+1].side = Cells[x][y].side;
        Cells[x][y-1].highlight = Cells[x][y].side;Cells[x][y+1].highlight = Cells[x][y].side;Cells[x-1][y-1].highlight = Cells[x][y].side;Cells[x-1][y].highlight = Cells[x][y].side;Cells[x-1][y+1].highlight = Cells[x][y].side;
      } else {
        int n = Cells[x][y].side;
        Cells[x-1][y-1].side = n;Cells[x][y-1].side = n;Cells[x+1][y-1].side = n;Cells[x-1][y].side = n;Cells[x+1][y].side = n;Cells[x-1][y+1].side = n;Cells[x][y+1].side = n;Cells[x+1][y+1].side = n;
        Cells[x-1][y-1].highlight = n;Cells[x][y-1].highlight = n;Cells[x+1][y-1].highlight = n;Cells[x-1][y].highlight = n;Cells[x+1][y].highlight = n;Cells[x-1][y+1].highlight = n;Cells[x][y+1].highlight = n;Cells[x+1][y+1].highlight = n;
      }
    }  
  }
  for (int i = 0; i < numReds+numBlues; i++) {
    Cells[locations[i][0]][locations[i][1]].reached35 = true;
    Indicators[numIndicators] = new Indicator (locations[i][0], locations[i][1]);
  }
}

static abstract class Side {
  static final int neutral = 0;
  static final int red = 1;
  static final int blue = 2;
}

class Cell {
  int x, y, number;
  int side;
  int highlight;
  boolean selected = false;
  boolean reached35 = false;
  Cell (int x, int y) {
    this.x = x;
    this.y = y;
    side = Side.neutral;
    highlight = Side.neutral;
  }
  void draw() {
    if (number != 0) {
      if (side == Side.red) {
        pg.fill (255, 0, 0);
      } else {
        pg.fill (0, 0, 255);
      }
      pg.textAlign (CENTER, CENTER);
      pg.textSize (38);
      pg.text (number, x*61.25+80+31, pg.height-(7-y)*61.25-80-32+ys);
    } else {
      pg.fill (0, 0, 0, 0);
      pg.noStroke();
      if (highlight == Side.red) {
        pg.fill (255, 0, 0, 55);
      } else if (highlight == Side.blue) {
        pg.fill (0, 0, 255, 55);
      }
      pg.rect (x*61.25+80, pg.height-(7-y)*61.25-80+ys, 61.25, -61.25);
    }
  }
  void update() {
    if (mouseIsPressed) {
      if (map(mouseX, 0, width, 0, pg.width) > x*61.25+80 && map(mouseY, 0, height, 0, pg.height) < pg.height-(7-y)*61.25-80+ys && map(mouseX, 0, width, 0, pg.width) < (x*61.25+80)+61.25 && map(mouseY, 0, height, 0, pg.height) > (pg.height-(7-y)*61.25-80)-61.25+ys) {
        selected = true;
      } else {
        selected = false;
      }
    }
    if (selected) {
      pg.fill (0, 0, 0, 0);
      pg.strokeWeight (5);
      pg.stroke (100, 200, 254);
      pg.rect (x*61.25+80, pg.height-(7-y)*61.25-80+ys, 61.25, -61.25);
    }
  }
}

class Indicator {
  int x, y;
  float w = 700;
  float opacity = 1;
  boolean reachedSquare = false;
  Indicator (int x, int y) {
    this.x = x;
    this.y = y;
    numIndicators += 1;
  }
  void draw() {
    if (opacity >= 0) {
      w -= 30;
      pg.fill (0, 0, 0, 0);
      pg.strokeWeight (5);
      pg.stroke (0, 255, 0, opacity);
      pg.rectMode (CENTER);
      if (w < 61.25) {
        w = 61.25;
        opacity -= 10;
        if (!reachedSquare) {
          opacity = 500;
          reachedSquare = true;
        }
      } else {
        opacity += 20;
      }
      pg.rect (x*61.25+80+30.625, pg.height-(7-y)*61.25-80-30.625+ys, w, w);
      pg.rectMode (0);
    }
  }
}
