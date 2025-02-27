import numpy as np
import kwave.kwave as kw
import matplotlib.pyplot as plt

# Define the simulation grid
Nx, Ny = 256, 256  # Grid size
dx = 1e-3  # Grid spacing (1 mm)
dy = dx
kgrid = kw.KWaveGrid(Nx, dx, Ny, dy)

# Define the medium properties (speed of sound, density)
medium = kw.KWaveMedium(sound_speed=1500)  # Water: ~1500 m/s

# Define a point source in the center
source = kw.KWaveSource()
source.p0 = np.zeros((Nx, Ny))
source.p0[Nx//2, Ny//2] = 1  # Initial pressure pulse

# Define a microphone array as the sensor mask
num_sensors = 10
sensor_x = np.linspace(50, 200, num_sensors).astype(int)
sensor_y = np.full(num_sensors, 180)  # Line array at y=180
sensor_mask = np.zeros((Nx, Ny))
sensor_mask[sensor_x, sensor_y] = 1  # Mark sensor locations

sensor = kw.KWaveSensor(sensor_mask)

# Create and run the simulation
k_sim = kw.KWaveSimulation(kgrid, medium, source, sensor)
sensor_data = k_sim.run(time_step=2.5e-7, time_end=2e-4)

# Visualize the final wavefield
plt.imshow(sensor_data[-1], cmap="hot", origin="lower")
plt.scatter(sensor_y, sensor_x, color="blue", label="Sensors")
plt.colorbar(label="Pressure")
plt.legend()
plt.show()
