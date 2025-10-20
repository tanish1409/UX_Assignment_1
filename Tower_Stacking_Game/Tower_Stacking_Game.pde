// Import required libraries for Box2D physics
import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;

// Main physics world
Box2DProcessing box2d;

// Store all falling blocks
ArrayList<Block> blocks;

// Ground surface at the bottom of the screen
Ground ground;

// Crane that moves left and right
Crane crane;

// Small visual effects when dropping blocks
ArrayList<Particle> particles;

// Game state variables
boolean gameOver = false;
boolean levelComplete = false;
int level = 1;
int totalBlocks = 5;
int blocksDropped = 0;
float targetHeight = 100;
float currentHeight = 0;
float stableStartTime = 0;
boolean stabilityTimerRunning = false;
float stabilityDuration = 5;      // How many seconds tower must stay stable
boolean countdownTriggered = false;
float countdownAlpha = 0;         // Controls fade in/out of countdown text

// Color palette for the game
color skyColor = color(135, 206, 250);
color skyColorBottom = color(200, 220, 255);
color groundColor = color(139, 90, 43);
color craneColor = color(255, 165, 0);
color blockColor = color(70, 130, 220);
color targetLineColor = color(255, 50, 50);

// Runs once when program starts
void setup() {
  size(600, 600);     // Window size
  smooth();           // Makes shapes look smoother
  initWorld();        // Create the game world and physics
}

// Runs every frame (main game loop)
void draw() {
  // Draw gradient background (top to bottom)
  for (int i = 0; i < height; i++) {
    float inter = map(i, 0, height, 0, 1);
    color c = lerpColor(skyColor, skyColorBottom, inter);
    stroke(c);
    line(0, i, width, i);
  }
  noStroke();

  // Draw decorative clouds on top
  drawClouds();

  // Reset rectangle drawing mode
  rectMode(CORNER);

  // Step the physics engine
  box2d.step();

  // Draw ground
  ground.display();

  // Draw the target height line
  drawTargetLine();

  // Handle main game states
  if (!gameOver && !levelComplete) {
    crane.update();        // Move crane trolley
    crane.display();       // Draw crane graphics

    // Show all blocks and check for falling out of screen
    for (Block b : blocks) {
      b.display();
      if (b.offScreen()) gameOver = true;
    }

    // Check height and conditions
    calculateTowerHeight();
    checkWinOrLoss();
    displayCountdown();
  } 
  else if (gameOver) {
    // If player lost, still draw everything but show message
    crane.display();
    for (Block b : blocks) b.display();
    showMessage("GAME OVER!", "Click to restart");
  } 
  else if (levelComplete) {
    // If player won, still draw everything but show message
    crane.display();
    for (Block b : blocks) b.display();
    showMessage("Level " + level + " Complete!", "Click to continue");
  }

  // Draw particle effects
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) particles.remove(i);
  }

  // Show HUD (level, blocks used, progress bar)
  displayHUD();
}

// Handles mouse clicks
void mousePressed() {
  // Restart if game over
  if (gameOver) {
    restartGame();
    return;
  }
  // Go to next level if complete
  if (levelComplete) {
    nextLevel();
    return;
  }

  // Drop new block from crane
  if (crane.holdingBlock && blocksDropped < totalBlocks) {
    Block newBlock = new Block(crane.x, crane.y + 100, 60, 40);
    newBlock.drop();
    blocks.add(newBlock);
    crane.holdingBlock = false;
    blocksDropped++;

    // Add particles for visual effect
    for (int i = 0; i < 10; i++) {
      particles.add(new Particle(crane.x, crane.y + 100));
    }
  }
}

// Set up physics world and reset variables
void initWorld() {
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -30);  // Negative = downward gravity

  blocks = new ArrayList<Block>();
  particles = new ArrayList<Particle>();
  ground = new Ground(width / 2, height - 10, width, 20);
  crane = new Crane();
  gameOver = false;
  levelComplete = false;
  blocksDropped = 0;
  currentHeight = 0;
}

