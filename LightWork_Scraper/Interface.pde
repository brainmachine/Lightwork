//  Interface.pde 
//  Lightwork-Mapper
//
//  Created by Leo Stefansson and Tim Rolls
//  
//  This class handles connecting to and switching between PixelPusher, FadeCandy and ArtNet devices.
//
//////////////////////////////////////////////////////////////


//Pixel Pusher library imports
import com.heroicrobot.controlsynthesis.*;
import com.heroicrobot.dropbit.common.*;
import com.heroicrobot.dropbit.devices.*;
import com.heroicrobot.dropbit.devices.pixelpusher.*;
import com.heroicrobot.dropbit.discovery.*;
import com.heroicrobot.dropbit.registry.*;
import java.util.*;
import java.io.*;

// ArtNet
import artnetP5.*;

enum device {
  FADECANDY, PIXELPUSHER, ARTNET, NULL
};

public class Interface {

  device              mode;

  //LED defaults
  String               IP = "fade2.local";
  int                  port = 7890;
  int                  ledsPerStrip = 64; // TODO: DOn't hardcode this
  int                  numStrips = 8;
  int                  numLeds = ledsPerStrip*numStrips;
  int                  ledBrightness;


  //Pixelpusher objects
  DeviceRegistry registry;
  TestObserver testObserver;

  //Fadecandy Objects
  OPC opc;

  // ArtNet objects
  ArtnetP5 artnet;
  byte artnetPacket[];
  int                  numArtnetChannels = 5; // Channels per ArtNet fixture
  int                  numArtnetFixtures = 9; // Number of ArtNet DMX fixtures (each one can have multiple channels and LEDs


  boolean isConnected =false;

  //////////////////////////////////////////////////////////////
  //Constructors
  /////////////////////////////////////////////////////////////

  Interface() {
    mode = device.NULL;
    //populateLeds();
    println("Interface created");
  }

  //setup for fadecandy
  Interface(device m, String ip, int strips, int leds) {
    mode = m;
    IP = ip;
    numStrips = strips;
    ledsPerStrip = leds;
    numLeds = ledsPerStrip*numStrips;
    //populateLeds();
    println("Interface created");
  }

  // Setup for PixelPusher and ArtNet (no address required)
  // strips and leds are from PIXELPUSHER
  // numFixtures and numChans are for ARTNET
  Interface(device m, int strips, int leds, int numFixtures, int numChans) {
    mode = m;
    if (mode == device.PIXELPUSHER) {
      numStrips = strips;
      ledsPerStrip = leds;
      numLeds = ledsPerStrip*numStrips;
    } else if (mode == device.ARTNET) {
      numArtnetFixtures = numFixtures; 
      numArtnetChannels = numChans; // Number of channels per fixture

    }

    //populateLeds();
    println("Interface created");
  }


  //////////////////////////////////////////////////////////////
  // Setters and getters
  //////////////////////////////////////////////////////////////

  void setMode(device m) {
    shutdown();
    mode = m;
  }

  device getMode() {
    return mode;
  }

  void setNumLedsPerStrip(int num) {
    ledsPerStrip = num;
    numLeds = ledsPerStrip*numStrips;
  }

  int getNumLedsPerStrip() {
    return ledsPerStrip;
  }

  void setNumStrips(int num) {
    numStrips = num;
    numLeds = ledsPerStrip*numStrips;
    //resetPixels();
  }

  int getNumStrips() {
    return numStrips;
  }
  
  int getNumArtnetFixtures() {
    return numArtnetFixtures;  
  }
  
  void setNumArtnetFixtures(int numFixtures) {
    numArtnetFixtures = numFixtures; 

  }
  
  int getNumArtnetChannels() {
     return numArtnetChannels; 
  }
  
  void setNumArtnetChannels(int numChannels) {
    numArtnetChannels = numChannels;
  }
  
 
  //TODO: rework this to work in mapper and scraper

