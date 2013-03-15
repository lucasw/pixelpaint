/*
   Copyright 2013 Lucas Walter

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

PImage img;
int cur_x;
int cur_y;

int cwd = 640;
int cht = cwd;

color[] colors = new color[16];
char[] keys = new char[16];

PFont font;

void setup()
{
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
  for (int i = 0; i < img.pixels.length; i++) {
    img.pixels[i] = colors[8];
  }
  img.updatePixels();
}

void keyPressed()
{
  if (key == 'j')
  {
     cur_x -= 1;
     cur_x = (cur_x + img.width) % img.width;
  } 
  if (key == 'l')
  {
     cur_x += 1;
     cur_x = (cur_x + img.width) % img.width;
  } 
  if (key == 'i')
  {
     cur_y -= 1;
     cur_y = (cur_y + img.height) % img.height;
  } 
  if (key == 'k')
  {
     cur_y += 1;
     cur_y = (cur_y + img.height) % img.height;
  } 
  
  ////////////////////////////////////////////////
  img.loadPixels(); 
  int ind = cur_y * img.width + cur_x;
  
  for (int i = 0; i < keys.length; i++) {
    if (key == keys[i]) { img.pixels[ind] = colors[i]; }
    
    
  }
  
  img.updatePixels();
  
  if (key == 'p')
  {
     saveFrame("cur-######.png");
     println("saving frame");
  } 
  
   //saveFrame("ugly_edit_#######.png");
   
  noStroke();
  textFont(font);
  textSize(32);
  fill(255);
  text(key, width-64, height-64);   
}

void draw()
{
  background(32);
  
  int rwd = cwd / img.width;
  int rht = cht / img.height;
  
  noStroke();
  textFont(font);
  for (int i = 0; i < keys.length; i++) 
  {  
    fill(colors[i]); 
    
    int x = cwd + 64 + (i % 4)*rwd*2;
    int y = 64 + (i/4)*rht*5;
    
    rect(x, y, rwd*2, rht*2);
    
    textSize(32);
    text(keys[i], x + rwd/2, y + rht*3+4);   
  }
  
  
  img.loadPixels(); 
  

  
  for (int j = 0; j < img.height; j++) 
  {
  for (int i = 0; i < img.width; i++) 
  {
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
