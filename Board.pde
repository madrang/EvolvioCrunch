import java.io.*;
import java.util.concurrent.*;
import java.util.Set;
import java.util.Collections;

//https://www.gicentre.net/utils/hashgrid
import org.gicentre.utils.geom.*;

class Board{
  int boardWidth;
  int boardHeight;
  int creatureMinimum;
  int creatureMaximum;
  Tile[][] tiles;
  double year = 0;
  
  float MIN_TEMPERATURE;
  float MAX_TEMPERATURE;
  final float THERMOMETER_MIN = -2;
  //final float THERMOMETER_MAX = 2;
  final float THERMOMETER_MAX = 8;
  
  final int ROCKS_TO_ADD;
  final float MIN_ROCK_ENERGY_BASE = 0.8;
  final float MAX_ROCK_ENERGY_BASE = 1.6;
  
  final float MIN_CREATURE_ENERGY = 10;
  final float MAX_CREATURE_ENERGY = 200.0;
  
  //final float UI_CREATURE_SCALE = 2.3;
  final float UI_CREATURE_SCALE = 1.5;
  //final float UI_CREATURE_SCALE = 0.9;

  final float ROCK_DENSITY = 5;
  final float OBJECT_TIMESTEPS_PER_YEAR = 100;
  final color ROCK_COLOR = color(0,0,0.5);
  final color BACKGROUND_COLOR = color(0,0,0.1);
  
  final float CREATURE_STROKE_WEIGHT = 0.04;
  
  HashGrid<SoftBody> hashGrid;
  //new and dead list is for added and removing from the hashgrid without using locking.
  ArrayList<SoftBody> newGridPtrList;
  ArrayList<SoftBody> deadGridPtrList;
  ArrayList<SoftBody> rocks;
  ArrayList<Creature> creatures;
  
  final int CREATURE_SURVIVAL_COUNT = 255;
  ArrayList<Creature> survivalRanking;
  final boolean CREATURE_SURVIVAL_REPRODUCTION = true;
  
  Creature selectedCreature = null;
  int creatureIDUpTo = 0;
  float[] letterFrequencies = {8.167,1.492,2.782,4.253,12.702,2.228,2.015,6.094,6.966,0.153,0.772,4.025,2.406,6.749,
  7.507,1.929,0.095,5.987,6.327,9.056,2.758,0.978,2.361,0.150,1.974,10000.0};//0.074};
  final int LIST_SLOTS = 6;
  int creatureRankMetric = 0;
  color buttonColor = color(0.82,0.8,0.7);
  
  Creature[] list = new Creature[LIST_SLOTS];
  final int creatureMinimumIncrement = 128;
  int lastDeathCount;
  double deathCountTimer;
  int curDeathCount = 0;
  int deathOldAge = 0;
  int deathOverweight = 0;
  int deathStarved = 0;
  int deathUnkownCauses = 0;
  
  String folder = "TEST";
  int[] fileSaveCounts;
  double[] fileSaveTimes;
  double imageSaveInterval = 64;
  double textSaveInterval = 64;
  
  final double FLASH_SPEED = 80;
  
  boolean userControl;
  double temperature;
  double MANUAL_BIRTH_SIZE = 1.2;
  boolean wasPressingB = false;
  double timeStep; 
  
  final long SEED;
  long mapSeed;
  final float STD_STEPS;
  
  final int POPULATION_HISTORY_LENGTH = 200;
  int[] populationHistory;
  double recordPopulationEvery = 0.02;
  
  int playSpeed = 1;
  
  Thread[] threads;
  TaskThread[] taskThreads;
  final LinkedBlockingQueue<Runnable> taskQueue;
  //final int MAX_THREADS = 8;
  final int MAX_THREADS = 12;
  //final int MAX_THREADS = 16;
  //final int MAX_THREADS = 24;

