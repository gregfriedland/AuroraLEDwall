// Class to detect beats
// Implementation by Greg Friedland in 2012 based on methods described by Simon Dixon in 
// "ONSET DETECTION REVISITED" Proc. of the 9th Int. Conference on Digital Audio Effects (DAFx-06), Montreal, Canada, September 18-20, 2006
// (http://www.dafx.ca/proceedings/papers/p_133.pdf)

import java.util.HashMap;

class BeatDetect {
  String[] metricNames = {"spectralFlux", "spectrum"}; 
  HashMap onsetHists, thresholds, metrics, metricSDs;
  long[] lastOnsetTimes; 
  
  CircularArray[] fullSpec;
  int numBands, historySize;
  FFT fft;
  float[] bandFreqs;
  float MIN_FREQ = 100, MAX_FREQ = 10000;
  float MIN_THRESHOLD = 0; 
  int SHORT_HIST_SIZE=3, LONG_HIST_SIZE=5; 
  int[] fftBandMap;
  boolean[] analyzeBands;
  int[] NUM_NEIGHBORS = {1, 5, 5};
  float[] threshSensitivity;
  int[] beatLength;
  
  BeatDetect(FFT fft, int numBands, int historySize) {
    MIN_FREQ = max(MIN_FREQ, SAMPLE_RATE/SAMPLE_SIZE);
    this.fft = fft;
    this.historySize = historySize;
    
    beatLength = new int[numBands];
    threshSensitivity = new float[numBands];
    for (int i=0; i<numBands; i++) {
      threshSensitivity[i] = 5;
      beatLength[i] = 200;
    }
    
    analyzeBands = new boolean[numBands];
    for (int i=0; i<numBands; i++) analyzeBands[i] = true;
    
    bandFreqs = new float[numBands];
    float logBandwidth = (log(MAX_FREQ) - log(MIN_FREQ)) / (numBands - 1);
    println("Using log bandwidth " + logBandwidth);
    for (int i=0; i<numBands; i++) {
      bandFreqs[i] = MIN_FREQ * exp(i*logBandwidth);
      println("Band " + i + " using frequency " + bandFreqs[i]);
    }
    
    // map fft bands (samplesize/2+1) to our band definition
    fftBandMap = new int[fft.specSize()];
    for (int i=0; i<fftBandMap.length; i++) {
      float freq = fft.indexToFreq(i);
      int ind = round(log(freq/MIN_FREQ) / logBandwidth);
      fftBandMap[i] = ind;
     // println("Mapping fft band " + i + " with freq " + freq + " to band " + ind);
    }
    
    this.numBands = numBands;
    
    onsetHists = new HashMap();
    thresholds = new HashMap();
    metrics = new HashMap();
    metricSDs = new HashMap();

    for (int i=0; i<metricNames.length; i++) {
      CircularArrayWithAvgs[] m = new CircularArrayWithAvgs[numBands];
      CircularArrayWithAvgs[] sd = new CircularArrayWithAvgs[numBands];
      CircularArray[] o = new CircularArray[numBands];
      CircularArray[] t = new CircularArray[numBands];
      for (int j=0; j<numBands; j++) {
        m[j] = new CircularArrayWithAvgs(historySize, SHORT_HIST_SIZE, LONG_HIST_SIZE);
        sd[j] = new CircularArrayWithAvgs(historySize, SHORT_HIST_SIZE, LONG_HIST_SIZE);
        o[j] = new CircularArray(historySize);
        t[j] = new CircularArray(historySize);
      }
      
      onsetHists.put(metricNames[i], o);
      thresholds.put(metricNames[i], t);
      metrics.put(metricNames[i], m);
      metricSDs.put(metricNames[i], sd);
    }
    lastOnsetTimes = new long[numBands];    
  }

  private CircularArray getArray(String type, String metricName, int band) {
    HashMap hm;
    if (type.equals("metric")) hm = metrics;
    else if (type.equals("onsetHist")) hm = onsetHists;
    else if (type.equals("threshold")) hm = thresholds;
    else if (type.equals("sd")) hm = metricSDs;
    else {
      println("Invalid array type " + type);
      return null;
    }
    
    CircularArray[] ca = (CircularArray[]) hm.get(metricName);
    return ca[band];
  }  
  
  private CircularArrayWithAvgs getArrayAvgs(String type, String metricName, int band) {
    return (CircularArrayWithAvgs) getArray(type, metricName, band);
  }

