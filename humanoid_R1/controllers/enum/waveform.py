import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter

# Konfigurasi
fs = 1000
duration = 2
t = np.linspace(0, duration, fs)
frequency = 1
amplitude = 1
phase_speed = 0.1

# Setup plot
fig, ax = plt.subplots()
line, = ax.plot([], [], lw=2)
ax.set_xlim(t[0], t[-1])
ax.set_ylim(-1.5, 1.5)
ax.set_title("Animated Sinusoidal Waveform")
ax.set_xlabel("Time [s]")
ax.set_ylabel("Amplitude")

def init():
    line.set_data([], [])
    return line,

def update(frame):
    phase = frame * phase_speed
    y = amplitude * np.sin(2 * np.pi * frequency * t + phase)
    line.set_data(t, y)
    return line,

# Animasi
ani = FuncAnimation(fig, update, frames=100, init_func=init, interval=50, blit=True)

# Simpan ke GIF
ani.save("animated_sine_wave.gif", writer=PillowWriter(fps=20))