  public Board(int w, int h, float stepSize, float min, float max, int rta, int cmin, int cmax, int seed, String INITIAL_FILE_NAME, double ts){
    taskQueue = new LinkedBlockingQueue<Runnable>();
    threads = new Thread[MAX_THREADS];
    taskThreads = new TaskThread[MAX_THREADS];
    for(int i = 0; i < MAX_THREADS; i++){
      TaskThread tt = new TaskThread ("Thread " + i, taskQueue);
      taskThreads[i] = tt;
      threads[i] = new Thread(tt);
      threads[i].start();
    }
    
    boardWidth = w;
    boardHeight = h;
    tiles = new Tile[boardWidth][boardHeight];
    
    STD_STEPS = stepSize;
    SEED = seed;
    changeLand(SEED, stepSize);
    mapSeed = SEED;
    
    /*
    noiseSeed(SEED);
    randomSeed(SEED);
    for(int x = 0; x < boardWidth; x++){
      for(int y = 0; y < boardHeight; y++){
        float bigForce = pow(((float)y) / boardHeight,0.5);
        float fertility = noise(x * stepSize * 3, y * stepSize * 3) * (1 - bigForce) * 5.0 + noise(x * stepSize * 0.5, y  * stepSize * 0.5) * bigForce * 5.0 - 1.5;
        float climateType = noise(x * stepSize * 0.2 + 10000, y * stepSize * 0.2 + 10000) * 1.63 - 0.4;
        climateType = min(max(climateType, 0), 0.8);
        tiles[x][y] = new Tile(x, y, fertility, 0, climateType, this);
      }
    }
    */
    MIN_TEMPERATURE = min;
    MAX_TEMPERATURE = max;
    
    float maxHitDistance = (float)((EvoMath.MAXIMUM_SURVIVABLE_SIZE * 2.0) + Math.max(EvoMath.REPRODUCTION_RANGE, EvoMath.FIGHT_RANGE));
    hashGrid = new HashGrid<SoftBody>(boardWidth, boardHeight, maxHitDistance);
    
    ROCKS_TO_ADD = rta;
    rocks = new ArrayList<SoftBody>(0);
    for(int i = 0; i < ROCKS_TO_ADD; i++){
      rocks.add(new SoftBody(random(0,boardWidth),random(0,boardHeight),0,0,
      getRandomSize(),ROCK_DENSITY,hue(ROCK_COLOR),saturation(ROCK_COLOR),brightness(ROCK_COLOR),this,year));
    }
    
    creatureMinimum = cmin;
    creatureMaximum = cmax;
    lastDeathCount = cmax;
    creatures = new ArrayList<Creature>(0);
    deadGridPtrList = new ArrayList<SoftBody>(0);
    newGridPtrList = new ArrayList<SoftBody>(0);
    survivalRanking = new ArrayList<Creature>(0);
    
    maintainCreatureMinimum(false);
    waitTask();
    
    for(int i = 0; i < LIST_SLOTS; i++){
      list[i] = null;
    }
    
    folder = INITIAL_FILE_NAME;
    fileSaveCounts = new int[4];
    fileSaveTimes = new double[4];
    for(int i = 0; i < 4; i++){
      fileSaveCounts[i] = 0;
      fileSaveTimes[i] = -999;
    }
    
    userControl = false;
    
    timeStep = ts;
    populationHistory = new int[POPULATION_HISTORY_LENGTH];
    for(int i = 0; i < POPULATION_HISTORY_LENGTH; i++){
      populationHistory[i] = 0;
    }
  }
  
  public void drawBoard(float scaleUp, float camZoom, int mX, int mY){
    //Calculate start and end positions for screen occlusion rendering.
    int startX = max((int)toWorldXCoordinate(0, 0), 0);
    int startY = max((int)toWorldYCoordinate(0, 0), 0);
    int maxX = min((int)toWorldXCoordinate(WINDOW_HEIGHT, WINDOW_HEIGHT) + 1, boardWidth);
    int maxY = min((int)toWorldYCoordinate(WINDOW_HEIGHT, WINDOW_HEIGHT) + 1, boardHeight);
    
    if (selectedCreature != null && userControl) {
        //FIXME, Apply rotation for screen occlusion.
        //At the moment disable occlusion rendering due to issues.
        startX = 0;
        startY = 0;
        maxX = boardWidth;
        maxY = boardHeight;
    }
    
    for(int x = startX; x < maxX; x++){
      for(int y = startY; y < maxY; y++){
        tiles[x][y].drawTile(scaleUp, (mX == x && mY == y));
      }
    }
    
    for(int i = 0; i < rocks.size(); i++){
      SoftBody b = rocks.get(i);
      if (b == null) {
        continue;
      }
      if (b.position.x > startX && b.position.x < maxX && b.position.y > startY && b.position.y < maxY) {
        b.drawSoftBody(scaleUp);
      }
    }
    for(int i = 0; i < creatures.size(); i++){
      //Draw all creatures.
      Creature c = creatures.get(i);
      if (c == null) {
        continue;
      }
      if (c.position.x > startX && c.position.x < maxX && c.position.y > startY && c.position.y < maxY) {
        //Only if in viewport.
        c.drawSoftBody(scaleUp, camZoom, true);
      }
    }
  }
  
  public void drawBlankBoard(float scaleUp){
    fill(BACKGROUND_COLOR);
    rect(0, 0, scaleUp * boardWidth, scaleUp * boardHeight);
  }
  
