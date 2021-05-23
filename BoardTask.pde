enum BoardStatus {
  HashGrid,
  Tiles,
  MaintainCreatureMinimum,
  GenerateNewCreature,
  NewSurvivorMutation
}

class BoardTask implements Runnable {
  private Board board;
  double timeStep;
  BoardStatus status;
  
  public BoardTask(Board b, BoardStatus st) {
    board = b;
    status = st;
  }
  
  public void run() {
    if (board == null) {
      println("Null board in task processing !!");
      return;
    }
    
    switch (status) {
    case HashGrid:
      //synchronized(board.hashGrid) {
        //Remove dead bodies.
        for (SoftBody sb : board.deadGridPtrList) {
          board.hashGrid.remove(sb);
        }
        board.deadGridPtrList.clear();
        //Add new softbodies.
        for (SoftBody sb : board.newGridPtrList) {
          board.hashGrid.add(sb);
        }
        board.newGridPtrList.clear();
        // Update the hash grid with new position of all the SoftBody.
        board.hashGrid.updateAll();
      //}
      return;
    
    case Tiles:
      for(int x = 0; x < board.boardWidth; x++){
        for(int y = 0; y < board.boardHeight; y++){
          board.tiles[x][y].iterate();
        }
      }
      int iYr = (int)floor((float)board.year);
      if (iYr + board.SEED > board.mapSeed + 2) {
       board.changeLand(board.SEED + iYr, board.STD_STEPS); 
      }
      return;
      
    case MaintainCreatureMinimum:
      board.maintainCreatureMinimum();
      return;
      
    case GenerateNewCreature:
      board.generateNewCreature();
      return;
    
    case NewSurvivorMutation:
      board.newSurvivorMutation();
      return;
    
    default:
      throw new AssertionError("Unknown task status " + status);
    }
  }
}
