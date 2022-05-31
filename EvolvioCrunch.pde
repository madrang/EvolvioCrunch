/*        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
 *                  Version 2, December 2004 
 *
 * Copyright (C) 2016 Carykh <https://www.youtube.com/user/carykh/about> 
 * Copyright (C) 2021 Madrang <https://github.com/madrang> 
 *
 * Everyone is permitted to copy and distribute verbatim or modified 
 * copies of this license document, and changing it is allowed as long 
 * as the name is changed. 
 *
 *            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
 *   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
 *
 *  0. You just DO WHAT THE FUCK YOU WANT TO.
 *
 * WTFPL – Do What the Fuck You Want to Public License - http://www.wtfpl.net/
 * Choose freedom. Do what the fuck you want to.
 */
 // Evolvio, a playground for virtual ants.
 // EvolvioCrunch, a rewrite of a work started by Carykh to increase population size by fixing multithreading with a task system.
 // Added a fitness function to the Neuron system and see the impact of different models.
 // Added the start of GANeuron, Still WIP...
import java.util.Set;

//https://www.gicentre.net/utils/hashgrid
import org.gicentre.utils.geom.*;
import org.gicentre.utils.FrameTimer;

Board evoBoard;
final int SEED = 51;
final float NOISE_STEP_SIZE = 0.1;
final int BOARD_WIDTH = 100;
final int BOARD_HEIGHT = 100;

final int WINDOW_WIDTH = 1920;
//final int WINDOW_WIDTH = 1600;
final int WINDOW_HEIGHT = 1040;
//final int WINDOW_HEIGHT = 900;

final float SCALE_TO_FIX_BUG = 100;
//final float SCALE_TO_FIX_BUG = 10;
final float GROSS_OVERALL_SCALE_FACTOR = ((float)WINDOW_HEIGHT) / BOARD_HEIGHT / SCALE_TO_FIX_BUG;

final double TIME_STEP = 0.001;
final float MIN_TEMPERATURE = -1.0;
final float MAX_TEMPERATURE = 1.0;

final int ROCKS_TO_ADD = 0;
//final int CREATURE_MINIMUM = 255;
final int CREATURE_MINIMUM = 512;
//final int CREATURE_MINIMUM = 1024;

//final int CREATURE_MAXIMUM = 1024;
final int CREATURE_MAXIMUM = 2048;
//final int CREATURE_MAXIMUM = 4096;
//final int CREATURE_MAXIMUM = 8192;

float cameraX = BOARD_WIDTH * 0.5;
float cameraY = BOARD_HEIGHT * 0.5;
float cameraR = 0;
float zoom = 1;
PFont font;
int dragging = 0; // 0 = no drag, 1 = drag screen, 2 and 3 are dragging temp extremes.
float prevMouseX;
float prevMouseY;
boolean draggedFar = false;
final String INITIAL_FILE_NAME = "PIC";
FrameTimer frameTimer;

void settings() {
  //fullScreen();
  //size(WINDOW_WIDTH, WINDOW_HEIGHT, P2D);
  size(WINDOW_WIDTH, WINDOW_HEIGHT, JAVA2D);
}