  public void drawUI(float scaleUp,double timeStep, int x1, int y1, int x2, int y2, PFont font){
    fill(0, 0, 0);
    noStroke();
    rect(x1, y1, x2-x1, y2-y1);
    
    pushMatrix();
    translate(x1, y1);
    
    fill(0,0,1);
    textAlign(LEFT);
    textFont(font,48);
    String yearText = "Year "+nf((float)year,0,2);
    text(yearText,10,48);
    float seasonTextXCoor = textWidth(yearText)+50;
    textFont(font,24);
    String[] seasons = {"Winter", "Spring", "Summer", "Autumn"};
    text(seasons[(int)(getSeason() * 4)], seasonTextXCoor, 30);
    text("Population: " + creatures.size(), 10, 80);
    if (survivalRanking.size() >= 2) {
      Collections.sort(survivalRanking, new SurvivalComparator());
      text("Score: " + survivalRanking.get(0).surviveScore + "-" + survivalRanking.get(survivalRanking.size() - 1).surviveScore, 250, 80);
    }
    
    if(selectedCreature == null){
      //Empty list.
      for(int i = 0; i < LIST_SLOTS; i++){
        list[i] = null;
      }
      
      for(int i = 0; i < creatures.size(); i++){
        int lookingAt = 0;
        Creature crea = creatures.get(i);
        if (crea == null) {
          continue;
        }
        
        if(creatureRankMetric == 4){
          while(lookingAt < LIST_SLOTS && list[lookingAt] != null && list[lookingAt].name.compareTo(crea.name) < 0){
            lookingAt++;
          }
        }else if(creatureRankMetric == 5){
          while(lookingAt < LIST_SLOTS && list[lookingAt] != null && list[lookingAt].name.compareTo(crea.name) >= 0){
            lookingAt++;
          }
        }else{
          while(lookingAt < LIST_SLOTS && list[lookingAt] != null && list[lookingAt].measure(creatureRankMetric) > crea.measure(creatureRankMetric)){
            lookingAt++;
          }
        }
        if(lookingAt < LIST_SLOTS){
          for(int j = LIST_SLOTS - 1; j >= lookingAt + 1; j--){
            //Shift array by one.
            list[j] = list[j - 1];
          }
          list[lookingAt] = crea;
        }
      }
      double maxEnergy = 0;
      for(int i = 0; i < LIST_SLOTS; i++){
        if(list[i] != null && list[i].energy > maxEnergy){
          maxEnergy = list[i].energy;
        }
      }
      for(int i = 0; i < LIST_SLOTS; i++){
        if(list[i] != null){
          list[i].preferredRank += (i - list[i].preferredRank) * 0.4;
          float y = y1 + 175 + 70 * list[i].preferredRank;
          //TODO replace 40f with UI_CREATURE_SCALE
          list[i].drawCreature(45, y + 5, 40f / list[i].getRadius());
          textFont(font, 24);
          textAlign(LEFT);
          noStroke();
          fill(0.333, 1, 0.4);
          float multi = (x2 - x1 - 200);
          if(list[i].energy > 0){
            rect(85, y+5, (float)(multi * list[i].energy / maxEnergy), 25);
          }
          if(list[i].energy > 1){
            fill(0.333, 1, 0.8);
            rect(85 + (float)(multi/maxEnergy), y + 5, (float)(multi * (list[i].energy - 1) / maxEnergy), 25);
          }
          fill(0,0,1);
          text(list[i].getCreatureName() + " [" + list[i].id + "] (" + toAge(list[i].birthTime) + ", " + list[i].surviveScore + "pts)", 90, y);
          text("Energy: " + nf((float)(list[i].energy), 0, 2), 90, y + 25);
          //println(list[i].getCreatureName() + "Energy: " + list[i].energy);
        }
      }
      noStroke();
      fill(buttonColor);
      rect(10,95,220,40);
      rect(240,95,220,40);
      fill(0,0,1);
      textAlign(CENTER);
      text("Reset zoom", 120, 123);
      String[] sorts = {"Biggest","Smallest","Youngest","Oldest","A to Z","Z to A","Highest Gen","Lowest Gen"};
      text("Sort by: " + sorts[creatureRankMetric], 350, 123);
      
      textFont(font,19);
      String[] buttonTexts = {
        "Brain Control",
        "-  Maintain pop. at " + creatureMinimum + "  +",
        "Screenshot now","-   Image every "+nf((float)imageSaveInterval, 0, 2) + " years   +",
        "Text file now","-    Text every "+nf((float)textSaveInterval, 0, 2) + " years    +",
        "-    Play Speed (" + playSpeed + "x)    +",
        "-  Maximum pop. at " + creatureMaximum + "  +"
      };
      if(userControl){
        buttonTexts[0] = "Keyboard Control";
      }
      for(int i = 0; i < 8; i++){
        float x = (i % 2) * 230 + 10;
        float y = floor(i / 2) * 50 + 570;
        fill(buttonColor);
        rect(x, y, 220, 40);
        if(i >= 2 && i < 6){
          double flashAlpha = 1.0 * Math.pow(0.5, (year - fileSaveTimes[i - 2]) * FLASH_SPEED);
          fill(0, 0, 1, (float)flashAlpha);
          rect(x, y, 220, 40);
        }
        fill(0, 0, 1, 1);
        text(buttonTexts[i], x + 110, y + 17);
        if(i == 0){
        }else if(i == 1){
          text("-" + creatureMinimumIncrement +
          "                    +" + creatureMinimumIncrement, x + 110, y + 37);
        }else if(i <= 5){
          text(getNextFileName(i - 2), x + 110, y + 37);
        } else if (i == 7) {
          text("-" + creatureMinimumIncrement +
          "                    +" + creatureMinimumIncrement, x + 110, y + 37);
        }
      }
    } else {
      //selectedCreature != null
      float energyUsage = (float)selectedCreature.getEnergyUsage(timeStep);
      noStroke();
      if(energyUsage <= 0){
        fill(0,1,0.5);
      }else{
        fill(0.33,1,0.4);
      }
      float EUbar = 20 * energyUsage;
      rect(110, 280, min(max(EUbar, -110), 110), 25);
      if(EUbar < -110){
        rect(0, 280, 25, (-110 - EUbar) * 20 + 25);
      }else if(EUbar > 110){
        float h = (EUbar - 110) * 20 + 25;
        rect(185, 280 - h, 25, h);
      }
      fill(0,0,1);
      text("Name: " + selectedCreature.getCreatureName(), 10, 225);
      text("Energy: " + nf((float)selectedCreature.energy, 0, 2) + " yums", 10, 250);
      text("E Change: " + nf(energyUsage, 0, 2)+" yums/year", 10, 275);
      
      text("ID: " + selectedCreature.id,10,325);
      text("X: " + nf((float)selectedCreature.position.x, 0, 2), 10, 350);
      text("Y: " + nf((float)selectedCreature.position.y, 0, 2), 10, 375);
      text("Rotation: " + nf((float)selectedCreature.rotation, 0, 2), 10, 400);
      text("B-day: " + toDate(selectedCreature.birthTime), 10, 425);
      text("(" + toAge(selectedCreature.birthTime) + ")",10, 450);
      text("Generation: " + selectedCreature.gen, 10, 475);
      text("Parents: " + selectedCreature.parents, 10, 500, 210, 255);
      text("Hue: " + nf((float)(selectedCreature.hue), 0, 2), 10, 550, 210, 255);
      text("Mouth hue: " + nf((float)(selectedCreature.mouthHue), 0, 2), 10, 575, 210, 255);
      
      if(userControl){
        text("Controls:\nUp/Down: Move\nLeft/Right: Rotate\nSpace: Eat\nF: Fight\nV: Vomit\nU,J: Change color"+
        "\nI,K: Change mouth color\nB: Give birth (Not possible if under " + Math.round(MANUAL_BIRTH_SIZE + 1) + " yums)", 10, 625, 250, 400);
      }
      
      pushMatrix();
      translate(400,80);
      float apX = round((mouseX - 400 - x1) / 46.0);
      float apY = round((mouseY - 80 - y1) / 46.0);
      selectedCreature.brain.drawBrain(font, 46, (int)apX, (int)apY);
      popMatrix();
    }
    
    drawPopulationGraph(x1, x2, 770, y2);
    
    fill(0,0,0);
    textAlign(RIGHT);
    textFont(font,24);
    text("Population: "+creatures.size(), x2 - x1 - 10, y2 - y1 - 10);
    popMatrix();
    
    pushMatrix();
    translate(x2, y1);
    textAlign(RIGHT);
    textFont(font, 24);
    text("Temperature", -10, 24);
    drawThermometer(-45, 30, 20, 660, temperature, THERMOMETER_MIN, THERMOMETER_MAX, color(0,1,1));
    popMatrix();
    
    if(selectedCreature != null){
      //TODO Replace 40f with UI_CREATURE_SCALE
      selectedCreature.drawCreature(x1 + 65, y1 + 147, 40f / selectedCreature.getRadius());
      //selectedCreature.drawCreature(x1 + 65, y1 + 147, UI_CREATURE_SCALE, scaleUp);
    }
  }
  
