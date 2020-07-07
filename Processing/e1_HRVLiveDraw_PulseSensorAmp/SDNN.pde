int SDNN_WINDOW = 16; //Window size for SDNN Calculation
float[] dataSDNN = new float[SDNN_WINDOW];

void initSDNN() {
  dataSDNN = new float[SDNN_WINDOW];
}

float nextValueSDNN(float val, float[] SDNNArray) {
  appendArray(SDNNArray, val);
  return standardDeviation(SDNNArray);
}

float standardDeviation(float[] data) {
  float sum_data=0;
  float avg_data=0;
  float sum_quadata=0;
  float sd=0;
  for (int i=0; i<data.length; i=i+1) {
    sum_data = sum_data+data[i];
  }
  avg_data = sum_data/data.length;
  for (int i=0; i<data.length; i=i+1) {
    sum_quadata=sum_quadata+sq(data[i]-avg_data);
  }
  sd=sqrt(sum_quadata/data.length);
  return sd;
}
