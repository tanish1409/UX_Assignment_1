// ==========================================
// Music Responsive Visualizer
// By ChatGPT + You 🎧
// ==========================================

import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput mic;       // microphone input
AudioPlayer song;     // optional for file playback
FFT fft;

int mode = 1;         // 1 = Circle mode, 2 = Bar mode
float amplitude = 0;
ArrayList<Float> ampHistory = new ArrayList<Float>();

void setup() {
  size(800, 600);
  colorMode(HSB, 255);
  
  minim = new Minim(this);
  
  // --- OPTION 1: Microphone input ---
  mic = minim.getLineIn(Minim.MONO, 1024);
  
  // --- OPTION 2 (optional): load an audio file ---
  // song = minim.loadFile("your_music.mp3", 1024);
  // song.loop();
  
  fft = new FFT(mic.bufferSize(), mic.sampleRate());
}

void draw() {
  background(0);
  
  // Analyze sound
  fft.forward(mic.mix);   // use mic or song.mix if using audio file
  amplitude = mic.mix.level() * 500;
  ampHistory.add(amplitude);
  if (ampHistory.size() > width) ampHistory.remove(0);

  if (mode == 1) {
    drawCircularVisualizer();
  } else if (mode == 2) {
    drawBarSpectrum();
  }

  displayInfo();
}

void keyPressed() {
  if (key == ' ') {
    mode = (mode == 1) ? 2 : 1;
  }
}

// ==========================================
// MODE 1: Circular Pulsing Visualizer
// ==========================================
void drawCircularVisualizer() {
  translate(width/2, height/2);
  
  noFill();
  strokeWeight(2);
  float baseRadius = 100;
  float angleStep = TWO_PI / 128;
  
  beginShape();
  for (int i = 0; i < 128; i++) {
    float energy = fft.getBand(i) * 3;
    float radius = baseRadius + energy;
    float x = cos(angleStep * i) * radius;
    float y = sin(angleStep * i) * radius;
    stroke((i * 2) % 255, 255, 255);
    vertex(x, y);
  }
  endShape(CLOSE);
  
  // History trail circles
  noStroke();
  for (int i = 0; i < ampHistory.size(); i += 10) {
    float val = ampHistory.get(i);
    fill(180, 255, 255, 60);
    ellipse(0, 0, val, val);
  }
}

// ==========================================
// MODE 2: Frequency Spectrum Bars
// ==========================================
void drawBarSpectrum() {
  int bands = 128;
  float bandWidth = width / float(bands);
  
  for (int i = 0; i < bands; i++) {
    float energy = fft.getBand(i) * 6;
    float hue = map(i, 0, bands, 0, 255);
    fill(hue, 255, 255);
    noStroke();
    rect(i * bandWidth, height, bandWidth - 2, -energy);
  }

  // Amplitude history line at bottom
  stroke(255);
  noFill();
  beginShape();
  for (int i = 0; i < ampHistory.size(); i++) {
    float y = height - ampHistory.get(i);
    vertex(i, y);
  }
  endShape();
}

// ==========================================
// INFO DISPLAY
// ==========================================
void displayInfo() {
  fill(255);
  textSize(16);
  textAlign(LEFT);
  text("Mode: " + (mode == 1 ? "Circular Rings" : "Bar Spectrum"), 20, 30);
  text("Press SPACE to switch modes", 20, 50);
}
    
