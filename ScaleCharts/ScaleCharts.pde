/* @pjs preload="/static/projects/ScaleCharts/audio.png" */

/* Note: this project relies more heavily than the others on native js. To run this in the processing IDE, you'll need to commment
	 out all the javascript (mostly related to the audio). */

String[] tuning = {"E", "A", "D", "G", "B", "E"};
String root = "G";
String scale = "Pentatonic";
String mode = "Minor (VI)";

int[] mask = {1, 1, 1, 1, 1};
boolean colored = true;
int frets = 15;
boolean noteNames = false;
String useNotesText = "ABC";

float boardX, boardY, boardW, boardH;

String prevMode;
String[] prevTuning;
String prevPreset;
int[] currScale;
float sat = 255;
float val = 170;
float[] cols = {40, 80, 120, 160, 200, 240, 20, 140};
boolean customScale, editTuning;
int[] customMask;
int[] customScaleMode1;
String customScaleInfo;

ArrayList<UIElement> elements;
Dropdown rootDrop, scaleDrop, modeDrop, presetsDrop;
Button customScaleButton, editTuningButton, noteToggle;
Button okButton, cancelButton, okButtonTuning, cancelButtonTuning;

String[] diatonicModes = {"Major (I)",  "Minor (VI)", "Dorian (II)", "Phrygian (III)", "Lydian (IV)", "Mixolydian (V)", "Locrian (VII)"};
String[] pentatonicModes = {"Major (I)",  "Minor (VI)", "Dorian (II)", "Phrygian (III)", "Mixolydian (V)"};
String[] harmonicMinorModes = {"I (Harmonic minor)", "II (Locrian 6)", "III (Ionian augmented)", "IV (Dorian #11)", "V (Phrygian dominant)", "VI (Lydian #2)", "VII (Super locrian bb7)"};
String[] melodicMinorModes = {"I (Melodic minor)", "II (Dorian b2)", "III (Lydian augmented)", "IV (Lydian dominant)", "V (Mixolydian b6)", "VI (Aeolian b5)", "VII (Super locrian)"};
String[] harmonicMajorModes = {"I (Harmonic major)", "II (Dorian b5)", "III (Phrygian b4)", "IV (Lydian b3)", "V (Mixolydian b2)", "VI (Lydian augmented #2)", "VII (Locrian bb7)"};
String[] diminishedModes = {"I (Whole-half)", "II (Half-whole)"};
String[] doubleHarmonicModes = {"I (Double harmonic major)", "IV (Hungarian/Gypsy minor)", "II (Lydian #2 #6)", "III (Ultraphrygian)", "V (Oriental)", "VI (Ionian #2 #5)", "VII (Locrian bb3 bb7)"};
String[] neapolitanMinorModes = {"I (Neapolitan minor)", "IV (Hungarian Gypsy scale)", "II (Lydian #6)", "III (Mixolydian augmented)", "V (Locrian dominant)", "VI (Ionian #2)", "VII (Ultralocrian bb3)"};

var sounds = [];
int pitchIndex = 0;
int scaleTimer;
boolean playScale;
PImage audioButton;

boolean isMobile, havePlayedAudio;
int touchCooldown1, touchCooldown2;

void setup() {
  isMobile = false;
  havePlayedAudio = false;
  touchCooldown1 = 0;
  touchCooldown2 = 0;
  float wid = screenWidth;
  float hei = screenHeight - 30;
  if (hei > wid) {
    size (max(hei, 700), max((int)(wid), 500), P2D);
  } else {
    size (max(wid, 700), max((int)(hei - 150), 500), P2D);
  }
  smooth(3);
  boardW = (width - 130) * 0.9; boardX = (width-boardW)/2.0;
  if (boardX + boardW + 130 > width) {
    boardX -= boardX + boardW + 130 - width;
  }
  boardH = height * 0.42; boardY = 125 + boardH / (tuning.length-1.0) * 1.35;
  audioButton = loadImage("/static/projects/ScaleCharts/data/audio.png"); // replace with just "audio.png"
  setupUI();
  recalculateScale();
  for (var i = 0; i < 24; i++) {
    var mySound = document.createElement("audio");
    mySound.src = "/static/projects/ScaleCharts/sounds/" + i + ".mp3";
    mySound.setAttribute("preload", "auto");
    mySound.setAttribute("controls", "none");
    mySound.style.display = "none";
    mySound.volume = 0.4;
    mySound.playbackRate = 1.5;
    document.body.appendChild(mySound);
    sounds.push(mySound);
  }
}

void draw() {
  touchCooldown1--;
  touchCooldown2--;
  background(250);
  uiFunctions();
  drawNeck();
  drawUI();
  if (customScale) {
    drawCustomScaleMenu();
  }
  if (editTuning) {
    drawEditTuningMenu();
  }
  scalePlay();
}

void scalePlay() {
  if (playScale) {
    if (scaleTimer % 45 == 0) {
      if (pitchIndex < currScale.length) {
        pitchIndex++;
        while (mask[pitchIndex % currScale.length] == false) {
          pitchIndex++;
        }
        int soundIndex = toneOf(root) + currScale[pitchIndex % currScale.length];
        if (pitchIndex >= currScale.length) {
          soundIndex += 12;
        }
        if (soundIndex < sounds.length) {
          if (sounds[soundIndex].paused || sounds[soundIndex].currentTime > 0) {
            sounds[soundIndex].currentTime = 0;
          }
          sounds[soundIndex].play();
        } else {
          playScale = false;
        }
      } else {
        playScale = false;
      }
    }
    scaleTimer++;
  }
}

