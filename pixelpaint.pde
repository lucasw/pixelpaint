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

import java.util.Iterator;
import java.util.Map;

PImage img;
PImage bg;

ArrayList imgs;
int imgs_ind = 0;

BufferedReader reader;

boolean drag_mode = false;
boolean draw_grid = true;
boolean add_frame = false;
boolean next_frame = false;
boolean prev_frame = false;

int cur_x;
int cur_y;

int cwd = 640;
int cht = cwd;

int lastColorIndex = 0;

color[] colors = new color[17];
char[] keys = new char[17];

PFont font;


void loadPalette(String paletteFilePath) {
  // Assumes it it loading a text file that has list of hex color values.
  //http://processing.org/reference/BufferedReader.html

  reader = createReader(paletteFilePath);

  String lines[] = loadStrings(paletteFilePath);

  // TBD check for max length

  for (int i = 0 ; i < lines.length; i++) {
    //  println(lines[i]);
    int c = unhex("FF" + trim(lines[i]));
    colors[i] = color(c);
    println("Updated color at " + i + " with hex value '" + trim(lines[i]) + "'" );
  }
  
}

// http://processing.org/reference/selectInput_.html
void paletteFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected palette " + selection.getAbsolutePath());
    loadPalette(selection.getAbsolutePath());
  }
}

void setupPaletteFromImage(PImage img) {
  
  HashMap colormap = new HashMap();
  
  img.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) {
        
    String value = hex(img.pixels[i]);

    Integer n =  (Integer)(colormap.get(value));
    int count = (n != null? n.intValue() + 1 : 1);
    colormap.put(value, count); 
  }


  // TBD need to sort the list
  Iterator i =  colormap.entrySet().iterator();  // Get an iterator
  
  int ind = 0;
  while (i.hasNext()) {
    Map.Entry me = (Map.Entry)i.next();

    int c = unhex( (String) (me.getKey()) );
    if (ind < colors.length) {
      colors[ind] = color(c);
    }

    print(str(ind) + " " + me.getKey() + " is ");
    println(me.getValue());

    ind++;
  }
}

void loadNewImage(String image_file, PImage img) {
  println("attempting to load " + image_file);
  img = loadImage(image_file);  // TBD pass in or return PImage instead
  println("loaded " + str(img.width) + "x" + str(img.height)); 
  
  setupPaletteFromImage(img);
}

void imageFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected file " + selection.getAbsolutePath());
    loadNewImage(selection.getAbsolutePath(), img);
  }
}

String saveImage(PImage img) {

  //PImage partialSave = get(0,0,cwd,cht);
  Date d = new Date();
  long ts = d.getTime();
  //partialSave.save("cur-" + ts + ".png");
  String name = "cur-" + ts + ".png";
  img.save(name);

  return name;
}

void saveImageSequence(ArrayList imgs) {

  Date d = new Date();
  long ts = d.getTime();
  for (int i = 0; i < imgs.size(); i++) {
    PImage img = (PImage)imgs.get(i); 
    String name = "imageseq_" + ts + "_" + (10000 + i) + ".png";
    img.save(name);
  }
  println("saved " + str(imgs.size()) + " images " + str(ts));
}

// setup the image that shows transparency
void setupBackgroundImage() {
  
  bg.loadPixels();
  // draw transparent pixel checkerboard
  for (int j = 0; j < bg.height; j++) {
    for (int i = 0; i < bg.width; i++) {
      int ind = j * bg.width + i;
      
      bg.pixels[ind] = color(80);
      if (((j % 8 < 4) && (i % 8 >= 4)) || 
          ((j % 8 >= 4) && (i % 8 < 4))) { 
        bg.pixels[ind] = color(110);
      }

  }}

  bg.updatePixels();
}

void setup() {

  size(cwd *1920/1080, cht);

  println(str(args.length) + " arguments");
  for (int i = 0; i < args.length; i++) {
    println(args[0]);
  }

  String image_file = "";
  if (args.length > 0) {
    image_file = args[0];
    
    loadNewImage(image_file, img);
  }

  if (img == null) {
    println("creating default 32x32 empty image");
    img = createImage(32, 32, ARGB); 
    
    bg = createImage(img.width * 8, img.height * 8, ARGB);
    setupBackgroundImage();

    setupPaletteDefault();

    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      // default transparent
      img.pixels[i] = colors[16]; 
    }

    img.updatePixels();
  }
  imgs = new ArrayList();
  imgs.add(img);

  font = createFont("Courier 10 Pitch", 8, false);

  cur_x = img.width/2;
  cur_y = img.height/2;

  setupKeysDefault();
}