// Restart the game at level 1
void restartGame() {
  level = 1;
  totalBlocks = 5;
  targetHeight = 60;
  initWorld();
}

// Load next level with new target
void nextLevel() {
  level++;
  totalBlocks += 1;
  targetHeight += 40;
  initWorld();
}

// Calculate the stable height of the tower
void calculateTowerHeight() {
  if (blocks.isEmpty()) {
    currentHeight = 0;
    return;
  }

  float minY = height; // Find top block position

  // Loop through all blocks
  for (Block b : blocks) {
    // Skip blocks still moving
    if (b.body.isAwake()) {
      continue;
    }

    // Find highest stable block
    Vec2 pos = box2d.getBodyPixelCoord(b.body);
    if (pos.y < minY) {
      minY = pos.y;
    }
  }

  // If no stable block, height is 0
  if (minY == height) {
     currentHeight = 0;
     return;
  }

  // Convert screen Y to tower height from ground
  currentHeight = height - minY;
}

// Check if player won or lost
void checkWinOrLoss() {
  // If tower crosses target height, start countdown
  if (currentHeight >= targetHeight) {
    if (!stabilityTimerRunning && !countdownTriggered) {
      stabilityTimerRunning = true;
      countdownTriggered = true;
      stableStartTime = millis();
    } else if (stabilityTimerRunning) {
      // Win after staying stable long enough
      if (millis() - stableStartTime > stabilityDuration * 1000) {
        levelComplete = true;
      }
    }
  } else {
    // Reset countdown if tower dips below target
    stabilityTimerRunning = false;
    countdownTriggered = false;
  }

  // Lose if any block falls
  for (Block b : blocks) {
    if (b.offScreen()) {
      gameOver = true;
      return;
    }
  }

  // Lose if all blocks are used but not tall enough
  if (blocksDropped == totalBlocks && !stabilityTimerRunning && currentHeight < targetHeight) {
    boolean allSleeping = true;
    for (Block b : blocks) {
      if (b.body.isAwake()) {
        allSleeping = false;
        break;
      }
    }
    if (allSleeping) {
      gameOver = true;
    }
  }
}

// Show message box for game over / next level
void showMessage(String main, String sub) {
  // Dark transparent overlay
  rectMode(CORNER);
  fill(0, 0, 0, 150);
  noStroke();
  rect(0, 0, width, height);

  // White message box
  rectMode(CENTER);
  fill(255);
  stroke(100);
  strokeWeight(3);
  rect(width/2, height/2, 400, 200, 20);

  // Title text
  textAlign(CENTER);
  fill(0);
  textSize(48);
  text(main, width/2, height/2 - 20);

  // Sub text
  textSize(18);
  fill(100);
  text(sub, width/2, height/2 + 30);

  // Button shape
  fill(50, 150, 250);
  stroke(30, 100, 200);
  strokeWeight(2);
  rect(width/2, height/2 + 70, 200, 50, 10);
  fill(255);
  textSize(20);
  text(gameOver ? "RESTART" : "NEXT LEVEL", width/2, height/2 + 78);
}

// Countdown display when tower crosses target
void displayCountdown() {
  if (stabilityTimerRunning) {
    float elapsed = (millis() - stableStartTime) / 1000;
    float remaining = stabilityDuration - elapsed;
    if (remaining >= 0) {
      countdownAlpha = lerp(countdownAlpha, 255, 0.1);
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(255, countdownAlpha);
      text(ceil(remaining), width / 2, height / 2);
    }
  } else {
    // Fade out if countdown stops
    if (countdownAlpha > 0.5) {
      countdownAlpha = lerp(countdownAlpha, 0, 0.1);
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(255, countdownAlpha);
    } else {
      countdownAlpha = 0;
    }
  }
}

