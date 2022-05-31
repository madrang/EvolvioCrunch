class Vision{
  Creature crea;
  
  final float[] visionAngles ={ 0, -0.4, 0.4 };
  final float[] visionDistances ={ 0.25, 0.9, 0.9 };
  final float[] maxAngle ={ 0.006, 0.7, 0.7 };
  double[] inputAngles = new double[visionAngles.length];
  
  PVector visionOccluded[] = new PVector[visionAngles.length];
  //3 Colors and Distance, 4 Outputs each.
  double visionResults[] = new double[visionAngles.length * 4];
  
  final String[] inputLabels = { "Hue", "Sat", "Bri", "HDst" };
  final String[] outputLabels = { "Angle" };
  final int STATIC_INPUT_COUNT = 4;
  
  public Vision(Creature c){
    crea = c;
    
    for(int i = 0; i < visionOccluded.length; i++){
      visionOccluded[i] = new PVector();
    }
  }
  
  public void see(double timeStep){
    for(int k = 0; k < visionAngles.length; k++) {
      PVector visionStart = getVisionStart(k);
      PVector visionEnd = getVisionEnd(k);
      
      //Set values for no occlusion.
      visionOccluded[k] = visionEnd;
      color c = getColorAt(visionEnd.x, visionEnd.y);
      visionResults[k * STATIC_INPUT_COUNT] = (hue(c) * 2) - 1f;
      visionResults[k * STATIC_INPUT_COUNT + 1] = (saturation(c) * 2f) - 1f;
      visionResults[k * STATIC_INPUT_COUNT + 2] = (brightness(c) * 2f) - 1f;
      visionResults[k * STATIC_INPUT_COUNT + 3] = 1f;
      float currentOcclutionRatio = 1.01f;
      
      Set<SoftBody> potentialVisionOccluders;
      //synchronized(crea.board.hashGrid) {
        potentialVisionOccluders = crea.board.hashGrid.get(visionEnd);
      //}
      
      float visionLineLength = visionDistances[k];
      for(SoftBody body : potentialVisionOccluders) {
        if (body == null || body == crea) {
          continue;
        }
        float distance = -1f;
        //A vector of the vision pointing in the direction of sight.
        PVector deltaVis = PVector.sub(visionEnd, visionStart);
        //PVector deltaVis = PVector.sub(visionStart, visionEnd);
        
        //A vector of the softbody position adjusted for visionStart as the origin.
        PVector deltaPos = PVector.sub(body.position, visionStart);
        
        //The Distance of sight from the softbody point of view.
        //PVector deltaPos = PVector.sub(visionStart, body.position);
        
        //Split direction and distance.
        float targetDist = deltaPos.mag();
        deltaPos.normalize();
        
        float radius = body.getRadius();
        float targetDistSq = targetDist * targetDist;
        float radiusSq = radius * radius;
        if (targetDistSq <= radiusSq) { // Ray origin inside the sphere.
          distance = 0;
        } else {
          //float dotDst = deltaVis.dot(deltaPos);
          float dotDst = deltaPos.dot(deltaVis);
          if (dotDst >= 0) {
           //Softbody in front of eye.
           float discriminant = targetDistSq - (dotDst * dotDst);
           if (discriminant <= radiusSq) {
             distance = dotDst - (float)Math.sqrt (radiusSq - discriminant);
           }
          }
        }
        if (distance >= 0 && distance < visionLineLength && distance / visionLineLength < currentOcclutionRatio) {
          //There is an occlussion and is closer than the last one.
          currentOcclutionRatio = distance / visionLineLength;
          visionOccluded[k] = PVector.lerp(visionStart, visionEnd, currentOcclutionRatio);
          visionResults[k * STATIC_INPUT_COUNT] = (body.hue * 2f) - 1f;
          visionResults[k * STATIC_INPUT_COUNT + 1] = (body.saturation * 2f) - 1f;
          visionResults[k * STATIC_INPUT_COUNT + 2] = (body.brightness * 2f) - 1f;
          visionResults[k * STATIC_INPUT_COUNT + 3] = (currentOcclutionRatio * 2f) - 1f;
        }
      }
    }
  }
  
  /*
  public void addPVOs(int x, int y, ArrayList<SoftBody> PVOs){
    if(x >= 0 && x < crea.board.boardWidth && y >= 0 && y < crea.board.boardHeight){
      Set<SoftBody> sftBodies;
      synchronized(crea.board.hashGrid) {
        sftBodies = crea.board.hashGrid.get(new PVector(x, y));
      }
      //ArrayList<SoftBody> sftBodies = new ArrayList<SoftBody>(crea.board.softBodiesInPositions[x][y]);
      for(SoftBody newCollider : sftBodies){
      //for(int i = 0; i < sftBodies.size(); i++){
      //  SoftBody newCollider = sftBodies.get(i);
        if(!PVOs.contains(newCollider) && newCollider != crea){
          PVOs.add(newCollider);
        }
      }
    }
  }
  */
  
  public color getColorAt(double x, double y){
    if(x >= 0 && x < crea.board.boardWidth && y >= 0 && y < crea.board.boardHeight){
      return crea.board.tiles[(int)(x)][(int)(y)].getColor();
    }else{
      return crea.board.BACKGROUND_COLOR;
    }
  }
  
  public String getInputLabel(int i) {
    if (i < visionResults.length){
      int inl = inputLabels.length;
      return inputLabels[i % inl] + nf(floor(i / inl));
    }
    throw new Error("Vision input label out of range.");
  }
  
  public String getOutputLabel(int i) {
    if (i < visionAngles.length){
      int inl = outputLabels.length;
      return outputLabels[i % inl] + nf(floor(i / inl));
    }
    throw new Error("Vision output label out of range.");
  }
  
  public PVector getVisionStart(int i){
    float radius = crea.getRadius();
    return new PVector(
      crea.position.x + radius * (float)Math.cos(crea.rotation + visionAngles[i]),
      crea.position.y + radius * (float)Math.sin(crea.rotation + visionAngles[i])
    );
  }
  
  public PVector getVisionEnd(int i){
    //return crea.px + (crea.getRadius() + visionDistances[i]) * Math.cos(crea.rotation + visionAngles[i]);
    //return crea.py + (crea.getRadius() + visionDistances[i]) * Math.sin(crea.rotation + visionAngles[i]);
    PVector start = getVisionStart(i);
    float radius = crea.getRadius();
    return new PVector(
      start.x + (visionDistances[i] * radius) * (float)Math.cos(crea.rotation + visionAngles[i] + (inputAngles[i] * maxAngle[i])),
      start.y + (visionDistances[i] * radius) * (float)Math.sin(crea.rotation + visionAngles[i] + (inputAngles[i] * maxAngle[i]))
    );
  }
}