  void drawPopulationGraph(float x1, float x2, float y1, float y2){
    float barWidth = (x2-x1) / ((float)(POPULATION_HISTORY_LENGTH));
    
    noStroke();
    fill(0.33333, 1, 0.6);
    
    int maxPopulation = 0;
    for(int i = 0; i < POPULATION_HISTORY_LENGTH; i++){
      if(populationHistory[i] > maxPopulation){
        maxPopulation = populationHistory[i];
      }
    }
    for(int i = 0; i < POPULATION_HISTORY_LENGTH; i++){
      float h = (((float)populationHistory[i]) / maxPopulation) * (y2 - y1);
      rect((POPULATION_HISTORY_LENGTH-1-i) * barWidth, y2 - h, barWidth, h);
    }
  }
  
  String getNextFileName(int type){
    String[] modes = {"manualImgs","autoImgs","manualTexts","autoTexts"};
    String ending = ".png";
    if(type >= 2){
      ending = ".txt";
    }
    return folder+"/"+modes[type]+"/"+nf(fileSaveCounts[type],5)+ending;
  }
  
  public void updateHashGrid() {
    // Update the hash grid with new position of all the SoftBody.
    
    //taskQueue.add(new BoardTask(this, BoardStatus.HASHGRID));
    //waitTask();
    
    //Remove dead bodies.
    for (SoftBody sb : deadGridPtrList) {
      if (sb == null){
        continue;
      }
      hashGrid.remove(sb);
    }
    deadGridPtrList.clear();
    
    //Add new softbodies.
    for (SoftBody sb : newGridPtrList) {
      if (sb == null){
        continue;
      }
      hashGrid.add(sb);
    }
    newGridPtrList.clear();
    
    // Update the hash grid with new position of all the SoftBody.
    hashGrid.updateAll();
  }
  