void drawNeck() {
  float fretW = boardW / frets;
  float stringH = boardH / (tuning.length - 1);
  float circleSize = min(min(stringH * 0.8, fretW * 0.8), 60);

  textAlign(CENTER, CENTER);
  textSize(50);
  fill(0);
  text(frets, boardX+boardW + 55, boardY + boardH/2.0);
  textSize(25);
  text("frets", boardX+boardW + 55, boardY + boardH * 0.65);
  
  fill(250);
  strokeWeight(2);
  stroke(150);
  if (mouseIn(boardX + boardW + 55 - 25, boardY + boardH/2.0 - 80, 50, 50, 1)) {
    rect(boardX + boardW + 55 - 25, boardY + boardH/2.0 - 80, 50, 50, 2);
  }
  if (mouseIn(boardX + boardW + 55 - 25, boardY + boardH/2.0 + 60, 50, 50, 1)) {
    rect(boardX + boardW + 55 - 25, boardY + boardH/2.0 + 60, 50, 50, 2);
  }
  
  fill(150);
  noStroke();
  rect(boardX + boardW + 55 - 15, boardY + boardH/2.0 - 60, 30, 10, 2);
  rect(boardX + boardW + 55 - 5, boardY + boardH/2.0 - 70, 10, 30, 2);
  
  rect(boardX + boardW + 55 - 15, boardY + boardH/2.0 + 80, 30, 10, 2);
  
  for (int i = 0; i < frets + 1; i++) {
    stroke(100);
    strokeWeight(2);
    if (i == 0) strokeWeight(8);
    line (boardX + i * fretW, boardY, boardX + i * fretW, boardY + boardH);
    
    if (i % 12 == 3 || i % 12 == 5 || i % 12 == 7 || i % 12 == 9) {
      noStroke();
      fill (200);
      ellipse (boardX + (i-0.5) * fretW, boardY + boardH / 2.0, stringH * 0.5, stringH * 0.5);
      ellipse (boardX + (i-0.5) * fretW, boardY - circleSize / 2.0 - fretW * 0.2, fretW * 0.2, fretW * 0.2);
    }
    if (i % 12 == 0 && i > 0) {
      noStroke();
      fill (200);
      ellipse (boardX + (i-0.5) * fretW, boardY + boardH / 3.0, stringH * 0.5, stringH * 0.5);
      ellipse (boardX + (i-0.5) * fretW, boardY + boardH / 3.0 * 2, stringH * 0.5, stringH * 0.5);
      ellipse (boardX + (i-0.67) * fretW, boardY - circleSize / 2.0 - fretW * 0.2, fretW * 0.2, fretW * 0.2);
      ellipse (boardX + (i-0.33) * fretW, boardY - circleSize / 2.0 - fretW * 0.2, fretW * 0.2, fretW * 0.2);
    }
  }
  
  String[] accidentals = null;
  String s = scale.toLowerCase();
  boolean useAccidentals = true;
  if (useAccidentals) {
    accidentals = calculateAccidentals(currScale);
  }
  boolean matchDegree = accidentals.length == 7 || s.equals("pentatonic") || s.equals("blues");
  if (matchDegree) {
    //rootDrop.value = bestRoot(root, accidentals);
  }

  drawNotesInOrder(width/2.0 - 50, clamp(boardY + boardH + 105, boardY + boardH + 70, height-30), clamp(circleSize * 1.15, 35, 50) * 1.15 * (65.0/50.0), clamp(circleSize * 1.15, 35, 50) * 1.15, accidentals, noteNames, mask);
  float notesW = clamp(circleSize * 1.15, 35, 50) * 1.15 * (65.0/50.0) * (accidentals.length - 1);
  float textX = width/2.0 - 50 + notesW/2.0 + clamp(circleSize * 1.15, 35, 50) * 1.15 * 0.5 + 25;
  float textY = clamp(boardY + boardH + 105, boardY + boardH + 70, height-30);
  if (mouseIn(textX - 15, textY - 25, 85, 50, 1)) {
    strokeWeight(2);
    stroke(150);
    fill(250);
    rect(textX - 15, textY - 25, 85, 50, 1);
  }
  textAlign(CENTER, CENTER);
  fill(150);
  textSize(30);
  text(useNotesText, width/2.0 + notesW/2.0 + clamp(circleSize * 1.15, 35, 50) * 1.15 * 0.5 + 3, clamp(boardY + boardH + 105, boardY + boardH + 70, height-30));

  if (mouseIn(textX + 70, textY - 30, 70, 60, 1)) {
    strokeWeight(2);
    stroke(150);
    fill(250);
    rect(textX + 70, textY - 30, 70, 60, 1);
  }
  image(audioButton, textX + 80, textY - 25, 50, 50);

  for (int i = 0; i < tuning.length; i++) {
    stroke(100);
    strokeWeight(3.5 * (1 - (i+0.0) / tuning.length) + 1.5);
    line (boardX, boardY + boardH - i * stringH, boardX + boardW, boardY + boardH - i * stringH);
    
    int pitchOfString = toneOf(tuning[i]);
    
    fill(0);
    float offset = 0;
    if (noteInScale(pitchOfString, toneOf(root), currScale) >= 0 && mask[noteInScale(pitchOfString, toneOf(root), currScale)] == 1) {
      offset = circleSize;
    }
    textSize(circleSize * 0.5);
    textAlign(CENTER, CENTER);
    text (tuning[i], boardX - fretW * 0.5 - offset, boardY + boardH - i * stringH);
    
    // draw scale notes
    for (int f = 0; f < frets + 1; f++) {
      int degree = noteInScale(pitchOfString + f, toneOf(root), currScale);
      if (degree >= 0 && mask[degree] == 1) {
        if (playScale && pitchIndex % currScale.length == degree) {
          strokeWeight(3);
          stroke(150);
          fill(255);
          ellipse(boardX + (f-0.5) * fretW, boardY + boardH - i * stringH, circleSize * 1.25, circleSize * 1.25);
        }
        fill(0);
        if (degree == 0) {
          fill (0, 0, 255);
          if (colored) fill(0);
        } else if (colored) {
          colorMode(HSB);
          int realDegree = -1;
          float valMult = 1;
          for (int n = 0; n < 3; n++) {
            if (accidentals[degree].length() > n && int(accidentals[degree].charAt(n) + "") > 0) {
              realDegree = int(accidentals[degree].charAt(n) + "");
              valMult = 1.0 - (n/7.0);
              break;
            }
          }
          fill (cols[realDegree-1], sat * valMult, val * valMult);
        }
        noStroke();
        ellipse (boardX + (f-0.5) * fretW, boardY + boardH - i * stringH, circleSize, circleSize);
        colorMode(RGB);
        if (degree >= 0) {
          textSize(circleSize * 0.5);
          textAlign(CENTER, CENTER);
          fill(250);
          String degText = degree + 1 + "";
          if (useAccidentals) {
            if (noteNames) {
              degText = degreeToNote(bestRoot(root, accidentals), accidentals[degree], matchDegree);
            } else {
              degText = accidentals[degree];
            }
          }
          if (degree == 0 && !noteNames) {
            degText = "R";
          }
          text (degText, boardX + (f-0.5) * fretW, boardY + boardH - i * stringH);
        }
      }
    }
  }
}

