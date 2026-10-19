import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, FFMpegWriter
from mpl_toolkits.mplot3d import Axes3D
import imageio

# Load CSV
df = pd.read_csv("C:/Users/ricoa/OneDrive/Desktop/PROYEK AKHIR/humanoid_R1/controllers/enum/com_log.csv")

# Ambil data
x = df['CoMY']
y = df['Time']
z = df['CoMZ']

# Setup figure
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
line, = ax.plot([], [], [], lw=2)

# Set label dan batas sumbu
ax.set_xlim(np.min(x), np.max(x))
ax.set_ylim(np.min(y), np.max(y))
ax.set_zlim(np.min(z), np.max(z))
ax.set_xlabel('CoMY')
ax.set_ylabel('Time')
ax.set_zlabel('CoMZ')
ax.set_title('3D Signal Animation')

# Inisialisasi animasi
def init():
    line.set_data([], [])
    line.set_3d_properties([])
    return line,

# Update animasi setiap frame
def update(frame):
    line.set_data(x[:frame], y[:frame])
    line.set_3d_properties(z[:frame])
    return line,

# Buat animasi
ani = FuncAnimation(fig, update, frames=len(df), init_func=init, blit=True, interval=30)

# Export ke .mp4
writer = FFMpegWriter(fps=30)
ani.save("com_animation.gif", writer="pillow", fps=20)

print("✅ Animation saved as com_animation.mp4")
