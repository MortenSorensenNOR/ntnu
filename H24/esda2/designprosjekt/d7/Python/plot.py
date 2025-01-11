import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import FixedLocator

fsamp  = 9100
fshalf = fsamp/2
fsmin  = fshalf*0.75
startf = 50  # frekvensen du begynnte målingen på

file = "../Data/working.csv"
fullFilter = pd.read_csv(file, sep=',', skiprows=25, encoding='ISO-8859-1')
f  = np.array(fullFilter.iloc[:,0])
c1 = np.array(fullFilter.iloc[:,1])
c2 = np.array(fullFilter.iloc[:,2])

passX = [startf, fsmin, fsmin, startf]
passY = [-3, -3, 3, 3]

stopX = [fshalf, f[-1], f[-1], fshalf]
stopY = [-100, -100, -10, -10]

file2 = "../Data/working_longer.csv"
fullFilter2 = pd.read_csv(file2, sep=',', skiprows=25, encoding='ISO-8859-1')
f2  = np.array(fullFilter2.iloc[:,0])
c1_2 = np.array(fullFilter2.iloc[:,1])
c2_2 = np.array(fullFilter2.iloc[:,2])

passX_2 = [startf, fsmin, fsmin, startf]
passY_2 = [-3, -3, 3, 3]

stopX_2 = [fshalf, f[-1], f[-1], fshalf]
stopY_2 = [-100, -100, -10, -10]


plt.figure(figsize=(12, 8))  # Øker størrelsen på hele plottet
plt.subplots_adjust(hspace=0.5)  # Øker vertikal avstand mellom subplottene

"""  --- plot whole filter  ---  """
plt.subplot(2, 1, 1)
plt.xscale("log")
plt.fill(passX_2, passY_2, color='skyblue')  
plt.fill(stopX_2, stopY_2, color='skyblue')  
plt.plot([fsmin * 0.75, fsamp, fsamp, fsmin * 0.75, fsmin * 0.75], [3, 3, -20, -20, 3], color="red", linestyle="dashed", alpha=0.4)
plt.plot(f2, c1_2, label="$v_1(f)$")
plt.plot(f2, c2_2, label="$v_2(f)$")
plt.title("Amplituderespons", fontsize=14)  # Større font på tittelen
plt.ylim(-40, 5)  # Begrens y-aksen til 0 til -50
plt.xlim(f2[0] * 0.9, f2[-1] * 1.1)
plt.legend(loc="lower left")
plt.xlabel("Frekvens (Hz)")
plt.ylabel("Dempning (dBV)")

"""  --- plot whole filter zoomed in  ---  """
plt.subplot(2, 1, 2)
plt.xscale("log")
plt.fill(passX, passY, color='skyblue')  
plt.fill(stopX, stopY, color='skyblue')  
plt.plot([fsmin * 0.75, fsamp * 1.25], [-3, -3], color="black", linestyle="dashed", alpha=0.4)
plt.plot([fsmin * 0.75, fsamp * 1.25], [-10, -10], color="black", linestyle="dashed", alpha=0.4)
plt.plot([fsamp, fsamp], [-20, 3], color="black", linestyle="dashed", alpha=0.4)
plt.plot([fshalf, fshalf], [-20, 3], color="black", linestyle="dashed", alpha=0.4)
plt.plot([fsmin, fsmin], [-20, 3], color="black", linestyle="dashed", alpha=0.4)
plt.plot(f, c1, label="$v_1(f)$")
plt.plot(f, c2, label="$v_2(f)$")
plt.xlim(fsmin * 0.75, fsamp * 1.25)
plt.ylim(-20, 3)
plt.yticks([-3, -10], ["-3", "-10"])
plt.xticks([fsamp, fshalf, fsmin], ["$f_s$", "$f_s/2$", "$0.75 \cdot f_s/2$"])
plt.gca().xaxis.set_major_locator(FixedLocator([fsamp, fshalf, fsmin]))
plt.gca().xaxis.set_minor_locator(FixedLocator([]))
plt.title("Amplituderespons forstørret", fontsize=14)  # Større font på tittelen
plt.legend(loc="lower left")
plt.xlabel("Frekvens (Hz)")
plt.ylabel("Dempning (dBV)")

plt.tight_layout()  # Fjern ekstra hvit plass rundt figuren
# plt.show()
plt.savefig("filter_freq_plot.png", dpi=300)