  public void iterate(double timeStep) {
    updateHashGrid();
    
    //Timers
    deathCountTimer += timeStep;
    
    //Update Pop History
    double prevYear = year;
    year += timeStep;
    if(Math.floor(year / recordPopulationEvery) != Math.floor(prevYear / recordPopulationEvery)){
      for(int i = POPULATION_HISTORY_LENGTH - 1; i >= 1; i--){
        populationHistory[i] = populationHistory[i - 1];
      }
      populationHistory[0] = creatures.size();
    }
    
    //Update tiles for current season.
    temperature = getGrowthRate(getSeason());
    taskQueue.add(new BoardTask(this, BoardStatus.Tiles));
    
    //Update Rocks.
    /*for(int i = 0; i < rocks.size(); i++){
      rocks.get(i).collide(timeStep*OBJECT_TIMESTEPS_PER_YEAR);
    }*/
    
    //maintainCreatureMinimum(CREATURE_SURVIVAL_REPRODUCTION);
    taskQueue.add(new BoardTask(this, BoardStatus.MaintainCreatureMinimum));
    
    //Update creatures.
    for(int i = 0; i < creatures.size(); i++){
      Creature me = creatures.get(i);
      
      CreatureDeathCauses deathCause = CreatureDeathCauses.None;
      if(me == null || (deathCause = me.shouldDie()) != CreatureDeathCauses.None){
        if (me != null) {
          taskQueue.add(new CreatureTask(me, timeStep, CreatureStatus.DESTRUCTION));
          
          //Print death log.
          if (deathCause == CreatureDeathCauses.OldAge) {
            //Died of old age.
            deathOldAge++;
            if (lastDeathCount < 8) {
              double age = (year + timeStep) - me.birthTime;
              println("Removing: " + me.name + "(" + me.surviveScore + ") due to old age " + nf((float)(year - me.birthTime), 0, 2) + " at array pos: " + i);
            }
          } else if (deathCause == CreatureDeathCauses.Overweight) {
            //Overweight
            deathOverweight++;
            if (lastDeathCount < 8) {
              println("Removing: " + me.name + "(" + me.surviveScore + ") as overweight " + nf((float)(year - me.birthTime), 0, 2) + " at array pos: " + i);
            }
          } else if (deathCause == CreatureDeathCauses.Starved) {
            //No energy and age > 50% life expectency.
            //Died at 50% or more life time.
            deathStarved++;
            if (lastDeathCount < 8) {
              println("Removing: " + me.name + "(" + me.surviveScore + ") starved to death at age " + nf((float)(year - me.birthTime), 0, 2) + " at array pos: " + i);
            }
          } else {
            //Unknown causes...
          deathUnkownCauses++;
          if (lastDeathCount < 8) {
              println("Removing: " + me.name + "(" + me.surviveScore + ") died at age " + nf((float)(year - me.birthTime), 0, 2) + " at array pos: " + i);
            }
          }
        }
        curDeathCount++;
        creatures.remove(i);
        i--;
      } else if(userControl && me == selectedCreature){
        //Add creature to processing queue.
        taskQueue.add(new CreatureTask(me, timeStep, CreatureStatus.USERCONTROLLED));
        
        if(keyPressed){
           if (key == CODED) {
            if (keyCode == UP) me.accelerate(0.04, timeStep * OBJECT_TIMESTEPS_PER_YEAR);
            if (keyCode == DOWN) me.accelerate(-0.04, timeStep * OBJECT_TIMESTEPS_PER_YEAR);
            if (keyCode == LEFT) me.turn(-0.1, timeStep * OBJECT_TIMESTEPS_PER_YEAR);
            if (keyCode == RIGHT) me.turn(0.1, timeStep * OBJECT_TIMESTEPS_PER_YEAR);
          }else{
            if(key == ' ') me.eat(0.1, timeStep * OBJECT_TIMESTEPS_PER_YEAR);
            if(key == 'v') me.eat(-0.1, timeStep * OBJECT_TIMESTEPS_PER_YEAR);
            if(key == 'f') me.fight(0.5,timeStep * OBJECT_TIMESTEPS_PER_YEAR);
            if(key == 'u') me.setHue(me.hue + 0.02);
            if(key == 'j') me.setHue(me.hue - 0.02);
            
            if(key == 'i') me.setMouthHue(me.mouthHue + 0.02);
            if(key == 'k') me.setMouthHue(me.mouthHue - 0.02);
            if(key == 'q') me.energy = 0;
            if(key == 'b') {
              if(!wasPressingB) {
                me.reproduce(MANUAL_BIRTH_SIZE, timeStep);
              }
              wasPressingB = true;
            }else{
              wasPressingB = false;
            }
          }
        }
      } else {
        //Add creature to processing queue.
        taskQueue.add(new CreatureTask(me, timeStep, CreatureStatus.THINK));
      }
    }
    
    float deathStep = 0.01f;
    if (deathCountTimer > 0.01f) {
      if (curDeathCount > 8) {
        if (deathUnkownCauses > 0) {
          println("Death Count: " + curDeathCount + ", Died of old age: " + deathOldAge + ", Died of Overweight: " + deathOverweight + ", Starved to death: " + deathStarved + ", Unknown: " + deathUnkownCauses);
        } else {
          println("Death Count: " + curDeathCount + ", Died of old age: " + deathOldAge + ", Died of Overweight: " + deathOverweight + ", Starved to death: " + deathStarved);
        }
      }
      
      deathCountTimer -= deathStep;
      lastDeathCount = curDeathCount;
      //Reset timer values.
      curDeathCount = 0;
      deathOldAge = 0;
      deathOverweight = 0;
      deathStarved = 0;
      deathUnkownCauses = 0;
    } else {
      //println("TimerTst: " + deathCountTimer); 
    }
    
    //waitTask();
    finishIterate(timeStep);
  }
  
