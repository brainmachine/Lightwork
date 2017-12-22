/* //<>//
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

  StringBuffer patternString; 
  //int[]  patternVector;

  int frameNum;

  // Constructor
  BinaryPattern() {
    //numBits = 10;
    patternLength = 10; // TODO: Can we use numBits for this?
    patternOffset = 512; // We need to offset by the half the maximum decimal representation of the binary string. 
    // This makes sure all of the blobs are visible in the first frame
    frameNum = 0; // Used for animation
    writeIndex = 0; 

    decodedString = new StringBuffer(patternLength); // Init with capacity
    decodedString.append("W123456789");

    //patternVector = new int[numBits];
    patternString = new StringBuffer(); 
  }

  void setNumBits(int num) {
    numBits = num;
  }

  // Generate Binary patterns for animation sequence and pattern-matching
  void generatePattern(int addr) {
    // How many LEDs do we have?
    int nLeds = network.getNumLeds();  // TODO: refactor this so I don't have to reference another object instance in here
    println("nLeds: "+nLeds); 

    // Find the required pattern length for nLeds
    // Create binary representation of nLeds
    String bString = new String(binary(nLeds)); // Produces a lot of leading zeros
    patternString = new StringBuffer(bString.split("1", 2)[1]);
    patternString.insert(0, "1"); // The above line splits one "1" off, add it again. Add an extra leading 1 to double the address space (all patterns have to start with 1)

    
    
    // Create a binary representation of the maximum decimal value in our address space. 
    StringBuffer maxBinaryValue = new StringBuffer(); 
    maxBinaryValue.append(patternString); 
    //println("max binaryValue (pre-replacement): "+maxBinaryValue); 
    for (int i = 0; i < maxBinaryValue.length(); i++) {
      maxBinaryValue.replace(i, i+1, "11");
    }
    //println("max binaryValue: "+maxBinaryValue); 
    int maxDecimalValue = unbinary(maxBinaryValue.toString()); 
    
    // Set Pattern Offset to half the maximum decimal value
    patternOffset = maxDecimalValue/2; 
    //println("pattern offset: "+patternOffset);
    
    // Create actual binary pattern
    patternString = null;
    patternString = new StringBuffer(binary(patternOffset+addr));
    patternString = new StringBuffer(patternString.toString().split("1", 2)[1]);
    patternString.insert(0, "11");
    println("patternString (with offet): " + patternString);
    
    // Get the pattern length
    patternLength = patternString.length();
    println("patternLength: "+patternLength); 
    
    // Make sure the decoded string is of the same length as the pattern string
    decodedString = new StringBuffer(patternLength);
    for (int i = 0; i < patternLength; i++) {
      decodedString.insert(i, "W"); 
    }
    println("Decoded string (not decoded yet, on init): "+decodedString); 

  }

  void advance() {
    state = Character.getNumericValue(patternString.charAt(frameNum)); // TODO: Replace pattern vector with patternString.charAt() (needs conversion to int...)
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
    println("writeNextBit() -> writeIndex: "+writeIndex);
    if (writeIndex > patternLength) {
      writeIndex = 0;
    }
  }
}