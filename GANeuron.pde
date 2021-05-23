class GANeuron implements Locatable {
  Neuron[][] neurons;
  Axon[][] axons;
  double output;
  double bias;
  double mutability;
  
  PVector pos;
  
  double outputHysteresis;

  public GANeuron(Neuron[][] nrns, int brheight){
    axons = new Axon[brheight][brheight-1];
    neurons = nrns;
    bias = 0;
    mutability = 0;
  }
  
  public GANeuron(Neuron[][] nrns, int brheight, int x, int y, double muta){
    axons = new Axon[brheight][brheight-1];
    neurons = nrns;
    mutability = muta;
    
    double startingWeight = 0;
    for(int z = 0; z < brheight-1; z++) {
      //if(y == brheight-1){
        startingWeight = ((Math.random() * 2) - 1) * mutability;
      //}
      axons[y][z] = new Axon(startingWeight, mutability);
    }
    bias = ((Math.random() * 2) - 1) * mutability;
  }
  
  public void update(int x, int y) {
    int brheight = axons.length;
    int brwidth = neurons.length;
    double total = bias;
    for(int input = 0; input < brheight; input++){
      total += neurons[x-1][input].output * neurons[x-1][input].axons[y].weight;
    }
    //if(x == brwidth - 1){
    //  output = total;
    //}else{
      output = EvoMath.bipolarSigmoid(total, EvoMath.NEURON_SIGMOID_ALPHA);
    //}
    
    outputHysteresis += (output - outputHysteresis) * mutability;
  }
  
  public Neuron mutateNeuron(Neuron[][] nrns, int brheight){
    Neuron nr = new Neuron(nrns, brheight);
    double mutabilityMutate = Math.pow(0.5, EvoMath.pmRan() * EvoMath.MUTABILITY_MUTABILITY);
    nr.bias = bias + Math.pow(EvoMath.pmRan(), EvoMath.MUTATE_POWER) * mutability / EvoMath.MUTATE_MULTI;
    nr.mutability = mutability * mutabilityMutate;
    nr.output = output;
    return nr;
  }
  
  public void drawAxon(int x1, int y1, int x2, int y2, float scaleUp) {
    stroke(toFillColor(axons[y1][y2].weight * output));
    line(x1*scaleUp, y1*scaleUp, x2*scaleUp, y2*scaleUp);
  }
  
  public color toFillColor(double d) {
    if(d >= 0){
      return color(0, 0, 1, (float)(d));
    }else{
      return color(0, 0, 0, (float)(-d));
    }
  }
  
  public color neuronFillColor(){
    float h = ((float)-outputHysteresis / 2f) + 0.5f;
    float s = 1f * (1f - (float)mutability);
    
    if(output >= 0){
      return color(h, s, 1, (float)(output));
    }else{
      return color(h, s, 1, (float)(-output));
    }
  }
  
  public color neuronTextColor() {
    if(output >= 0){
      return color(0,0,0);
    }else{
      return color(0,0,1);
    }
  }
  
  public PVector getLocation() 
  { 
    return pos;
  }
}
