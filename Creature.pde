import java.util.Comparator;

enum CreatureDeathCauses {
  //Should Live
  None,
  Starved,
  Overweight,
  OldAge,
}

//TODO Change move score so it is based on distance relative to world (Fix moving in circles).

class Creature extends SoftBody{
  double ACCELERATION_ENERGY = 0.001;
  double ACCELERATION_BACK_ENERGY = 0.009;
  double SWIM_ENERGY = 0.8;
  double TURN_ENERGY = 0.025;
  double EAT_ENERGY = 0.5;
  double EAT_SPEED = 0.33; // 1 is instant, 0 is nonexistent, 0.001 is verrry slow.
  double EAT_WHILE_MOVING_INEFFICIENCY_MULTIPLIER = 2.0; // The bigger this number is, the less effiently creatures eat when they're moving.
  double FIGHT_ENERGY = 15;
  double INJURED_ENERGY = 25;
  double METABOLISM_ENERGY = 0.04f;
  String name;
  String parents;
  int gen;
  int id;
  double MAX_VISION_DISTANCE = 10;
  double currentEnergy;
  
  final int ENERGY_HISTORY_LENGTH = 6;
  final double SAFE_SIZE = 1.25;
  
  double[] previousEnergy = new double[ENERGY_HISTORY_LENGTH];
  
  final double MATURE_AGE = 0.1;
  final double FOOD_SENSITIVITY = 0.3;
  
  final double DRAW_DISTANCE_VISION = 1;
  final double DRAW_DISTANCE_VISION_CROSS = 1;
  final double DRAW_DISTANCE_MOUTH = 1;
  final double DRAW_DISTANCE_NAME = 1;
  final double DRAW_DISTANCE_MINIMUM_SURVIVABLE = 1;
  
  double vr = 0;
  double rotation = 0;
  
  final String[] inputLabels = {
    "Size",
  };
  final String[] outputLabels = {
    "BHue",
    "Accel.",
    "Turn",
    "Eat",
    "Fight",
    "Birth",
    "MHue",
  };
  
  //final int BRAIN_WIDTH = 3;
  final int BRAIN_WIDTH = 4;
  //final int BRAIN_HEIGHT = 13;
  //final int BRAIN_WIDTH = 7;
  final int BRAIN_HEIGHT = 19;
  Brain brain;
  
  final int MIN_NAME_LENGTH = 3;
  final int MAX_NAME_LENGTH = 10;
  final float BRIGHTNESS_THRESHOLD = 0.7;
  
  float preferredRank = 8;
  Vision vision;
  
  float CROSS_SIZE = 0.022;
  
  double birthHue;
  double mouthHue;
  
  long surviveScore;
  boolean alive;
  
  public Creature(float tpx, float tpy, float tvx, float tvy, double tenergy,
  double tdensity, double thue, double tsaturation, double tbrightness, Board tb, double bt,
  double rot, double tvr, String tname,String tparents, boolean mutateName,
  Brain tbrain, int tgen, double tmouthHue){
    super(tpx,tpy,tvx,tvy,tenergy,tdensity, thue, tsaturation, tbrightness, tb, bt);
    
    vision = new Vision (this);
    if (tbrain == null) {
      brain = new Brain(this, BRAIN_WIDTH, BRAIN_HEIGHT);
    } else {
      brain = tbrain;
    }
    
    rotation = rot;
    vr = tvr;
    isCreature = true;
    id = board.creatureIDUpTo + 1;
    if(tname.length() >= 1){
      if(mutateName){
        name = mutateName(tname);
      }else{
        name = tname;
      }
      name = sanitizeName(name);
    }else{
      name = createNewName();
    }
    parents = tparents;
    board.creatureIDUpTo++;
    
    gen = tgen;
    mouthHue = tmouthHue;
    birthHue = thue;
    surviveScore = 0;
    alive = true;
    
    //synchronized(board.hashGrid) {
      //board.hashGrid.add(this);
      board.newGridPtrList.add(this);
    //}
  }
  
  public void drawSoftBody(float scaleUp, float camZoom, boolean showVision){
    push();
    scale(scaleUp);
    drawSoftBody(false, camZoom, showVision);
    pop();
  }
  
