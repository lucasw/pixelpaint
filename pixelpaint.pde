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

// TBD these shouldn't be final, everytime an image is loaded these should be reset   
final int w_sz = 32;
final int h_sz = 32;

PImage img;
PImage bg;

ArrayList imgs;
int imgs_ind = 0;

BufferedReader reader;

boolean palette_select_draws_mode = true;
boolean drag_mode = false;
boolean mouse_mode = false;
boolean draw_grid = true;
boolean add_frame = false;
boolean clear_frame = false;
boolean next_frame = false;
boolean prev_frame = false;
boolean is_dirty = false;

boolean do_voxels = true;
final int vox_view_height = 320;
PGraphics vox_view;
float vox_rot_y = 0;
float vox_rot_x = 0;
float vox_z = 64;
boolean do_view_x = false;
boolean do_view_y = false;

int cur_x;
int cur_y;

int cwd = 640;
int cht = cwd;

int last_color_index = 0;

color[] colors = new color[17];
char[] keys = new char[17];

String prefix;
color prev_pixel_color;

PFont font;

int count = 0;
int anim_ind = 0;

final int BSZ = 32;

/**
  *
  */
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

/**
  * http://processing.org/reference/selectInput_.html
  */
void paletteFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected palette " + selection.getAbsolutePath());
    loadPalette(selection.getAbsolutePath());
  }
}

/**
  *
  */
void setupPaletteFromImage(PImage img) {
  
  HashMap colormap = new HashMap();
  
  img.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) {
        
    String value = hex(img.pixels[i]);

    Integer n =  (Integer)(colormap.get(value));
    int num = (n != null? n.intValue() + 1 : 1);
    colormap.put(value, num); 
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

/**
  *
  */
void loadNewImage(String image_file, PImage img) {
  println("attempting to load " + image_file);
  img = loadImage(image_file);  // TBD pass in or return PImage instead
  println("loaded " + str(img.width) + "x" + str(img.height)); 
  
  imgs.set(imgs_ind, img);   
  //setupPaletteFromImage(img);
}

/**
  *
  */
void imageFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected file " + selection.getAbsolutePath());
    loadNewImage(selection.getAbsolutePath(), img);
  }
}

/**
  *
  */
String saveImage(PImage img) {

  //PImage partialSave = get(0,0,cwd,cht);
  Date d = new Date();
  long ts = d.getTime();
  //partialSave.save("cur-" + ts + ".png");
  String name = "cur-" + ts + ".png";
  img.save(name);

  return name;
}

int save_count = 0;

/**
  *
  */
void saveImageSequence(ArrayList imgs, String prefix) {

  for (int i = 0; i < imgs.size(); i++) {
    PImage img = (PImage)imgs.get(i); 
    String name = prefix + "_" + str(1000 + save_count) + "_" + (10000 + i) + ".png";
    img.save(name);
  }
  println("saved " + str(imgs.size()) + " images " + prefix + " " + 
     str(save_count));

  save_count++;
}

/**
  * setup the image that shows transparency
  */
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

/**
  * Set the resolution
  * Create and initialize variables
  *
  */
