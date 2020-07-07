# Real-time HRV calculation and collection from PPG signal
Dr. Rong-Hao Liang | *TU Eindhoven* | r.liang@tue.nl

## Prerequisites:

### Hardware:
- Any Arduino-compatiable microcontrollers.
- PPG Sensor: [Pulse Sensor Amped](https://pulsesensor.com/products/pulse-sensor-amped}
- A USB Cable.

### Software:
- [Arduino IDE](https://www.arduino.cc/)
- [Processing IDE](https://processing.org/)

## Run the Software:
1. Plug the PPG sensor's signal line to the AnalogInput0 port of the Arduino, and also it's power and ground lines.
2. Upload the SerialRxTx_A0PulseSensor.ino to the Arduino.
3. Run the e1_HRVLiveDraw_PulseSensorAmp.pde on the Processing IDE
- Press 'c' to restart capturing
- Press 's' to save the captured IBIs into <date>_<time>.txt file

## To modify the Arduino code:
- Change the Sample rate via `#define INT_MICROS 2000 //500Hz = 1M/MICRO_S`
- Change the Pulse sensor pin via `#define pulseSensorPin A0`

## To modify the Processing code:
- Change the Length of Collection: `float minutes = 3; //collect 3-minutes data`
- Increase the File Size: `int maxFileSize = 1000; //max amount of IBIs to save in the file.`
- Adjust the threshold of ectopic detection: `float ratio = 0.25; //thld of ectopic beat detection.`
- Serial Port does not work on Windows PC: `String portName = Serial.list()[0]; //For windows PC`
- Access the Parameters: Check `drawInfo(minutes, h)` and `drawDataLive(minutes, h, IBIList, HRList, SDNNList)`