  public void drawSoftBody(boolean local, float camZoom, boolean showVision){

    ellipseMode(RADIUS);
    float radius = getRadius();
    if(showVision && camZoom > 0.10f / EvoMath.MINIMUM_SURVIVABLE_SIZE){
      //Draw Vision, but only if it can be seen...
      for(int i = 0; i < vision.visionAngles.length; i++){
        color visionUIcolor = color(0,0,1);
        if(vision.visionResults[i * vision.STATIC_INPUT_COUNT + 2] > BRIGHTNESS_THRESHOLD){
          visionUIcolor = color(0,0,0);
        }
        stroke(visionUIcolor);
        strokeWeight(board.CREATURE_STROKE_WEIGHT);
        PVector start = vision.getVisionStart(i);
        PVector end = vision.getVisionEnd(i);
        line(start.x, start.y, end.x, end.y);
        noStroke();
        fill(visionUIcolor);
        ellipse(vision.visionOccluded[i].x, vision.visionOccluded[i].y, 2.5f * CROSS_SIZE, 2.5f * CROSS_SIZE);
        
        //Draw a cross at Vision point.
        if (camZoom > 0.4f / EvoMath.MINIMUM_SURVIVABLE_SIZE) {
          //Only if it can be seen...
          stroke((float)(vision.visionResults[i * vision.STATIC_INPUT_COUNT] + 1) / 2.0f, (float)(vision.visionResults[i * vision.STATIC_INPUT_COUNT + 1] + 1) / 2.0f, (float)(vision.visionResults[i * vision.STATIC_INPUT_COUNT + 2] + 1) / 2.0f);
          strokeWeight(board.CREATURE_STROKE_WEIGHT);
          // Draw cross
          PVector visionOccluded = vision.visionOccluded[i];
          line(visionOccluded.x - CROSS_SIZE, visionOccluded.y - CROSS_SIZE, visionOccluded.x + CROSS_SIZE, visionOccluded.y + CROSS_SIZE);
          line(visionOccluded.x - CROSS_SIZE, visionOccluded.y + CROSS_SIZE, visionOccluded.x + CROSS_SIZE, visionOccluded.y - CROSS_SIZE);
        }
      }
    }
    
    push();
    if (!local) {
      translate(position.x, position.y);
    }
    
    noStroke();
    if(fightLevel > 0){
      fill(0,1,1,(float)(fightLevel * 0.8));
      ellipse(0, 0, EvoMath.FIGHT_RANGE * radius, EvoMath.FIGHT_RANGE * radius);
    }
    
    
    if(this == board.selectedCreature){
      strokeWeight(board.CREATURE_STROKE_WEIGHT);
      stroke(0,0,1);
      fill(0,0,1);
      //ellipse(0, 0, radius + 1 + 75.0 / camZoom, radius + 1 + 75.0 / camZoom);
      ellipse(0, 0, radius + 0.125f + (0.5f / camZoom), radius + 0.125f + (0.5f / camZoom));
    }
    
    //Draw Body
    super.drawSoftBody(true);
    
    //Add ellipse to show minimum viable size.
    if (camZoom > 0.45f / EvoMath.MINIMUM_SURVIVABLE_SIZE) {
      noFill();
      strokeWeight(board.CREATURE_STROKE_WEIGHT);
      stroke(0,0,1);
      ellipseMode(RADIUS);
      ellipse(0, 0, EvoMath.MINIMUM_SURVIVABLE_SIZE, EvoMath.MINIMUM_SURVIVABLE_SIZE);
    }
    
    //Draw Mouth
    if (camZoom > 0.33f / EvoMath.MINIMUM_SURVIVABLE_SIZE) {
      strokeWeight((float)(board.CREATURE_STROKE_WEIGHT/(radius * 100)));
      stroke(0,0,0);
      fill((float)mouthHue,1.0,1.0);
            
      pushMatrix();
      //translate((float)(position.x * scaleUp), (float)(position.y * scaleUp));
      scale(radius);
      rotate((float)rotation);
      ellipse(0.75f, 0, 0.33f, 0.33f);
      
      /*rect(-0.7*scaleUp,-0.2*scaleUp,1.1*scaleUp,0.4*scaleUp);
      beginShape();
      vertex(0.3*scaleUp,-0.5*scaleUp);
      vertex(0.3*scaleUp,0.5*scaleUp);
      vertex(0.8*scaleUp,0.0*scaleUp);
      endShape(CLOSE);*/
      popMatrix();
    }
    
    //Draw Name
    if(showVision && camZoom > 0.25f / EvoMath.MINIMUM_SURVIVABLE_SIZE){
      fill(0,0,1);
      textFont(font, 0.2);
      textAlign(CENTER);
      text(getCreatureName(), 0, 0 - getRadius() * 1.4 - 0.07);
    }
    
    pop();
  }
  