void setup() {

  if (do_voxels) {
    size(cwd * 1920/1080, cht, P2D);
    vox_view = createGraphics(vox_view_height, vox_view_height, P3D);
    // TBD this doesn't seem to work
    //vox_view.ortho();
    float fov = PI/6;
    // this doesn't look like it is working either
    float cameraZ = (vox_view.height/2.0) / tan(fov/2.0);
    vox_view.perspective(fov, 
        float(vox_view.width)/float(vox_view.height), 
        cameraZ/10.0, cameraZ*10.0);
    vox_view.ambientLight(255, 255, 250);

  } else {
    size(cwd * 1920/1080, cht);
  }

  {
    // TBD make ability to set this?
    Date d = new Date();
    long ts = d.getTime();
    prefix = "data/pixelpaint_" + ts;
  }

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
    // TBD changing this messes up the menu drawing
    println("creating default " + str(w_sz) + "x" + str(h_sz) + " empty image");
    img = createImage(w_sz, h_sz, ARGB); 
   
    // make this independent
    bg = createImage(BSZ * 8, BSZ * 8, ARGB);
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

  font = createFont("Courier 10 Pitch", BSZ, false);

  cur_x = img.width/2;
  cur_y = img.height/2;

  setupKeysDefault();


  if (do_voxels) {
    for (int i = 0; i < h_sz; i++) {
      duplicateFrame();
    }
  }
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


int old_mouse_x;
int old_mouse_y;
int shift_x = 0;
int shift_y = 0;
boolean do_shift = false;
boolean do_pixel_change = false;
boolean do_flood_fill = false;
// Use vi-style navigation j/k = down/up, h/l for left/right

ArrayList keys_pressed = new ArrayList();
int last_key_count = 0;

void keyPressed() {

  {
    Character c = key;
    keys_pressed.add(c);
    last_key_count = count;
  }

  // movement keys
  // TBD don't modify the cur_x/y directly here, just record that
  // the motion was requested and update cur_xy in draw- then no pixels will
  // be missed
  if (key == 'j') {
    cur_y += 1;
    mouse_mode = false;
  } 

  if (key == 'k') {
    cur_y -= 1;
    mouse_mode = false;
  } 

  if (key == 'h') {
    cur_x -= 1;
    mouse_mode = false;
  } 

  if (key == 'l') {
    cur_x += 1;
    mouse_mode = false;
  } 
  
  // diagonal keys (not used in vi but standard in roguelikes?)
  if (key == 'y') {
    cur_y -= 1;
    cur_x -= 1;
    mouse_mode = false;
  } 
  if (key == 'u') {
    cur_y -= 1;
    cur_x += 1;
    mouse_mode = false;
  }
  if (key == 'b') {
    cur_y += 1;
    cur_x -= 1;
    mouse_mode = false;
  }
  if (key == 'n') {
    cur_y += 1;
    cur_x += 1;
    mouse_mode = false;
  }

  cur_x = (cur_x + img.width) % img.width;
  cur_y = (cur_y + img.height) % img.height;

  // a toggleable drag mode where the last color is placed
  // under the cursor instead of having to press a key at every pixel
  if (key == ';') {
    drag_mode = !drag_mode;
    println("drag_mode " + str(drag_mode));
  }
  
  if (key == '\'') {
    mouse_mode = !mouse_mode;
    println("drag_mode " + str(mouse_mode));
  }
  
  if (key == '/') {
    palette_select_draws_mode = !palette_select_draws_mode;
    println("palette_select_draws_mode " + str(palette_select_draws_mode));
  }


  if (key == 'b') {
    draw_grid = !draw_grid;
    println("draw_grid " + str(draw_grid));
  }
 
  if (key == 'L' ) {
    selectInput("Select a palette file to process:", "paletteFileSelected");
  }
  
  if (key == 'o' ) {
    selectInput("Select an image file to edit:", "imageFileSelected");
  }

  if (key == '-') {
    // add frame to sequence
    clear_frame = true;
  }
 
  // animation
  if (key == '0') {
    // add frame to sequence
    if (!do_voxels) {
      add_frame = true;
    }
  }

  // rotate view
  if (key == '5') {
    do_view_x = true;
  }
  if (key == '6') {
    do_view_y = true;
  }

  if (key == '9') {
    // go to next frame in sequence
    next_frame = true;
  }
  
  if (key == '8') {
    prev_frame = true;
  }

  if (key == '[') {
    vox_z += 4;
    println("vox_z " + str(vox_z));
  }
  
  if (key == ']') {
    vox_z -= 5;
    println("vox_z " + str(vox_z));
  }


  /////////////////////////
  if (key == 'p') {
    //String name = saveImage(img);
    //println("saving frame: " + name);
    saveImageSequence(imgs, prefix);
  } 

  
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
  for (int i = 0; i < keys.length; i++) {
    if (key == keys[i]) { 
      last_color_index = i;
      if (palette_select_draws_mode) {
        do_pixel_change = true;
      }
    }
  }
 
  if ((key == ' ') || (key == 'm')) {
    do_pixel_change = true;
  }

  if (key == 'i') {
    do_flood_fill = true;
  }

}

boolean floodFillLeftRight(
  PImage img, 
  int cur_x, 
  int cur_y, 
  color color_to_replace, 
  color color_to_flood) {
 
 // flood to right
  for (int x = cur_x; x < img.width; x++) {
    int ind = cur_y * img.width + x;
    if (img.pixels[ind] != color_to_replace) {
      break;
    }  
    img.pixels[ind] = color_to_flood;
  }

  // flood to left
  for (int x = cur_x - 1; x >= 0; x--) {
    int ind = cur_y * img.width + x;
    if (img.pixels[ind] != color_to_replace) {
      break;
    }  
    img.pixels[ind] = color_to_flood;
  }

  return true;
}

class XY {
  int x;
  int y;

  XY(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

boolean testXY(PImage img, XY xy, 
    color color_to_replace 
    ) {

  if (xy.x >= img.width)  { return false; }
  if (xy.y >= img.height) { return false; }
  if (xy.x < 0) { return false; }
  if (xy.y < 0) { return false; }
 
  return (img.pixels[xy.y * img.width + xy.x] == color_to_replace);
}

void duplicateFrame() {
  PImage temp = img.get(0, 0, img.width, img.height);
    //PImage temp = createImage(img.width, img.height, ARGB);
    imgs_ind += 1;
    imgs.add(imgs_ind, temp); // index
    img = (PImage)imgs.get(imgs_ind); // should get temp right back
    //println("added frame, cur sequence index " + str(imgs_ind) + "/" + imgs.size());
    
}

// try http://en.wikipedia.org/wiki/Flood_fill next
boolean floodFill(
  PImage img, 
  int cur_x, 
  int cur_y, 
  color color_to_replace, 
  color color_to_flood) {

  if (color_to_replace == color_to_flood) { return false; }
  /// TBD should this wrap or not or optionally?
  if (cur_x >= img.width)  { return false; }
  if (cur_y >= img.height) { return false; }
  if (cur_x < 0) { return false; }
  if (cur_y < 0) { return false; }
  
  //println("floodfilling");
  
  ArrayList fillq = new ArrayList();
  
  XY xy = new XY(cur_x, cur_y);
  fillq.add(xy);
  
  int num_flooded = 0;

  while (fillq.size() > 0) {
    XY nxy = (XY) fillq.get(fillq.size()-1);
    fillq.remove(fillq.size()-1);

    if (testXY(img, nxy, color_to_replace)) {
      img.pixels[nxy.y * img.width + nxy.x] = color_to_flood;
      num_flooded++;
      fillq.add(new XY(nxy.x - 1, nxy.y));
      fillq.add(new XY(nxy.x + 1, nxy.y));
      fillq.add(new XY(nxy.x, nxy.y - 1));
      fillq.add(new XY(nxy.x, nxy.y + 1));
    }
  }

  //println("floodfilling done " + str(num_flooded));
  /*
  for (int y = cur_y; y < img.width; y++) {
    int indy = y * img.width + cur_x;
    if (img.pixels[indy] != color_to_replace) {
      break;
    }  
    floodFillLeftRight(img, cur_x, y, color_to_replace, color_to_flood);
  } 
  
  for (int y = cur_y - 1; y >= 0; y--) {
    int indy = y * img.width + cur_x;
    if (img.pixels[indy] != color_to_replace) {
      break;
    }  
    floodFillLeftRight(img, cur_x, y, color_to_replace, color_to_flood);
  } 
  
  */
  
  // vertical flood

/*
// this is too recursive, results in StackOverflowError: This sketch is attempting too much recursion
  floodFill(img, cur_x + 1, cur_y, color_to_replace, color_to_flood);
  floodFill(img, cur_x - 1, cur_y, color_to_replace, color_to_flood);
  floodFill(img, cur_x, cur_y + 1, color_to_replace, color_to_flood);
  floodFill(img, cur_x, cur_y - 1, color_to_replace, color_to_flood);
*/
  return true;
}


///////////////////////////////////////////////////////////////////////////////
void draw() {

  if (do_voxels) {
    if (do_view_x) {
      println("rotating x");
      ArrayList new_imgs = new ArrayList();
      final int depth_sz = img.width;

      for (int src_y = 0; src_y < depth_sz; src_y++) {
      
        PImage dst = createImage(img.width, img.height, ARGB);
        dst.loadPixels();
        for (int dst_y = 0; dst_y < dst.height && 
            dst_y < imgs.size(); dst_y++) {
          PImage src = (PImage)imgs.get(dst_y); // should get temp right back
          src.loadPixels();

          for (int x = 0; x < dst.width; x++) {

            int src_ind = src_y * img.width + x;
            int dst_ind = dst_y * img.width + x;

            dst.pixels[dst_ind] = src.pixels[src_ind];
          } 

        }
        dst.updatePixels();
        new_imgs.add(dst);
        print(new_imgs.size() + " ");
      }
      
      do_view_x = false;
      imgs = new_imgs;
      imgs_ind = cur_y;
      img = (PImage)imgs.get(imgs_ind);
      println("done");
    }
    
    if (do_view_y) {
      println("rotating y");
      ArrayList new_imgs = new ArrayList();
      final int depth_sz = img.width;

      for (int src_x = 0; src_x < depth_sz; src_x++) {
      
        PImage dst = createImage(img.width, img.height, ARGB);
        dst.loadPixels();
        for (int dst_x = 0; dst_x < dst.width && 
            dst_x < imgs.size(); dst_x++) {
          PImage src = (PImage)imgs.get(dst_x); // should get temp right back
          src.loadPixels();

          for (int y = 0; y < dst.height; y++) {

            int src_ind = y * img.width + src_x;
            int dst_ind = y * img.width + dst_x;

            dst.pixels[dst_ind] = src.pixels[src_ind];
          } 

        }
        dst.updatePixels();
        new_imgs.add(dst);
        print(new_imgs.size() + " ");
      }
    
      do_view_y = false;
      imgs = new_imgs;
      imgs_ind = cur_y;
      img = (PImage)imgs.get(imgs_ind);

    }
  }

  if ((keys_pressed.size() > 10) || 
      ((keys_pressed.size() > 0) && (count - last_key_count > 100))) {
    keys_pressed.remove(0);
    last_key_count = count;
  }
 
  /// update stuff
  if (imgs.size() > 0) {
  if (add_frame) {
    duplicateFrame();
    add_frame = false;
  }

  if (clear_frame) {
    println("clearing frame");
    PImage temp = createImage(img.width, img.height, ARGB);
    img = temp;
    imgs.set(imgs_ind, img);   
    clear_frame = false;
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
  } else {
    println("imgs wasn't initialized properly?");
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

  final int rwd = cwd / BSZ;
  final int rht = cht / BSZ;

  final int rwd2 = cwd / max(img.width, img.height);
  final int rht2 = cht / max(img.width, img.height);

  // TBD make a queue of changed pixels and update them in one go to increase
  // responsitivity?  The frame rate of the drawing of the image shouldn't
  // limit drawing speed.
  if (mouse_mode) {
    cur_x = (mouseX - rwd2/4)/rwd2;
    cur_y = (mouseY - rht2/4)/rht2;

    if (cur_x >= img.width)  cur_x = img.width - 1;
    if (cur_y >= img.height) cur_y = img.height - 1;
    if (cur_x < 0)  cur_x = 0;
    if (cur_y < 0)  cur_y = 0;
    //println(str(mouseX) + " " + str(mouseY) + " " + str(cur_x) + " " + str(cur_y));

    if (mousePressed && (mouseButton == LEFT)) {
      do_pixel_change = true;
    }
    if (mousePressed && (mouseButton == RIGHT)) {
      //do_pixel_change = true;
      // TBD use a different secondary color
    }
  } else if (do_voxels) {
    final int dx = mouseX - old_mouse_x;
    final int dy = mouseY - old_mouse_y;
    old_mouse_x = mouseX;
    old_mouse_y = mouseY;

    vox_rot_y += (float)dx/50.0;
    vox_rot_x += (float)dy/50.0;
  }

  ///
  //
  //

  // update the image
  {
    img.loadPixels();
    if (do_pixel_change || drag_mode) {
      int ind = cur_y * img.width + cur_x;
      prev_pixel_color = img.pixels[ind];
      img.pixels[ind] = colors[last_color_index]; 
      img.updatePixels();
      do_pixel_change = false;
      is_dirty = true;
    }

    if (do_flood_fill) {
      int ind = cur_y * img.width + cur_x;
      color color_to_replace = img.pixels[ind];
      color color_to_flood = colors[last_color_index]; 
      floodFill(img, cur_x, cur_y, color_to_replace, color_to_flood); 
      img.updatePixels();
      do_flood_fill = false;
      is_dirty = true;
    }
  }

  /////////////////////////////////////////////////////////////
  /////// draw stuff
  background(32);

  // put last typed key on screen, TBD print multiple keys
  noStroke();
  textFont(font);
  textSize(BSZ);
  fill(255);
  for (int i = 0; i < keys_pressed.size(); i++) {
    text( ((Character)keys_pressed.get(i)).charValue(), width - 250 + i*20, height - 64);  
  }


  // draw all the colors and keys
  textFont(font);
  for (int i = 0; i < keys.length; i++) {  
    
    int x = cwd + 140 + (i % 4) * (rwd * 2 + 6);
    int y = vox_view_height + 40 + (i / 4) * rht * 2;

    if (i == last_color_index) {
      stroke(220);
    } else {
      noStroke();
    }

    fill(0); 
    rect(x - 2, y - 2, rwd * 2 + 4, rht * 2 + 4);
    
    // TBD check if transparent color and draw checkers
    fill(colors[i]); 
    rect(x, y, rwd * 2, rht * 2);

    textSize(BSZ);
    fill(24); 
    text(keys[i], x + rwd/2 - 2, y + rht * 1 + 6);  
    //text(keys[i], x + rwd/2 + 2, y + rht * 1 + 6);  
    textSize(BSZ);
    fill(230); 
    text(keys[i], x + rwd/2, y + rht * 1 + 7);  

    // TBD print out tally of how many pixels in image use this color
  }
 
  text("frame " + str(imgs_ind + 1) + "/" + imgs.size(), 
      width - 256, height - BSZ);

  fill(230); 
  // print current location
  text("x " + str(cur_x), width - 128, height - 128);   
  text("y " + str(cur_y), width - 128, height - 100);   


  // lay down the background that shows where the image is transparent
  image(bg, 0, 0, rwd2*img.width, rht2*img.height);

  // daw the a faint image of the previous frame under the current frame 
  // (TBD make toggleable)
  if (imgs_ind > 1) {
    drawImage((PImage)imgs.get(imgs_ind - 2), 0, 0, rwd2, rht2, draw_grid, 0.25);
  }
  if (imgs_ind > 0) {
    drawImage((PImage)imgs.get(imgs_ind - 1), 0, 0, rwd2, rht2, draw_grid, 0.5);
  }
  // draw 1 frame forward in the sequence too
  if (imgs_ind < imgs.size() - 1 ) {
    drawImage((PImage)imgs.get(imgs_ind + 1), 0, 0, rwd2, rht2, draw_grid, 0.1);
  }

  // daw the main image 
  drawImage(img, 0, 0, rwd2, rht2, draw_grid, 1.0);

  // draw the cursor
  {
  stroke(0);
  strokeWeight(2);
  fill(255); 
  rect(cur_x * rwd2 + rwd2/4, cur_y * rht2 + rht2/4, rwd2/2, rht2/2);
  }

  // draw a thumbnail of all frames in sequence
  final int sc = 3;
  final int sc2 = (sc * BSZ)/max(img.width, img.height);
  final int x = cwd + 10;
  final int w = img.width * sc2;
  final int h = img.height * sc2;
  for (int i = 0; i < 5; i++) {
    if ((i == 0) && (imgs.size() < 5)) continue; 
    if ((i == 4) && (imgs.size() < 4)) continue; 
    if ((i == 1) && (imgs.size() < 3)) continue; 
    if ((i == 3) && (imgs.size() < 2)) continue; 
    
    int real_ind = imgs_ind + (i - 2);
    real_ind = (real_ind + imgs.size()) % imgs.size();

    int y = i * (h + 5) + 10; //height - img.height * sc - 10;

    fill(100);
    stroke(155);
    if (i == 2) {
      stroke(255);
    }
    rect(x - 1, y - 1, w + 1, h + 1);

    text(str(real_ind), x + w + 5, y + h-10);
    //println(str(real_ind) + " " + str(imgs.size()) );
    drawImage((PImage)imgs.get(real_ind), x, y, sc2, sc2, false);
  }

  // draw animation preview 
  {
    // slow down animation
    if (count % 7 == 0) {
      anim_ind++;
    }
    count++;
    anim_ind %= imgs.size();
    int y = 5 * (h + 5) + 26; //height - img.height * sc - 10;
    fill(100);
    stroke(155);
    rect(x-1, y-1, w+1, h+1);
    drawImage((PImage)imgs.get(anim_ind), x, y, sc2, sc2, false);
  }

  if ((count % 1000 == 0) && (is_dirty)) {
    println("backup save");
    is_dirty = false;
    // save old sequence, just in case
    saveImageSequence(imgs, prefix + "_tmp_");
  }

  // draw voxels
  if (do_voxels) {
    //vox_rot += 0.025;
    final int vsc = 10;
    vox_view.beginDraw();
    vox_view.background(0);
    if (!draw_grid) {
      vox_view.noStroke();
    }
    vox_view.pushMatrix();
    vox_view.translate(
        vox_view.width/2, vox_view.height/2, 
        -vox_z );

    vox_view.rotateX(vox_rot_x);
    vox_view.rotateY(vox_rot_y);
    vox_view.translate( 0, 0, -vsc*imgs.size()/2 );

    for (int k = 0; k < imgs.size(); k++) {
      PImage im = (PImage)imgs.get(k);
      vox_view.translate( 0, 0, vsc );

      for (int j = 0; j < im.height; j++) {
        for (int i = 0; i < im.width; i++) {
         
          boolean is_cursor = false;
          // highlight the voxel the cursor is on
          if ((k == imgs_ind) && (j == cur_y) && (i == cur_x))  {
            is_cursor = true;
            vox_view.stroke(255); 
          } else {
            // highlight the plane currently being edited
            if (draw_grid) {
              if (k == imgs_ind) {
                vox_view.stroke(130);
              } else {
                vox_view.stroke(24);
              }
            }
          }

          final int ind = j * img.width + i;
          // don't draw transparent pixels
          if (((int)alpha(im.pixels[ind]) != 0) || is_cursor) { 
            vox_view.pushMatrix();
            vox_view.translate( (i - im.width / 2) * vsc, (j - im.height / 2) * vsc, 0 );
            if (is_cursor && ((int)alpha(im.pixels[ind]) == 0)) {
              // draw a wireframe box even if the pixel under the cursor is transparent 
              vox_view.noFill();
            } else {
              vox_view.fill(im.pixels[ind]);
            }
            vox_view.box(10);
            vox_view.popMatrix();
          }

        }}
    }
    vox_view.popMatrix();
    vox_view.endDraw();

    image(vox_view, cwd + w + 50, 10);
  }
} // draw

// expensive.
void drawImage(PImage im, int x_off, int y_off, int rwd, int rht, boolean draw_grid)
{
  drawImage(im, x_off, y_off, rwd, rht, draw_grid, 1.0);
}

// draw nice pixellated image, probably somewhat computationally
// expensive.
void drawImage(PImage im, int x_off, int y_off, int rwd, int rht, boolean draw_grid,
  float modifier)
{
  /// draw the edited image
  // TBD rename img to im?
  im.loadPixels(); 

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

      // only draw if not transparent      
      if ((int)alpha(im.pixels[ind]) != 0) { 
        // draw normal pixel
        // TBD make stroke toggleable
        fill(im.pixels[ind], modifier*255);
        rect(x_off + i * rwd , y_off + j * rht , rwd, rht);
      }


    }

  }

}
