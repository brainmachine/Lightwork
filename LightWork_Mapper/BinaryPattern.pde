/*
 *  BinaryPattern Generator Class
 *  
 *  This class generates binary patterns used in matching LED addressed to physical locations
 *  
 *  Copyright (C) 2017 PWRFL
 *  
 *  @author Leó Stefánsson
 */

public class BinaryPattern {

  // Pattern detection
  int state; // Current bit state, used by animator
  int patternLength; // 10 bit pattern with a START at the end and an OFF after each one
  int numBits;

  int patternOffset;
  
  StringBuffer decodedString; 
  int writeIndex; // For writing detected bits

  String patternString; 
  int[]  patternVector;

  int frameNum;

  // Constructor
  BinaryPattern() {
    numBits = 10;
    patternLength = 10; // TODO: Can we use numBits for this?
    patternOffset = 512; // We need to offset by the half the maximum decimal representation of the binary string. 
                         // This makes sure all of the blobs are visible in the first frame
    frameNum = 0; // Used for animation
    writeIndex = 0; 

    decodedString = new StringBuffer(numBits); // Init with capacity
    decodedString.append("W123456789");

    patternVector = new int[numBits];
    patternString = "";
  }
  
  void setNumBits(int num) {
    numBits = num;
  }

  // Generate Binary patterns for animation sequence and pattern-matching
  void generatePattern(int addr) {
    // Convert int to String of fixed length
    String s = Integer.toBinaryString(patternOffset+addr); 
    // TODO: string format, use numBits instead of hardcoded 10
    s = String.format("%10s", s).replace(" ", "0"); // Insert leading zeros to maintain pattern length
    patternString = s;

    // Convert Binary String to Vector of Ints
    for (int i = 0; i < patternVector.length; i++) {
      char c = patternString.charAt(i);
      int x = Character.getNumericValue(c);
      patternVector[i] = x;
    }
  }

  void advance() {
    state = patternVector[frameNum];
    frameNum = frameNum+1;
    if (frameNum >= patternLength) {
      frameNum = 0;
    }
  }

  // Pattern storage
  void writeNextBit(int bit) {
    String s =  String.valueOf(bit);
    decodedString.replace(this.writeIndex, this.writeIndex+1, s);
    
    this.writeIndex++; 
    if (writeIndex >= patternLength) {
      writeIndex = 0;
    }
  }
  
}