  public void drawCreature(float x, float y, float scale, float scaleUp){
    pushMatrix();
    float scaleIconUp = scaleUp * scale;
    translate((float)(-position.x * scaleIconUp), (float)(-position.y * scaleIconUp));
    translate(x, y);
    drawSoftBody(scaleIconUp, 40.0 / scale, false);
    popMatrix();
  }
  
  public void drawCreature(float x, float y, float scale){
    pushMatrix();
    translate(x, y);
    scale(scale);
    drawSoftBody(true, 1000.0f, false);
    popMatrix();
  }
  
  public void metabolize(double timeStep){
    loseEnergy(energy * METABOLISM_ENERGY * timeStep);
    //adjSurviveScore(1);
  }
  
  public void accelerate(double amount, double timeStep){
    double multiplied = amount * timeStep / getMass();
    velocity.x += Math.cos(rotation) * multiplied;
    velocity.y += Math.sin(rotation) * multiplied;
    adjSurviveScore((int)(10 * abs((float)amount)));
    if(amount >= 0){
      loseEnergy(amount * ACCELERATION_ENERGY * timeStep);
    }else{
      loseEnergy(Math.abs(amount * ACCELERATION_BACK_ENERGY * timeStep));
    }
  }
  
  public void turn(double amount, double timeStep){
    vr += 0.04 * amount * timeStep / getMass();
    loseEnergy(Math.abs(amount * TURN_ENERGY * energy * timeStep));
  }
  
  public Tile getRandomCoveredTile(){
    double radius = (float)getRadius();
    double choiceX = 0;
    double choiceY = 0;
    while(dist((float)position.x,(float)position.y,(float)choiceX,(float)choiceY) > radius){
      choiceX = (Math.random() * 2 * radius - radius) + position.x;
      choiceY = (Math.random() * 2 * radius - radius) + position.y;
    }
    int x = xBound((int)choiceX);
    int y = yBound((int)choiceY);
    return board.tiles[x][y];
  }
  
  public void eat(double attemptedAmount, double timeStep){
    double amount = attemptedAmount / (1.0 + EvoMath.distance(0, 0, velocity.x, velocity.y) * EAT_WHILE_MOVING_INEFFICIENCY_MULTIPLIER); // The faster you're moving, the less efficiently you can eat.
    if(amount < 0){
      dropEnergy(-amount * timeStep);
      loseEnergy(-attemptedAmount * EAT_ENERGY * timeStep);
      adjSurviveScore((int)(amount * timeStep));
    }else{
      Tile coveredTile = getRandomCoveredTile();
      double foodToEat = coveredTile.foodLevel * (1d - Math.pow((1d - EAT_SPEED), amount * timeStep));
      if(foodToEat > coveredTile.foodLevel){
        foodToEat = coveredTile.foodLevel;
      }
      
      double foodDistance = Math.min(Math.abs(coveredTile.foodType - mouthHue), 1d - Math.abs(coveredTile.foodType - mouthHue));
      double multiplier = 1.0 - foodDistance / FOOD_SENSITIVITY;
      double foodEaten = foodToEat * multiplier;
      
      coveredTile.removeFood(foodEaten, true);
      if(foodEaten >= 0){
        addEnergy(foodEaten);
        //adjSurviveScore((int)foodEaten);
      }else{
        loseEnergy(-foodEaten);
        adjSurviveScore((int)foodEaten);
      }
      loseEnergy(attemptedAmount * EAT_ENERGY * timeStep);
    }
  }
  