void updateCustomScaleInfo() {
  String[] exists = scaleAlreadyExists(customScalePitches());
  if (exists[0] != null && exists[1] != null) {
    if (isNumeral(exists[1].split(" ")[0]) > 0) {
      customScaleInfo = "This is mode " + exists[1] + " of the " + exists[0] + " scale.";
    } else {
      customScaleInfo = "This is the " + exists[1] + " mode of the " + exists[0] + " scale.";
    }
  } else {
    customScaleInfo = "";
  }
}

void drawCustomScaleMenu() {
  fill (250, 250, 250);
  noStroke();
  rect(-1, -1, width+2, height+2);
  String[] accidentals = {"R", "b2", "2", "b3", "3", "4", "b5", "5", "b6", "6", "b7", "7"};
  float fillGap = width * 0.8 / 11;
  if (75 * 11 < width * 0.9) {
    drawNotesInOrder (width/2.0, height/2.0 - 52, 75, 65, accidentals, false, customMask);
  } else {
    drawNotesInOrder (width/2.0, height/2.0 - 52, fillGap, fillGap * (65.0/75.0), accidentals, false, customMask);
  }
  okButton.draw();
  cancelButton.draw();
  fill(0);
  textSize(55);
  textAlign(CENTER, BOTTOM);
  text("Select notes", width/2.0, height/2.0 - 175);
  textSize(30);
  text(customScaleInfo, width/2.0, height/2.0 + 55);
}

void drawEditTuningMenu() {
  background(250);
  fill(50);
  textSize(28);
  textAlign(RIGHT, CENTER);
  text("Tuning:", width/2.0 - 100 - 23, height/2.0-194);
  float wholeW = 600;
  float gap = wholeW / (tuning.length-1);
  for (int i = 0; i < tuning.length; i++) {
    fill (50);
    textSize(60);
    if (tuning.length > 6) textSize(50);
    textAlign(CENTER, CENTER);
    float textX = width/2.0 - wholeW/2.0 + gap * i;
    float textY = height/2.0 - 30;
    text (tuning[i], width/2.0 - wholeW/2.0 + gap*i, height/2.0 - 30);
    
    float rectX = textX - 30, rectW = 60;
    fill (250);
    strokeWeight(2);
    stroke(150);
    if (mouseIn(rectX - 10, textY - 80, rectW + 20, 50, 1)) {
      rect(rectX, textY - 70, rectW, 40, 2);
    }
    if (mouseIn(rectX - 10, textY + 22, rectW + 20, 50, 1)) {
      rect(rectX, textY + 32, rectW, 40, 2);
    }
    
    noStroke();
    fill(150);
    triangle(textX - 20, textY - 40, textX + 20, textY - 40, textX, textY - 60);
    triangle(textX - 20, textY + 42, textX + 20, textY + 42, textX, textY + 62);
  }
  
  okButtonTuning.draw();
  cancelButtonTuning.draw();
  presetsDrop.draw();
}

void toggleNotes(float posX, float y, float gap, float circleSize, int[] outMask) {
  for (int i = 0; i < outMask.length; i++) {
    float wholeW = gap * (outMask.length-1);
    float x = posX - wholeW/2.0 + i*gap;
    if (dist(mouseX, mouseY, x, y) <= circleSize/2 && rootDrop.inFocus == 0 && scaleDrop.inFocus == 0 && modeDrop.inFocus == 0) {
      outMask[i] = 1-outMask[i];
    }
  }
}

void drawNotesInOrder(float posX, float y, float gap, float circleSize, String[] accidentals, boolean useNotes, int[] noteMask) {
  for (int i = 0; i < accidentals.length; i++) {
    float a = (noteMask[i] == 1) ? 255 : 25;
    float wholeW = gap * (accidentals.length-1);
    float x = posX - wholeW/2.0 + i*gap;
    if (playScale && pitchIndex % currScale.length == i) {
      strokeWeight(3);
      stroke(150);
      fill(255);
      ellipse(x, y, circleSize * 1.25, circleSize * 1.25);
    }
    fill (0, 0, 0, a);
    if (i == 0) {
      float b = 0;
      if (!colored) b = 255;
      fill(0, 0, b, a);
      if (dist(mouseX, mouseY, x, y) <= circleSize /2) {
        fill (0, 0, b * 0.8, a * 1.5);
      }
    } else if (colored) {
      colorMode(HSB);
      int realDegree = -1;
      float valMult = 1;
      for (int n = 0; n < 3; n++) {
        if (accidentals[i].length() > n && int(accidentals[i].charAt(n) + "") > 0) {
          realDegree = int(accidentals[i].charAt(n) + "");
          valMult = (1.0 - (n/7.0));
          break;
        }
      }
      fill (cols[realDegree-1], sat * valMult, val * valMult, a);
      if (dist(mouseX, mouseY, x, y) <= circleSize /2) {
        fill (cols[realDegree-1], sat * valMult, val * valMult * 0.7, a * 2);
      }
    }
    colorMode(RGB);
    noStroke();
    ellipse(x, y, circleSize, circleSize);
    fill(250);
    if (noteMask[i] == 0) fill (170);
    textAlign(CENTER, CENTER);
    textSize(circleSize * 0.5);
    String degText = accidentals[i];
    if (useNotes) {
      boolean matchDegree = accidentals.length == 7 || scale.toLowerCase().equals("pentatonic") || scale.toLowerCase().equals("blues");
      degText = degreeToNote(bestRoot(root, accidentals), accidentals[i], matchDegree);
    }
    text((i == 0 && !useNotes) ? "R" : degText, x, y);
  }
}

