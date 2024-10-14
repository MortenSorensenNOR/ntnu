import pandas as pd
import numpy as np

# Load the CSV file
file_path = '../Data/buffer_load_no_input_res.csv'
data = pd.read_csv(file_path)

# Extract the voltage signals from the DataFrame
length = len(data.iloc[:, 1])
start = length // 2 - length // 4
end = length // 2 + length // 4
voltage_signal_1 = data.iloc[start:end, 1]  # Assuming second column is the first voltage signal
voltage_signal_2 = data.iloc[start:end, 2]  # Assuming third column is the second voltage signal

# voltage_signal_1 -= 1.0
# voltage_signal_2 -= 1.0

# Function to calculate RMS voltage
def calculate_rms(signal):
    return np.sqrt(np.mean(np.square(signal)))

# Calculate the average RMS voltage for each signal
rms_voltage_1 = calculate_rms(voltage_signal_1)
rms_voltage_2 = calculate_rms(voltage_signal_2)

print(f"Average RMS Voltage of Signal 1: {rms_voltage_1:.4f} V")
print(f"Average RMS Voltage of Signal 2: {rms_voltage_2:.4f} V")

attenuation = 20 * np.log10(rms_voltage_2/rms_voltage_1)
print(f"Attenuation: {attenuation} dB")