  public void fight(double amount, double timeStep){
    if(amount > 0 && board.year - birthTime >= MATURE_AGE){
      fightLevel = amount;
      loseEnergy(fightLevel * FIGHT_ENERGY * energy * timeStep);
      
      Set<SoftBody> targets;
      //synchronized(board.hashGrid) {
        targets = board.hashGrid.get(getLocation()); 
      //}
      
      for(SoftBody tgt : targets) {
        if(tgt != null && tgt != this && tgt.isCreature){
          float distance = dist((float)position.x, (float)position.y, (float)tgt.position.x, (float)tgt.position.y);
          double combinedRadius = getRadius() * EvoMath.FIGHT_RANGE + tgt.getRadius();
          if(distance < combinedRadius){
            //((Creature)collider).dropEnergy(fightLevel * INJURED_ENERGY * timeStep);
            Creature target = ((Creature)tgt);
            double dmg = fightLevel * INJURED_ENERGY * timeStep;
            double hueDistance = Math.min(Math.abs(target.hue - mouthHue), 1 - Math.abs(target.hue - mouthHue));
            target.dropEnergy(hueDistance * dmg);
            target.loseEnergy((1 - hueDistance) * dmg);
            addEnergy((1 - hueDistance) * dmg);
            adjSurviveScore((int)((1d - hueDistance) * dmg));
            //println(name + " attacked " + target.name + " for " + dmg + " damage.");
          }
        }
      }
    } else {
      fightLevel = 0;
    }
  }
  
  public void loseEnergy(double energyLost){
    if(energyLost > 0){
      energy -= energyLost;
    }
  }
  
  public void dropEnergy(double energyLost){
    if(energyLost > 0){
      energyLost = Math.min(energyLost, energy);
      energy -= energyLost;
      getRandomCoveredTile().addFood(energyLost, hue, true);
    }
  }
  
  public CreatureDeathCauses shouldDie(){
    if (energy > EvoMath.MAXIMUM_SURVIVABLE_ENERGY) {
      //Overweigth
      return CreatureDeathCauses.Overweight;
    }
    
    double age = board.year - birthTime;
    double mAge = maxAge();
    if (age > mAge) {
      //Old Age
      return CreatureDeathCauses.OldAge;
    }
    if (getRadius() <= EvoMath.MINIMUM_SURVIVABLE_SIZE) {
      // Starving
      if (age > mAge / 2f) {
        // No energy and age > 50% life expectency.
        // Died at 50% or more life time.
        return CreatureDeathCauses.Starved;
      }
    }
    if (energy <= 0) {
      return CreatureDeathCauses.Starved;
    }
    
    //Should live
    return CreatureDeathCauses.None;
  }
  
  public double maxAge(){
    return Math.max(EvoMath.bipolarSigmoid(board.year, EvoMath.MAXIMUM_SURVIVABLE_ALPHA) * EvoMath.MAXIMUM_SURVIVABLE_AGE, 0.5f);
  }
  
  public void returnToEarth(){
    if (energy > 0) {
      int pieces = 20;
      //double radius = (float)getRadius();
      double releasedEnergy = energy * 0.5f;
      for(int i = 0; i < pieces; i++){
        getRandomCoveredTile().addFood(releasedEnergy / pieces, hue, true);
      }
    }
    //synchronized(board.hashGrid) {
      //board.hashGrid.remove(this);
      board.deadGridPtrList.add(this);
    //}
    if(board.selectedCreature == this){
      board.unselect();
    }
    alive = false;
    
    //Apply a last score bonus for survival time.
    double age = board.year - birthTime;
    adjSurviveScore((int)(age * 1000));
    
    board.checkSurvive(this);
  }
  
