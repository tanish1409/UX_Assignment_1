import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import org.jbox2d.dynamics.joints.*;

// Physics + Game objects
Box2DProcessing box2d;
ArrayList<Block> blocks;
Ground ground;
Crane crane;

boolean gameOver = false;
boolean levelComplete = false;
int level = 1;
int totalBlocks = 5;
int blocksDropped = 0;
float targetHeight = 150;  // pixels above ground
float currentHeight = 0;

void setup() {
  size(600, 600);
  smooth();
  initWorld();
}

void draw() {
  background(180, 210, 255);
  box2d.step();

  ground.display();

  // --- GAME STATE ---
  if (!gameOver && !levelComplete) {
    crane.update();
    crane.display();

    for (Block b : blocks) {
      b.display();
      if (b.offScreen()) gameOver = true;
    }

    calculateTowerHeight();
    checkWinOrLoss();
  } else if (gameOver) {
    showMessage("😢 GAME OVER", "Click to restart");
  } else if (levelComplete) {
    showMessage("🎉 Level " + level + " Complete!", "Click to continue");
  }

  displayHUD();
}

void mousePressed() {
  if (gameOver) {
    restartGame();
    return;
  }
  if (levelComplete) {
    nextLevel();
    return;
  }

  // Drop a block
  if (crane.holdingBlock && blocksDropped < totalBlocks) {
    Block newBlock = new Block(crane.x, crane.y + 50, crane.blockWidth, 30);
    newBlock.drop();
    blocks.add(newBlock);
    crane.holdingBlock = false;
    blocksDropped++;
  }
}

// =========================================
// GAME FUNCTIONS
// =========================================
void initWorld() {
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -25);

  blocks = new ArrayList<Block>();
  ground = new Ground(width/2, height - 10, width, 20);
  crane = new Crane();

  gameOver = false;
  levelComplete = false;
  blocksDropped = 0;
  currentHeight = 0;
}

void restartGame() {
  level = 1;
  totalBlocks = 5;
  targetHeight = 150;
  initWorld();
}

void nextLevel() {
  level++;
  totalBlocks += 1;
  targetHeight += 40;
  initWorld();
}

void calculateTowerHeight() {
  if (blocks.isEmpty()) {
    currentHeight = 0;
    return;
  }
  float minY = height;
  for (Block b : blocks) {
    Vec2 pos = box2d.getBodyPixelCoord(b.body);
    if (pos.y < minY) minY = pos.y;
  }
  currentHeight = height - minY;
}

void checkWinOrLoss() {
  // Win if tower reaches target and all blocks are settled
  if (blocksDropped == totalBlocks && allBlocksRested()) {
    if (currentHeight >= targetHeight) {
      levelComplete = true;
    } else {
      gameOver = true;
    }
  }
}

boolean allBlocksRested() {
  for (Block b : blocks) {
    if (b.body.isAwake()) return false;
  }
  return true;
}

void showMessage(String main, String sub) {
  textAlign(CENTER);
  fill(0);
  textSize(36);
  text(main, width/2, height/2 - 20);
  textSize(20);
  text(sub, width/2, height/2 + 20);
}

void displayHUD() {
  fill(0);
  textSize(14);
  textAlign(LEFT);
  text("Level: " + level, 20, 25);
  text("Blocks: " + blocksDropped + "/" + totalBlocks, 20, 45);
  text("Height: " + int(currentHeight) + " / " + int(targetHeight), 20, 65);

  // Target line
  stroke(255, 0, 0);
  line(0, height - targetHeight, width, height - targetHeight);
  noStroke();
  fill(255, 0, 0);
  textAlign(RIGHT);
  text("Target", width - 10, height - targetHeight - 5);
}

// =========================================
// CRANE CLASS
// =========================================
class Crane {
  float x, y;
  float speed = 2;
  boolean movingRight = true;
  boolean holdingBlock = true;
  float blockWidth;

  Crane() {
    x = width/2;
    y = 100;
    blockWidth = 80;
  }

  void update() {
    if (movingRight) x += speed;
    else x -= speed;

    if (x > width - 60) movingRight = false;
    if (x < 60) movingRight = true;

    // Ready new block
    if (!holdingBlock && blocksDropped < totalBlocks) {
      holdingBlock = true;
    }
  }

  void display() {
    stroke(0);
    fill(255, 200, 0);
    rectMode(CENTER);
    rect(x, y, 100, 20);
    line(x, y + 10, x, y + 40);

    if (holdingBlock) {
      fill(100, 120, 255);
      rect(x, y + 60, blockWidth, 30);
    }
  }
}

// =========================================
// BLOCK CLASS
// =========================================
class Block {
  Body body;
  float w, h;

  Block(float x, float y, float w, float h) {
    this.w = w;
    this.h = h;
    makeBody(new Vec2(x, y));
  }

  void makeBody(Vec2 center) {
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position = box2d.coordPixelsToWorld(center);
    bd.linearDamping = 0.05;
    bd.angularDamping = 0.1;
    body = box2d.createBody(bd);

    PolygonShape ps = new PolygonShape();
    float box2Dw = box2d.scalarPixelsToWorld(w/2);
    float box2Dh = box2d.scalarPixelsToWorld(h/2);
    ps.setAsBox(box2Dw, box2Dh);

    FixtureDef fd = new FixtureDef();
    fd.shape = ps;
    fd.density = 1.0;
    fd.friction = 0.6;
    fd.restitution = 0.1;
    body.createFixture(fd);

    body.setActive(false);
  }

  void drop() {
    body.setActive(true);
  }

  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = -body.getAngle();
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(a);
    fill(100, 120, 255);
    stroke(0);
    rectMode(CENTER);
    rect(0, 0, w, h);
    popMatrix();
  }

  boolean offScreen() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    return (pos.y > height + 50);
  }
}

// =========================================
// GROUND CLASS
// =========================================
class Ground {
  Body body;
  float w, h;

  Ground(float x, float y, float w, float h) {
    this.w = w;
    this.h = h;
    makeBody(new Vec2(x, y));
  }

  void makeBody(Vec2 center) {
    BodyDef bd = new BodyDef();
    bd.position = box2d.coordPixelsToWorld(center);
    body = box2d.createBody(bd);
    PolygonShape ps = new PolygonShape();
    float box2Dw = box2d.scalarPixelsToWorld(w/2);
    float box2Dh = box2d.scalarPixelsToWorld(h/2);
    ps.setAsBox(box2Dw, box2Dh);
    body.createFixture(ps, 1);
  }

  void display() {
    fill(100, 70, 40);
    noStroke();
    rectMode(CENTER);
    rect(width/2, height - 10, w, h);
  }
}