  public void finishIterate(double timeStep){
    for(int i = 0; i < rocks.size(); i++){
      rocks.get(i).applyMotions(timeStep * OBJECT_TIMESTEPS_PER_YEAR);
    }
    for(int i = 0; i < creatures.size(); i++){
      Creature crea = creatures.get(i);
      taskQueue.add(new CreatureTask(crea, timeStep * OBJECT_TIMESTEPS_PER_YEAR, CreatureStatus.APPLYMOTION));
      //creatures.get(i).applyMotions(timeStep*OBJECT_TIMESTEPS_PER_YEAR);
      //creatures.get(i).see(timeStep*OBJECT_TIMESTEPS_PER_YEAR);
    }

    waitTask();
    
    if(Math.floor(fileSaveTimes[1] / imageSaveInterval) != Math.floor(year / imageSaveInterval)){
      prepareForFileSave(1);
    }
    if(Math.floor(fileSaveTimes[3] / textSaveInterval) != Math.floor(year / textSaveInterval)){
      prepareForFileSave(3);
    }
  }
  
  private void waitTask(){
    //int manuallyProcessed = 0;
    while(!taskQueue.isEmpty()){
      try {
        //Try to process some task instead of waiting for completion.
        Runnable task = taskQueue.poll(0, TimeUnit.NANOSECONDS);
        if (task != null) {
          try {
            //manuallyProcessed++;
            task.run();
          } catch (Exception e) {
            println("RenderThread:TaskThread.run, Exception: " + e);
          }
        }
      } catch (InterruptedException e) {
        println("CreatureThread.manrun: " + e);
      }
    }
    
    //Wait for all threads to complete the currently running task.
    for(int i = 0; i < MAX_THREADS; i++){
      TaskThread tt = taskThreads[i];
      tt.waitIdle();
    }
    
    /*
    if (manuallyProcessed > 0) {
      println("Manually processed " + manuallyProcessed + " operations.");
    }
    */
  }
  
  private double getGrowthRate(double theTime){
    double temperatureRange = MAX_TEMPERATURE-MIN_TEMPERATURE;
    return MIN_TEMPERATURE + temperatureRange * 0.5 - temperatureRange * 0.5 * Math.cos(theTime * 2*Math.PI);
  }
  
  private double getGrowthOverTimeRange(double startTime, double endTime){
    double temperatureRange = MAX_TEMPERATURE - MIN_TEMPERATURE;
    double m = MIN_TEMPERATURE + temperatureRange * 0.5;
    return (endTime - startTime) * m + (temperatureRange / Math.PI / 4.0) * (Math.sin(2*Math.PI * startTime) - Math.sin(2*Math.PI * endTime));
  }
  
  private double getSeason(){
    return (year % 1.0);
  }
  