  public void reproduce(double babySize, double timeStep){
    int highestGen = 0;
    if(babySize < 0){
      return;
    }
    
    ArrayList<Creature> parents = new ArrayList<Creature>(0);
    parents.add(this);
    double availableEnergy = getBabyEnergy();
    
    Set<SoftBody> bodies;
    //synchronized(board.hashGrid) {
      bodies = board.hashGrid.get(getLocation()); 
    //}
    for(SoftBody possibleParent : bodies){
      if (possibleParent == null || !possibleParent.isCreature) {
        continue;
      }
      if (possibleParent == this && EvoMath.sigmoid(board.year, EvoMath.REPLICATION_ALPHA) > (Math.random() - EvoMath.NEURON_OUTPUT_EPSILON)) {
        //The first few years allows to make a child with it's self.
        //Otherwise, dont...
        continue;
      }
      Creature cr = (Creature)possibleParent;
      int rprIdx = cr.brain.BRAIN_STATIC_OUTPUT_REPRODUCE_INDEX + cr.brain.VISION_OUTPUT_COUNT;
      if (cr.brain.neurons[BRAIN_WIDTH-1][rprIdx].output > EvoMath.NEURON_OUTPUT_EPSILON){ // Must be a WILLING creature to also give birth.
        float distance = dist((float)position.x,(float)position.y,(float)possibleParent.position.x,(float)possibleParent.position.y);
        double combinedRadius = getRadius() * EvoMath.REPRODUCTION_RANGE + possibleParent.getRadius();
        if(distance < combinedRadius){
          parents.add((Creature)possibleParent);
          availableEnergy += ((Creature)possibleParent).getBabyEnergy();
        }
      }
    }
    if(availableEnergy < babySize){
      return;
    }
    
    energy -= babySize * (getBabyEnergy( ) / availableEnergy);
    adjSurviveScore((int)(babySize * (getBabyEnergy( ) / availableEnergy)));
    
    float newPX = random(-0.01,0.01);
    float newPY = random(-0.01,0.01); //To avoid landing directly on parents, resulting in division by 0)
    double newHue = 0;
    double newSaturation = 0;
    double newBrightness = 0;
    double newMouthHue = 0;
    int parentsTotal = parents.size();
    String[] parentNames = new String[parentsTotal];
    float randomParentRotation = random(0,1);
    Brain newBrain = brain.reproduce(parents);
    
    for(int i = 0; i < parentsTotal; i++){
      int chosenIndex = (int)random(0,parents.size());
      Creature parent = parents.get(chosenIndex);
      parents.remove(chosenIndex);
      parent.energy -= babySize * (parent.getBabyEnergy( ) / availableEnergy);
      parent.adjSurviveScore((int)(babySize * (parent.getBabyEnergy( ) / availableEnergy)));
      
      newPX += parent.position.x / parentsTotal;
      newPY += parent.position.y / parentsTotal;
      newHue += parent.birthHue / parentsTotal;
      newSaturation += parent.saturation / parentsTotal;
      newBrightness += parent.brightness / parentsTotal;
      newMouthHue += parent.mouthHue / parentsTotal;
      parentNames[i] = parent.name;
      if(parent.gen > highestGen){
        highestGen = parent.gen;
      }
    }
    newSaturation = 1;
    newBrightness = 1;
    Creature cr = new Creature(newPX, newPY, 0, 0,
      babySize, density, newHue, newSaturation, newBrightness, board, board.year, random(0, 2*PI), 0,
      stitchName(parentNames), andifyParents(parentNames), true,
      newBrain, highestGen+1, newMouthHue);
    
    newBrain.setCreature(cr);
    board.creatures.add(cr);
  }
  
  public void see(double timeStep){
    vision.see(timeStep);
  }
  
  public String stitchName(String[] s){
    String result = "";
    for(int i = 0; i < s.length; i++){
      float portion = ((float)s[i].length())/s.length;
      int start = (int)min(max(round(portion*i),0),s[i].length());
      int end = (int)min(max(round(portion*(i+1)),0),s[i].length());
      result = result+s[i].substring(start,end);
    }
    return result;
  }
  
  public String andifyParents(String[] s){
    String result = "";
    for(int i = 0; i < s.length; i++){
      if(i >= 1){
        result = result + " & ";
      }
      result = result + capitalize(s[i]);
    }
    return result;
  }
  
  public String createNewName(){
    String nameSoFar = "";
    int chosenLength = (int)(random(MIN_NAME_LENGTH,MAX_NAME_LENGTH));
    for(int i = 0; i < chosenLength; i++){
      nameSoFar += getRandomChar();
    }
    return sanitizeName(nameSoFar);
  }
  
  public char getRandomChar(){
    float letterFactor = random(0,100);
    int letterChoice = 0;
    while(letterFactor > 0){
      letterFactor -= board.letterFrequencies[letterChoice];
      letterChoice++;
    }
    return (char)(letterChoice+96);
  }
  