  void setSensitivity(int band, float threshSensitivity, int beatLength) {
    this.threshSensitivity[band] = threshSensitivity;
    this.beatLength[band] = beatLength;
  }

  int getBandMapping(int fftBand) {
    return fftBandMap[fftBand];
  }

  void setFFTWindow(int window) {
    fft.window(window);
  }
  
  void update(AudioBuffer data) {
    fft.forward(data);
    
    for (int i=0; i<NUM_BANDS; i++) {
      if (!analyzeBands[i]) continue;
      
      // multiply neighbors
      int fftBand = fft.freqToIndex(bandFreqs[i]);
      double val = 1;
      for (int j=max(0, fftBand-NUM_NEIGHBORS[i]); j<=min(fft.specSize()-1, fftBand+NUM_NEIGHBORS[i]); j++) {
        val *= fft.getBand(j);
      }
      getArray("metric", "spectrum", i).add(val);
      
      //spectrum[i].add(specSums[i] / counts[i]);
      int ind = getArray("metric", "spectrum", i).getIndex();
      getArray("sd", "spectrum", i).add(getArray("metric", "spectrum", i).sd(ind-LONG_HIST_SIZE+1, ind));

      // calculate GF metric
      double thresh = getArrayAvgs("metric", "spectrum", i).getEMA2(ind-1) + threshSensitivity[i] * getArrayAvgs("sd", "spectrum", i).getEMA2(ind-1);
      getArray("threshold", "spectrum", i).add(thresh);
      if (getArrayAvgs("metric", "spectrum", i).getEMA1(ind) > max((float)thresh, MIN_THRESHOLD)) {
        getArray("onsetHist", "spectrum", i).add(1);
      } else {
        getArray("onsetHist", "spectrum", i).add(0);
      }
      
      // calculate spectral flux     
      float diff = abs((float)getArray("metric", "spectrum", i).get()) - abs((float)getArray("metric", "spectrum", i).getPrev());
      getArray("metric", "spectralFlux", i).add((diff + abs(diff)) / 2.0);
      getArray("sd", "spectralFlux", i).add(getArray("metric", "spectralFlux", i).sd(ind-LONG_HIST_SIZE+1, ind));
      
      thresh = getArrayAvgs("metric", "spectralFlux", i).getEMA2(ind-1) + threshSensitivity[i] * getArrayAvgs("sd", "spectralFlux", i).getEMA2(ind-1);
      getArray("threshold", "spectralFlux", i).add(thresh);
      if (getArrayAvgs("metric", "spectralFlux", i).getEMA1(ind) > max((float)thresh, MIN_THRESHOLD) && millis() - lastOnsetTimes[i] >= beatLength[i] ) {
        getArray("onsetHist", "spectralFlux", i).add(1);
        //println("beat gap" + (i+1) + ": " + (millis() - lastOnsetTimes[i]));
        lastOnsetTimes[i] = millis();
      } else {
        getArray("onsetHist", "spectralFlux", i).add(0);
      }
    }    
  }
  
  void analyzeBand(int band, boolean on) { analyzeBands[band] = on; }
  
  double getMetric(String type, int band, int index) { return getArray("metric", type, band).get(index); }
  double getMetricMean(String type, int band, int index) { return getArrayAvgs("metric", type, band).getEMA1(index); }
  double getThreshold(String type, int band, int index) { return getArray("threshold", type, band).get(index); }
  double getMetricMax(String type, int band) { return getArray("metric", type, band).maxVal(); }
  boolean isOnset(String type, int band, int index) { return getArray("onsetHist", type, band).get(index) == 1; }
  String[] getMetricNames() { return metricNames; }
  boolean isBeat(String type, int band) { 
    return (millis() - lastOnsetTimes[band]) < beatLength[band]; 
  }
  float beatPos(String type, int band) {
    float diff = (millis() - lastOnsetTimes[band]) / float(beatLength[band]);
    if (diff <= 1){
     float val = sin(diff*PI/2);
     //float val = 1 - abs(diff-0.5) * 2; //exp(-pow(diff - 0.5, 2.0)*25);
     return val;
    }
    else return 0;
  }
  
  float beatPosSimple(String type, int band) {
    float diff = (millis() - lastOnsetTimes[band]) / float(beatLength[band]);
    if (diff <= 1) return diff;
    else return 0;
  }
}