  private void changeLand(long seed, float stepSize)
  {
    mapSeed = seed;
    noiseSeed(seed);
    randomSeed(seed);
    for(int x = 0; x < boardWidth; x++){
      for(int y = 0; y < boardHeight; y++){
        float bigForce = pow(((float)y) / boardHeight,0.5);
        float fertility = noise(x * stepSize * 3, y * stepSize * 3) * (1 - bigForce) * 5.0 + noise(x * stepSize * 0.5, y  * stepSize * 0.5) * bigForce * 5.0 - 1.5;
        float climateType = noise(x * stepSize * 0.2 + 10000, y * stepSize * 0.2 + 10000) * 1.63 - 0.4;
        climateType = min(max(climateType, 0), 0.8);
        if (tiles[x][y] == null) {
          //No previous tile, create a new one.
          tiles[x][y] = new Tile(x, y, fertility, 0, climateType, this);
        } else {
          //Update the old tile.
          tiles[x][y].fertility_setPoint = Math.max(0, fertility);
          //tiles[x][y].foodLevel = 0;
          //tiles[x][y].foodType = climateType;
          tiles[x][y].climateType = climateType;
        }
      }
    } 
  }
  
  private void drawThermometer(float x1, float y1, float w, float h, double prog, double min, double max,
  color fillColor){
    noStroke();
    fill(0, 0, 0.2);
    rect(x1, y1, w, h);
    fill(fillColor);
    double proportionFilled = (prog - min) / (max - min);
    rect(x1, (float)(y1 + h * (1 - proportionFilled)), w, (float)(proportionFilled * h));
    
    double zeroHeight = (0 - min) / (max - min);
    double zeroLineY = y1 + h * (1 - zeroHeight);
    textAlign(RIGHT);
    stroke(0, 0, 1);
    strokeWeight(3);
    line(x1, (float)(zeroLineY), x1 + w, (float)(zeroLineY));
    double minY = y1 + h * (1 - (MIN_TEMPERATURE - min) / (max - min));
    double maxY = y1 + h * (1 - (MAX_TEMPERATURE - min) / (max - min));
    fill(0, 0, 0.8);
    line(x1, (float)(minY), x1 + w * 1.8, (float)(minY));
    line(x1, (float)(maxY), x1 + w * 1.8, (float)(maxY));
    line(x1 + w * 1.8, (float)(minY), x1 + w * 1.8, (float)(maxY));
    
    fill(0, 0, 1);
    text("Zero", x1 - 5, (float)(zeroLineY + 8));
    text(nf(MIN_TEMPERATURE, 0, 2), x1 - 5, (float)(minY + 8));
    text(nf(MAX_TEMPERATURE, 0, 2), x1 - 5, (float)(maxY + 8));
  }
  
  private void drawVerticalSlider(float x1, float y1, float w, float h, double prog, color fillColor, color antiColor){
    noStroke();
    fill(0, 0, 0.2);
    rect(x1, y1, w, h);
    
    if(prog >= 0){
      fill(fillColor);
    }else{
      fill(antiColor);
    }
    
    rect(x1, (float)(y1 + h * (1 - prog)), w, (float)(prog * h));
  }
  
  private boolean setMinTemperature(float temp){
    MIN_TEMPERATURE = tempBounds(THERMOMETER_MIN + temp * (THERMOMETER_MAX - THERMOMETER_MIN));
    if(MIN_TEMPERATURE > MAX_TEMPERATURE){
      float placeHolder = MAX_TEMPERATURE;
      MAX_TEMPERATURE = MIN_TEMPERATURE;
      MIN_TEMPERATURE = placeHolder;
      return true;
    }
    return false;
  }
  
  private boolean setMaxTemperature(float temp){
    MAX_TEMPERATURE = tempBounds(THERMOMETER_MIN + temp * (THERMOMETER_MAX - THERMOMETER_MIN));
    if(MIN_TEMPERATURE > MAX_TEMPERATURE){
      float placeHolder = MAX_TEMPERATURE;
      MAX_TEMPERATURE = MIN_TEMPERATURE;
      MIN_TEMPERATURE = placeHolder;
      return true;
    }
    return false;
  }
  
  private float tempBounds(float temp){
    return min(max(temp, THERMOMETER_MIN), THERMOMETER_MAX);
  }
  
  private float getHighTempProportion(){
    return (MAX_TEMPERATURE - THERMOMETER_MIN) / (THERMOMETER_MAX - THERMOMETER_MIN);
  }
  
  private float getLowTempProportion(){
    return (MIN_TEMPERATURE - THERMOMETER_MIN) / (THERMOMETER_MAX - THERMOMETER_MIN);
  }
  
  private String toDate(double d){
    return "Year " + nf((float)(d),0,2);
  }
  
  private String toAge(double d){
    return nf((float)(year - d), 0, 2) + "yrs old";
  }
  
