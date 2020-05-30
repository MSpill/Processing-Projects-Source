boolean created = false;
Player play = new Player (650, 200);
ArrayList<Obstacle> Obstacles = new ArrayList<Obstacle>();
ArrayList<Explosion> Explosions = new ArrayList<Explosion>();
ArrayList<Enemy> Enemies = new ArrayList<Enemy>();
ArrayList<Heavy> Heavies = new ArrayList<Heavy>();
float spawnHeavy = 200;
float spawnEnemy = 0;
float obFade = 255;
float lineVal = 100;
float valCount = 0;
float lifeCount = 100;
float sessionScore = 0;
float score = 30;
float makeOb = 60;
ArrayList<Bullet> Bullets = new ArrayList<Bullet>();
int setFlash = 150;
float gravity = 1;
float str;
float enemySpeed = 1;
int menuJump = 50;
int numObsCurrent = 0;
boolean menu = true;
PFont f;
PFont h;
PFont s;

float sF;

void setup()
{
  size((int)(screenWidth*0.75), (int)(screenWidth*0.75*(800.0/1280)), P2D);
  sF = ((int)(screenWidth*0.75)) / 1280.0;
}
void draw()
{
  background (200);
  for (Bullet b : Bullets)
  {
    b.update();
    b.draw();
  }
  for (Enemy e : Enemies)
  {
    e.update();
    e.draw();
  }
  for (Heavy h : Heavies)
  {
    h.update();
    h.draw();
  }
  valCount -= 1;
  play.update();
  play.draw();
  makeOb -= 1;
  str = 1;
  spawnEnemy -= 1;
  spawnHeavy -= 1;
  if (spawnEnemy <= 0)
  {
    spawnEnemy = 400;
    if (score >= 15)
    {
      int r = round(random(0, 1));
      Enemy enem = new Enemy (r * 1280 + (r - 0.5) * 65, random (800));
      Enemies.add(enem);
    }
  }
  if (spawnHeavy <= 0)
  {
    spawnHeavy = 800;
    if (score >= 25)
    {
      if (play.x > 1280/2)
      {
        Heavies.add(new Heavy (-35, random (800)));
      } else {
        Heavies.add(new Heavy (1280 + 35, random (800)));
      }
    }
  }
  if (makeOb <= 0)
  {
    if (score >= 5)
    {
      Obstacles.add(new Obstacle (random (150, 1280 - 350), random(150, 800 - 250), random(180, 220), random(80, 120)));
      for (int i = 0; i < 1000; i++)
      {
        Obstacle ob1 = Obstacles.get(Obstacles.size() - 1);
        for (int n = 0; n < Obstacles.size(); n++)
        {
          Obstacle ob2 = Obstacles.get(n);
          if (Obstacles.size() - 1 != n && ((ob1.x > ob2.x && ob1.y > ob2.y && ob1.x < ob2.x + ob2.l && ob1.y < ob2.y + ob2.w) || (ob2.x > ob1.x && ob2.y > ob1.y && ob2.x < ob1.x + ob1.l && ob2.y < ob1.y + ob1.w) || (ob1.x + ob1.l > ob2.x && ob1.y > ob2.y && ob1.x + ob1.l < ob2.x + ob2.l && ob1.y < ob2.y + ob2.w) || (ob2.x + ob2.l > ob1.x && ob2.y > ob1.y && ob2.x + ob2.l < ob1.x + ob1.l && ob2.y + ob2.y < ob1.y + ob1.w) || (ob1.x > ob2.x && ob1.y + ob1.w > ob2.y && ob1.x < ob2.x + ob2.l && ob1.y + ob1.w < ob2.y + ob2.w) || (ob2.x > ob1.x && ob2.y + ob2.w > ob1.y && ob2.x < ob1.x + ob1.l && ob2.y + ob2.w < ob1.y + ob1.w) || (ob1.x + ob1.l > ob2.x && ob1.y + ob1.w > ob2.y && ob1.x + ob1.l < ob2.x + ob2.l && ob1.y + ob1.w < ob2.y + ob2.w) || (ob2.x + ob2.l > ob1.x && ob2.y + ob2.w > ob1.y && ob2.x + ob2.l < ob1.x + ob1.l && ob2.y + ob2.w < ob1.y + ob1.w)) && ob2.life >= 0 && ob1.life>= 0)
          {
            ob1.x = random (150, 1280 - 350);
            ob1.y = random (150, 800 - 250);
          }
        }
      }
    }
    if (numObsCurrent < 25)
    {
      makeOb = 200;
    } else {
      makeOb = 142.85714286;
    }
  }
  if (numObsCurrent >= 25)
  {
    setFlash = 70;
  }
  for (Obstacle o : Obstacles)
  {
    o.flashing();
    o.draw();
    o.checkCol(play);
  }
  lineVal = 100;
  if (lifeCount < 100)
  {
    lifeCount -= 1;
    fill (100, 100, 100, obFade * 4);
    textAlign (CENTER, CENTER);
    textSize(250 * sF);
    text (round(score), 1280/2 * sF, 800/2 * sF);
    fill (255, 0, 0, 50);
    noStroke();
    rect (0, 0, 1280 * sF, 800 * sF);
    obFade = lifeCount * 2.55;
  }
  if (lifeCount < 0)
  {
    obFade = 255;
    lifeCount = 100;
    play.x = 650; 
    play.y = 200;
    play.xv = 0; 
    play.yv = 0;
    play.alive = true;
    if (menu)
    {
      score = 30;
    } else {
      score = 0;
    }
    if (menu == false)
    {
      numObsCurrent = 0;
      makeOb = 200;
      setFlash = 150;
      for (Obstacle o : Obstacles)
      {
        o.life = 0;
      }
      for (Enemy e : Enemies)
      {
        e.alive = false;
        e.drawme = false;
      }
      for (Heavy h : Heavies)
      {
        h.alive = false;
        h.drawme = false;
      }
    }
  }
  if (valCount >= 0)
  {
    lineVal = 255;
    str = 1.25;
    fill (150, 150, 50);
    noStroke();
    ellipse ((play.x + revAngleX (Angle(play.x, play.y, map(mouseX, 0, width, 0, 1280), map(mouseY, 0, height, 0, 800)), 13)) * sF, (play.y + revAngleY (Angle(play.x, play.y, map(mouseX, 0, width, 0, 1280), map(mouseY, 0, height, 0, 800)), 13)) * sF, 10 * sF, 10 * sF);
  }
  fill (0);
  if (menu == false)
  {
    textAlign (LEFT, BOTTOM);
    textSize(27 * sF);
    text ("Session best: " + round(sessionScore), 20 * sF, 60 * sF);
    text ("Score: " + round(score), 20 * sF, 90 * sF);
  }
  if (score > sessionScore)
  {
    sessionScore = score;
  }
  for (Explosion e : Explosions)
  {
    e.update();
    e.draw();
  }
  if (menu)
  {
    noStroke();
    fill (200, 200, 200, 200);
    rect (0, 0, 1280 * sF, 800 * sF);
    stroke (75);
    float l = 250;
    float x1 = (1280/2 - l/2);
    float y1 = (800/2 - l/2);
    if (map(mouseX, 0, width, 0, 1280) > x1 && map(mouseY, 0, height, 0, 800) > y1 && map(mouseX, 0, width, 0, 1280) < x1 + l && map(mouseY, 0, height, 0, 800) < y1 + l)
    {
      fill (150);
    } else {
      fill (185);
    }
    rect ((1280/2 - l/2)*sF, (800/2 - l/2)*sF, l*sF, l*sF, 30*sF);
    fill (75);
    textSize (90*sF);
    textAlign (CENTER, CENTER);
    text ("Kickback", 1280/2.0*sF, (800/2.0-220)*sF);
    noStroke();
    triangle ((x1 + 70)*sF, (y1 + 50)*sF, (x1 + 70)*sF, (y1 + (l-50))*sF, (x1 + 200)*sF, (y1 + l/2)*sF);
    if (mousePressed && map(mouseX, 0, width, 0, 1280) > x1 && map(mouseY, 0, height, 0, 800) > y1 && map(mouseX, 0, width, 0, 1280) < x1 + l && map(mouseY, 0, height, 0, 800) < y1 + l)
    {
      menu = false;
      obFade = 255;
      lifeCount = 100;
      play.x = 650; 
      play.y = 200;
      play.xv = 0; 
      play.yv = 0;
      play.alive = true;
      sessionScore = 0;
      if (menu)
      {
        score = 30;
      } else {
        score = 0;
      }
      if (menu == false)
      {
        numObsCurrent = 0;
        makeOb = 200;
        setFlash = 150;
        for (Obstacle o : Obstacles)
        {
          o.life = 0;
        }
        for (Enemy e : Enemies)
        {
          e.alive = false;
          e.drawme = false;
        }
        for (Heavy h : Heavies)
        {
          h.alive = false;
          h.drawme = false;
        }
        for (Bullet b : Bullets)
        {
          b.alive = false;
        }
      }
    }
    menuJump -= 1;
    if (menuJump <= 0)
    {
      float x = random(play.x + play.xv + 1, play.x + play.xv + 1);
      float y = random(play.y, 800);
      play.xv -= revAngleX (Angle (play.x, play.y, x, y), gravity*10);
      play.yv -= revAngleY (Angle (play.x, play.y, x, y), gravity*10);
      valCount = 6;
      score += 1;
      Bullets.add(new Bullet (play.x, play.y, revAngleX (Angle (play.x, play.y, x, y), 15), revAngleY (Angle (play.x, play.y, x, y), 15)));
      menuJump = 90;
    }
  }
}
void mousePressed()
{
  if (play.alive == true)
  {
    if (menu == false)
    {
      play.xv -= revAngleX (Angle (play.x, play.y, map(mouseX, 0, width, 0, 1280), map(mouseY, 0, height, 0, 800)), gravity*10);
      play.yv -= revAngleY (Angle (play.x, play.y, map(mouseX, 0, width, 0, 1280), map(mouseY, 0, height, 0, 800)), gravity*10);
      valCount = 6;
      score += 1;
      Bullets.add(new Bullet (play.x, play.y, revAngleX (Angle (play.x, play.y, map(mouseX, 0, width, 0, 1280), map(mouseY, 0, height, 0, 800)), 15), revAngleY (Angle (play.x, play.y, map(mouseX, 0, width, 0, 1280), map(mouseY, 0, height, 0, 800)), 15)));
      int drop = round (random (1.5, 4.49));
      /*if (drop == 1)
       {
       Drop1.play();
       }
       if (drop == 2)
       {
       Drop1.play();
       }
       if (drop == 3)
       {
       Drop2.play();
       }
       if (drop == 4)
       {
       Drop3.play();
       }*/
    }
  }
}

