/*
   Copyright 2013 Lucas Walter

   Modifications made by James Britt <james@neurogami.com>

   Sun Mar 17 11:43:21 MST 2013
 * Changed navigation keys to match those used by vi
 * Added a method to save only the artwork section for the frame, excluding the palette.
 * Added the use of the space-bar to repeat the last-used color
 * Added loading of custom palettes.

 --------------------------------------------------------------------
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import java.util.Date;

PImage img;
BufferedReader reader;

int cur_x;
int cur_y;

int cwd = 640;
int cht = cwd;

int lastColorIndex = 0;

color[] colors = new color[16];
char[] keys = new char[16];

PFont font;


void loadPalette(String paletteFilePath) {
  // Assumes it it loading a text file that has list of hex color values.
  //http://processing.org/reference/BufferedReader.html

  reader = createReader(paletteFilePath);

String lines[] = loadStrings(paletteFilePath);

for (int i = 0 ; i < lines.length; i++) {
//  println(lines[i]);
   int c = unhex("FF" + trim(lines[i]));
    colors[i] = color(c);
    println("Updated color at " + i + " with hex value '" + trim(lines[i]) + "'" );
}

  
}



// http://processing.org/reference/selectInput_.html
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
  }

  loadPalette(selection.getAbsolutePath());
}

void saveImage() {

  PImage partialSave = get(0,0,cwd,cht);
  Date d = new Date();
  long ts = d.getTime();
  partialSave.save("cur-" + ts + ".png");
}

void setup() {

  size(cwd *1920/1080, cht);
  img = createImage(32, 32, RGB); 

  font = createFont("Courier 10 Pitch", 8, false);

  cur_x = img.width/2;
  cur_y = img.height/2;

  keys[0]  = '1';
  keys[1]  = '2';
  keys[2]  = '3';
  keys[3]  = '4';
  keys[4]  = 'q';
  keys[5]  = 'w';
  keys[6]  = 'e';
  keys[7]  = 'r';
  keys[8]  = 'a';
  keys[9]  = 's';
  keys[10] = 'd';
  keys[11] = 'f';
  keys[12] = 'z';
  keys[13] = 'x';
  keys[14] = 'c';
  keys[15] = 'v';

  colors[0]  = color(#000000); 
  colors[1]  = color(#0000AA); 
  colors[2]  = color(#00AA00); 
  colors[3]  = color(#00AAAA); 
  colors[4]  = color(#AA0000); 
  colors[5]  = color(#AA00AA); 
  colors[6]  = color(#AA5500); 
  colors[7]  = color(#AAAAAA); 
  colors[8]  = color(#555555); 
  colors[9]  = color(#5555ff); 
  colors[10] = color(#55ff55); 
  colors[11] = color(#55ffff); 
  colors[12] = color(#ff5555); 
  colors[13] = color(#ff55ff); 
  colors[14] = color(#ffff55); 
  colors[15] = color(#ffffff); 

  img.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) { img.pixels[i] = colors[8]; }

  img.updatePixels();
}


// Use vi-style navigation j/k = down/up, h/l for left/right

void keyPressed() {
  if (key == 'j') {
    cur_y += 1;
    cur_y = (cur_y + img.height) % img.height;
  } 

  if (key == 'k') {
    cur_y -= 1;
    cur_y = (cur_y + img.height) % img.height;
  } 

  if (key == 'h') {
    cur_x -= 1;
    cur_x = (cur_x + img.width) % img.width;
  } 

  if (key == 'l') {
    cur_x += 1;
    cur_x = (cur_x + img.width) % img.width;
  } 



  ////////////////////////////////////////////////
  img.loadPixels(); 

  int ind = cur_y * img.width + cur_x;

  if (key == ' ') {
    img.pixels[ind] = colors[lastColorIndex]; 
  }

  if (key == 'L' ) {
    selectInput("Select a file to process:", "fileSelected");
  }

  for (int i = 0; i < keys.length; i++) {
    if (key == keys[i]) { 
      img.pixels[ind] = colors[i]; 
      lastColorIndex = i;
    }
  }

  img.updatePixels();

  if (key == 'p') {
    saveImage();
    println("saving frame");
  } 


  noStroke();
  textFont(font);
  textSize(32);
  fill(255);
  text(key, width-64, height-64);   
}

void draw() {
  background(32);

  int rwd = cwd / img.width;
  int rht = cht / img.height;

  noStroke();
  textFont(font);
  for (int i = 0; i < keys.length; i++) {  
    fill(colors[i]); 

    int x = cwd + 64 + (i % 4)*rwd*2;
    int y = 64 + (i/4)*rht*5;

    rect(x, y, rwd*2, rht*2);

    textSize(32);
    text(keys[i], x + rwd/2, y + rht*3+4);   
  }


  img.loadPixels(); 



  for (int j = 0; j < img.height; j++) {
    for (int i = 0; i < img.width; i++) {
      int ind = j * img.width + i;
      //stroke(255);

      noStroke();
      fill(img.pixels[ind]);

      rect(i * rwd , j * rht , rwd, rht);

    }

  }

  stroke(0);
  strokeWeight(2);
  fill(255); 
  rect(cur_x * rwd + rwd/4, cur_y * rht + rht/4, rwd/2, rht/2);

}
