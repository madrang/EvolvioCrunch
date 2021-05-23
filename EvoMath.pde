static class EvoMath {
  static final double COLLISION_FORCE = 0.01;
  static final double FRICTION = 0.004;
  static final float FIGHT_RANGE = 2.0;
  static final double REPRODUCTION_RANGE = 5.0;
  
  //static final double MINIMUM_SURVIVABLE_SIZE = 0.06;
  static final float MINIMUM_SURVIVABLE_SIZE = 0.12;
  //static final double MINIMUM_SURVIVABLE_SIZE = 0.2;
  static final float MAXIMUM_SURVIVABLE_ENERGY = 250.0;
  
  static final float MAXIMUM_SURVIVABLE_AGE = 100.0;
  //Longevity increase over time, used with bipolarSigmoid.
  //static final double MAXIMUM_SURVIVABLE_ALPHA = 0.0025d;
  static final double MAXIMUM_SURVIVABLE_ALPHA = 0.005d;
  //Self replication probability rate.
  static final double REPLICATION_ALPHA = 0.08d;
  
  //set so when a creature is of minimum size, it equals one.
  static final double ENERGY_DENSITY = 1.0 / (MINIMUM_SURVIVABLE_SIZE * MINIMUM_SURVIVABLE_SIZE * PI);
  static final float MAXIMUM_SURVIVABLE_SIZE = getRadius((float)MAXIMUM_SURVIVABLE_ENERGY);
  
  static final double AXON_START_MUTABILITY = 0.0005;
  static final double NEURON_START_MUTABILITY = 0.0005;
  static final double STARTING_AXON_VARIABILITY = 1.0;
  static final double MUTABILITY_MUTABILITY = 0.7;
  static final int MUTATE_POWER = 9;
  static final double MUTATE_MULTI = Math.pow(0.5, MUTATE_POWER);

  //1e-15 is Double Epsilon, limit to someting a higher.
  //https://upload.wikimedia.org/wikipedia/commons/3/3f/IEEE754.png
  //Minimum ouput needed to trigger action.
  static final double NEURON_OUTPUT_EPSILON = 1e-14;
  
  //Maximum propagation distance, VERY CPU INTENSIVE.
  //Also limited by propagation epsilon.
  static final int NEURON_MAX_PROPAGATION = 16;
  //Propagation distance seems more important, but limit to node with a higher delta.
  //Limit minimum delta needed to trigger propagation.
  static final double NEURON_PROPAGATION_EPSILON = 25e-3;
  //static final double NEURON_PROPAGATION_EPSILON = 25e-2;
  static final double NEURON_LEARNRATE = 0.0125d;
  
  static final double NEURON_HYSTERESIS = 0.25d;
  static final double NEURON_SIGMOID_ALPHA = 0.68d;
  static final double NEURON_SOFTPLUS_CONST = 2d;
  
  public static double distance(double x1, double y1, double x2, double y2){
    return(Math.sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)));
  }
  
  public static double pmRan(){
    return ((Math.random() * 2) - 1);
  }
  
  public static double sigmoid(double val, double alpha){
    //Values for Alpha = 1
    //__________________________________
    //|                       @@@@@@_.9|
    //|                    @@@     |   |
    //|                  @@  |     |   |
    //|                 @    |     |   |
    //|              @@@_____|_____|_.5|
    //|             @ |      |     |   |
    //|           @@  |      |     |   |
    //|        @@@    |      |     |   |
    //|@@@@@@@@_______|______|_____|_.0|
    //|-oo...-6       0      6.....oo  |
    //|________________________________|
    //Alpha determines steepness of the function.
    return (1.0d / (1.0d + Math.exp(-alpha * val)));
  }
  
  public static double sigmoidDerivative(double val, double alpha){
    return val * (1.0d - val) * alpha;
  }
  
  public static double bipolarSigmoid(double val, double alpha){
    //Values for Alpha = 1
    //__________________________________
    //|                       @@@@@@__1|
    //|                    @@@     |   |
    //|                  @@  |     |   |
    //|                 @    |     |   |
    //|              @@@_____|_____|__0|
    //|             @ |      |     |   |
    //|           @@  |      |     |   |
    //|        @@@    |      |     |   |
    //|@@@@@@@@_______|______|_____|_-1|
    //|-oo...-6       0      6.....oo  |
    //|________________________________|
    //Alpha determines steepness of the function.
    return ((2.0d / (1.0d + Math.exp(-alpha * val))) - 1.0d);
  }
  
  public static double bipolarSigmoidDerivative(double val, double alpha){
    return (alpha / 2d) * (1d - (val * val));
  }
  
  public static double softplus(double val, double c){
    if (val > 709){
      //Avoid to return positive infinity due to double limit.
      return val;
    }
    return Math.log(1d + Math.exp(c * val)) / c;
  }
  
  public static double softplusDerivative(double val, double c){
    //Same function as sigmoid !?!
    return (1.0d / (1.0d + Math.exp(-c * val)));
  }
  
  public static double scale(double x, double in_min, double in_max, double out_min, double out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
  }
  
  public static double getMass(double e){
    if(Double.isNaN(e) || e < 1.0){
      return (1.0 / ENERGY_DENSITY);
    } else {
      return (e / ENERGY_DENSITY);
    }
  }
  
  public static float getRadius(float e){
    if(Float.isNaN(e) || e < 1.0){
      return (float)MINIMUM_SURVIVABLE_SIZE;
    } else {
      return (float)Math.sqrt((e / ENERGY_DENSITY) / Math.PI);
    }
  }
}