class Enemy
{
  float x;
  float y;
  float xv;
  float yv;
  boolean alive = true;
  boolean hit = false;
  boolean drawme = true;
  float count = 1;
  Enemy (float xc, float yc)
  {
    x = xc;
    y = yc;
  }
  void update()
  {
    if (hit == false && alive)
    {
      x += xv;
      y += yv;
      xv = revAngleX (Angle (x, y, play.x, play.y), enemySpeed);
      yv = revAngleY (Angle (x, y, play.x, play.y), enemySpeed);
      if (hit)
      {
        count -= 0.01;
      }
      if (count <= 0)
      {
        alive = false;
      }
      for (int i = 0; i < Bullets.size(); i++)
      {
        Bullet bul = Bullets.get(i);
        if (dist (bul.x, bul.y, x, y) <= 38.5 && bul.alive == true)
        {
          hit = true;
          alive = false;
          Explosions.add(new Explosion (bul.x, bul.y));
          bul.alive = false;
        }
      }
      if (dist (x, y, play.x, play.y) < 20 && play.alive)
      {
        lifeCount = 99;
        play.alive = false;
        //play.x = random(1280); play.y = random(800);
        play.xv = 0;
        play.yv = 0;
      }
      for (int i = 0; i < Obstacles.size(); i++)
      {
        Obstacle ob = Obstacles.get(i);
        if (ob.life >= 0)
        {
          if (y < ob.y + ob.w + 40 && y > ob.y + ob.w && x < ob.x + ob.l && x > ob.x && yv/abs(yv) == -1)
          {
            if (y < ob.y + ob.w + 35)
            {
              yv = enemySpeed/2;
            } else {yv = 0.001;}
            if ((play.x - x)/abs(play.x - x) == 1)
            {
              xv = enemySpeed;
            } else {xv = -enemySpeed;}
          }
          if (y > ob.y - 40 && y < ob.y && x < ob.x + ob.l && x > ob.x && yv/abs(yv) == 1)
          {
            if (y > ob.y - 35)
            {
              yv = -enemySpeed/2;
            } else {yv = 0.001;}
            if ((play.x - x)/abs(play.x - x) == 1)
            {
              xv = enemySpeed;
            } else {xv = -enemySpeed;}
          }
          if (x < ob.x && x > ob.x - 40 && y > ob.y && y < ob.y + ob.w && xv/abs(xv) == 1)
          {
            if (x > ob.x - 35)
            {
              xv = -enemySpeed/2;
            } else {xv = 0.001;}
            if ((play.y - y)/abs(play.y - y) == 1)
            {
              yv = enemySpeed;
            } else {yv = -enemySpeed;}
          }
          if (x < ob.x + ob.l + 40 && x > ob.x + ob.l && y > ob.y && y < ob.y + ob.w && xv/abs(xv) == -1)
          {
            if (x < ob.x + ob.l + 35)
            {
              xv = enemySpeed/2;
            } else {xv = 0.001;}
            if ((play.y - y)/abs(play.y - y) == 1)
            {
              yv = enemySpeed;
            } else {yv = -enemySpeed;}
          }
        }
      }
    }
  }
  void draw()
  {
    if (drawme)
    {
      fill (150, 150, 50, 0.75*lifeCount*count);
      stroke (150, 150, 50, 1.50*lifeCount*count);
      strokeWeight(2);
      line (x*sF, y*sF, (x + revAngleX (Angle (x, y, x + xv, y + yv), 32.5))*sF, (y + revAngleY (Angle (x, y, x + xv, y + yv), 32.5))*sF);
      strokeWeight (1);
      ellipse (x*sF, y*sF, 65*sF, 65*sF);
      fill (150, 150, 50, 2.55*lifeCount*count);
      noStroke();
      ellipse (x*sF, y*sF, 20*sF, 20*sF);
      if (hit)
      {
        count -= 0.02;
      }
      if (count <= 0)
      {
        drawme = false;
      }
    }
  }
}

