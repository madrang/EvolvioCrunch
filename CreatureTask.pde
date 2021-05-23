enum CreatureStatus {
  CREATION,
  
  THINK,
  USERCONTROLLED,
  APPLYMOTION,
  
  INACTIVE,
  DESTRUCTION;
}

class CreatureTask implements Runnable {
  private Creature crea;
  double timeStep;
  CreatureStatus status;

  public CreatureTask(Creature creature, double ts, CreatureStatus st) {
    crea = creature;
    timeStep = ts;
    status = st;
  }

  public void run() {
    if (status != CreatureStatus.CREATION && crea == null) {
      println("Disposed creature in task processing !!");
      return;
    }
    
    switch (status) {
    case CREATION:
      return;
    
    case THINK:
      crea.setPreviousEnergy();
      
      crea.collide(timeStep);
      crea.metabolize(timeStep);
      crea.brain.useBrain(timeStep, true);
      return;
    case USERCONTROLLED:
      crea.setPreviousEnergy();
      
      crea.collide(timeStep);
      crea.metabolize(timeStep);
      crea.brain.useBrain(timeStep, false);
      return;
    case APPLYMOTION:
      crea.applyMotions(timeStep);
      crea.see(timeStep);
      return;
    
    case INACTIVE:
      crea.collide(timeStep);
      return;
    case DESTRUCTION:
      crea.returnToEarth();
      return;
    
    default:
      throw new AssertionError("Unknown task status " + status);
    }
  }
}
