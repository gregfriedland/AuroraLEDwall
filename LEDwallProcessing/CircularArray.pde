// Utility class holding data in a circular buffer and implementing basic exponential moving averages

class CircularArrayWithAvgs extends CircularArray {
  int avgLength = -1, avgLength2 = -1;
  double alpha = -1, alpha2 = -1;
  double[] ema, ema2;

  CircularArrayWithAvgs(int length, int avgLength, int avgLength2) {
    super(length);
    this.avgLength = avgLength;
    this.avgLength2 = avgLength2;
    this.alpha = 2.0 / (avgLength + 1);
    this.alpha2 = 2.0 / (avgLength2 + 1);
    ema = new double[length];
    ema2 = new double[length];
  }

  void add(double val) {
    super.add(val);
    ema[index] = data[index] * alpha + (ema[getIndex(index-1)] * (1-alpha));
    ema2[index] = data[index] * alpha2 + (ema2[getIndex(index-1)] * (1-alpha2));
  }
  
  double getEMA1(int ind) {
    return ema[getIndex(ind)];
  }

  double getEMA2(int ind) {
    return ema2[getIndex(ind)];
  }
}  
  

class CircularArray {
  int index = -1, prevIndex = -1, length, avgLength = -1, sdLength = -1;
  double[] data;
  double[] movingAvg, movingSD;
  
  CircularArray(int length) {
    this.length = length;
    data = new double[length];
  }
  
  int getIndex() { return index; }
  int getPrevIndex() { return prevIndex; }
  
  void add(double val) {
    prevIndex = index;
    index++;
    if (index == length) index = 0;
    
    data[index] = val;    
  }

  double getPrev() { 
    if (prevIndex == -1) return 0; 
    return data[prevIndex]; 
  }
  double get() { 
    if (index == -1) return 0; 
    return data[index]; 
  }
  double get(int ind) { return data[getIndex(ind)]; }

  int getLength() { return length; }
  int getIndex(int ind) { return (ind + length) % length; }
  
  
  // not compatible with moving average
//  void set(int ind, double val) {
//    data[getIndex(ind)] = val;
//  }
  
  double maxVal() {
    double m = 0;
    for (int i=0; i<length; i++) m = max((float)m, (float)data[i]);
    return m;
  }
  
  double[] getArray() { return data; }
  double mean() { return mean(0, length-1); }
  double mean(int startInd, int endInd) { return calcMean(data, startInd, endInd); }
  double sd(double mean) { return sd(0, length-1, mean); }
  double sd(int startInd, int endInd, double mean) { return calcSD(data, startInd, endInd, mean); }
  double sd(int startInd, int endInd) { return calcSD(data, startInd, endInd); }
}


int getIndex(int ind, int length) { return (ind + length) % length; }

double calcMean(double[] data, int startInd, int endInd) {
  double sum = 0;
  int diff = endInd - startInd + 1;
  if (endInd < startInd ) diff = endInd+data.length - startInd + 1;

  for (int i=startInd; i<startInd+diff; i++) sum += data[getIndex(i, data.length)];
  return sum / diff;
}  

double calcSD(double[] data, int startInd, int endInd, double mean) {
  float sum = 0;
  int diff = endInd - startInd + 1;
  if (endInd < startInd ) diff = endInd+data.length - startInd + 1;
  for (int i=startInd; i<startInd+diff; i++) sum += sq((float)(data[getIndex(i, data.length)] - mean));
  return sqrt(sum / diff);
}

double calcSD(double[] data, int startInd, int endInd) {
  double mean = calcMean(data, startInd, endInd);
  return calcSD(data, startInd, endInd, mean);
}