// color selection kesy
void setupKeysDefault() {

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
  keys[16] = 'g'; // alpha

}

void setupPaletteDefault() {

  println("using default EGA palette");
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
  // 100% transparent alpha
  colors[16] = color(0,0,0,0); //ffffff);

  for (int i = 0; i < colors.length; i++) {
    println(str(i) + " " + str((int)alpha(colors[i])));
  }
}


int shift_x = 0;
int shift_y = 0;
boolean do_shift = false;

// Use vi-style navigation j/k = down/up, h/l for left/right

void keyPressed() {

  // movement keys
  if (key == 'j') {
    cur_y += 1;
  } 

  if (key == 'k') {
    cur_y -= 1;
  } 

  if (key == 'h') {
    cur_x -= 1;
  } 

  if (key == 'l') {
    cur_x += 1;
  } 
  
  // diagonal keys (not used in vi but standard in roguelikes?)
  if (key == 'y') {
    cur_y -= 1;
    cur_x -= 1;
  } 
  if (key == 'u') {
    cur_y -= 1;
    cur_x += 1;
  }
  if (key == 'b') {
    cur_y += 1;
    cur_x -= 1;
  }
  if (key == 'n') {
    cur_y += 1;
    cur_x += 1;
  }

  cur_x = (cur_x + img.width) % img.width;
  cur_y = (cur_y + img.height) % img.height;

  // a toggleable drag mode where the last color is placed
  // under the cursor instead of having to press a key at every pixel
  if (key == ';') {
    drag_mode = !drag_mode;
    println("drag_mode " + str(drag_mode));
  }

  if (key == '5') {
    draw_grid = !draw_grid;
    println("draw_grid " + str(draw_grid));
  }
 
  if (key == 'L' ) {
    selectInput("Select a palette file to process:", "paletteFileSelected");
  }
  
  if (key == 'o' ) {
    selectInput("Select an image file to edit:", "imageFileSelected");
  }

  // animation
  if (key == '0') {
    // add frame to sequence
    add_frame = true;
  }
  
  if (key == '9') {
    // go to next frame in sequence
    next_frame = true;
  }
  
  if (key == '8') {
    prev_frame = true;

    
  }

  /////////////////////////
  if (key == 'p') {
    //String name = saveImage(img);
    //println("saving frame: " + name);
    saveImageSequence(imgs);
  } 

  // put last typed key on screen, TBD print multiple keys
  noStroke();
  textFont(font);
  textSize(32);
  fill(255);
  text(key, width - 128, height - 72);  


  // arrow keys shift image around
  if (key == CODED) {
    if (keyCode == UP) {
      shift_y =  1;
      do_shift = true;
    }
    if (keyCode == DOWN) {
      shift_y = -1;
      do_shift = true;
    }
    if (keyCode == LEFT) {
      shift_x = 1;
      do_shift = true;
    }
    if (keyCode == RIGHT) {
      shift_x = -1;
      do_shift = true;
    }
  }

 
  ////////////////////////////////////////////////
  // draw on pixel
  {
  img.loadPixels(); 

  int ind = cur_y * img.width + cur_x;

  if (key == ' ') {
    img.pixels[ind] = colors[lastColorIndex]; 
  }


  boolean key_pressed = false;
  for (int i = 0; i < keys.length; i++) {
    if (key == keys[i]) { 
      lastColorIndex = i;
      key_pressed = true;
    }
  }
  
  if (key_pressed || drag_mode) {
    img.pixels[ind] = colors[lastColorIndex]; 
  }

  img.updatePixels();
  }

}

int count = 0;
int anim_ind = 0;

