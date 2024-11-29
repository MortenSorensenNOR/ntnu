#include <math.h>
#include "kalman.h"

KalmanSensor::KalmanSensor(float measured_error, float estimated_error, float q) {
    _measured_error = measured_error;
    _estimated_error = estimated_error;
    _q = q;
}

float KalmanSensor::updateEstimate(float measurement) {
    _kalman_gain = _estimated_error / (_estimated_error + _measured_error);
    _current_estimate = _last_estimate + _kalman_gain * (measurement - _last_estimate);
    _estimated_error = (1.0f - _kalman_gain) * _estimated_error + fabs(_last_estimate - _current_estimate) * _q;
    _last_estimate = _current_estimate;

    return _current_estimate;
}

void KalmanSensor::setMeasurementError(float measured_error) {
    _measured_error = measured_error;
}

void KalmanSensor::setEstimateError(float estimated_error) {
    _estimated_error = estimated_error;
}

void KalmanSensor::setProcessNoise(float q) {
    _q = q;
}

float KalmanSensor::getKalmanGain() {
    return _kalman_gain;
}

float KalmanSensor::getEstimateError() {
    return _estimated_error;
}