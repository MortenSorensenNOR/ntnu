import numpy as np
import matplotlib.pyplot as plt

def v_c(t, tau, v0, v_inf):
    return v_inf + (v0 - v_inf)*np.exp(-t/tau)

c = "dodgerblue"
def plot_v_c(ax, tau, t_min, t_max, v0, v_inf):
    t = np.linspace(0, t_max-t_min, 100000)
    v_c_vals = v_c(t, tau, v0, v_inf)
    
    t += t_min
    ax.plot(t, v_c_vals, color=f"{c}")
    
    return v_c_vals[-1]

tau = 10e-6

t_switch = 1/30e3
t_max = t_switch * 4

V_max = 1

fig, ax = plt.subplots(1, 1)
ax.set_xlabel("Tid (s)")
ax.set_ylabel("Spenning (V)")
# ax.set_xticks(np.arange(0, t_max, 0.0005))
ax.set_yticks(np.arange(0, V_max + 0.1, 0.1))
ax.set_title("$v_C(t)$ ved $f = 5$kHz")
ax.legend()
ax.grid(linestyle='-', linewidth=1)

v0 = 0
for i in range(4):
    if i > 1:
        c = "darkorange"
    if i % 2 == 0:
        v0 = plot_v_c(ax, tau, i * t_switch, (i+1)*t_switch, v0, V_max)
    else:
        v0 = plot_v_c(ax, tau, i * t_switch, (i+1)*t_switch, v0, 0)

plt.savefig("tau.png", dpi=500)
# plt.show()
