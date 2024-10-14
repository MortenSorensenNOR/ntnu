"""
Calculate the gain of the amplifier in the different test cases.
Input is a csv file where the first column is time in seconds, the second column is input voltage and the third column is output voltage.
Calculate the AC RMS voltages for the input and output signal, 
and calculate the overall gain of the amplifier as the ratio of the output voltage to the input voltage.
"""

import numpy as np

def gain(file):
    data = np.genfromtxt(file, delimiter=',', skip_header=1)

    # Calculate RMS of input and output signal
    v_pluss = data[:, 1]
    v_out = data[:, 2]

    # Normalize input and output signal
    v_pluss = v_pluss - np.mean(v_pluss)
    v_out = v_out - np.mean(v_out)

    # Calculate RMS of input and output signal
    rms_v_pluss = np.sqrt(np.mean(v_pluss**2))
    rms_v_out = np.sqrt(np.mean(v_out**2))

    # Calculate gain
    gain = rms_v_out/rms_v_pluss

    return (rms_v_pluss, rms_v_out, gain)

if __name__ == "__main__":
    file = "open_loop_100k_signal"
    (v_in, v_out, calculate_gain) = gain(f"../Data/{file}.csv")
    print(f"Gain for {file} is {v_out:.2f}/{v_in:.2f} = {calculate_gain:.2f}")
    print()

    file = "open_loop_100_signal"
    (v_in, v_out, calculate_gain) = gain(f"../Data/{file}.csv")
    print(f"Gain for {file} is {v_out:.2f}/{v_in:.2f} = {calculate_gain:.2f}")
    print()

    file = "inverting_no_load_signal"
    (v_in, v_out, calculate_gain) = gain(f"../Data/{file}.csv")
    print(f"Gain for {file} is {v_out:.2f}/{v_in:.2f} = {calculate_gain:.2f}")
    print()

    file = "inverting_100k_signal"
    (v_in, v_out, calculate_gain) = gain(f"../Data/{file}.csv")
    print(f"Gain for {file} is {v_out:.2f}/{v_in:.2f} = {calculate_gain:.2f}")
    print()
