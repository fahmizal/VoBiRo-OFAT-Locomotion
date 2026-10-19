import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

# Baca file CSV (ganti path jika diperlukan)
gyro_df = pd.read_csv("C:/Users/ricoa/OneDrive/Desktop/PROYEK AKHIR/humanoid_R1/controllers/enum/gyro_log.csv")

# Ambil data
time = gyro_df['Time']
gyrox = gyro_df['GyroX']
gyroy = gyro_df['GyroY']
gyroz = gyro_df['GyroZ']

# Setup figure
fig, ax = plt.subplots()
line_x, = ax.plot([], [], label='GyroX')
line_y, = ax.plot([], [], label='GyroY')
line_z, = ax.plot([], [], label='GyroZ')

ax.set_xlim(min(time), max(time))
ax.set_ylim(min(min(gyrox), min(gyroy), min(gyroz)) - 1,
            max(max(gyrox), max(gyroy), max(gyroz)) + 1)

ax.set_xlabel("Time")
ax.set_ylabel("Gyro Value")
ax.set_title("Gyroscope Animation")
ax.legend()

# Init
def init():
    line_x.set_data([], [])
    line_y.set_data([], [])
    line_z.set_data([], [])
    return line_x, line_y, line_z

# Update
def update(frame):
    line_x.set_data(time[:frame], gyrox[:frame])
    line_y.set_data(time[:frame], gyroy[:frame])
    line_z.set_data(time[:frame], gyroz[:frame])
    return line_x, line_y, line_z

# Animasi
ani = FuncAnimation(fig, update, frames=len(time), init_func=init, blit=True, interval=30)

# Simpan sebagai GIF
ani.save("gyro_animation.gif", writer='pillow', fps=20)

print("✅ Animasi berhasil disimpan sebagai 'gyro_animation.gif'")
