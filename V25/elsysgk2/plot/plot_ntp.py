import pandas as pd
import matplotlib.pyplot as plt

# Load the CSV file, skipping metadata and header row
file_path = "../data/ntp_time_sync_test_5ms.csv"
column_names = ["Time (s)", "DIO 1", "DIO 0"]
df = pd.read_csv(file_path, skiprows=10, names=column_names)

# Plot the digital lines
plt.figure(figsize=(12, 6))
plt.plot(df["Time (s)"], df["DIO 1"] + 1, label="Clock device 2")  # offset for visibility
plt.plot(df["Time (s)"], df["DIO 0"], label="Clock device 1")
plt.xlabel("Time (s)", fontsize=18)
plt.ylabel("Clock pulse", fontsize=18)
plt.title("Clock syncrhonization test", fontsize=18)
plt.legend(fontsize=14)
plt.grid(True)
plt.tight_layout()
plt.savefig("./ntp_sync_test.png", dpi=300)
plt.show()
