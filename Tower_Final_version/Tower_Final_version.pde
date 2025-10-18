import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;

Box2DProcessing box2d;
ArrayList<Block> blocks;
Ground ground;
Crane crane;
ArrayList<Particle> particles;

boolean gameOver = false;
boolean levelComplete = false;
int level = 1;
int totalBlocks = 5;
int blocksDropped = 0;
float targetHeight = 100;
float currentHeight = 0;
float stableStartTime = 0;
boolean stabilityTimerRunning = false;
float stabilityDuration = 5; // seconds to stay above target for win
boolean countdownTriggered = false; // tracks if countdown already started for this crossing
float countdownAlpha = 0; // controls fade in/out of countdown



// Color scheme
color skyColor = color(135, 206, 250);
color skyColorBottom = color(200, 220, 255);
color groundColor = color(139, 90, 43);
color craneColor = color(255, 165, 0);
color blockColor = color(70, 130, 220);
color targetLineColor = color(255, 50, 50);

void setup() {
  size(600, 600);
  smooth();
  initWorld();
}

void draw() {
  // Gradient background
  for (int i = 0; i < height; i++) {
    float inter = map(i, 0, height, 0, 1);
    color c = lerpColor(skyColor, skyColorBottom, inter);
    stroke(c);
    line(0, i, width, i);
  }
  noStroke();
  
  // Draw simple clouds
  drawClouds();
  
  // Reset drawing modes to prevent artifacts
  rectMode(CORNER);
  
  box2d.step();

  ground.display();
  
  // Draw target line BEFORE game state messages
  drawTargetLine();

  if (!gameOver && !levelComplete) {
    crane.update();
    crane.display();

    for (Block b : blocks) {
      b.display();
      if (b.offScreen()) gameOver = true;
    }

    calculateTowerHeight();
    checkWinOrLoss();
    displayCountdown();
  } else if (gameOver) {
    // Draw crane and blocks even in game over state
    crane.display();
    for (Block b : blocks) {
      b.display();
    }
    showMessage("GAME OVER!", "Click to restart");
  } else if (levelComplete) {
    // Draw crane and blocks even in level complete state
    crane.display();
    for (Block b : blocks) {
      b.display();
    }
    showMessage("Level " + level + " Complete!", "Click to continue");
  }

  // Update and display particles
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) particles.remove(i);
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

  if (crane.holdingBlock && blocksDropped < totalBlocks) {
    Block newBlock = new Block(crane.x, crane.y + 100, 60, 40);
    newBlock.drop();
    blocks.add(newBlock);
    crane.holdingBlock = false;
    blocksDropped++;
    
    // Add particles
    for (int i = 0; i < 10; i++) {
      particles.add(new Particle(crane.x, crane.y + 100));
    }
  }
}

void initWorld() {
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  box2d.setGravity(0, -30);

  blocks = new ArrayList<Block>();
  particles = new ArrayList<Particle>();
  ground = new Ground(width / 2, height - 10, width, 20);
  crane = new Crane();
  gameOver = false;
  levelComplete = false;
  blocksDropped = 0;
  currentHeight = 0;
}

void restartGame() {
  level = 1;
  totalBlocks = 5;
  targetHeight = 60;
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

  float minY = height; // topmost block's position (lowest y-coordinate)
  
  // Find the highest resting block's position (minY)
  for (Block b : blocks) {
    // Only consider blocks that are either dropped AND sleeping (at rest)
    // OR blocks that have not been fully dropped yet (which shouldn't happen 
    // unless you change the logic, but this is the safest check).
    
    // The key condition is to ignore any block that is currently 'awake' 
    // (i.e., falling, sliding, or spinning).
    if (b.body.isAwake()) {
      continue; // Skip any block that is actively moving/unstable
    }
    
    // If the block is stable/sleeping, check its height
    Vec2 pos = box2d.getBodyPixelCoord(b.body);
    if (pos.y < minY) {
      minY = pos.y;
    }
  }

  // If after checking all sleeping blocks, minY is still 'height', it means
  // either the list is empty (handled above) or all blocks are currently moving.
  if (minY == height) {
     currentHeight = 0; // Or keep currentHeight as is, but resetting is cleaner.
     // In your game, if all blocks are moving, the tower has no stable height.
     return;
  }

  // Convert from screen coordinates (top-down) to height-from-ground
  currentHeight = height - minY;
}