void touchStart(TouchEvent e) {
  if (touchCooldown1 <= 0) {
    document.getElementById("sketch").removeEventListener('touchmove', touchMove);
    mouseX = e.touches[0].offsetX;
    mouseY = e.touches[0].offsetY;
    pmouseX = mouseX;
    pmouseY = mouseY;
    isMobile = false;
    mousePressed();
    isMobile = true;
    touchCooldown1 = 5;
  }
}

void touchEnd() {
  if (touchCooldown2 <= 0) {
    isMobile = false;
    mouseReleased();
    isMobile = true;
    touchCooldown2 = 5;
  }
}

/*void touchMove(TouchEvent e) {
  mouseX = e.touches[0].offsetX;
  mouseY = e.touches[0].offsetY;
}*/

void mousePressed() {
  if (!havePlayedAudio) {
    var audioList = document.getElementsByTagName("audio");
    for (var i = 0; i < audioList.length; i++) {
      audioList[i].play();
      audioList[i].pause();
      audioList[i].currentTime = 0;
    }
    havePlayedAudio = true;
  }
  if (!isMobile) {
    if (!customScale && !editTuning) {
      String[] accidentals = null;
      String s = scale.toLowerCase();
      boolean useAccidentals = true;
      if (useAccidentals) {
        accidentals = calculateAccidentals(currScale);
      }
      
      float fretW = boardW / frets;
      float stringH = boardH / (tuning.length - 1);
      float circleSize = min(min(stringH * 0.8, fretW * 0.8), 50);
      toggleNotes(width/2.0 - 50, clamp(boardY + boardH + 105, boardY + boardH + 70, height-30), clamp(circleSize * 1.15, 35, 50) * 1.15 * (65.0/50.0), clamp(circleSize * 1.15, 35, 50) * 1.15, mask);
      
      if (mouseIn(boardX + boardW + 55 - 25, boardY + boardH/2.0 - 80, 50, 50, 1)) {
        if (frets % 12 == 9 || frets % 12 == 0) frets += 3;
        else frets += 2;
        if (frets > 21) frets = 9;
      }
      if (mouseIn(boardX + boardW + 55 - 25, boardY + boardH/2.0 + 60, 50, 50, 1)) {
        if (frets % 12 == 0 || frets % 12 == 3) frets -= 3;
        else frets -= 2;
        if (frets < 9) frets = 21;
      }

      float notesW = clamp(circleSize * 1.15, 35, 50) * 1.15 * (65.0/50.0) * (accidentals.length - 1);
      float textX = width/2.0 - 50 + notesW/2.0 + clamp(circleSize * 1.15, 35, 50) * 1.15 * 0.5 + 25;
      float textY = clamp(boardY + boardH + 105, boardY + boardH + 70, height-30);
      if (mouseIn(textX - 15, textY - 25, 90, 50, 1)) {
        if (!noteNames) {
          useNotesText = "1 2 3";
        } else {
          useNotesText = "ABC";
        }
        noteNames = !noteNames;
      }

      if (mouseIn(textX + 70, textY - 30, 70, 60, 1)) {
        if (!playScale) {
          boolean anyNoteActive = false;
          for (int i = 0; i < mask.length; i++) {
            if (mask[i]) anyNoteActive = true;
          }
          if (anyNoteActive) {
            pitchIndex = -1;
            scaleTimer = 0;
            playScale = true;
          }
        } else {
          playScale = false;
        }
      }
    }
    if (customScale) {
      float fillGap = width * 0.8 / 11;
      if (75 * 11 < width * 0.9) {
        toggleNotes (width/2.0, height/2.0 - 52, 75, 65, customMask);
      } else {
        toggleNotes (width/2.0, height/2.0 - 52, fillGap, fillGap * (65.0/75.0), customMask);
      }
      customMask[0] = 1;
      updateCustomScaleInfo();
    }
    if (editTuning) {
      float wholeW = 600;
      float gap = wholeW / (tuning.length-1);
      for (int i = 0; i < tuning.length; i++) {
        float textX = width/2.0 - wholeW/2.0 + gap * i;
        float textY = height/2.0 - 30;
        float rectX = textX - 30, rectW = 60;
        boolean changeIt = false;
        int offset = 0;
        int sharpOrFlat = 0;
        if (mouseIn(rectX - 10, textY - 80, rectW + 20, 50, 1) && presetsDrop.inFocus == 0) {
          changeIt = true;
          offset = 1;
          sharpOrFlat = 0;
        }
        if (mouseIn(rectX - 10, textY + 22, rectW + 20, 50, 1) && presetsDrop.inFocus == 0) {
          changeIt = true;
          offset = rootDrop.options.length - 1;
          sharpOrFlat = 1;
        }
        if (changeIt) {
          int indexOfCurrNote = -1;
          for (int n = 0; n < rootDrop.options.length; n++) {
            String[] splitted = rootDrop.options[n].split("/");
            if (splitted[0].equals(tuning[i]) || (splitted.length > 1 && splitted[1].equals(tuning[i]))) {
              indexOfCurrNote = n;
            }
          }
          tuning[i] = rootDrop.options[(indexOfCurrNote + offset) % rootDrop.options.length];
          if (tuning[i].contains("/")) tuning[i] = tuning[i].split("/")[sharpOrFlat];
          String hyphenatedTuning = "(" + tuning[0];
          for (int n = 1; n < tuning.length; n++) {
            hyphenatedTuning += "-" + tuning[n];
          }
          hyphenatedTuning += ")";
          presetsDrop.value = "Custom";
          for (int n = 0; n < presetsDrop.options.length; n++) {
            if (presetsDrop.options[n].contains(hyphenatedTuning)) {
              presetsDrop.value = presetsDrop.options[n];
            }
          }
        }
      }
    }
    for (UIElement e : elements) {
      e.mousePressed();
    }
  }
}