void setup() {
  colorMode(HSB, 1.0);
  font = loadFont("Jygquip1-48.vlw");
  
  // Frame rate to be displayed every 30 frames.
  frameTimer = new FrameTimer(30);
  evoBoard = new Board(BOARD_WIDTH, BOARD_HEIGHT, NOISE_STEP_SIZE, MIN_TEMPERATURE, MAX_TEMPERATURE, 
  ROCKS_TO_ADD, CREATURE_MINIMUM, CREATURE_MAXIMUM, SEED, INITIAL_FILE_NAME, TIME_STEP);
  resetZoom();
}
void draw() {
  // Report frame rate.
  frameTimer.displayFrameRate();
  
  for (int iteration = 0; iteration < evoBoard.playSpeed; iteration++) {
    evoBoard.iterate(TIME_STEP);
  }
  
  if (dist(prevMouseX, prevMouseY, mouseX, mouseY) > 5) {
    draggedFar = true;
  }
  if (dragging == 1) {
    cameraX -= toWorldXCoordinate(mouseX, mouseY)-toWorldXCoordinate(prevMouseX, prevMouseY);
    cameraY -= toWorldYCoordinate(mouseX, mouseY)-toWorldYCoordinate(prevMouseX, prevMouseY);
  } else if (dragging == 2) { //UGLY UGLY CODE.  Do not look at this
    if (evoBoard.setMinTemperature(1.0-(mouseY-30)/660.0)) {
      dragging = 3;
    }
  } else if (dragging == 3) {
    if (evoBoard.setMaxTemperature(1.0-(mouseY-30)/660.0)) {
      dragging = 2;
    }
  }
  if (evoBoard.selectedCreature != null) {
    //Camera follow
    cameraX = (float)evoBoard.selectedCreature.position.x;
    cameraY = (float)evoBoard.selectedCreature.position.y;
    if (evoBoard.userControl) {
      //Camera Rotation
      cameraR = -PI/2.0-(float)evoBoard.selectedCreature.rotation;
    } else {
      cameraR = 0;
    }
  } else {
    cameraR = 0;
  }
  pushMatrix();
  scale(GROSS_OVERALL_SCALE_FACTOR);
  evoBoard.drawBlankBoard(SCALE_TO_FIX_BUG);
  
  translate(BOARD_WIDTH*0.5*SCALE_TO_FIX_BUG, BOARD_HEIGHT*0.5*SCALE_TO_FIX_BUG);
  scale(zoom);
  if (evoBoard.userControl && evoBoard.selectedCreature != null) {
    rotate(cameraR);
  }
  translate(-cameraX*SCALE_TO_FIX_BUG, -cameraY*SCALE_TO_FIX_BUG);
  
  evoBoard.drawBoard(SCALE_TO_FIX_BUG, zoom, (int)toWorldXCoordinate(mouseX, mouseY), (int)toWorldYCoordinate(mouseX, mouseY));
  popMatrix();
  
  evoBoard.drawUI(SCALE_TO_FIX_BUG, TIME_STEP, WINDOW_HEIGHT, 0, WINDOW_WIDTH, WINDOW_HEIGHT, font);

  evoBoard.fileSave();
  prevMouseX = mouseX;
  prevMouseY = mouseY;
}

void mouseWheel(MouseEvent event) {
  float delta = event.getCount();
  if (delta >= 0.5) {
    setZoom(zoom * 0.90909, mouseX, mouseY);
  } else if (delta <= -0.5) {
    setZoom(zoom * 1.1, mouseX, mouseY);
  }
}

void mousePressed() {
  if (mouseX < WINDOW_HEIGHT) {
    dragging = 1;
  } else {
    if (abs(mouseX - (WINDOW_HEIGHT + 65)) <= 60 && abs(mouseY - 147) <= 60 && evoBoard.selectedCreature != null) {
        cameraX = (float)evoBoard.selectedCreature.position.x;
        cameraY = (float)evoBoard.selectedCreature.position.y;
        zoom = 16;
    } else if (mouseY >= 95 && mouseY < 135 && evoBoard.selectedCreature == null) {
      if (mouseX >= WINDOW_HEIGHT+10 && mouseX < WINDOW_HEIGHT+230) {
        resetZoom();
      } else if (mouseX >= WINDOW_HEIGHT + 240 && mouseX < WINDOW_HEIGHT + 460) {
        evoBoard.creatureRankMetric = (evoBoard.creatureRankMetric + 1) % 8;
      }
    } else if (mouseY >= 570) {
      float x = (mouseX - (WINDOW_HEIGHT + 10));
      float y = (mouseY - 570);
      boolean clickedOnLeft = (x % 230 < 110);
      if (x >= 0 && x < 2 * 230 && y >= 0 && y < 4 * 50 && x % 230 < 220 && y % 50 < 40) {
        int mX = (int)(x / 230);
        int mY = (int)(y / 50);
        int buttonNum = mX + mY * 2;
        if (buttonNum == 0) {
          evoBoard.userControl = !evoBoard.userControl;
        } else if (buttonNum == 1) {
          if (clickedOnLeft) {
            evoBoard.creatureMinimum -= evoBoard.creatureMinimumIncrement;
          } else {
            evoBoard.creatureMinimum += evoBoard.creatureMinimumIncrement;
          }
        } else if (buttonNum == 2) {
          evoBoard.prepareForFileSave(0);
        } else if (buttonNum == 3) {
          if (clickedOnLeft) {
            evoBoard.imageSaveInterval *= 0.5;
          } else {
            evoBoard.imageSaveInterval *= 2.0;
          }
          if (evoBoard.imageSaveInterval >= 0.7) {
            evoBoard.imageSaveInterval = Math.round(evoBoard.imageSaveInterval);
          }
        } else if (buttonNum == 4) {
          evoBoard.prepareForFileSave(2);
        } else if (buttonNum == 5) {
          if (clickedOnLeft) {
            evoBoard.textSaveInterval *= 0.5;
          } else {
            evoBoard.textSaveInterval *= 2.0;
          }
          if (evoBoard.textSaveInterval >= 0.7) {
            evoBoard.textSaveInterval = Math.round(evoBoard.textSaveInterval);
          }
        }else if(buttonNum == 6){
          if (clickedOnLeft) {
            if(evoBoard.playSpeed >= 2){
              evoBoard.playSpeed /= 2;
            }else{
              evoBoard.playSpeed = 0;
            }
          } else {
            if(evoBoard.playSpeed == 0){
              evoBoard.playSpeed = 1;
            }else{
              evoBoard.playSpeed *= 2;
            }
          }
        } else if (buttonNum == 7) {
          if (clickedOnLeft) {
            evoBoard.creatureMaximum -= evoBoard.creatureMinimumIncrement;
          } else {
            evoBoard.creatureMaximum += evoBoard.creatureMinimumIncrement;
          }
        }
      }
    } else if (mouseX >= height + 10 && mouseX < width - 50 && evoBoard.selectedCreature == null) {
      int listIndex = (mouseY - 150) / 70;
      if (listIndex >= 0 && listIndex < evoBoard.LIST_SLOTS) {
        evoBoard.selectedCreature = evoBoard.list[listIndex];
        cameraX = (float)evoBoard.selectedCreature.position.x;
        cameraY = (float)evoBoard.selectedCreature.position.y;
        zoom = 16;
      }
    }
    if (mouseX >= width - 50) {
      float toClickTemp = (mouseY - 30) / 660.0;
      float lowTemp = 1.0 - evoBoard.getLowTempProportion();
      float highTemp = 1.0 - evoBoard.getHighTempProportion();
      if (abs(toClickTemp - lowTemp) < abs(toClickTemp - highTemp)) {
        dragging = 2;
      } else {
        dragging = 3;
      }
    }
  }
  draggedFar = false;
}