// Heads-Up Display with level info
void displayHUD() {
  fill(255, 255, 255, 220);
  stroke(150);
  strokeWeight(2);
  rectMode(CORNER);
  rect(10, 10, 200, 70, 10);

  // Level and block counter
  fill(0);
  textSize(14);
  textAlign(LEFT);
  noStroke();
  text("Level: " + level, 20, 30);
  text("Blocks: " + blocksDropped + "/" + totalBlocks, 20, 50);

  // Tower height progress bar
  fill(200);
  noStroke();
  rect(20, 55, 170, 15, 7);
  fill(50, 200, 50);
  float progress = constrain(currentHeight / targetHeight, 0, 1);
  rect(20, 55, 170 * progress, 15, 7);

  fill(0);
  textSize(11);
  text(int(currentHeight) + " / " + int(targetHeight) + " px", 25, 67);
}

// Draw red dashed target height line
void drawTargetLine() {
  float targetY = height - 10 - targetHeight;
  strokeWeight(3);
  stroke(targetLineColor);

  // Dashed effect
  for (int i = 0; i < width; i += 20) {
    line(i, targetY, i + 10, targetY);
  }

  // Small label box
  noStroke();
  fill(targetLineColor);
  rectMode(CORNER);
  rect(width - 80, targetY - 25, 70, 20, 5);
  fill(255);
  textAlign(CENTER);
  textSize(12);
  text("TARGET", width - 45, targetY - 11);
}

// Simple white clouds for decoration
void drawClouds() {
  fill(255, 255, 255, 180);
  noStroke();

  // Each group of ellipses makes a cloud
  ellipse(100, 80, 60, 30);
  ellipse(120, 75, 50, 35);
  ellipse(140, 80, 55, 30);

  ellipse(320, 100, 70, 35);
  ellipse(345, 95, 60, 40);
  ellipse(370, 100, 65, 35);

  ellipse(500, 60, 50, 25);
  ellipse(520, 57, 45, 30);
  ellipse(540, 60, 50, 25);
}
// -------------------------
// CRANE CLASS
// -------------------------
// The crane moves automatically left and right, and holds/drops blocks.
class Crane {
  float x, y;               // Current position of trolley
  float craneX;             // Fixed crane base position
  float speed = 2.5;        // Speed of trolley movement
  boolean movingRight = true;
  boolean holdingBlock = true;
  float jibLength = width - 100;  // Length of crane arm
  float jibHeight = 30;           // Height of crane arm structure
  float trolleyPos = 0;           // Horizontal position along jib

  Crane() {
    craneX = width / 6;   // Place crane base on left side
    y = 90;               // Height from top of window
    x = craneX;           // Start at base
    trolleyPos = 0;
  }

  void update() {
    // Move the trolley back and forth
    if (movingRight) trolleyPos += speed;
    else trolleyPos -= speed;

    // Limit how far trolley can go (avoid hitting tower)
    float towerRightEdge = -40 + 12.5;
    float blockHalfWidth = 30;
    float safetyMargin = 5;
    float leftBoundary = towerRightEdge + blockHalfWidth + safetyMargin;

    leftBoundary = -27.5 + 30 + 5;

    // Reverse direction if it reaches edges
    if (trolleyPos > jibLength - 30) movingRight = false;
    if (trolleyPos < leftBoundary) movingRight = true;

    // Update x position based on trolley
    x = craneX + trolleyPos;

    // If not holding anything and blocks are left, grab next
    if (!holdingBlock && blocksDropped < totalBlocks) {
      holdingBlock = true;
    }
  }

  void display() {
    pushStyle();

    // Draw main crane structure
    pushMatrix();
    translate(craneX, y);

    color craneRed = color(200, 30, 30);
    color craneDarkRed = color(150, 20, 20);

    drawJib(craneRed, craneDarkRed);
    pushMatrix();
    scale(-1, 1);                // Mirror to draw counterweight
    drawCounterweight(craneRed, craneDarkRed);
    popMatrix();

    drawTower(craneRed);         // Draw vertical tower
    popMatrix();

    // Draw moving parts
    drawTrolley();               // The moving cab
    drawCable();                 // Hanging cable
    if (holdingBlock) drawBlock(); // Draw the hanging block

    popStyle();
  }