  //void setLedBrightness(int brightness) { //TODO: set overall brightness?
  //  ledBrightness = brightness;

  //  if (mode == device.PIXELPUSHER && isConnected()) {
  //    registry.setOverallBrightnessScale(ledBrightness);
  //  }

  //  if (opc!=null&&opc.isConnected()) {
  //  }
  //}

  void setIP(String ip) {
    IP=ip;
  }

  String getIP() {
    println(IP);
    return IP;
  }

  void setInterpolation(boolean state) {
    if (mode == device.FADECANDY) {
      opc.setInterpolation(state);
    } else {
      println("Interpolation only supported for FADECANDY.");
    }
  }

  void setDithering(boolean state) {
    if (mode == device.FADECANDY) {
      opc.setDithering(state); 
      opc.setInterpolation(state);
    } else {
      println("Dithering only supported for FADECANDY.");
    }
  }

  boolean isConnected() {
    return isConnected;
  }

  //Set number of strips and pixels based on pusher config - only pulling for one right now.
  void fetchPPConfig() {
    if (mode == device.PIXELPUSHER && isConnected()) {
      List<PixelPusher> pps = registry.getPushers();
      for (PixelPusher pp : pps) {
        IP = pp.getIp().toString();
        numStrips = pp.getNumberOfStrips();
        ledsPerStrip = pp.getPixelsPerStrip();
      }
    }
  }

  //TODO: rework this to work in mapper and scrapergit 

  // Reset the LED vector
  //void populateLeds() {

  //  //int bPatOffset = 150; // Offset to get more meaningful patterns (and avoid 000000000);

  //  if (leds.size()>0) {
  //    leds.clear();
  //  }

  //  for (int i = 0; i < numLeds; i++) {
  //    LED temp= new LED();
  //    leds.add(temp);
  //    leds.get(i).setAddress(i);
  //    //leds[i].binaryPattern.generatePattern(i+bPatOffset); // Generate a unique binary pattern for each LED
  //  }
  //}

  //////////////////////////////////////////////////////////////
  // Network Methods
  //////////////////////////////////////////////////////////////

  void update(color[] colors) {

    switch(mode) { //<>//
    case FADECANDY: 
      {
        //check if opc object exists and is connected before writing data
        if (opc!=null&&opc.isConnected()) {
          opc.autoWriteData(colors);
        }
        break;
      }
    case PIXELPUSHER: 
      {
        //check if network observer exists and has discovered strips before writing data
        if (testObserver!=null&&testObserver.hasStrips) {
          registry.startPushing();

          //iterate through PP strip objects to set LED colors
          List<Strip> strips = registry.getStrips();
          if (strips.size() > 0) {
            int stripNum =0;
            for (Strip strip : strips) {
              for (int stripPos = 0; stripPos < strip.getLength(); stripPos++) {
                color c = colors[(ledsPerStrip*stripNum)+stripPos];

                strip.setPixel(c, stripPos);
              }
              stripNum++;
            }
          }
        }

        break;
      }

    case ARTNET:
      {
        // Grab all the colors
        for (int i = 0; i < colors.length; i++) {
          // Extract RGB values
          // We assume the first three channels are RGB, and the rest is WHITE.
          int r = (colors[i] >> 16) & 0xFF;  // Faster way of getting red(argb)
          int g = (colors[i] >> 8) & 0xFF;   // Faster way of getting green(argb)
          int b = colors[i] & 0xFF;          // Faster way of getting blue(argb)
          
          // Write RGB values to the packet
          int index = i*numArtnetChannels; 
          artnetPacket[index]   = byte(r); // Red
          artnetPacket[index+1] = byte(g); // Green
          artnetPacket[index+2] = byte(b); // Blue

          // Populate remaining channels (presumably W) with color brightness
          //int br = int(brightness(colors[i])); // Follow the brightness
          color c = colors[i]; 
          
          int br = int(min(red(c), green(c), blue(c))); // White tracks the minimum color channel value
          //println(min(red(c), green(c), blue(c)));
          for (int j = 3; j < numArtnetChannels; j++) {
            artnetPacket[index+j] = byte(br); // White 
          }
        }

        artnet.broadcast(artnetPacket);
      }

    case NULL: 
      {
      }
    };
  }