void mouseReleased() {
  if (!draggedFar) {
    if (mouseX < WINDOW_HEIGHT) { // DO NOT LOOK AT THIS CODE EITHER it is bad
      dragging = 1;
      float mX = toWorldXCoordinate(mouseX, mouseY);
      float mY = toWorldYCoordinate(mouseX, mouseY);
      int x = (int)(floor(mX));
      int y = (int)(floor(mY));
      evoBoard.unselect(false);
      cameraR = 0;
      if (x >= 0 && x < BOARD_WIDTH && y >= 0 && y < BOARD_HEIGHT) {
        Set<SoftBody> neighbours;
        //synchronized(evoBoard.hashGrid) {
          neighbours = evoBoard.hashGrid.get(new PVector(mX, mY));
        //}
        for(SoftBody body : neighbours){
        //for (int i = 0; i < evoBoard.softBodiesInPositions[x][y].size (); i++) {
        //  SoftBody body = (SoftBody)evoBoard.softBodiesInPositions[x][y].get(i);
          if(body == null) {
           continue; 
          }
          if (body.isCreature) {
            float distance = dist(mX, mY, (float)body.position.x, (float)body.position.y);
            if (distance <= body.getRadius()) {
              evoBoard.selectedCreature = (Creature)body;
              zoom = 16;
            }
          }
        }
      }
    }
  }
  dragging = 0;
}

void resetZoom() {
  cameraX = BOARD_WIDTH * 0.5;
  cameraY = BOARD_HEIGHT * 0.5;
  zoom = 1;
}

void setZoom(float target, float x, float y) {
  float grossX = grossify(x, BOARD_WIDTH);
  cameraX -= (grossX / target - grossX / zoom);
  float grossY = grossify(y, BOARD_HEIGHT);
  cameraY -= (grossY / target - grossY / zoom);
  zoom = target;
}

float grossify(float input, float total) { // Very weird function
  return (input / GROSS_OVERALL_SCALE_FACTOR - total * 0.5 * SCALE_TO_FIX_BUG) / SCALE_TO_FIX_BUG;
}

float toWorldXCoordinate(float x, float y) {
  float w = WINDOW_HEIGHT / 2;
  float angle = atan2(y - w, x - w);
  float dist = dist(w, w, x, y);
  return cameraX+grossify(cos(angle - cameraR) * dist + w, BOARD_WIDTH) / zoom;
}

float toWorldYCoordinate(float x, float y) {
  float w = WINDOW_HEIGHT / 2;
  float angle = atan2(y - w, x - w);
  float dist = dist(w, w, x, y);
  return cameraY+grossify(sin(angle - cameraR) * dist + w, BOARD_HEIGHT) / zoom;
}
