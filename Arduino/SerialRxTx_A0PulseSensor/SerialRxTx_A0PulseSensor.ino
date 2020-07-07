#define INT_MICROS 2000 //500Hz = 1M/MICRO_S;
#define pulseSensorPin A0

int data = 0;
long timer = micros(); //timer
int ledOn = 0;
int beat = 0;

//  VARIABLES FOR THE PULSE SENSOR
int beatPulse = 0;
// these variables are volatile because they are used during the interrupt service routine!
volatile int BPM;                   // used to hold the pulse rate
volatile int Signal;                // holds the incoming raw data
volatile int IBI = 600;             // holds the time between beats, the Inter-Beat Interval
volatile boolean Pulse = false;     // true when pulse wave is high, false when it's low
volatile boolean QS = false;        // becomes true when Arduoino finds a beat.

//Pulse sensor related
volatile int rate[10];                    // used to hold last ten IBI values
volatile unsigned long sampleCounter = 0;          // used to determine pulse timing
volatile unsigned long lastBeatTime = 0;           // used to find the inter beat interval
volatile int P = 512;                     // used to find peak in pulse wave
volatile int T = 512;                     // used to find trough in pulse wave
volatile int thresh = 512;                // used to find instant moment of heart beat
volatile int amp = 100;                   // used to hold amplitude of pulse waveform
volatile boolean firstBeat = true;        // used to seed rate array so we startup with reasonable BPM
volatile boolean secondBeat = true;       // used to seed rate array so we startup with reasonable BPM

void setup() {
  Serial.begin(115200); //initialize a serial port at a 115200 baud rate.
  pinMode(LED_BUILTIN, OUTPUT); //set the built-in LED to output
}

void loop() {
  if (micros() - timer > INT_MICROS) { //Timer: send sensor data in every 2ms
    timer = micros();
    getDataFromProcessing(); //Receive before sending out the signals
    Serial.flush(); //Flush the serial buffer
    Signal = analogRead(pulseSensorPin);
    sendDataToProcessing('A', Signal); //Put the beat into buffer to sent it out later.
    beatPulse = checkHeartBeat(pulseSensorPin);
    sendDataToProcessing('B', beatPulse);
  }
}

void getDataFromProcessing() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == 'a') { //when an 'a' charactor is received.
      ledOn = 1 - ledOn;
      digitalWrite(LED_BUILTIN, ledOn); //turn on the built in LED on Arduino Uno
    }
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}

int checkHeartBeat(int pulsePin) {
  sampleCounter += 2;                         // keep track of the time in mS with this variable
  int N = sampleCounter - lastBeatTime;       // monitor the time since the last beat to avoid noise

  //  find the peak and trough of the pulse wave
  if (Signal < thresh && N > (IBI / 5) * 3) { // avoid dichrotic noise by waiting 3/5 of last IBI
    if (Signal < T) {                       // T is the trough
      T = Signal;                         // keep track of lowest point in pulse wave
    }
  }

  if (Signal > thresh && Signal > P) {        // thresh condition helps avoid noise
    P = Signal;                             // P is the peak
  }                                        // keep track of highest point in pulse wave
  //  NOW IT'S TIME TO LOOK FOR THE HEART BEAT
  // signal surges up in value every time there is a pulse
  if (N > 250) {                                  // avoid high frequency noise
    if ( (Signal > thresh) && (Pulse == false) && (N > (IBI / 5) * 3) ) {
      Pulse = true;                               // set the Pulse flag when we think there is a pulse
      IBI = sampleCounter - lastBeatTime;         // measure time between beats in mS
      lastBeatTime = sampleCounter;               // keep track of time for next pulse

      if (firstBeat) {                       // if it's the first time we found a beat, if firstBeat == TRUE
        firstBeat = false;                 // clear firstBeat flag
        return 0;                            // IBI value is unreliable so discard it
      }
      if (secondBeat) {                      // if this is the second beat, if secondBeat == TRUE
        secondBeat = false;                 // clear secondBeat flag
        for (int i = 0; i <= 9; i++) {   // seed the running total to get a realisitic BPM at startup
          rate[i] = IBI;
        }
      }

      // keep a running total of the last 10 IBI values
      word runningTotal = 0;                   // clear the runningTotal variable

      for (int i = 0; i <= 8; i++) {          // shift data in the rate array
        rate[i] = rate[i + 1];            // and drop the oldest IBI value
        runningTotal += rate[i];          // add up the 9 oldest IBI values
      }

      rate[9] = IBI;                          // add the latest IBI to the rate array
      runningTotal += rate[9];                // add the latest IBI to runningTotal
      runningTotal /= 10;                     // average the last 10 IBI values
      BPM = 60000 / runningTotal;             // how many beats can fit into a minute? that's BPM!
      QS = true;                              // set Quantified Self flag
      // QS FLAG IS NOT CLEARED INSIDE THIS ISR
    }
  }

  if (Signal < thresh && Pulse == true) {    // when the values are going down, the beat is over
    Pulse = false;                         // reset the Pulse flag so we can do it again
    amp = P - T;                           // get amplitude of the pulse wave
    thresh = amp / 2 + T;                  // set thresh at 50% of the amplitude
    P = thresh;                            // reset these for next time
    T = thresh;
  }

  if (N > 2500) {                            // if 2.5 seconds go by without a beat
    thresh = 512;                          // set thresh default
    P = 512;                               // set P default
    T = 512;                               // set T default
    lastBeatTime = sampleCounter;          // bring the lastBeatTime up to date
    firstBeat = true;                      // set these to avoid noise
    secondBeat = true;                     // when we get the heartbeat back
  }
  if(QS){ 
    QS=false;
    return 1;
  }
  else return 0;
}