class Bullet
{
  float x;
  float y;
  float xv;
  float yv;
  boolean alive = true;
  Bullet (float xc, float yc, float xvc, float yvc)
  {
    x = xc;
    y = yc;
    xv = xvc;
    yv = yvc;
  }
  void update()
  {
    if (alive)
    {
      x += xv;
      y += yv;
      yv += gravity/10;
      if (x < 0 || y < 0 || x > 1280 || y > 800)
      {
        alive = false;
      }
      for (int i = 0; i < Obstacles.size(); i++)
      {
        Obstacle ob = Obstacles.get(i);
        if (x > ob.x && x < ob.x + ob.l && y > ob.y && y < ob.y + ob.w && ob.life >= 0 && ob.isflashing == false)
        {
          alive = false;
          Explosions.add(new Explosion (x, y));
        }
      }
    }
  }
  void draw()
  {
    if (alive)
    {
      stroke(1);
      fill (0);
      strokeWeight(2);
      //line (x, y, x - xv/2, y - yv/2);
      ellipse(x*sF, y*sF, 6*sF, 6*sF);
      strokeWeight(1);
    }
  }
}

class Explosion
{
  float x;
  float y;
  float size = 1;
  boolean alive = true;
  Explosion (float xc, float yc)
  {
    x = xc;
    y = yc;
  }
  void update()
  {
    if (alive)
    {
      size += 4;
      if (size > 50)
      {
        alive = false;
      }
    }
  }
  void draw()
  {
    if (alive)
    {
      fill (200, 100, 100);
      noStroke();
      ellipse (x*sF, y*sF, size*sF, size*sF);
    }
  }
}