  private void maintainCreatureMinimum() {
    maintainCreatureMinimum(CREATURE_SURVIVAL_REPRODUCTION);
  }
  
  private void maintainCreatureMinimum(boolean choosePreexisting) {
    int missing = creatureMinimum - creatures.size();
    while(missing > 0){
      //createCreature(choosePreexisting);
      if (choosePreexisting && survivalRanking.size() > CREATURE_SURVIVAL_COUNT / 2) {
        taskQueue.add(new BoardTask(this, BoardStatus.NewSurvivorMutation));
      } else {
        taskQueue.add(new BoardTask(this, BoardStatus.GenerateNewCreature));
      }
      missing--;
    }
  }

  private void createCreature() {
    boolean choosePreexisting = CREATURE_SURVIVAL_REPRODUCTION;
    createCreature(choosePreexisting);
  }
  
  private void createCreature(boolean choosePreexisting) {
    if(choosePreexisting && survivalRanking.size() > CREATURE_SURVIVAL_COUNT / 2) {
      newSurvivorMutation();
    } else {
      generateNewCreature();
    }
  }
  
  private void newSurvivorMutation() {
    //Creature c = getRandomCreature();
    Creature c = getRandomSurvivor();
    c.addEnergy(c.SAFE_SIZE);
    c.reproduce(c.SAFE_SIZE, timeStep);
    Tile goodTile = getRandomTile(true);
    c.position.x = goodTile.posX + 0.5f;
    c.position.y = goodTile.posY + 0.5f;
  }
  
  private void generateNewCreature() {
    Tile t = getRandomTile(true);
    int creadDensity = 1;
    Creature chld = new Creature(t.posX + 0.5f, t.posY + 0.5f, 0, 0,
      random(MIN_CREATURE_ENERGY, MAX_CREATURE_ENERGY), creadDensity, random(0, 1), 1, 1,
      this, year, random(0, 2*PI), 0, "","[PRIMORDIAL]", true, null, 1, random(0, 1)
    );
    creatures.add(chld);
  }
  
  public void checkSurvive(Creature c){
    if (c == null) {
      return;
    }
    
    double age = year - c.birthTime;
    if (age < 0.125f) {
      //Should live at least some amout of time.
      return;
    }
    
    synchronized(survivalRanking) {
      if (survivalRanking.size() < CREATURE_SURVIVAL_COUNT) {
        survivalRanking.add(c);
        return;
      }
      Collections.sort(survivalRanking, new SurvivalComparator());
      
      if(survivalRanking.get(survivalRanking.size() - 1).surviveScore < c.surviveScore){
        survivalRanking.add(c);
        Collections.sort(survivalRanking, new SurvivalComparator());
      }
      
      while(survivalRanking.size() > CREATURE_SURVIVAL_COUNT) {
        survivalRanking.remove(survivalRanking.size() - 1);
      }
    }
  }
  
  private Creature getRandomCreature(){
    int index = (int)(random(0, creatures.size()));
    return creatures.get(index);
  }
  
  private Creature getRandomSurvivor(){
    synchronized(survivalRanking) {
      int len = survivalRanking.size();
      if (len < 2) {
        return getRandomCreature();
      }
      int index = (int)(random(0, survivalRanking.size()));
      return survivalRanking.get(index);
    }
  }
  
  private Tile getRandomTile(boolean livable){
    boolean foundLiv = false;
    int indX = (int)(random(0, boardWidth));
    int indY = (int)(random(0, boardHeight));
    Tile t = null;
    
    while (livable && !foundLiv) {
      t = tiles[indX][indY];
      indX = (int)(random(0, boardWidth));
      indY = (int)(random(0, boardHeight));
      foundLiv = t.fertility < 0.9f;
    }
    return t;
  }
  
  private double getRandomSize(){
    return pow(random(MIN_ROCK_ENERGY_BASE, MAX_ROCK_ENERGY_BASE), 4);
  }
  

  private void prepareForFileSave(int type){
    fileSaveTimes[type] = -999999;
  }
  
  private void fileSave(){
    for(int i = 0; i < 4; i++){
      if(fileSaveTimes[i] < -99999){
        fileSaveTimes[i] = year;
        if(i < 2){
          saveFrame(getNextFileName(i));
        }else{
          String[] data = this.toBigString();
          saveStrings(getNextFileName(i),data);
        }
        fileSaveCounts[i]++;
      }
    }
  }
  
  public String[] toBigString(){ // Convert current evolvio board into string. Does not work
    String[] placeholder = {"Goo goo","Ga ga"};
    return placeholder;
  }
  
  public void unselect(){
    boolean replace = true;
    unselect(replace);
  }
  
  public void unselect(boolean replace){
    if (replace) {
      selectedCreature = getRandomCreature();;
    } else {
      selectedCreature = null;
    }
  }
}