void checkWinOrLoss() {
  // When tower crosses target height
  if (currentHeight >= targetHeight) {
    // Start countdown only once per crossing
    if (!stabilityTimerRunning && !countdownTriggered) {
      stabilityTimerRunning = true;
      countdownTriggered = true;
      stableStartTime = millis(); // start countdown
    } else if (stabilityTimerRunning) {
      // If tower stayed above target for full duration
      if (millis() - stableStartTime > stabilityDuration * 1000) {
        levelComplete = true;
      }
    }
  } else {
    // Reset everything if tower dips below
    stabilityTimerRunning = false;
    countdownTriggered = false;
  }

  // Loss: any block falls off screen
  for (Block b : blocks) {
    if (b.offScreen()) {
      gameOver = true;
      return;
    }
  }

  // Loss: all blocks used, not tall enough, and no countdown running
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

void showMessage(String main, String sub) {
  // Overlay
  rectMode(CORNER);
  fill(0, 0, 0, 150);
  noStroke();
  rect(0, 0, width, height);
  
  // Message box
  rectMode(CENTER);
  fill(255);
  stroke(100);
  strokeWeight(3);
  rect(width/2, height/2, 400, 200, 20);
  
  // Main text
  textAlign(CENTER);
  fill(0);
  textSize(48);
  text(main, width/2, height/2 - 20);
  
  // Sub text
  textSize(18);
  fill(100);
  text(sub, width/2, height/2 + 30);
  
  // Button
  fill(50, 150, 250);
  stroke(30, 100, 200);
  strokeWeight(2);
  rect(width/2, height/2 + 70, 200, 50, 10);
  fill(255);
  textSize(20);
  text(gameOver ? "RESTART" : "NEXT LEVEL", width/2, height/2 + 78);
}

void displayCountdown() {
  if (stabilityTimerRunning) {
    float elapsed = (millis() - stableStartTime) / 1000;
    float remaining = stabilityDuration - elapsed;
    if (remaining >= 0) {
      // Fade in quickly when countdown starts
      countdownAlpha = lerp(countdownAlpha, 255, 0.1);
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(255, countdownAlpha);
      text(ceil(remaining), width / 2, height / 2);  // ceil() to show rounded-up seconds
    }
  } else {
    // Fade out smoothly when countdown stops
    if (countdownAlpha > 0.5) {
      countdownAlpha = lerp(countdownAlpha, 0, 0.1);
      textAlign(CENTER, CENTER);
      textSize(100);
      fill(255, countdownAlpha);
      // Optional: can show a faint " " or just leave empty
    } else {
      countdownAlpha = 0;
    }
  }
}



void displayHUD() {
  // Semi-transparent panel for HUD
  fill(255, 255, 255, 220);
  stroke(150);
  strokeWeight(2);
  rectMode(CORNER);
  rect(10, 10, 200, 70, 10);
  
  // HUD text
  fill(0);
  textSize(14);
  textAlign(LEFT);
  noStroke();
  text("Level: " + level, 20, 30);
  text("Blocks: " + blocksDropped + "/" + totalBlocks, 20, 50);
  
  // Progress bar for height
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

// Draw target line (separated so it can be drawn before dialogs)
void drawTargetLine() {
  // Animated target line
  float targetY = height - 10 - targetHeight;
  strokeWeight(3);
  stroke(targetLineColor);
  
  // Dashed line effect
  for (int i = 0; i < width; i += 20) {
    line(i, targetY, i + 10, targetY);
  }
  
  // Target label with background
  noStroke();
  fill(targetLineColor);
  rectMode(CORNER);
  rect(width - 80, targetY - 25, 70, 20, 5);
  fill(255);
  textAlign(CENTER);
  textSize(12);
  text("TARGET", width - 45, targetY - 11);
}

// Draw simple clouds
void drawClouds() {
  fill(255, 255, 255, 180); // Semi-transparent white
  noStroke();
  
  // Cloud 1 - top left
  ellipse(100, 80, 60, 30);
  ellipse(120, 75, 50, 35);
  ellipse(140, 80, 55, 30);
  
  // Cloud 2 - top center
  ellipse(320, 100, 70, 35);
  ellipse(345, 95, 60, 40);
  ellipse(370, 100, 65, 35);
  
  // Cloud 3 - top right
  ellipse(500, 60, 50, 25);
  ellipse(520, 57, 45, 30);
  ellipse(540, 60, 50, 25);
}

// -------------------------
// CRANE CLASS
// -------------------------
class Crane {
  float x, y;  // x is the trolley position, y is crane height
  float craneX;  // Fixed crane center position
  float speed = 2.5;
  boolean movingRight = true;
  boolean holdingBlock = true;
  float jibLength = width-100;  // Length of crane arm
  float jibHeight = 30;   // Height of crane truss
  float trolleyPos = 0;   // Position of trolley along jib

  Crane() {
    craneX = width / 6;  // Crane stays centered
    y = 90;
    x = craneX;  // Start at center
    trolleyPos = 0;
  }

  void update() {
    // Move trolley back and forth along the jib
    if (movingRight) trolleyPos += speed;
    else trolleyPos -= speed;

    // Boundaries: trolley stops before vertical tower and end of jib
    // Vertical tower is at -40px with width of 25px (extends from -52.5 to -27.5)
    // Block is 60px wide (30px on each side from center)
    // Need to account for: tower right edge (-27.5) + block half-width (30) + safety margin
    float towerRightEdge = -40 + 12.5; // -27.5px
    float blockHalfWidth = 30; // 60px / 2
    float safetyMargin = 5; // Small safety buffer
    float leftBoundary = towerRightEdge + blockHalfWidth + safetyMargin; // approximately -27.5 + 30 + 5 = 7.5
    
    // However, trolley starts at craneX, so we need relative position
    // Tower is at craneX - 40, so relative to trolley starting point:
    leftBoundary = -27.5 + 30 + 5; // This gives us about 7.5px from center
    
    if (trolleyPos > jibLength - 30) movingRight = false;
    if (trolleyPos < leftBoundary) movingRight = true;

    // Update x position based on trolley position
    x = craneX + trolleyPos;

    // If not holding and blocks remain, get ready for next
    if (!holdingBlock && blocksDropped < totalBlocks) {
      holdingBlock = true;
    }
  }

  void display() {
    // Save current state
    pushStyle();
    
    // Draw stationary crane structure
    pushMatrix();
    translate(craneX, y);
    
    // Red color for crane
    color craneRed = color(200, 30, 30);
    color craneDarkRed = color(150, 20, 20);
    
    // Draw the jib (horizontal crane arm) with lattice structure
    drawJib(craneRed, craneDarkRed);
    
    // Draw counterweight side (left side, shorter)
    pushMatrix();
    scale(-1, 1);  // Mirror horizontally
    drawCounterweight(craneRed, craneDarkRed);
    popMatrix();
    
    // Center tower/pivot point (fixed)
    drawTower(craneRed);
    
    popMatrix();
    // Crane structure complete - matrix restored
    
    // Draw moving trolley (uses absolute coordinates)
    drawTrolley();
    
    // Draw cable and block (follows trolley)
    drawCable();
    
    if (holdingBlock) {
      drawBlock();
    }
    
    popStyle();
  }
  
  void drawJib(color mainColor, color darkColor) {
    // Main boom extending to the right
    strokeWeight(3);
    stroke(darkColor);
    
    // Top chord
    line(0, 0, jibLength, 0);
    // Bottom chord
    line(0, jibHeight, jibLength, jibHeight);
    
    // Calculate uniform lattice spacing
    float maxLatticeWidth = 40; // Maximum width for each lattice section
    float minLatticeWidth = 20; // Minimum width for each lattice section
    
    // Find optimal number of sections that divides evenly
    int numSections = round(jibLength / maxLatticeWidth);
    if (numSections < 1) numSections = 1;
    
    // Calculate actual spacing (evenly divides the full length)
    float latticeSpacing = jibLength / numSections;
    
    // Ensure spacing is within reasonable bounds
    while (latticeSpacing > maxLatticeWidth && numSections < 50) {
      numSections++;
      latticeSpacing = jibLength / numSections;
    }
    while (latticeSpacing < minLatticeWidth && numSections > 1) {
      numSections--;
      latticeSpacing = jibLength / numSections;
    }
    
    // Draw lattice pattern with uniform spacing
    strokeWeight(2);
    stroke(mainColor);
    
    // Vertical members at regular intervals
    for (int i = 0; i <= numSections; i++) {
      float xPos = i * latticeSpacing;
      line(xPos, 0, xPos, jibHeight);
    }
    
    // Diagonal cross-bracing (creates triangular pattern)
    for (int i = 0; i < numSections; i++) {
      float xStart = i * latticeSpacing;
      float xEnd = (i + 1) * latticeSpacing;
      
      // Diagonal going down-right
      line(xStart, 0, xEnd, jibHeight);
      // Diagonal going up-right
      line(xStart, jibHeight, xEnd, 0);
    }
    
    // End cap
    strokeWeight(3);
    stroke(darkColor);
    line(jibLength, 0, jibLength, jibHeight);
  }
  
  void drawCounterweight(color mainColor, color darkColor) {
    // Shorter counterweight boom on left side
    float cwLength = 80;
    
    strokeWeight(3);
    stroke(darkColor);
    
    // Top and bottom chords
    line(0, 0, cwLength, 0);
    line(0, jibHeight, cwLength, jibHeight);
    
    // Calculate uniform lattice spacing
    float maxLatticeWidth = 40; // Maximum width for each lattice section
    float minLatticeWidth = 20; // Minimum width for each lattice section
    
    // Find optimal number of sections that divides evenly
    int numSections = round(cwLength / maxLatticeWidth);
    if (numSections < 1) numSections = 1;
    
    // Calculate actual spacing (evenly divides the full length)
    float latticeSpacing = cwLength / numSections;
    
    // Ensure spacing is within reasonable bounds
    while (latticeSpacing > maxLatticeWidth && numSections < 50) {
      numSections++;
      latticeSpacing = cwLength / numSections;
    }
    while (latticeSpacing < minLatticeWidth && numSections > 1) {
      numSections--;
      latticeSpacing = cwLength / numSections;
    }
    
    // Lattice pattern with uniform spacing
    strokeWeight(2);
    stroke(mainColor);
    
    // Vertical members at regular intervals
    for (int i = 0; i <= numSections; i++) {
      float xPos = i * latticeSpacing;
      line(xPos, 0, xPos, jibHeight);
    }
    
    // Diagonal cross-bracing
    for (int i = 0; i < numSections; i++) {
      float xStart = i * latticeSpacing;
      float xEnd = (i + 1) * latticeSpacing;
      
      line(xStart, 0, xEnd, jibHeight);
      line(xStart, jibHeight, xEnd, 0);
    }
    
    // Counterweight box at the end
    fill(100);
    stroke(50);
    strokeWeight(2);
    rectMode(CORNER);
    rect(cwLength, 5, 25, 20);
  }
  
  void drawTower(color mainColor) {
    // Vertical support beam from ground to crane
    // Attached at 2nd lattice section from counterweight (-40px from center)
    
    float towerX = -40; // 2nd lattice section
    float towerWidth = 25; // Match lattice spacing
    float towerBottom = height - 20 - y - jibHeight; // Distance from bottom of jib to ground
    
    // Calculate uniform lattice spacing
    float maxLatticeHeight = 40; // Maximum height for each lattice section
    float minLatticeHeight = 25; // Minimum height for each lattice section
    
    // Find optimal number of sections that divides evenly
    int numSections = round(towerBottom / maxLatticeHeight);
    if (numSections < 1) numSections = 1;
    
    // Calculate actual spacing (evenly divides the full height)
    float latticeSpacing = towerBottom / numSections;
    
    // Ensure spacing is within reasonable bounds
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
    
    // Main vertical members (left and right sides)
    line(towerX - towerWidth/2, jibHeight, towerX - towerWidth/2, jibHeight + towerBottom);
    line(towerX + towerWidth/2, jibHeight, towerX + towerWidth/2, jibHeight + towerBottom);
    
    // Horizontal cross-bracing at each lattice division
    strokeWeight(2);
    for (int i = 0; i <= numSections; i++) {
      float yPos = jibHeight + (i * latticeSpacing);
      line(towerX - towerWidth/2, yPos, towerX + towerWidth/2, yPos);
    }
    
    // Diagonal X-pattern cross-bracing for each section
    for (int i = 0; i < numSections; i++) {
      float yStart = jibHeight + (i * latticeSpacing);
      float yEnd = jibHeight + ((i + 1) * latticeSpacing);
      
      // Diagonal going down-right
      line(towerX - towerWidth/2, yStart, towerX + towerWidth/2, yEnd);
      // Diagonal going down-left
      line(towerX + towerWidth/2, yStart, towerX - towerWidth/2, yEnd);
    }
    
    // Connection point where tower meets jib (at bottom of jib)
    strokeWeight(3);
    fill(mainColor);
    noStroke();
    circle(towerX, jibHeight, 10);
  }
  
  void drawTrolley() {
    // Moving trolley/cab that travels along the jib
    pushMatrix();
    translate(x, y);
    
    // Trolley body
    fill(220, 50, 50);
    stroke(0);
    strokeWeight(2);
    rectMode(CENTER);
    rect(0, jibHeight/2, 18, 25);
    
    // Window
    fill(150, 200, 255);
    noStroke();
    rect(0, jibHeight/2 - 3, 12, 12);
    
    // Wheels/rollers on top (on the jib)
    fill(80);
    circle(-6, 3, 6);
    circle(6, 3, 6);
    
    popMatrix();
  }
  
  void drawCable() {
    // Cable hanging from trolley
    strokeWeight(2);
    stroke(60, 60, 60);
    line(x, y + jibHeight, x, y + 80);
    
    // Pulley at trolley bottom
    fill(80);
    noStroke();
    circle(x, y + jibHeight, 8);
  }
  
  void drawBlock() {
    // Hook
    strokeWeight(2);
    stroke(100);
    line(x, y + 80, x, y + 85);
    
    // Wooden crate - 60 wide x 40 tall
    pushMatrix();
    translate(x, y + 105); // Adjusted Y position for 40px height
    
    // Main crate body - brown wood color
    fill(180, 120, 60); // Medium brown
    stroke(100, 60, 30); // Dark brown border
    strokeWeight(2);
    rectMode(CENTER);
    rect(0, 0, 60, 40, 2);
    
    // Draw vertical wooden planks
    stroke(140, 90, 45); // Darker brown for plank lines
    strokeWeight(2);
    float plankSpacing = 60 / 5;
    for (float xPos = -30 + plankSpacing; xPos < 30; xPos += plankSpacing) {
      line(xPos, -20, xPos, 20);
    }
    
    // Draw diagonal cross bracing (X pattern)
    stroke(120, 75, 35); // Even darker brown for bracing
    strokeWeight(3);
    // Top-left to bottom-right
    line(-27, -17, 27, 17);
    // Top-right to bottom-left
    line(27, -17, -27, 17);
    
    // Corner metal brackets/screws
    fill(80, 80, 80); // Dark gray metal
    noStroke();
    circle(-25, -15, 4); // Top-left
    circle(25, -15, 4);  // Top-right
    circle(-25, 15, 4);  // Bottom-left
    circle(25, 15, 4);   // Bottom-right
    
    // Add lighter wood grain highlight on top
    fill(200, 140, 80, 100); // Lighter brown, semi-transparent
    noStroke();
    rect(0, -10, 52, 10);
    
    popMatrix();
  }
}

// -------------------------
// BLOCK CLASS
// -------------------------
class Block {
  Body body;
  float w, h;
  boolean dropped = false;

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
    fd.restitution = 0.05;
    body.createFixture(fd);
    body.setActive(false);
  }

  void drop() {
    dropped = true;
    body.setActive(true);
  }

  void display() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    float a = -body.getAngle();
    
    // Draw shadow first
    pushMatrix();
    translate(pos.x + 3, pos.y + 3);
    rotate(a);
    fill(0, 0, 0, 50);
    noStroke();
    rectMode(CENTER);
    rect(0, 0, w, h);
    popMatrix();
    
    // Draw wooden crate
    pushMatrix();
    translate(pos.x, pos.y);
    rotate(a);
    
    // Main crate body - brown wood color
    fill(180, 120, 60); // Medium brown
    stroke(100, 60, 30); // Dark brown border
    strokeWeight(2);
    rectMode(CENTER);
    rect(0, 0, w, h, 2);
    
    // Draw vertical wooden planks
    stroke(140, 90, 45); // Darker brown for plank lines
    strokeWeight(2);
    float plankSpacing = w / 5;
    for (float x = -w/2 + plankSpacing; x < w/2; x += plankSpacing) {
      line(x, -h/2, x, h/2);
    }
    
    // Draw diagonal cross bracing (X pattern)
    stroke(120, 75, 35); // Even darker brown for bracing
    strokeWeight(3);
    // Top-left to bottom-right
    line(-w/2 + 3, -h/2 + 3, w/2 - 3, h/2 - 3);
    // Top-right to bottom-left
    line(w/2 - 3, -h/2 + 3, -w/2 + 3, h/2 - 3);
    
    // Corner metal brackets/screws
    fill(80, 80, 80); // Dark gray metal
    noStroke();
    float cornerOffset = 5;
    circle(-w/2 + cornerOffset, -h/2 + cornerOffset, 4); // Top-left
    circle(w/2 - cornerOffset, -h/2 + cornerOffset, 4);  // Top-right
    circle(-w/2 + cornerOffset, h/2 - cornerOffset, 4);  // Bottom-left
    circle(w/2 - cornerOffset, h/2 - cornerOffset, 4);   // Bottom-right
    
    // Add lighter wood grain highlight on top
    fill(200, 140, 80, 100); // Lighter brown, semi-transparent
    noStroke();
    rect(0, -h/4, w - 8, h/4);
    
    popMatrix();
  }

  boolean offScreen() {
    Vec2 pos = box2d.getBodyPixelCoord(body);
    return (pos.y > height + 100);
  }
}