  // Draw the horizontal crane arm with lattice pattern
  void drawJib(color mainColor, color darkColor) {
    strokeWeight(3);
    stroke(darkColor);

    line(0, 0, jibLength, 0);
    line(0, jibHeight, jibLength, jibHeight);

    // Calculate spacing between lattice segments
    float maxLatticeWidth = 40;
    float minLatticeWidth = 20;
    int numSections = round(jibLength / maxLatticeWidth);
    if (numSections < 1) numSections = 1;
    float latticeSpacing = jibLength / numSections;

    // Adjust spacing to keep it neat
    while (latticeSpacing > maxLatticeWidth && numSections < 50) {
      numSections++;
      latticeSpacing = jibLength / numSections;
    }
    while (latticeSpacing < minLatticeWidth && numSections > 1) {
      numSections--;
      latticeSpacing = jibLength / numSections;
    }

    strokeWeight(2);
    stroke(mainColor);

    // Draw vertical supports
    for (int i = 0; i <= numSections; i++) {
      float xPos = i * latticeSpacing;
      line(xPos, 0, xPos, jibHeight);
    }

    // Draw X-pattern diagonal bracing
    for (int i = 0; i < numSections; i++) {
      float xStart = i * latticeSpacing;
      float xEnd = (i + 1) * latticeSpacing;
      line(xStart, 0, xEnd, jibHeight);
      line(xStart, jibHeight, xEnd, 0);
    }

    // End line
    strokeWeight(3);
    stroke(darkColor);
    line(jibLength, 0, jibLength, jibHeight);
  }

  // Draw smaller counterweight arm on the opposite side
  void drawCounterweight(color mainColor, color darkColor) {
    float cwLength = 80;
    strokeWeight(3);
    stroke(darkColor);
    line(0, 0, cwLength, 0);
    line(0, jibHeight, cwLength, jibHeight);

    // Repeat lattice logic for shorter arm
    float maxLatticeWidth = 40;
    float minLatticeWidth = 20;
    int numSections = round(cwLength / maxLatticeWidth);
    if (numSections < 1) numSections = 1;
    float latticeSpacing = cwLength / numSections;
    while (latticeSpacing > maxLatticeWidth && numSections < 50) {
      numSections++;
      latticeSpacing = cwLength / numSections;
    }
    while (latticeSpacing < minLatticeWidth && numSections > 1) {
      numSections--;
      latticeSpacing = cwLength / numSections;
    }

    strokeWeight(2);
    stroke(mainColor);
    for (int i = 0; i <= numSections; i++) {
      float xPos = i * latticeSpacing;
      line(xPos, 0, xPos, jibHeight);
    }
    for (int i = 0; i < numSections; i++) {
      float xStart = i * latticeSpacing;
      float xEnd = (i + 1) * latticeSpacing;
      line(xStart, 0, xEnd, jibHeight);
      line(xStart, jibHeight, xEnd, 0);
    }

    // Draw weight box at end
    fill(100);
    stroke(50);
    strokeWeight(2);
    rectMode(CORNER);
    rect(cwLength, 5, 25, 20);
  }

  // Draw the tall vertical tower with X bracing
  void drawTower(color mainColor) {
    float towerX = -40;
    float towerWidth = 25;
    float towerBottom = height - 20 - y - jibHeight;

    float maxLatticeHeight = 40;
    float minLatticeHeight = 25;
    int numSections = round(towerBottom / maxLatticeHeight);
    if (numSections < 1) numSections = 1;
    float latticeSpacing = towerBottom / numSections;
    while (latticeSpacing > maxLatticeHeight && numSections < 50) {
      numSections++;
      latticeSpacing = towerBottom / numSections;
    }
    while (latticeSpacing < minLatticeHeight && numSections > 1) {
      numSections--;
      latticeSpacing = towerBottom / numSections;
    }

    stroke(mainColor);
    strokeWeight(3);
    line(towerX - towerWidth/2, jibHeight, towerX - towerWidth/2, jibHeight + towerBottom);
    line(towerX + towerWidth/2, jibHeight, towerX + towerWidth/2, jibHeight + towerBottom);

    strokeWeight(2);
    for (int i = 0; i <= numSections; i++) {
      float yPos = jibHeight + (i * latticeSpacing);
      line(towerX - towerWidth/2, yPos, towerX + towerWidth/2, yPos);
    }

    // X bracing per section
    for (int i = 0; i < numSections; i++) {
      float yStart = jibHeight + (i * latticeSpacing);
      float yEnd = jibHeight + ((i + 1) * latticeSpacing);
      line(towerX - towerWidth/2, yStart, towerX + towerWidth/2, yEnd);
      line(towerX + towerWidth/2, yStart, towerX - towerWidth/2, yEnd);
    }

    fill(mainColor);
    noStroke();
    circle(towerX, jibHeight, 10);
  }

