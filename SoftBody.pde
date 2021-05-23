class SoftBody implements Locatable{
  PVector position;
  PVector velocity;

  double energy;
  double density;
  
  double hue;
  double saturation;
  double brightness;
  
  double birthTime;
  boolean isCreature = false;
  double fightLevel = 0;
  
  int prevSBIPMinX;
  int prevSBIPMinY;
  int prevSBIPMaxX;
  int prevSBIPMaxY;
  
  int SBIPMinX;
  int SBIPMinY;
  int SBIPMaxX;
  int SBIPMaxY;
  
  //Set<SoftBody> colliders;
  
  Board board;
  public SoftBody(float px, float py, float vx, float vy, double tenergy, double tdensity,
  double thue, double tsaturation, double tbrightness, Board tb, double bt){
    position = new PVector(px, py);
    velocity = new PVector(vx, vy);
    energy = tenergy;
    density = tdensity;
    hue = thue;
    saturation = tsaturation;
    brightness = tbrightness;
    board = tb;
    //setSBIP(false);
    //setSBIP(false); // just to set previous SBIPs as well.
    birthTime = bt;
  }
  
  /*
  public void setSBIP(boolean shouldRemove){
    double radius = getRadius() * EvoMath.FIGHT_RANGE;
    prevSBIPMinX = SBIPMinX;
    prevSBIPMinY = SBIPMinY;
    prevSBIPMaxX = SBIPMaxX;
    prevSBIPMaxY = SBIPMaxY;
    SBIPMinX = xBound((int)(Math.floor(px-radius)));
    SBIPMinY = yBound((int)(Math.floor(py-radius)));
    SBIPMaxX = xBound((int)(Math.floor(px+radius)));
    SBIPMaxY = yBound((int)(Math.floor(py+radius)));
    if(prevSBIPMinX != SBIPMinX || prevSBIPMinY != SBIPMinY || 
    prevSBIPMaxX != SBIPMaxX || prevSBIPMaxY != SBIPMaxY){
      if(shouldRemove){
        for(int x = prevSBIPMinX; x <= prevSBIPMaxX; x++){
          for(int y = prevSBIPMinY; y <= prevSBIPMaxY; y++){
            if(x < SBIPMinX || x > SBIPMaxX || 
            y < SBIPMinY || y > SBIPMaxY){
              board.softBodiesInPositions[x][y].remove(this);
            }
          }
        }
      }
      for(int x = SBIPMinX; x <= SBIPMaxX; x++){
        for(int y = SBIPMinY; y <= SBIPMaxY; y++){
          if(x < prevSBIPMinX || x > prevSBIPMaxX || 
          y < prevSBIPMinY || y > prevSBIPMaxY){
            board.softBodiesInPositions[x][y].add(this);
          }
        }
      }
    }
  }
  */
  
  public int xBound(int x){
    return Math.min(Math.max(x, 0), board.boardWidth - 1);
  }
  
  public int yBound(int y){
    return Math.min(Math.max(y, 0), board.boardHeight - 1);
  }
  
  public float xBodyBound(float x){
    float radius = getRadius();
    return Math.min(Math.max(x, radius), board.boardWidth - radius);
  }
  
  public float yBodyBound(float y){
    float radius = getRadius();
    return Math.min(Math.max(y, radius), board.boardHeight - radius);
  }
  
  public void collide(double timeStep){
    Set<SoftBody> colliders;
    //synchronized(board.hashGrid) {
      colliders = board.hashGrid.get(getLocation());
    //}
    for(SoftBody collider : colliders){
    //for(int i = 0; i < tmpColliders.size(); i++){
      //SoftBody collider = tmpColliders.get(i);
      //if (collider == null) {
        //println("Found Null collider!!");
        //continue;
      //}
       if (collider == this) {
          continue;
        }

      
      float distance = dist(position.x, position.y, collider.position.x, collider.position.y);
      if (distance == 0) {
       distance = 0.00001;
      }
      float combinedRadius = getRadius() + collider.getRadius();
      
      if(distance < combinedRadius){
        float force = combinedRadius * (float)EvoMath.COLLISION_FORCE;
        PVector forceVector = PVector.sub(position, collider.position).div(distance);
        forceVector.mult(force / (float)getMass());
        velocity.add(forceVector);
      }
    }
    
    fightLevel = 0;
  }
  
  public void applyMotions(double timeStep){
    position.x = xBodyBound(position.x + velocity.x * (float)timeStep);
    position.y = yBodyBound(position.y + velocity.y * (float)timeStep);
    velocity.x *= Math.max(0, 1 - EvoMath.FRICTION / getMass());
    velocity.y *= Math.max(0, 1 - EvoMath.FRICTION / getMass());
    //setSBIP(true);
  }
  
  public void drawSoftBody(float scaleUp){
    push();
    scale(scaleUp);
    drawSoftBody(false);
    pop();
  }
  
  public void drawSoftBody(boolean local){
    push();
    if (!local) {
      translate(position.x, position.y);
    }
    stroke(0);
    strokeWeight(board.CREATURE_STROKE_WEIGHT);
    fill((float)hue, (float)saturation, (float)brightness);
    ellipseMode(RADIUS);
    float radius = getRadius();
    ellipse(0, 0, radius, radius);
    pop();
  }
    
  public PVector getLocation() 
  {
    return position;
  }
  
  public float getRadius(){
    return EvoMath.getRadius((float)energy);
  }
  
  public double getMass(){
    return EvoMath.getMass(energy) * density;
  }
}