  public String sanitizeName(String input){
    String output = "";
    int vowelsSoFar = 0;
    int consonantsSoFar = 0;
    for(int i = 0; i < input.length(); i++){
      char ch = input.charAt(i);
      if(isVowel(ch)){
        consonantsSoFar = 0;
        vowelsSoFar++;
      }else{
        vowelsSoFar = 0;
        consonantsSoFar++;
      }
      if(vowelsSoFar <= 2 && consonantsSoFar <= 2){
        output = output+ch;
      }else{
        double chanceOfAddingChar = 0.5;
        if(input.length() <= MIN_NAME_LENGTH){
          chanceOfAddingChar = 1.0;
        }else if(input.length() >= MAX_NAME_LENGTH){
          chanceOfAddingChar = 0.0;
        }
        if(random(0,1) < chanceOfAddingChar){
          char extraChar = ' ';
          while(extraChar == ' ' || (isVowel(ch) == isVowel(extraChar))){
            extraChar = getRandomChar();
          }
          output = output+extraChar+ch;
          if(isVowel(ch)){
            consonantsSoFar = 0;
            vowelsSoFar = 1;
          }else{
            consonantsSoFar = 1;
            vowelsSoFar = 0;
          }
        }else{ // do nothing
        }
      }
    }
    return output;
  }
  
  public String getCreatureName(){
    return capitalize(name);
  }
  
  public String capitalize(String n){
    return n.substring(0,1).toUpperCase()+n.substring(1,n.length());
  }
  
  public boolean isVowel(char a){
    return (a == 'a' || a == 'e' || a == 'i' || a == 'o' || a == 'u' || a == 'y');
  }
  
  public String mutateName(String input){
    if(input.length() >= 3){
      if(random(0,1) < 0.2){
        int removeIndex = (int)random(0,input.length());
        input = input.substring(0,removeIndex)+input.substring(removeIndex+1,input.length());
      }
    }
    if(input.length() <= 9){
      if(random(0,1) < 0.2){
        int insertIndex = (int)random(0,input.length()+1);
        input = input.substring(0,insertIndex)+getRandomChar()+input.substring(insertIndex,input.length());
      }
    }
    int changeIndex = (int)random(0,input.length());
    input = input.substring(0,changeIndex)+getRandomChar()+input.substring(changeIndex+1,input.length());
    return input;
  }
  
  public void applyMotions(double timeStep){
    if(getRandomCoveredTile().fertility > 1){
      //If in water / Dead Zone.
      loseEnergy(SWIM_ENERGY * energy);
    }
    super.applyMotions(timeStep);
    rotation += vr;
    vr *= Math.max(0, 1 - EvoMath.FRICTION / getMass());
  }
  
  public double getEnergyUsage(double timeStep){
    return (energy - previousEnergy[ENERGY_HISTORY_LENGTH - 1]) / ENERGY_HISTORY_LENGTH / timeStep;
  }
  
  public double getBabyEnergy(){
    return energy - SAFE_SIZE;
  }
  
  public void addEnergy(double amount){
    energy += amount;
  }
  
  public void setPreviousEnergy(){
    for(int i = ENERGY_HISTORY_LENGTH-1; i >= 1; i--){
      previousEnergy[i] = previousEnergy[i-1];
    }
    previousEnergy[0] = energy;
  }
  
  public double measure(int choice){
    int sign = 1 - 2 * (choice % 2);
    if(choice < 2){
      return sign*energy;
    }else if(choice < 4){
      return sign * birthTime;
    }else if(choice == 6 || choice == 7){
      return sign*gen;
    }
    return 0;
  }
  
  public void setHue(double set){
    hue = Math.min(Math.max(set,0),1);
  }
  
  public void setMouthHue(double set){
    mouthHue = Math.min(Math.max(set,0),1);
  }
  
  public void setSaturarion(double set){
    saturation = Math.min(Math.max(set,0),1);
  }
  
  public void setBrightness(double set){
    brightness = Math.min(Math.max(set,0),1);
  }
  
  public void adjSurviveScore(int val){
    if (!alive) {
      return;
    }
    if (val == 0) {
      surviveScore += 1;
    } else {
      surviveScore += val;
    }
  }
  