  // Draw the moving trolley (the cab)
  void drawTrolley() {
    pushMatrix();
    translate(x, y);
    fill(220, 50, 50);
    stroke(0);
    strokeWeight(2);
    rectMode(CENTER);
    rect(0, jibHeight/2, 18, 25);
    fill(150, 200, 255);
    noStroke();
    rect(0, jibHeight/2 - 3, 12, 12);
    fill(80);
    circle(-6, 3, 6);
    circle(6, 3, 6);
    popMatrix();
  }

  // Draw cable hanging from trolley
  void drawCable() {
    strokeWeight(2);
    stroke(60, 60, 60);
    line(x, y + jibHeight, x, y + 80);
    fill(80);
    noStroke();
    circle(x, y + jibHeight, 8);
  }

  // Draw the wooden block currently hanging from the crane
  void drawBlock() {
    strokeWeight(2);
    stroke(100);
    line(x, y + 80, x, y + 85);

    pushMatrix();
    translate(x, y + 105);

    fill(180, 120, 60);
    stroke(100, 60, 30);
    strokeWeight(2);
    rectMode(CENTER);
    rect(0, 0, 60, 40, 2);

    stroke(140, 90, 45);
    strokeWeight(2);
    float plankSpacing = 60 / 5;
    for (float xPos = -30 + plankSpacing; xPos < 30; xPos += plankSpacing) {
      line(xPos, -20, xPos, 20);
    }

    stroke(120, 75, 35);
    strokeWeight(3);
    line(-27, -17, 27, 17);
    line(27, -17, -27, 17);

    fill(80, 80, 80);
    noStroke();
    circle(-25, -15, 4);
    circle(25, -15, 4);
    circle(-25, 15, 4);
    circle(25, 15, 4);

    fill(200, 140, 80, 100);
    noStroke();
    rect(0, -10, 52, 10);

    popMatrix();
  }
}
// -------------------------
// BLOCK CLASS
// -------------------------
// Each Block is a wooden crate with its own physics body
class Block {
  Body body;
  float w, h;
  boolean dropped = false;

  Block(float x, float y, float w, float h) {
    this.w = w;
    this.h = h;
    makeBody(new Vec2(x, y));
  }

  // Create a Box2D body for this block
  void makeBody(Vec2 center) {
    BodyDef bd = new BodyDef();
    bd.type = BodyType.DYNAMIC;
    bd.position = box2d.coordPixelsToWorld(center);
    bd.linearDamping = 0.05;
    bd.angularDamping = 0.05;
    body = box2d.createBody(bd);

    PolygonShape ps = new PolygonShape();
    float box2Dw = box2d.scalarPixelsToWorld(w / 2);
    float box2Dh = box2d.scalarPixelsToWorld(h / 2);
    ps.setAsBox(box2Dw, box2Dh);

    FixtureDef fd = new FixtureDef();
    fd.shape = ps;
    fd.density = 1.0;
    fd.friction = 0.7;
    fd.restitution = 0.05; // slight bounce
    body.createFixture(fd);
    body.setActive(false);
  }

  // Activate the block so it starts falling
  void drop() {
    dropped = true;
    body.setActive(true);
  }

