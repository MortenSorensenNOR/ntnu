import numpy as np
import matplotlib.pyplot as plt
import sys

def raspi_import(path, channels=3):
    with open(path, 'r') as fid:
        sample_period = np.fromfile(fid, count=1, dtype=float)[0]
        data = np.fromfile(fid, dtype='uint16').astype('float64')
        data = data.reshape((-1, channels))
    data = data[1:, :]
    sample_period *= 1e-6
    return sample_period, data

if __name__ == "__main__":
    sample_period, data = raspi_import(sys.argv[1] if len(sys.argv) > 1 else 'foo.bin')
    voltage = data * (3.3 / 4095)

    time = np.arange(len(voltage)) * sample_period * 1000  # ms

    fig, axes = plt.subplots(3, 1, figsize=(10, 6), sharex=True)
    for i, ax in enumerate(axes):
        ax.plot(time, voltage[:, i])
        ax.set_ylabel(f'Ch {i+1} (V)')
        ax.grid(True, alpha=0.3)
    axes[-1].set_xlabel('Time (ms)')
    plt.tight_layout()
    plt.show()
