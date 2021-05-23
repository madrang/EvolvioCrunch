class Axon{
  double weight;
  double mutability;
  
  public Axon(double w, double m){
    weight = w;
    mutability = m;
  }
  
  public Axon mutateAxon(){
    double mutabilityMutate = Math.pow(0.5, EvoMath.pmRan() * EvoMath.MUTABILITY_MUTABILITY);
    return new Axon(weight + Math.pow(EvoMath.pmRan(), EvoMath.MUTATE_POWER) * mutability / EvoMath.MUTATE_MULTI, mutability * mutabilityMutate);
  }
}