  // Draw the block with a shadow and wood texture
  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = -body.getAngle();

    // Shadow
    pushMatrix();
    translate(pos.x + 3, pos.y + 3);
    rotate(a);
    fill(0, 0, 0, 50);
    noStroke();
    rectMode(CENTER);
    rect(0, 0, w, h);
    popMatrix();

    // Actual crate
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(a);
    fill(180, 120, 60);
    stroke(100, 60, 30);
    strokeWeight(2);
    rectMode(CENTER);
    rect(0, 0, w, h, 2);

    stroke(140, 90, 45);
    strokeWeight(2);
    float plankSpacing = w / 5;
    for (float x = -w/2 + plankSpacing; x < w/2; x += plankSpacing) {
      line(x, -h/2, x, h/2);
    }

    stroke(120, 75, 35);
    strokeWeight(3);
    line(-w/2 + 3, -h/2 + 3, w/2 - 3, h/2 - 3);
    line(w/2 - 3, -h/2 + 3, -w/2 + 3, h/2 - 3);

    fill(80, 80, 80);
    noStroke();
    float cornerOffset = 5;
    circle(-w/2 + cornerOffset, -h/2 + cornerOffset, 4);
    circle(w/2 - cornerOffset, -h/2 + cornerOffset, 4);
    circle(-w/2 + cornerOffset, h/2 - cornerOffset, 4);
    circle(w/2 - cornerOffset, h/2 - cornerOffset, 4);

    fill(200, 140, 80, 100);
    noStroke();
    rect(0, -h/4, w - 8, h/4);

    popMatrix();
  }

  // Check if block has fallen below the screen
  boolean offScreen() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    return (pos.y > height + 100);
  }
}
// -------------------------
// GROUND CLASS
// -------------------------
// Ground is a static Box2D body at the bottom where blocks land
class Ground {
  Body body;
  float w, h;

  Ground(float x, float y, float w, float h) {
    this.w = w;
    this.h = h;
    makeBody(new Vec2(x, y));
  }

  // Create a static ground body
  void makeBody(Vec2 center) {
    BodyDef bd = new BodyDef();
    bd.position = box2d.coordPixelsToWorld(center);
    body = box2d.createBody(bd);

    PolygonShape ps = new PolygonShape();
    float box2Dw = box2d.scalarPixelsToWorld(w / 2);
    float box2Dh = box2d.scalarPixelsToWorld(h / 2);
    ps.setAsBox(box2Dw, box2Dh);
    body.createFixture(ps, 1);
  }

  // Draw concrete ground with slab pattern
  void display() {
    fill(80, 50, 20);
    noStroke();
    rectMode(CENTER);
    rect(width/2, height - 5, w, 10);

    int slabWidth = 90;
    for (int i = 0; i < width; i += slabWidth) {
      if ((i / slabWidth) % 2 == 0) fill(140, 140, 145);
      else fill(130, 130, 135);
      rectMode(CORNER);
      rect(i, height - 20, slabWidth, 20);
    }

    stroke(100, 100, 105);
    strokeWeight(3);
    for (int i = 0; i < width; i += slabWidth) {
      line(i, height - 18, i, height);
    }

    noStroke();
  }
}
// -------------------------
// PARTICLE CLASS
// -------------------------
// Small fading particles shown when a block is dropped
class Particle {
  float x, y;
  float vx, vy;
  float life = 255;

  Particle(float x, float y) {
    this.x = x;
    this.y = y;
    vx = random(-2, 2);       // Small random velocity
    vy = random(-3, -1);
  }

  // Update position and fade out
  void update() {
    x += vx;
    y += vy;
    vy += 0.2;               // Simulated gravity
    life -= 8;               // Fade out over time
  }

  // Draw the particle as a glowing circle
  void display() {
    noStroke();
    fill(255, 200, 100, life);
    circle(x, y, 6);
  }

  // Check if particle is fully faded
  boolean isDead() {
    return life < 0;
  }
}
