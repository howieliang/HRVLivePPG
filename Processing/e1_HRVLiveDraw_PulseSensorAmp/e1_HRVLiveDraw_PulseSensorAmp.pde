//*********************************************
// Time-Series Physiological Signal Processing
// e8_TimeSeriesData_HRVLiveDrawPPG
// Rong-Hao Liang: r.liang@tue.nl
//*********************************************
//Before use, please make sure your Arduino has 1 ppg sensor connected
//to the analog input, and arduino sketch was uploaded.

import processing.serial.*;
Serial port;
int ppg = 0; //value of ppg sensor


int dataNum = 500; //number of data to show
float[] ppgHist = new float[dataNum]; 
float[] beatHist = new float[dataNum];
float[] IBIHist = new float[dataNum];

float minutes = 3; //collect 3-minutes data
int maxFileSize = 1000; //max amount of IBIs to save in the file.
int TS = 0; //global timestamp (updated by the incoming data)
int lastCaptureTS = 0; //the timestamp when last capture started

boolean beatDetected = false;
int lastBeatTS = 0;
ArrayList<Float> IBIList;
ArrayList<Float> HRList;
ArrayList<Float> SDNNList;
int currIBI = 0;
float currHR = 0;
float currSDNN = 0;

//Filtering
int lastIBI = 0;
float ratio = 0.25; //thld of ectopic beat detection.
float IBI_UB = 1500; //40 bpm
float IBI_LB = 400; //150 bpm

//File Writer
PrintWriter output;

boolean bClear = false;
boolean bDrawOnly = false;
boolean bSave = false;
boolean isCollecting = true;

void setup() {
  size(500, 500);

  //Initiate the serial port
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];//check the printed list
  //String portName = Serial.list()[0]; //For windows PC
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear();           // flush the Serial buffer

  IBIList = new ArrayList<Float>();
  HRList = new ArrayList<Float>();
  SDNNList = new ArrayList<Float>();
}

void draw() {
  //set styles
  background(255);
  fill(255, 0, 0);

  //visualize the serial data
  float h = height/2;
  if((float)(TS-lastCaptureTS)/1000. > (60*minutes)) isCollecting = false;

  lineGraph(ppgHist, 0, 1023, 0, 0*h, width, h, color(255, 0, 0));
  lineGraph(beatHist, 0, 1, 0, 0*h, width, h, color(0, 0, 255));
  drawInfo(minutes, h);
  pushMatrix();
  translate(0, 2*h);
  drawDataLive(minutes, h, IBIList, HRList, SDNNList);
  popMatrix();
  
  if (bSave) {
    saveIBIFile(month()+"-"+day()+"-"+hour()+"-"+minute()+"-"+second()+".txt");
    bSave = false;
  }

  if (bClear) {
    IBIList.clear();
    HRList.clear();
    SDNNList.clear();
    initHR();
    initSDNN();
    lastCaptureTS = TS;
    bClear = false;
    isCollecting = true;
  }
}

void saveIBIFile(String fileName) {
  output = createWriter(dataPath("")+"/"+fileName);
  for (float d : IBIList) { 
    if (d>0) output.println(nf(d/1000., 1, 3));
    else output.println(nf(-d/1000., 1, 3));
  }
  output.flush(); // Writes the remaining data to the file
  output.close(); // Finishes the file
  println("File Saved: "+fileName);
}

void drawDataLive(float scale, float h, ArrayList<Float> IBIList, ArrayList<Float> HRList, ArrayList<Float> SDNNList) {
  if (IBIList!=null) {
    float lastX = 0;
    float lastY = 0;
    int visLength = min(IBIList.size(), min(HRList.size(), SDNNList.size()));
    for (int i = 0; i < visLength; i++) {
      float ibi = IBIList.get(i);
      float hr =  HRList.get(i);
      float sdnn = SDNNList.get(i);
      float x = map(ibi, 0, 60000*scale, 0, width); //60000ms = 1 min;
      float yIBI = map(ibi, 0, 1500, 0, h);
      float yHR = map(hr, 0, 120, 0, h);
      float ySDNN = map(sdnn, 0, 100, 0, h);

      if (ibi > 0) { //normal beat
        stroke(0, 255, 255);
      } else { //abnormal beat
        stroke(255, 0, 255);
        x = map(-ibi, 0, 60000*scale, 0, width); //60000ms = 1 min;
        yIBI = map(-ibi, 0, 1500, 0, h);
      }

      noStroke();
      if (ibi > 0) { //normal beat
        fill(0, 255, 255);
      } else { //abnormal beat
        fill(255, 0, 255);
      }
      ellipse(lastX, -yHR, 10/scale, 10/scale);

      noStroke();
      if (ibi > 0) { //normal beat
        fill(0, 255, 0);
      } else { //abnormal beat
        fill(255, 0, 255);
      }
      ellipse(lastX, -ySDNN, 10/scale, 10/scale);

      stroke(255, 0, 0);
      noFill();
      line(lastX, 0, lastX, -yIBI); 
      lastX+=x;
      lastY=yIBI;
    }
  }
}