  //open connection to controller
  void connect(PApplet parent) {
    //if (isConnected) {
    //  shutdown();
    //}

    if (mode == device.FADECANDY) {
      if (opc== null) {
        opc = new OPC(parent, IP, port);

        int startTime = millis();

        print("waiting");
        while (!opc.isConnected) {
          int currentTime = millis(); 
          int deltaTime = currentTime - startTime;
          if ((deltaTime%1000)==0) {
            print(".");
          }
          if (deltaTime > 5000) {
            println(" ");
            println("connection failed, check your connections..."); 
            isConnected = false;
            //network.shutdown();
            break;
          }
        }
        println(" ");
      }

      if (opc.isConnected()) {
        // TODO: Find a more elegant way to initialize dithering
        // Currently this is the only safe place where this is guaranteed to work
        //opc.setDithering(false);
        //opc.setInterpolation(false);
        // TODO: Deal with this (doesn't work for FUTURE wall, works fine one LIGHT WORK wall).

        // Clear LEDs
        //animator.setAllLEDColours(off);
        // Update pixels twice (elegant, I know... but it works)
        //update(animator.getPixels());
        //update(animator.getPixels());
        println("Connected to Fadecandy OPC server at: "+IP+":"+port); 
        isConnected =true;
        opc.setPixelCount(numLeds);
      }
      //populateLeds();
    } else if (mode == device.PIXELPUSHER ) {
      // does not like being instantiated a second time
      if (registry == null) {
        registry = new DeviceRegistry();
        testObserver = new TestObserver();
      }

      registry.addObserver(testObserver);
      registry.setAntiLog(true);
      registry.setLogging(false);

      int startTime = millis();

      print("waiting");
      while (!testObserver.hasStrips) {
        int currentTime = millis(); 
        int deltaTime = currentTime - startTime;
        if ((deltaTime%1000)==0) {
          print(".");
        }
        if (deltaTime > 5000) {
          println(" ");
          println("connection failed, check your connections..."); 
          isConnected = false; 
          break;
        }
      }
      println(" ");

      fetchPPConfig();

      if (testObserver.hasStrips) {
        isConnected =true;

        // Clear LEDs
        //animator.setAllLEDColours(off);
        update(scrape.getColors());
      }

      registry.setLogging(false);
      //populateLeds();
    } else if (mode == device.ARTNET) {
      artnet = new ArtnetP5();
      isConnected = true; 
      artnetPacket = new byte[numArtnetFixtures*numArtnetChannels]; // Reusing numLeds to indicate the number of fixtures (even though
      
      update(scrape.getColors());  
  }

    // Turn off LEDs
    // Turn off LEDs first
    //animator.resetPixels();
  }

  //Close existing connections
  void shutdown() {
    if (mode == device.FADECANDY && opc!=null) {
      //opc.dispose();
      opc = null;
    }
    if (mode==device.PIXELPUSHER && registry !=null) {
      registry.stopPushing() ;  //TODO: Need to disconnect devices as well
      registry.deleteObserver(testObserver);
    }
    if (mode==device.ARTNET) {
    }
    if (mode==device.NULL) {
    }
  }

  //toggle verbose logging for PixelPusher
  void pusherLogging(boolean b) {
    registry.setLogging(b);
  }
}

// PixelPusher Observer
// Monitors network for changes in PixelPusher configuration

class TestObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable registry, Object updatedDevice) {
    println("Registry changed!");
    if (updatedDevice != null) {
      println("Device change: " + updatedDevice);
    }
    this.hasStrips = true;
  }
}

void delayThread(int ms)
{
  try
  {    
    Thread.sleep(ms);
  }
  catch(Exception e) {
  }
}