void mouseReleased() {
  if (!isMobile) {
    for (UIElement e : elements) {
      e.mouseReleased();
    }
  }
}

int[] customScalePitches() {
  int numNotes = 0;
  for (int i = 0; i < customMask.length; i++) numNotes += customMask[i];
  int[] ret = new int[numNotes];
  int n = 0;
  for (int i = 0; i < customMask.length; i++) {
    if (customMask[i] == 1) {
      ret[n] = i;
      n++;
    }
  }
  return ret;
}

void uiFunctions() {
  if (customScale) {
    if (okButton.active) {
      customScale = false;
      String[] exists = scaleAlreadyExists(customScalePitches());
      if (exists[0] == null || exists[1] == null) {
        int numNotes = 0;
        for (int i = 0; i < customMask.length; i++) numNotes += customMask[i];
        currScale = new int[numNotes];
        customScaleMode1 = new int[numNotes];
        mask = new int[numNotes];
        int n = 0;
        for (int i = 0; i < customMask.length; i++) {
          if (customMask[i] == 1) {
            currScale[n] = i;
            customScaleMode1[n] = i;
            mask[n] = 1;
            n++;
          }
        }
        scaleDrop.value = "Custom";
        scale = "Custom";
        modeDrop.options = numeralArr(numNotes);
        modeDrop.value = "I";
      } else {
        scaleDrop.value = exists[0];
        scale = scaleDrop.value;
        modeDrop.options = getModeOptions(scale);
        modeDrop.value = exists[1];
        mode = modeDrop.value;
        recalculateScale();
        mask = new int[currScale.length];
        for (int i = 0; i < mask.length; i++) mask[i] = 1;
      }
      prevMode = modeDrop.value;
    }
    if (cancelButton.active) {
      customScale = false;
    }
  }
  if (editTuning) {
    if (presetsDrop.inFocus == 2) {
      tuning = presetsDrop.value.split("\\(")[1].split("\\)")[0].split("-");
    }
    if (okButtonTuning.active) {
      editTuning = false;
      presetsDrop.onScreen = false;
    }
    if (cancelButtonTuning.active) {
      editTuning = false;
      presetsDrop.onScreen = false;
      tuning = prevTuning;
      presetsDrop.value = prevPreset;
    }
  }
  if (customScaleButton.active) {
    customScale = true;
    rootDrop.onScreen = false;
    scaleDrop.onScreen = false;
    modeDrop.onScreen = false;
    customScaleButton.onScreen = false;
    editTuningButton.onScreen = false;
    customMask = new int[12];
    playScale = false;
    for (int i = 0; i < currScale.length; i++) {
      customMask[currScale[i]] = 1;
    }
    updateCustomScaleInfo();
  }
  if (editTuningButton.active) {
    editTuning = true;
    rootDrop.onScreen = false;
    scaleDrop.onScreen = false;
    modeDrop.onScreen = false;
    customScaleButton.onScreen = false;
    editTuningButton.onScreen = false;
    playScale = false;
    prevTuning = new String[tuning.length];
    for (int i = 0; i < tuning.length; i++) prevTuning[i] = tuning[i];
    prevPreset = presetsDrop.value;
  }
  if (rootDrop.inFocus == 2) {
    root = rootDrop.value;
    playScale = false;
  }
  if (scaleDrop.inFocus == 2) {
    scale = scaleDrop.value;
    playScale = false;
    modeDrop.options = getModeOptions(scale);
    boolean changeMode = true;
    for (int i = 0; i < modeDrop.options.length; i++) {
      if (modeDrop.options[i].equals(modeDrop.value)) {
        changeMode = false;
        break;
      }
    }
    if (changeMode) {
      modeDrop.value = modeDrop.options[0];
    }
    mode = modeDrop.value;
    prevMode = modeDrop.value;
    mask = new int[generateScalePitches(scaleDrop.value, "1").length];
    for (int i = 0; i < mask.length; i++) mask[i] = 1;
    recalculateScale();
  }
  if (modeDrop.inFocus == 2) {
    playScale = false;
    int[] jumps = jumpsFromScale(scale);
    int prevRot = rotationFromMode(jumps, prevMode);
    int currRot = rotationFromMode(jumps, modeDrop.value);
    mask = rotateLeft(mask, (currRot - prevRot + mask.length) % mask.length);
    mode = modeDrop.value;
    prevMode = modeDrop.value;
    recalculateScale();
  }
}

void drawUI() {
  customScaleButton.draw();
  editTuningButton.draw();
  fill(0);
  textSize(25);
  textAlign(LEFT, BOTTOM);
  text("Root", rootDrop.x, rootDrop.y - 5);
  text("Scale", scaleDrop.x, scaleDrop.y - 5);
  text("Mode", modeDrop.x, modeDrop.y - 5);
  rootDrop.draw();
  scaleDrop.draw();
  modeDrop.draw();
}

