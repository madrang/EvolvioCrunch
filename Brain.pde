class Brain {
  
  int BRAIN_WIDTH;
  int BRAIN_HEIGHT;
  final int BRAIN_STATIC_INPUT_COUNT = 1;
  
  final int BRAIN_STATIC_OUTPUT_BHUE_INDEX = 0;
  final int BRAIN_STATIC_OUTPUT_EAT_INDEX = 3;
  final int BRAIN_STATIC_OUTPUT_REPRODUCE_INDEX = 5;
  final int BRAIN_STATIC_OUTPUT_MHUE_INDEX = 6;
  
  final int BRAIN_STATIC_OUTPUT_COUNT = 7;
  
  final int BRAIN_STATIC_MEMORY_COUNT = 6;
  final int BRAIN_STATIC_MEMORY_DELAY = 16;
  
  //final boolean ENABLE_TEACH = false;
  final boolean ENABLE_TEACH = true;
  
  final double OUTPUT_MINIMUM = -1d;
  //final double OUTPUT_MINIMUM = 0d;
  //final double OUTPUT_MINIMUM = -255d;
  
  final double OUTPUT_MAXIMUM = 1d;
  //final double OUTPUT_MAXIMUM = 255;
  
  Neuron[][] neurons;
  double[][] memories;
  int VISION_INPUT_COUNT;
  int VISION_OUTPUT_COUNT;
  
  Creature crea;
  
  public Brain(Creature c, int brwidth, int brheight){
    BRAIN_WIDTH = brwidth;
    BRAIN_HEIGHT = brheight;
    
    memories = new double[BRAIN_STATIC_MEMORY_COUNT][BRAIN_STATIC_MEMORY_DELAY];
    for(int i = 0; i < BRAIN_STATIC_MEMORY_COUNT; i++){
      for(int d = 0; d < BRAIN_STATIC_MEMORY_DELAY; d++){
        memories[i][d] = 0;
      }
    }
    
    if (c != null) {
      setCreature(c);
    }
    
    generateRandomNetwork();
  }
  
  public Brain(Creature c, int brwidth, int brheight, Neuron[][] tbrain){
    BRAIN_WIDTH = brwidth;
    BRAIN_HEIGHT = brheight;
    
    memories = new double[BRAIN_STATIC_MEMORY_COUNT][BRAIN_STATIC_MEMORY_DELAY];
    for(int i = 0; i < BRAIN_STATIC_MEMORY_COUNT; i++){
      for(int d = 0; d < BRAIN_STATIC_MEMORY_DELAY; d++){
        memories[i][d] = 0;
      }
    }
    
    if (c != null) {
      setCreature(c);
    }
    
    if(tbrain == null){
      generateRandomNetwork();
    }else{
      neurons = tbrain;
    }
  }
  
  public void generateRandomNetwork() {
    neurons = new Neuron[BRAIN_WIDTH][BRAIN_HEIGHT];
    for(int x = 0; x < BRAIN_WIDTH-1; x++){
      //Last row are output, no need for axons.
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        Neuron nr = new Neuron(neurons, BRAIN_HEIGHT, x, y, EvoMath.NEURON_START_MUTABILITY, EvoMath.AXON_START_MUTABILITY);
        //Interconnections activation function.
        //nr.af = ActivationFunction.SOFTPLUS;
        nr.af = ActivationFunction.BIPOLARSIGMOID;
        neurons[x][y] = nr;
      }
    }
    
    for(int x = 0; x < BRAIN_WIDTH; x++){
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        if(x == BRAIN_WIDTH - 1){
          //Create output nodes.
          Neuron nr = new Neuron(neurons, BRAIN_HEIGHT);
          nr.mutability = EvoMath.NEURON_START_MUTABILITY;
          if (y >= VISION_OUTPUT_COUNT + BRAIN_STATIC_OUTPUT_COUNT && y < VISION_OUTPUT_COUNT + BRAIN_STATIC_OUTPUT_COUNT + BRAIN_STATIC_MEMORY_COUNT) {
            //Memories
            //nr.af = ActivationFunction.NONE;
            nr.af = ActivationFunction.BIPOLARSIGMOID;
          } else {
            //Vision and Crea Output
            nr.af = ActivationFunction.BIPOLARSIGMOID;
          }
          neurons[x][y] = nr;
        }
        //Seed some values to kick start the network.
        neurons[x][y].output = EvoMath.pmRan();
        
        /*
        if(y == BRAIN_HEIGHT-1){
          neurons[x][y].output = 1;
        }else{
          neurons[x][y].output = 0;
        }
        */
      }
    }
    
    //Bias Primordial creature to try to eat.
    int x = BRAIN_WIDTH - 1;
    int y = BRAIN_STATIC_OUTPUT_EAT_INDEX + VISION_OUTPUT_COUNT;
    neurons[x][y].bias = Math.random();
    
    //Bias for reproduction.
    y = BRAIN_STATIC_OUTPUT_REPRODUCE_INDEX + VISION_OUTPUT_COUNT;
    neurons[x][y].bias = Math.random();
  }
  
  public void setCreature(Creature c) {
    if (c == null) {
      throw new AssertionError("Null creature in Brain.");
    }
    crea = c;
    VISION_INPUT_COUNT = crea.vision.visionResults.length;
    VISION_OUTPUT_COUNT = crea.vision.visionAngles.length;
  }
  
  public void useBrain(double timeStep, boolean useOutput){
    //Read Inputs
    for(int y = 0; y < BRAIN_HEIGHT; y++){
      neurons[0][y].output = crea.getInput(y);
    }
    
    //Compute
    for(int x = 1; x < BRAIN_WIDTH; x++){
      //X Start at 1 as input nodes no not have inputs/Axons to read.
      for(int y = 0; y < BRAIN_HEIGHT; y++){
      //for(int y = 0; y < BRAIN_HEIGHT - 1; y++){
        neurons[x][y].update(x, y);
      }
    }
    
    //If not mature only, teach is very cpu intensive.
    if (crea.board.year - crea.birthTime <= crea.MATURE_AGE && ENABLE_TEACH) {
      //Try to teach the brain it's birth hue.
      //Mutability will stop teach from locking down the color,
      //but should keep the value in a meaningfull range.
      int x = BRAIN_WIDTH - 1;
      int y = BRAIN_STATIC_OUTPUT_BHUE_INDEX + VISION_OUTPUT_COUNT;
      neurons[x][y].teachOutput(x, y, (crea.birthHue * 2) - 1f);
      
      y = BRAIN_STATIC_OUTPUT_MHUE_INDEX + VISION_OUTPUT_COUNT;
      Tile t = crea.board.tiles[floor((float)crea.position.x)][floor((float)crea.position.y)];
      neurons[x][y].teachOutput(x, y, (t.foodType * 2) - 1f);
    }
    
    //Update memories.
    //Move array up by one.
    for(int i = 0; i < BRAIN_STATIC_MEMORY_COUNT; i++){
      //Start from end to not overwrite values when moving.
      for(int d = BRAIN_STATIC_MEMORY_DELAY - 1; d > 0; d--){
        memories[i][d] = memories[i][d - 1];
      }
    }
    
    if(useOutput){
      //Apply outputs.
      int end = BRAIN_WIDTH - 1;
      for(int y = 0; y < BRAIN_HEIGHT-1; y++){
        crea.applyOutput(y, neurons[end][y].output, timeStep);
      }
    }
  }
  
  public void drawBrain(PFont font, float scaleUp, int mX, int mY){
    final float neuronSize = 0.4;
    noStroke();
    fill(0,0,0.4);
    rect((-1.7 - neuronSize) * scaleUp, -neuronSize  *scaleUp, (2.4 + BRAIN_WIDTH + neuronSize*2) * scaleUp, (BRAIN_HEIGHT + neuronSize*2) * scaleUp);
    
    //Draw Input/Output names.
    ellipseMode(RADIUS);
    strokeWeight(2);
    textFont(font, 0.58 * scaleUp);
    fill(0,0,1);
    for(int y = 0; y < BRAIN_HEIGHT; y++){
        textAlign(RIGHT);
        text(crea.getInputLabel(y), (-neuronSize-0.1) * scaleUp, (y+(neuronSize*0.6)) * scaleUp);
        textAlign(LEFT);
        text(crea.getOutputLabel(y), (BRAIN_WIDTH-1+neuronSize+0.1) * scaleUp, (y+(neuronSize*0.6)) * scaleUp);
    }
    
    //Draw Nodes
    textAlign(CENTER);
    noStroke();
    for(int x = 0; x < BRAIN_WIDTH; x++){
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        fill(neurons[x][y].neuronFillColor());
        ellipse(x * scaleUp, y * scaleUp, neuronSize * scaleUp, neuronSize * scaleUp);
        
        fill(neurons[x][y].neuronTextColor());
        text(nf((float)neurons[x][y].output, 0, 1), x * scaleUp, (y + (neuronSize*0.6)) * scaleUp);
      }
    }
    
    //Draw lines linking neurons(Axons).
    if(mX >= 0 && mX < BRAIN_WIDTH && mY >= 0 && mY < BRAIN_HEIGHT){
      //If mouse is over a node.
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        if(mX >= 1 && mY < BRAIN_HEIGHT){
        //if(mX >= 1 && mY < BRAIN_HEIGHT-1){
          //Input Axon
          drawAxon(mX-1, y, mX, mY, scaleUp);
        }
        if(mX < BRAIN_WIDTH-1 && y < BRAIN_HEIGHT){
        //if(mX < BRAIN_WIDTH-1 && y < BRAIN_HEIGHT-1){
          //Output Axon
          drawAxon(mX, mY, mX+1, y, scaleUp);
        }
      }
      if (mousePressed && (mouseButton == LEFT)) {
        neurons[mX][mY].teachError(mX, mY, 0.1d);
      } else if (mousePressed && (mouseButton == RIGHT)) {
        neurons[mX][mY].teachError(mX, mY, -0.1d);
      }
    }
  }
  
  public void drawAxon(int x1, int y1, int x2, int y2, float scaleUp){
    neurons[x1][y1].drawAxon(x1, y1, x2, y2, scaleUp);
  }
  
  public Brain reproduce(ArrayList<Creature> parents){
    int parentsTotal = parents.size();
    
    if (parentsTotal <= 0) {
     return new Brain(null, BRAIN_WIDTH, BRAIN_HEIGHT);
    }
    
    Axon[][][] newBrain = new Axon[BRAIN_WIDTH-1][BRAIN_HEIGHT][BRAIN_HEIGHT];
    //Axon[][][] newBrain = new Axon[BRAIN_WIDTH-1][BRAIN_HEIGHT][BRAIN_HEIGHT-1];
    Neuron[][] newNeurons = new Neuron[BRAIN_WIDTH][BRAIN_HEIGHT];
    float randomParentRotation = random(0,1);
    
    for(int x = 0; x < BRAIN_WIDTH-1; x++){
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        for(int z = 0; z < BRAIN_HEIGHT; z++){
        //for(int z = 0; z < BRAIN_HEIGHT-1; z++){
          //Mutate Axon
          float axonAngle = atan2((y + z) / 2.0 - BRAIN_HEIGHT / 2.0, x - BRAIN_WIDTH / 2.0) / (2.0 * PI) + PI;
          Creature parentForAxon = parents.get((int)(((axonAngle + randomParentRotation) % 1.0) * parentsTotal));
          newBrain[x][y][z] = parentForAxon.brain.neurons[x][y].axons[z].mutateAxon();
        }
      }
    }
    
    for(int x = 0; x < BRAIN_WIDTH; x++){
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        float neuronAngle = atan2(y - BRAIN_HEIGHT / 2.0, x - BRAIN_WIDTH / 2.0) / (2.0 * PI) + PI;
        Creature parentForNeuron = parents.get((int)(((neuronAngle + randomParentRotation) % 1.0) * parentsTotal));
        newNeurons[x][y] = parentForNeuron.brain.neurons[x][y].mutateNeuron(newNeurons, BRAIN_HEIGHT);
      }
    }
    
    //Copy Axons in nerons.
    for(int x = 0; x < BRAIN_WIDTH - 1; x++){
      for(int y = 0; y < BRAIN_HEIGHT; y++){
        //if (x == BRAIN_WIDTH - 1) {
          //Last row are constants.
          //continue;
        //}
        for(int z = 0; z < BRAIN_HEIGHT; z++){
        //for(int z = 0; z < BRAIN_HEIGHT-1; z++){
          newNeurons[x][y].axons[z] = newBrain[x][y][z];
        }
      }
    }
    return new Brain(null, BRAIN_WIDTH, BRAIN_HEIGHT, newNeurons);
  }
}
