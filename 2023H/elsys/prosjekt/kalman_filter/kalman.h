#ifndef KALMAN_H
#define KALMAN_H

class KalmanSensor {
public:
    KalmanSensor(float measured_error, float estimated_error, float q);
    float updateEstimate(float measurement);
    void setMeasurementError(float measured_error);
    void setEstimateError(float estimated_error);
    void setProcessNoise(float q);
    float getKalmanGain();
    float getEstimateError();

private:
    float _measured_error;
    float _estimated_error;
    float _q;
    float _current_estimate = 0;
    float _last_estimate = 0;
    float _kalman_gain = 0; 
}

#endif