  public double getInput(int i) {
    if (i < brain.VISION_INPUT_COUNT){
      return vision.visionResults[i];
    }
    i -= brain.VISION_INPUT_COUNT;
    switch(i) {
      case 0:
        return ((energy / EvoMath.MAXIMUM_SURVIVABLE_ENERGY) * 2f) - 1f;
        
        //E
        //Return CPU Time or Population Size.
        
      
      default:
        i -= brain.BRAIN_STATIC_INPUT_COUNT;
    }
    if (i < brain.BRAIN_STATIC_MEMORY_COUNT) {
      //Return last position in memory array.
      return brain.memories[i][brain.BRAIN_STATIC_MEMORY_DELAY - 1];
    }
    
    return 0;
  }
  
  public String getInputLabel(int i) {
    if (i < brain.VISION_INPUT_COUNT){
      return vision.getInputLabel(i);
    }
    i -= brain.VISION_INPUT_COUNT;
    
    if (i < brain.BRAIN_STATIC_INPUT_COUNT) {
     return inputLabels[i]; 
    }
    i -= brain.BRAIN_STATIC_INPUT_COUNT;
    
    if (i < brain.BRAIN_STATIC_MEMORY_COUNT) {
      return "Mem" + nf(i);
    }
    i -= brain.BRAIN_STATIC_MEMORY_COUNT;
    
    return "Const.";
  }
  
  public void applyOutput(int i, double val, double timeStep) {
    if (i < brain.VISION_OUTPUT_COUNT){
      vision.inputAngles[i] = EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, -1d, 1d);
      return;
    }
    i -= brain.VISION_OUTPUT_COUNT;
    
    switch(i) {
      case 0:
        hue = EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, 0d, 1d);
        return;
      case 1:
        accelerate(EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, -8d, 8d), timeStep);
        return;
      case 2:
        turn(EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, -6d, 6d), timeStep);
        return;
      case 3:
        if (val > EvoMath.NEURON_OUTPUT_EPSILON || val < -EvoMath.NEURON_OUTPUT_EPSILON) {
          eat(EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, -50d, 100d), timeStep);
        }
        return;
      case 4:
        val = EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, -10d, 100d);
        if (val > EvoMath.NEURON_OUTPUT_EPSILON || val < -EvoMath.NEURON_OUTPUT_EPSILON) {
          fight(val, timeStep);
        }
        return;
      case 5:
        if (EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, -0.5d, 1d) > EvoMath.NEURON_OUTPUT_EPSILON) {
          if(board.year - birthTime >= MATURE_AGE && energy > SAFE_SIZE && board.creatures.size() < board.creatureMaximum){
            float size = random((float)SAFE_SIZE, (float)getBabyEnergy());
            reproduce(size, timeStep);
          }
        }
        return;
      case 6:
        mouthHue = EvoMath.scale(val, brain.OUTPUT_MINIMUM, brain.OUTPUT_MAXIMUM, 0d, 1d);
        //mouthHue += val;
        //mouthHue %= 1f;
        return;
      default:
        i -= brain.BRAIN_STATIC_OUTPUT_COUNT;
    }
    
    if(i < brain.BRAIN_STATIC_MEMORY_COUNT){
      //Set first pos in memory array.
      brain.memories[i][0] = val;
    }
  }
  
  public String getOutputLabel(int i) {
    if (i < brain.VISION_OUTPUT_COUNT){
      return vision.getOutputLabel(i);
    }
    i -= brain.VISION_OUTPUT_COUNT;
    
    if (i < brain.BRAIN_STATIC_OUTPUT_COUNT) {
     return outputLabels[i]; 
    }
    i -= brain.BRAIN_STATIC_OUTPUT_COUNT;
    
    if (i < brain.BRAIN_STATIC_MEMORY_COUNT) {
      return "Mem" + nf(i);
    }
    i -= brain.BRAIN_STATIC_MEMORY_COUNT;
    
    return "N/C";
  }
}
class SurvivalComparator implements Comparator<Creature>{
    @Override
    public int compare(Creature a, Creature b) {
        // Descending order
        return a.surviveScore > b.surviveScore ? -1 : a.surviveScore == b.surviveScore ? 0 : 1;
    }
}