void setupUI() {
  elements = new ArrayList<UIElement>();
  
  float dropsX = width/2.0 - 280, dropsY = 40;
  
  String[] rootOptions = {"A", "A#/Bb", "B", "C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb", "G", "G#/Ab"};
  rootDrop = new Dropdown(dropsX, dropsY, 100, rootOptions, root);
  
  String[] scaleOptions = {"Diatonic", "Pentatonic", "Blues", "Harmonic minor", "Melodic minor", "Harmonic major", "Whole tone", "Diminished/Symmetric", "Persian",
                           "Double Harmonic", "Japanese", "Hirajoshi", "Neapolitan minor", "Neapolitan major"};
  scaleDrop = new Dropdown(dropsX + 120, dropsY, 200, scaleOptions, scale);
  
  String[] modeOptions = getModeOptions(scale);
  modeDrop = new Dropdown(dropsX + 340, dropsY, 200, modeOptions, mode);
  prevMode = modeDrop.value;
  
  customScaleButton = new Button("Custom scale...", dropsX + 120, dropsY + 35 + 15, 300, 35);
  
  customScaleInfo = "";
  
  okButton = new Button("OK", width/2.0 - 250, height/2.0 + 95, 240, 60);
  cancelButton = new Button("Cancel", width/2.0 + 10, height / 2.0 + 95, 240, 60);
  
  editTuningButton = new Button("Change tuning", max(boardX - 80, 10), boardY + boardH + 40, 160, 35);
  String[] tuningPresets = {"Standard (E-A-D-G-B-E)", "Bass Standard (E-A-D-G)", "Drop D (D-A-D-G-B-E)", "Open A (E-A-C#-E-A-E)", "Open B (B-F#-B-F#-B-D#)",
                            "Open C (C-G-C-G-C-E)", "Open D (D-A-D-F#-A-D)", "Open E (E-B-E-G#-B-E)", "Open F (C-F-C-F-A-C)", "Open G (D-G-D-G-B-D)"};
  presetsDrop = new Dropdown(width/2.0 - 100, height/2.0 - 215, 350, tuningPresets, tuningPresets[0]);
  presetsDrop.h = 45;
  presetsDrop.onScreen = false;
  
  okButtonTuning = new Button("OK", width/2.0 - 250, height/2.0 + 95, 240, 60);
  cancelButtonTuning = new Button("Cancel", width/2.0 + 10, height/2.0 + 95, 240, 60);
}

class Button extends UIElement {
  float x, y, w, h;
  String buttonText;
  boolean active, beingPressed;
  float rounding;
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
    this.rounding = 5;
  }
  
  void draw() {
    onScreen = true;
    stroke(0);
    strokeWeight(1);
    fill(255);
    if (!othersFocus() && mouseIn(x, y, w, h, 1)) {
      fill (240);
      if (beingPressed) {
        fill (220);
      }
    }
    rect(x, y, w, h, rounding);
    fill(50);
    textSize(h * (16.0/30.0));
    textAlign(CENTER, CENTER);
    text(buttonText, x + w/2, y + h/2);
    if (active) {
      active = false;
    }
  }
  
  boolean hoveredOver() {
    return mouseIn(x, y, w, h, 1);
  }
  
  void setRounding(float newRound) {
    this.rounding = newRound;
  }
  
  void mousePressed() {
    if (mouseIn(x, y, w, h, 1) && onScreen) {
      if (!othersFocus()) {
        beingPressed = true;
      }
    }
  }
  
  void mouseReleased() {
    if (mouseIn(x, y, w, h, 1) && onScreen) {
      if (!othersFocus() && beingPressed) {
        active = true;
      }
    }
    beingPressed = false;
  }
}

