int HR_WINDOW = 10; //Window size for Heart Rate Calculation
float[] dataIBI = new float[HR_WINDOW];

void initHR() {
  dataIBI = new float[HR_WINDOW];
}

float nextValueHR(float val, float[] HRArray) {
  float totalIBI = 0;
  appendArray(HRArray, val);
  for(int i = 0 ; i < HRArray.length; i++){
    totalIBI += HRArray[i];
  }
  return 60000./(totalIBI/(float)HR_WINDOW);
}