class Heavy
{
  float x;
  float y;
  float xv;
  float yv;
  boolean alive = true;
  int waitShot = 30;
  boolean on = false;
  boolean hit = false;
  boolean drawme = true;
  float count = 1;
  float f = 1.25;
  Heavy (float xc, float yc)
  {
    x = xc;
    y = yc;
  }
  void update()
  {
    if (hit == false && alive)
    {
      if (x > 10 || x < 1280 - 10 || y > 10 || y < 800 - 10 && on == false)
      {
        on = true;
      }
      x += xv;
      y += yv;
      yv += gravity/10;
      waitShot -= 1;
      for (int i = 0; i < Bullets.size(); i++)
      {
        Bullet bul = Bullets.get(i);
        if (dist (bul.x, bul.y, x, y) <= 38.5 && bul.alive == true)
        {
          hit = true;
          alive = false;
          Explosions.add(new Explosion (bul.x, bul.y));
          bul.alive = false;
        }
      }
      if (dist (x, y, play.x, play.y) < 20 && play.alive)
      {
        lifeCount = 99;
        play.alive = false;
        //play.x = random(1280); play.y = random(800);
        play.xv = 0;
        play.yv = 0;
        xv = 0;
        yv = 0;
      }
      if (waitShot <= 0)
      {
        if (Angle (x, y, play.x, play.y) > 260 || Angle (x, y, play.x, play.y) < 100)
        {
          if (dist (0, 0, xv, yv) > gravity*10.5)
          {
            xv += revAngleX (Angle (x, y, x - xv, y - yv), gravity * 10);
            yv += revAngleY (Angle (x, y, x - xv, y - yv), gravity * 10);
          } else
          {
          xv += revAngleX (Angle (x, y, play.x, play.y), gravity * 10);
          yv += revAngleY (Angle (x, y, play.x, play.y), gravity * 10);
          }
        }
        waitShot = 70;
      }
      if (on == true)
      {
        if (x < 10 || x > 1280 - 10)
        {
          xv *= -0.15;
          yv /= f;
          if (x < 10)
          {
            x = 11;
          } else {x = 1280 - 11;}
        }
        if (y < 10 || y > 800 - 10)
        {
          yv *= -0.15;
          xv /= f;
          if (y < 10)
          {
            y = 11;
          } else {y = 800 - 11;}
        }
      }
      for (int i = 0; i < Obstacles.size(); i++)
      {
        Obstacle ob = Obstacles.get(i);
        if (x < ob.x + ob.l + 10 && x > ob.x - 10 && y < ob.y + ob.w + 10 && y > ob.y - 10 && ob.life >= 0)
        {
          if (x < ob.x && index(xv) == 1)
          {
            xv *= -0.15;
            yv /= f;
            x = ob.x - 10;
          }
          if (x > ob.x + ob.l - 10 && index(xv) == -1)
          {
            xv *= -0.15;
            yv /= f;
            x = ob.x + ob.l + 10;
          }
          if (y < ob.y && index(yv) == 1)
          {
            yv *= -0.15;
            xv /= f;
            y = ob.y - 10;
          }
          if (y > ob.y + ob.w - 10 && index(yv) == -1)
          {
            yv *= -0.15;
            xv /= f;
            y = ob.y + ob.w + 10;
          }
        }
      }
    }
  }
  void draw()
  {
    if (drawme)
    {
      fill (150, 100, 100, 0.75*lifeCount*count);
      stroke (200, 100, 100, 1.50*lifeCount*count);
      strokeWeight(2);
      line (x*sF, y*sF, (x + revAngleX (Angle (x, y, play.x, play.y), 35))*sF, (y + revAngleY (Angle (x, y, play.x, play.y), 35))*sF);
      strokeWeight (1);
      ellipse (x*sF, y*sF, 70*sF, 70*sF);
      fill (150, 100, 100, 2.55*lifeCount*count);
      noStroke();
      ellipse (x*sF, y*sF, 20*sF, 20*sF);
      if (hit)
      {
        count -= 0.02;
      }
      if (count <= 0)
      {
        drawme = false;
      }
    }
  }
}

