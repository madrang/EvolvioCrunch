enum ActivationFunction {
  NONE,
  SIGMOID,
  BIPOLARSIGMOID,
  SOFTPLUS;
}

class Neuron {
  Neuron[][] neurons;
  Axon[] axons;
  ActivationFunction af;
  double output;
  double bias;
  double mutability;
  
  double outputHysteresis;
  
  public Neuron(Neuron[][] nrns, int brheight){
    axons = new Axon[brheight];
    neurons = nrns;
    bias = 0;
    outputHysteresis = 0;
    mutability = EvoMath.NEURON_START_MUTABILITY;
    af = ActivationFunction.NONE;
  }
  
  public Neuron(Neuron[][] nrns, int brheight, int x, int y, double nrmuta, double axmuta){
    axons = new Axon[brheight];
    neurons = nrns;
    mutability = nrmuta;
    outputHysteresis = 0;
    af = ActivationFunction.NONE;
    
    double startingWeight = 0;
    for(int z = 0; z < brheight; z++){
    //for(int z = 0; z < brheight-1; z++){
      //if(y == brheight-1){
        startingWeight = EvoMath.pmRan() * axmuta;
      //}
      axons[z] = new Axon(startingWeight, axmuta);
    }
    //bias = EvoMath.pmRan();
    bias = EvoMath.pmRan() * nrmuta;
  }
  
  public void update(int x, int y){
    int brheight = axons.length;
    int brwidth = neurons.length;
    double total = bias;
    for(int input = 0; input < brheight; input++){
      Neuron nr = neurons[x-1][input];
      //if(x==1){
        total += nr.output * nr.axons[y].weight;
      //} else {
      //  total += nr.outputHysteresis * nr.axons[y].weight;
      //}
    }
    
    switch(af){
      case NONE:
        output = total;
        break;
      case SIGMOID:
        output = EvoMath.sigmoid(total, EvoMath.NEURON_SIGMOID_ALPHA);
        break;
      case BIPOLARSIGMOID:
        output = EvoMath.bipolarSigmoid(total, EvoMath.NEURON_SIGMOID_ALPHA);
        break;
      case SOFTPLUS:
        output = EvoMath.softplus(total, EvoMath.NEURON_SOFTPLUS_CONST);
        break;
      default:
        throw new Error("Unknown activation function at teachError.");
    }
    
    outputHysteresis += (output - outputHysteresis) * EvoMath.NEURON_HYSTERESIS;
  }
  
  public void teachOutput(int x, int y, double val){
    teachOutput(x, y, val, EvoMath.NEURON_MAX_PROPAGATION);
  }
  
  public void teachOutput(int x, int y, double val, int iter){
    teachError(x, y, val - output, iter);
  }
  
  public void teachError(int x, int y, double err){
    teachError(x, y, err, EvoMath.NEURON_MAX_PROPAGATION);
  }
  
  public void teachError(int x, int y, double err, int iter){
    // iter is the number of iterations left, ie how far to propagate from here.
    
    if (Math.abs(err) < EvoMath.NEURON_PROPAGATION_EPSILON) {
      return;
    }
    
    int brwidth = neurons.length;
    if (x < 0 || x > brwidth) {
      return;
    }
    int brheight = axons.length;
    if (y < 0 || y > brheight) {
      return;
    }
    
    double delta = err * getDerivative(output);
    
    //Correct Bias
    bias += delta * mutability * EvoMath.NEURON_LEARNRATE;
    
    if (x <= 0) {
      return;
    }
    
    //FIXME clone the axons weights of the upper layers before correcting
    // as the deltas of later nodes will be wrong as the first node will change all in the previous layer.
    // Thus the second one is correcting on already altered node, adding errors in the delta.
    for(int input = 0; input < brheight; input++) {
      //The sending node
      Neuron nr = neurons[x-1][input];
      //The axon that we are receiving from that is connected to the node we want to teach.
      Axon ax = nr.axons[y];
      
      double wErr = delta * ax.weight;
      
      //Correct weight.
      ax.weight += wErr * nr.output * ax.mutability * EvoMath.NEURON_LEARNRATE;
      
      if (iter > 0 && Math.abs(wErr) > EvoMath.NEURON_PROPAGATION_EPSILON) {
        neurons[x-1][input].teachError(x-1, input, wErr, iter-1);
      }
    }
  }
  
  public double getDerivative(){
    return getDerivative(output);
  }
  public double getDerivative(double val){
    switch(af){
      case NONE:
        if(val <= 0d) {
          return 0.5d;
        }
        return 1d;
      case SIGMOID:
        return EvoMath.sigmoidDerivative(val, EvoMath.NEURON_SIGMOID_ALPHA);
      case BIPOLARSIGMOID:
        return EvoMath.bipolarSigmoidDerivative(val, EvoMath.NEURON_SIGMOID_ALPHA);
      case SOFTPLUS:
        return EvoMath.softplusDerivative(val, EvoMath.NEURON_SOFTPLUS_CONST);
      default:
        throw new Error("Unknown activation function at teachError.");
    }
  }
  
  public Neuron mutateNeuron(Neuron[][] nrns, int brheight){
    Neuron nr = new Neuron(nrns, brheight);
    double mutabilityMutate = Math.pow(0.5, EvoMath.pmRan() * EvoMath.MUTABILITY_MUTABILITY);
    nr.bias = bias + Math.pow(EvoMath.pmRan(), EvoMath.MUTATE_POWER) * mutability / EvoMath.MUTATE_MULTI;
    nr.mutability = mutability * mutabilityMutate;
    nr.output = output;
    nr.af = af;
    return nr;
  }
  
  public void drawAxon(int x1, int y1, int x2, int y2, float scaleUp){
    stroke(axonToColor(axons[y2].weight * output));
    line(x1*scaleUp, y1*scaleUp, x2*scaleUp, y2*scaleUp);
  }
  
  public color axonToColor(double d){
        
    float dr = ((float)getDerivative(outputHysteresis) + 1.75f) % 1f;
    if(d >= 0d && d <= 1d){
      //0 to 1
      return color(dr, 1, 1, (float)(d));
    } else if(d < 0d && d >= -1d){
      //0 to -1
      return color(dr, 0.5, 1, (float)(-d));
    } else if(d >= 1){
      //Bigger than 1
      return color(dr, 1, 1, 1);
    } else {
      //Small than 1
      return color(dr, 0.5,  1, 1);
    }
  }
  
  public color neuronFillColor(){
    float h = ((float)getDerivative(outputHysteresis) + 1.75f) % 1f;
    float s = 1f * (1f - (float)mutability);
    
    if(output >= 0){
      return color(h, s, 1, (float)(output));
    }else{
      return color(h, s, 1, (float)(-output));
    }
  }
  
  public color neuronTextColor(){
    if(output >= 0){
      return color(0, 0, 1);
    }else{
      return color(0, 0, 0);
    }
  }
}
