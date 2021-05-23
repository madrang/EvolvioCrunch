import java.util.concurrent.*;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

class TaskThread implements Runnable {
  private String threadName;
  private LinkedBlockingQueue<Runnable> blQueue;
  private boolean running = false;
  private final Lock mutex = new ReentrantLock(true);
  
  public TaskThread(String name, LinkedBlockingQueue<Runnable> queue)
  {
    if(queue == null) {
     throw new NullPointerException("Argument queue is null."); 
    }
    threadName = name;
    blQueue = queue;
  }
  
  public void run() {
    println(threadName + ":TaskThread.run: Starting new thread.");
    try {
      while (true) {
        Runnable task = blQueue.take();
        running = true;
        mutex.lock();
        try {
          task.run();
        } catch (Exception e) {
          println(threadName + ":TaskThread.run, Exception: " + e);
          println("Source: " + e.getStackTrace()[0]);
        } finally {
          running = false;
          mutex.unlock();
        }
      }
    } catch (InterruptedException e) {
      println(threadName + ":TaskThread.run_taskWait, Interrupted: " + e);
    } catch (Exception e) {
      println(threadName + ":TaskThread.run_taskWait, Exception: " + e);
      println("Source: " + e.getStackTrace()[0]);
    }
    println(threadName + ":TaskThread.run: Quitting run loop.");
  }
  
  public void waitIdle() {
    //if (!running) {
    //  return;
    //}
    do {
      try {
        mutex.lock();
      } finally {
        mutex.unlock();
      }
    } while(!blQueue.isEmpty() || running);
  }
}