void drawInfo(float scale, float h) {
  fill(0);
  textAlign(RIGHT, CENTER);
  text("Press 'c' to restart capturing", width, 0.1*h);
  text("Press 's' to save the captured IBIs", width, 0.2*h);
  stroke(0);
  fill(0);
  textAlign(LEFT, CENTER);
  text("PPG and Beat", 0, .1*h);
  line(0, 1*h, width, 1*h);

  fill(0);
  textAlign(LEFT, CENTER);
  text("Legend", 0, 1.1*h);
  textAlign(RIGHT, CENTER);
  text("Last IBI: "+currIBI+" ms", width, 1.1*h);
  text("IBI collected: "+IBIList.size()+"/"+maxFileSize, width, 1.2*h);
  text("Time Lapsed: "+nf((float)(TS-lastCaptureTS)/1000., 0, 1)+" (s)", width, 1.3*h);
  if (HRList.size()<HR_WINDOW) text("Calculating Heart Rate: "+HRList.size()+"/"+HR_WINDOW, width, 1.4*h);
  else text("Heart Rate: "+nf(currHR, 0, 1)+" bpm", width, 1.4*h);
  if (SDNNList.size()<SDNN_WINDOW) text("Calculating SDNN: "+SDNNList.size()+"/"+SDNN_WINDOW, width, 1.5*h);
  else text("SDNN: "+nf(currSDNN, 0, 1)+" ms", width, 1.5*h);
  textAlign(LEFT, CENTER);
  text(0+"s", 0, 1.9*h);
  textAlign(RIGHT, CENTER);
  text(60*scale+"s", width, 1.9*h);
  stroke(0);
  line(0, 2*h, width, 2*h);
}

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  int dataIndex = -1;
  if (inData.charAt(0) == 'A') {  
    dataIndex = 0;
  }
  if (inData.charAt(0) == 'B') {  
    dataIndex = 1;
  }
  if (dataIndex==0) {
    ppg = int(trim(inData.substring(1))); //store the value
    appendArray(ppgHist, ppg); //store the data to history (for visualization)
    TS+=2; //update the timestamp
    return;
  }
  if (dataIndex==1) {
    float beatPulse = int(trim(inData.substring(1))); //store the value
    appendArray(beatHist, beatPulse); //store the data to history (for visualization)
    if (!beatDetected) {
      if (beatPulse==1) { 
        beatDetected = true; //detection edge rising
        if (lastBeatTS>0) {
          currIBI = TS-lastBeatTS;
          if (IBIList.size() < maxFileSize && isCollecting) {
            boolean flagAB = false; // flag: abnormal beat
            float diff = (float)abs(currIBI-lastIBI);
            float diffRatio = (lastIBI == 0 ? 1: diff/(float)lastIBI);
            if (diffRatio>ratio && IBIList.size()>0) {
              flagAB = true; //abnormal beat
            }
            if (!flagAB) { 
              IBIList.add((float)currIBI); //add the currIBI to the IBIList
              currHR = nextValueHR((float)currIBI, dataIBI); //Compute Heart Rate
              if (HRList.size()<HR_WINDOW) {
                HRList.add((float)0);
              } else {
                HRList.add(currHR);
              }
              currSDNN = nextValueSDNN((float)currIBI, dataSDNN); //Compute SDNN
              if (SDNNList.size()<SDNN_WINDOW) {
                SDNNList.add((float)0);
              } else {
                SDNNList.add(currSDNN);
              }
            } else {
              IBIList.add((float)-currIBI); //add the currIBI to the IBIList
              if (HRList.size()<HR_WINDOW) { //Not enough samples
                HRList.add((float)0); //Fill in 0
              } else { //Enough samples
                HRList.add(currHR); //Fill in last HR
              }
              if (SDNNList.size()<SDNN_WINDOW) { //Not enough samples
                SDNNList.add((float)0); //Fill in 0
              } else { //Enough samples
                SDNNList.add(currSDNN); //Fill in last SDNN
              }
            }
            lastIBI = currIBI; //save last IBI
          }
        } 
        lastBeatTS = TS; //save the timestamp of last beat
      }
    } else {
      if (beatPulse==0) beatDetected = false; //detection edge falling
    }
    return;
  }
}

//Append a value to a float[] array.
float[] appendArray (float[] _array, float _val) {
  float[] array = _array;
  float[] tempArray = new float[_array.length-1];
  arrayCopy(array, 1, tempArray, 0, tempArray.length);
  array[array.length-1] = _val;
  arrayCopy(tempArray, 0, array, 0, tempArray.length);
  return array;
}

//Draw a line graph to visualize the sensor stream
//lineGraph(float[] data, float lowerbound, float upperbound, float x, float y, float width, float height, color c)
void lineGraph(float[] data, float _l, float _u, float _x, float _y, float _w, float _h, color _c) {
  pushStyle();
  noFill();
  stroke(_c);
  float delta = _w/data.length;
  beginShape();
  for (float i : data) {
    float y = map(i, _l, _u, 0, _h);
    vertex(_x, _y+(_h-y));
    _x = _x + delta;
  }
  endShape();
  popStyle();
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    TS = 0;
    lastBeatTS = 0;
    currIBI = 0;
  }
  if (key == 'c' || key == 'C') {
    bClear = true;
  }
  if (key == 's' || key == 'S') {
    bSave = true;
  }
}