abstract class UIElement {
  int inFocus;
  boolean onScreen;
  abstract void mousePressed();
  abstract void mouseReleased();
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
    this.h = 35;
    dropped = false;
    inFocus = 0;
    elements.add(this);
  }
  
  void draw() {
    onScreen = true;
    drawBackground();
    drawText();
    drawArrow();
    if (dropped) {
      float maxWidth = 0;
      textSize(15.0/30.0 * h);
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
    if (onScreen) {
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
        textSize(15.0/30.0 * h);
        for (int i = 0; i < options.length; i++) {
          float thisW = textWidth(options[i]);
          maxWidth = max(maxWidth, thisW);
        }
        float currY = y+h+5;
        for (int i = 0; i < options.length; i++) {
          if (mouseIn (x, currY, max(maxWidth + 20, 100), h, 1)) {
            value = options[i];
            dropped = false;
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
  }
  
  void drawOption(String opText, float opX, float opY, float opW, float opH) {
    noStroke();
    fill (255);
    opW = max(opW, 100);
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
    textSize(16.0/30.0 * h);
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
    strokeWeight(0.1 * h);
    stroke (180);
    if (mouseIn (x, y, w, h, 1)) {
      stroke (100);
    }
    float arrowY = y+(13.0/30.0) * h;
    float arrowW = h * (12.0/30.0);
    float arrowH = (7+(30.0-5)/2.0-13) / 30.0 * h;
    float arrowX = x+w-arrowW-7;
    line (arrowX, arrowY, arrowX+arrowW/2.0, arrowY+arrowH);
    line (arrowX+arrowW/2.0, arrowY+arrowH, arrowX+arrowW, arrowY);
  }
}

float clamp(float val, float vmin, float vmax) {
  return min(max(val, vmin), vmax);
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


// returns {scale, mode} if pitches already matches one of the pairs
String[] scaleAlreadyExists(int[] pitches) {
  for (String tryScale : scaleDrop.options) {
    String[] modes = getModeOptions(tryScale);
    for (String tryMode : modes) {
      int[] thisScale = generateScalePitches(tryScale, tryMode);
      boolean same = false;
      if (thisScale.length == pitches.length) {
        same = true;
        for (int i = 0; i < thisScale.length; i++) {
          if (thisScale[i] != pitches[i]) same = false;
        }
      }
      if (same) {
        return new String[] {tryScale, tryMode};
      }
    }
  }
  return new String[] {null, null};
}

String[] getModeOptions(String localScale) {
  String s = localScale.toLowerCase();
  String[] ret;
  if (s.equals("diatonic")) {
    ret = diatonicModes;
  } else if (s.equals("pentatonic") || s.equals("blues")) {
    ret = pentatonicModes;
  } else if (s.equals("harmonic minor")) {
    ret = harmonicMinorModes;
  } else if (s.equals("melodic minor")) {
    ret = melodicMinorModes;
  } else if (s.equals("harmonic major")) {
    ret = harmonicMajorModes;
  } else if (s.equals("diminished/symmetric")) {
    ret = diminishedModes;
  } else if (s.equals("double harmonic")) {
    ret = doubleHarmonicModes;
  } else if (s.equals("neapolitan minor")) {
    ret = neapolitanMinorModes;
  } else if (s.equals("whole tone")) {
    ret = numeralArr(1);
  } else {
    int numNotes = generateScalePitches(scaleDrop.value, "1").length;
    ret = numeralArr(numNotes);
  }
  return ret;
}

void recalculateScale() {
  currScale = generateScalePitches(scale, mode);
}

// compares a scale to the major scale
String[] calculateAccidentals(int[] scalePitches) {
  
  String[] ret = new String[scalePitches.length];
  int[] majorScale = generateScalePitches("diatonic", "major");
  
  boolean compareFails = true;
  if (scaleDrop.value.toLowerCase().equals("custom") && scalePitches.length == 7) {
    compareFails = directCompareFails(scalePitches);
  }
  
  for (int i = 0; i < ret.length; i++) {
    int compareTo = i;
    
    // algorithm for non 7-note scales, makes everything a natural or a flat
    if (ret.length != 7 || (scaleDrop.value.toLowerCase().equals("custom") && compareFails)) {
      compareTo = 0;
      while (scalePitches[i] > majorScale[compareTo]) {
        compareTo = (compareTo + 1) % majorScale.length;
      }
    }
    
    if (scalePitches[i] == majorScale[compareTo] - 2) {
      ret[i] = "bb" + (compareTo+1);
    } if (scalePitches[i] == majorScale[compareTo] - 1) {
      ret[i] = "b" + (compareTo+1);
    } else if (scalePitches[i] == majorScale[compareTo]) {
      ret[i] = "" + (compareTo+1);
    } else if (scalePitches[i] == majorScale[compareTo] + 1) {
      ret[i] = "#" + (compareTo+1);
    } else if (scalePitches[i] == majorScale[compareTo] + 2) {
      ret[i] = "##" + (compareTo+1);
    }
  }
  
  return ret;
}

String bestRoot(String slashedRoot, String[] degAccidentals) {
  if (slashedRoot.contains("/")) {
    int num1 = countNoteAccidentals(slashedRoot.split("/")[0], degAccidentals);
    int num2 = countNoteAccidentals(slashedRoot.split("/")[1], degAccidentals);
    if (num1 <= num2) {
      return slashedRoot.split("/")[0];
    } else {
      return slashedRoot.split("/")[1];
    }
  } else {
    return slashedRoot;
  }
}

int countNoteAccidentals(String root, String[] degAccidentals) {
  int ret = 0;
  for (int i = 0; i < degAccidentals.length; i++) {
    ret += degreeToNote(root, degAccidentals[i], true).length() - 1;
  }
  return ret;
}

String degreeToNote(String root, String degree, boolean matchDegree) {
  String[] naturals = {"A", "B", "C", "D", "E", "F", "G"};
  int indexOfRoot = -1;
  for (int i = 0; i < naturals.length; i++) {
    if (naturals[i].equals(root.charAt(0))) {
      indexOfRoot = i;
    }
  }
  int rootPitch = toneOf(root);
  int degreeNum = int(degree.charAt(degree.length-1));
  int[] majorPitches = generateScalePitches("diatonic", "major");
  int offset = 0;
  for (int i = 0; i < degree.length() - 1; i++) {
    if (degree.charAt(i).equals("b")) {
      offset -= 1;
    } else if (degree.charAt(i).equals("#")) {
      offset += 1;
    }
  }
  int notePitch = (rootPitch + majorPitches[degreeNum - 1] + offset) % 12;
  if (!matchDegree) {
    return rootDrop.options[notePitch].split("/")[0];
  } else {
    String natural = naturals[(indexOfRoot + degreeNum - 1) % naturals.length];
    int naturalPitch = toneOf(natural);
    while (naturalPitch != notePitch) {
      if (naturalPitch < notePitch) {
        if (notePitch - naturalPitch  < 6) {
          natural += "#";
        } else {
          natural += "b";
        }
      } else {
        if (naturalPitch - notePitch  < 6) {
          natural += "b";
        } else {
          natural += "#";
        }
      }
      naturalPitch = toneOf(natural);
    }
    return natural;
  }
}

boolean directCompareFails(int[] scalePitches) {
  String[] ret = new String[scalePitches.length];
  int[] majorScale = generateScalePitches("diatonic", "major");
  
  for (int i = 0; i < ret.length; i++) {
    int compareTo = i;
    
    if (scalePitches[i] < majorScale[compareTo] - 2 || scalePitches[i] > majorScale[compareTo] + 2) {
      return true;
    }
  }
  return false;
}

int[] generateScalePitches(String type, String mode) {
  int[] jumps = jumpsFromScale(type);
  
  int rotation = rotationFromMode(jumps, mode);
  
  jumps = rotateLeft(jumps, rotation);
  
  return scalePitchesFromJumps(jumps);
  
}

int[] jumpsFromScale(String type) {
  int[] jumps = null;
  
  if (type.toLowerCase().equals("diatonic")) {
    jumps = new int[] {2, 2, 1, 2, 2, 2, 1};
  } else if (type.toLowerCase().equals("pentatonic")) {
    jumps = new int[] {2, 2, 3, 2, 3};
  } else if (type.toLowerCase().equals("blues")) {
    jumps = new int[] {2, 1, 1, 3, 2, 3};
  } else if (type.toLowerCase().equals("harmonic minor")) {
    jumps = new int[] {2, 1, 2, 2, 1, 3, 1};
    //return scalePitchesFromJumps(jumps);
  } else if (type.toLowerCase().equals("melodic minor")) {
    jumps = new int[] {2, 1, 2, 2, 2, 2, 1};
    //return scalePitchesFromJumps(jumps);
  } else if (type.toLowerCase().equals("harmonic major")) {
    jumps = new int[] {2, 2, 1, 2, 1, 3, 1};
    //return scalePitchesFromJumps(jumps);
  } else if (type.toLowerCase().equals("whole tone")) {
    jumps = new int[] {2, 2, 2, 2, 2, 2};
  } else if (type.toLowerCase().equals("diminished/symmetric")) {
    jumps = new int[] {2, 1, 2, 1, 2, 1, 2, 1};
  } else if (type.toLowerCase().equals("persian")) {
    jumps = new int[] {1, 3, 1, 1, 2, 3, 1};
  } else if (type.toLowerCase().equals("double harmonic")) {
    jumps = new int[] {1, 3, 1, 2, 1, 3, 1};
  } else if (type.toLowerCase().equals("japanese")) {
    jumps = new int[] {2, 3, 2, 1, 4};
  } else if (type.toLowerCase().equals("hirajoshi")) {
    jumps = new int[] {2, 1, 4, 1, 4};
  } else if (type.toLowerCase().equals("neapolitan minor")) {
    jumps = new int[] {1, 2, 2, 2, 1, 3, 1};
  } else if (type.toLowerCase().equals("neapolitan major")) {
    jumps = new int[] {1, 2, 2, 2, 2, 2, 1};
  } else if (type.toLowerCase().equals("yeet")) {
    jumps = new int[] {3, 2, 1, 1, 2, 2, 1};
  } else if (type.toLowerCase().equals("custom")) {
    jumps = jumpsFromScalePitches(customScaleMode1);
  }
  
  return jumps;
}

int rotationFromMode(int[] jumps, String mode) {
  String modeWord = mode.split(" ")[0].toLowerCase();
  
  int rotation = 0;
  if (modeWord.equals("major") || modeWord.equals("ionian")) {
    rotation = 0;
  } else if (modeWord.equals("dorian")) {
    rotation = 1;
  } else if (modeWord.equals("phrygian")) {
    rotation = 2;
    if (jumps.length == 6) rotation = 3; // for blues scale
  } else if (modeWord.equals("lydian")) {
    rotation = 3;
  } else if (modeWord.equals("mixolydian")) {
    rotation = 4;
    if (jumps.length == 5) rotation = 3; // for pentatonic
  } else if (modeWord.equals("minor") || mode.toLowerCase().equals("aeolian")) {
    rotation = 5;
    if (jumps.length == 5) rotation = 4; // for pentatonic
  } else if (modeWord.equals("locrian")) {
    rotation = 6;
  } else if (int(modeWord) > 0) { // number mode
    rotation = int(modeWord) - 1;
  } else if (isNumeral(modeWord) >= 1) { // numeral
    rotation = isNumeral(modeWord) - 1;
  }
  return rotation;
}

int[] rotateLeft(int[] arr, int rot) {
  int[] ret = new int[arr.length];
  for (int i = 0; i < ret.length; i++) ret[i] = arr[i];
  
  for (int i = 0; i < rot; i++) {
    int temp = ret[0];
    for (int n = 1; n < arr.length; n++) {
      ret[n-1] = ret[n];
    }
    ret[ret.length-1] = temp;
  }
  return ret;
}

String[] numeralArr(int l) {
  String[] numerals = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"};
  String[] ret = new String[l];
  for (int i = 0; i < ret.length; i++) {
    ret[i] = numerals[i];
  }
  return ret;
}

int isNumeral(String s) {
  String[] numerals = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"};
  for (int i = 0; i < numerals.length; i++) {
    if (s.toLowerCase().equals(numerals[i].toLowerCase())) {
      return i+1;
    }
  }
  return 0;
}

// returns scale degree
int noteInScale(int note, int root, int[] scalePitches) {
  note = note % 12;
  root = root % 12;
  
  for (int i = 0; i < scalePitches.length; i++) {
    if (note == (root + scalePitches[i]) % 12) {
      return i;
    }
    //root = (root + jumps[i]) % 12;
  }
  return -1;
}

int[] jumpsFromScalePitches(int[] pitches) {
  int[] ret = new int[pitches.length];
  for (int i = 0; i < ret.length - 1; i++) {
    ret[i] = pitches[i+1] - pitches[i];
  }
  ret[ret.length-1] = 12 - pitches[ret.length-1];
  return ret;
}

// ignores the last jump, assumes that it leads to the root
int[] scalePitchesFromJumps(int[] jumps) {
  int[] ret = new int[jumps.length];
  int currNote = 0;
  for (int i = 1; i < jumps.length; i++) {
    currNote += jumps[i-1];
    ret[i] = currNote;
  }
  return ret;
}

int toneOf(String note) {
  int base = 0;
  char c = note.charAt(0);
  if (c.equals("A")) {
      base = 0;
  } else if (c.equals("B")) {
      base = 2;
  } else if (c.equals("C")) {
      base = 3;
  } else if (c.equals("D")) {
      base = 5;
  } else if (c.equals("E")) {
      base = 7;
  } else if (c.equals("F")) {
      base = 8;
  } else if (c.equals("G")) {
      base = 10;
  }
  
  for (int i = 1; i < note.length(); i++) {
    if (note.charAt(i).equals("#")) {
      base = (base + 13) % 12;
    } else if (note.charAt(i).equals("b")){
      base = (base + 11) % 12;
    } else if (note.charAt(i).equals("/")) {
      break;
    }
  }
  
  return base;
}