// -------------------------
// GROUND CLASS
// -------------------------
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
    float box2Dw = box2d.scalarPixelsToWorld(w / 2);
    float box2Dh = box2d.scalarPixelsToWorld(h / 2);
    ps.setAsBox(box2Dw, box2Dh);
    body.createFixture(ps, 1);
  }

  void display() {
    // Ground shadow/depth
    fill(80, 50, 20);
    noStroke();
    rectMode(CENTER);
    rect(width/2, height - 5, w, 10);
    
    // Main ground - draw alternating concrete slabs
    noStroke();
    
    // Alternate between two shades of gray for each slab
    int slabWidth = 90;
    for (int i = 0; i < width; i += slabWidth) {
      // Alternate colors
      if ((i / slabWidth) % 2 == 0) {
        fill(140, 140, 145); // Standard gray
      } else {
        fill(130, 130, 135); // Slightly darker gray
      }
      rectMode(CORNER);
      rect(i, height - 20, slabWidth, 20);
    }
    
    // Pavement texture - concrete slab joints
    stroke(100, 100, 105); // Darker gray for joints
    strokeWeight(3); // Make joints more visible
    
    // Vertical joints every 90 pixels (concrete slabs)
    for (int i = 0; i < width; i += slabWidth) {
      line(i, height - 18, i, height);
    }
    
    noStroke();
  }
}

// -------------------------
// PARTICLE CLASS
// -------------------------
class Particle {
  float x, y, vx, vy;
  float life = 255;
  
  Particle(float x, float y) {
    this.x = x;
    this.y = y;
    vx = random(-2, 2);
    vy = random(-3, -1);
  }
  
  void update() {
    x += vx;
    y += vy;
    vy += 0.2; // gravity
    life -= 8;
  }
  
  void display() {
    noStroke();
    fill(255, 200, 100, life);
    circle(x, y, 6);
  }
  
  boolean isDead() {
    return life < 0;
  }
}