float index(float x)
{
  return x/abs(x);
}

class Obstacle
{
  float x;
  float y;
  float l;
  float w;
  boolean isflashing = true;
  float flashinit = 6;
  float flash = flashinit;
  float flashLength = setFlash;
  float life = 1000; 
  Obstacle (float xc, float yc, float lc, float wc)
  {
    x = xc;
    y = yc;
    l = lc;
    w = wc;
    numObsCurrent++;
  }
  void flashing()
  {
    life -= 1;
    if (life < 50)
    {
      isflashing = true;
      flashLength = 100;
    }
    if (isflashing && flashLength >= 0 && life >= 0)
    {
      flash -= 1;
      flashLength -= 1;
      if (flashLength <= 0)
      {
        isflashing = false;
      }
      if (flash <= 0)
      {
        flash = flashinit;
      }
      if (flash > flashinit/2)
      {
        fill (0, 0, 200, obFade/2.55);
      } else {fill (0, 0, 200, 0);}
      rect (x*sF, y*sF, l*sF, w*sF, 2);
    }
  }
  void draw()
  {
    if (isflashing == false && life >= 0)
    {
      noStroke();
      fill (100, 100, 100, obFade/3);
      rect ((x-5)*sF, (y-5)*sF, l*sF, w*sF, 2);
      fill (0, 0, 200, obFade);
      rect (x*sF, y*sF, l*sF, w*sF, 2);
    }
  }
  void checkCol(Player play)
  {
    if (play.x > x - 10 && play.y > y - 10 && play.x < x + l + 10 && play.y < y + w + 10 && isflashing == false && life >= 1 && play.alive == true)
    {
      if (menu == false)
      {
        lifeCount = 99;
        play.alive = false;
      } else {play.x = random(1280); play.y = random(800);}
      play.xv = 0;
      play.yv = 0;
    }
  }
}