void draw() {

  /// update stuff
  if (add_frame) {
    PImage temp = img.get(0, 0, img.width, img.height);
    //PImage temp = createImage(img.width, img.height, ARGB);
    imgs_ind += 1;
    imgs.add(imgs_ind, temp); // index
    img = (PImage)imgs.get(imgs_ind); // should get temp right back
    //println("added frame, cur sequence index " + str(imgs_ind) + "/" + imgs.size());
    add_frame = false;
  }

  if (prev_frame) {
      // go to previous frame in sequence
      imgs_ind -= 1;
      imgs_ind = (imgs_ind + imgs.size()) % imgs.size();
      img = (PImage)imgs.get(imgs_ind); // should get temp right back
      //println("went back a frame, cur sequence index " + str(imgs_ind) + "/" + imgs.size());
      prev_frame = false;
  }
  if (next_frame) {
      imgs_ind += 1;
      imgs_ind = (imgs_ind + imgs.size()) % imgs.size();
      img = (PImage)imgs.get(imgs_ind); // should get temp right back
      //println("advanced frame, cur sequence index " + str(imgs_ind) + "/" + imgs.size());
      next_frame = false;
  }

  if (do_shift) {
    PImage temp = createImage(img.width, img.height, ARGB);
   
    temp.loadPixels();
    for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width;  x++) {

      int src_ind = y * img.width + x;
      int dx = (x + shift_x + img.width) % img.width;
      int dy = (y + shift_y + img.height) % img.height;
      int dst_ind = dy * img.width + dx; 
      
      temp.pixels[dst_ind] = img.pixels[src_ind];

      //println("src_ind " + str(x) + " " + str(y)  + " -> " +
      //    str(dx) + " " + str(dy) );
    }}
    temp.updatePixels();
   
    img = temp;
    imgs.set(imgs_ind, img);
    // copy is not reliable due to forced interpolation
    //img.copy(temp, 0 ,0, img.width, img.height, 0, 0, img.width, img.height);
    //img.updatePixels();

    shift_x = 0;
    shift_y = 0;
    do_shift = false;
  } // do_shift

  /////// draw stuff
  background(32);

  int rwd = cwd / img.width;
  int rht = cht / img.height;

  // draw all the colors and keys
  noStroke();
  textFont(font);
  for (int i = 0; i < keys.length; i++) {  
    
    int x = cwd + 128 + (i % 4)*rwd*2;
    int y = 64 + (i/4)*rht*5;
    
    fill(0); 
    rect(x - 2, y - 2, rwd*2 + 4, rht*4 + 4);

    fill(colors[i]); 


    rect(x, y, rwd*2, rht*2);

    fill(230); 
    //textSize(38);
    //text(keys[i], x + rwd/2 - 2, y + rht*3+4 + 1);  
    //fill(colors[i]); 
    textSize(32);
    text(keys[i], x + rwd/2, y + rht*3+4);  

    // TBD print out tally of how many pixels in image use this color
  }
 
  text("frame " + str(imgs_ind + 1) + "/" + imgs.size(), 
      width - 256, height - 32);

  // print current location
  text("x " + str(cur_x), width - 128, height - 128);   
  text("y " + str(cur_y), width - 128, height - 100);   


  // lay down the background that shows where the image is transparent
  image(bg, 0, 0, cwd, cwd);

  drawImage(img, 0, 0, rwd, rht, draw_grid);

  // draw the cursor
  {
  stroke(0);
  strokeWeight(2);
  fill(255); 
  rect(cur_x * rwd + rwd/4, cur_y * rht + rht/4, rwd/2, rht/2);
  }

  // draw a thumbnail of all frames in sequence
  int sc = 3;
  int x = cwd + 10;
  int w = img.width * sc;
  int h = img.height * sc;
  for (int i = 0; i < 5; i++) {
    int real_ind = imgs_ind + (i - 2);
    real_ind = (real_ind + imgs.size()) % imgs.size();

    int y = i * (h + 5) + 10; //height - img.height * sc - 10;

    fill(100);
    stroke(155);
    if (i == 2) {
      stroke(255);
    }
    rect(x-1, y-1, w+1, h+1);
    //println(str(real_ind) + " " + str(imgs.size()) );
    drawImage((PImage)imgs.get(real_ind), x, y, sc, sc, false);
  }

  // slow down animation
  if (count % 7 == 0) {
    anim_ind++;
  }
  count++;
  anim_ind %= imgs.size();
  int y = 5 * (h + 5) + 10; //height - img.height * sc - 10;
  rect(x-1, y-1, w+1, h+1);
  drawImage((PImage)imgs.get(anim_ind), x, y, sc, sc, false);
}

// draw nice pixellated image, probably somewhat computationally
// expensive.
void drawImage(PImage im, int x, int y, int rwd, int rht, boolean draw_grid)
{
  /// draw the edited image
  img.loadPixels(); 

  if (draw_grid) {
    strokeWeight(1.0);
    stroke(0, 60);
  } else {
    noStroke();
  }

  for (int j = 0; j < im.height; j++) {
    for (int i = 0; i < im.width; i++) {
      int ind = j * im.width + i;
      //stroke(255);

      
      if ((int)alpha(im.pixels[ind]) != 0) { 
        // draw normal pixel
        // TBD make stroke toggleable
        fill(im.pixels[ind]);
        rect(x + i * rwd , y + j * rht , rwd, rht);
      }


    }

  }
}