class Player
{
  float x;
  float y;
  float xv;
  float yv;
  boolean alive = true;
  Player (float xc, float yc)
  {
    x = xc;
    y = yc;
    xv = 0;
    yv = 0;
  }
  void update()
  {
    if (alive == true)
    {
      x += xv;
      y += yv;
      yv += gravity/10;
      if (x < 10 || y < 10 || x > 1280 - 10 || y > 800 - 10)
      {
        if (menu == false)
        {
          alive = false;
          lifeCount = 99;
        } else {x = random(1280); y = random(800);}
        xv = 0;
        yv = 0;
      }
    }
  }
  void draw()
  {
    stroke (0, 0, 200, lineVal*(lifeCount/100));
    strokeWeight (str);
    if (alive && menu == false)
    {
    line (x*sF, y*sF, map(mouseX, 0, width, 0, 1280)*sF, map(mouseY, 0, height, 0, 800)*sF);
    }
    fill (100, 100, 200, 0.75*lifeCount);
    ellipse (x*sF, y*sF, 75*sF, 75*sF);
    noStroke();
    fill (100, 100, 200, 2.55*lifeCount);
    ellipse (x*sF, y*sF, 20*sF, 20*sF);
  }
}

float Angle(float x, float y, float endx, float endy)
{
  float Angle = 0;
  float angle = (degrees(acos((endx - x)/dist(x, y, endx, endy))));
  if (angle <= 90 && endy <= y)
  {
    Angle = 90 - angle;
  }
  if (angle > 90 && endy <= y)
  {
    Angle = 450 - angle;
  }
  if (endy > y)
  {
    Angle = angle + 90;
  }
  return Angle;
}
float findAngle (float angle1, float angle2)
{
  if (max (angle1, angle2) - min (angle1, angle2) <= 180)
  {
    return max (angle1, angle2) - min (angle1, angle2);
  } else {return 360 - max (angle1, angle2) + min (angle1, angle2);}
}
float revAngleX (float Angle, float length)
{
  if (Angle < 90 && Angle >= 0)
  {
    return cos(radians(-(Angle - 90))) * length;
  }
  if (Angle < 180 && Angle >= 90)
  {
    return cos(radians(Angle - 90)) * length;
  }
  if (Angle < 270 && Angle >= 180)
  {
    return cos(radians(Angle - 90)) * length;
  }
  if (Angle < 360 && Angle >= 270)
  {
    return cos(radians(-(Angle - 450))) * length;
  }else {return 0;}
}
float revAngleY (float Angle, float length)
{
  float y =  sqrt(sq (length) - sq (revAngleX (Angle, length)));
  if ((Angle > 270 && Angle <= 360) || (Angle > 0 && Angle <=90))
  {
    return -y;
  } else {return y;}
}
