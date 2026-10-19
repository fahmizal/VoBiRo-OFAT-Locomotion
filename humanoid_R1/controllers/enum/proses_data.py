import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

RAW = "com_log.csv"                         # nama file asli yang kamu kirim
OUT = "com_log_pretuning_10s_min45.csv"     # hasil yang kita inginkan
PLOT_Z = "pretuning_comz_min45.png"         # plot verifikasi (opsional)
PLOT_3D = "pretuning_traj3d_min45.png"      # plot 3D (opsional)

def norm(s):
    return "".join(ch for ch in str(s).lower().strip() if ch.isalnum())

# 1) Load CSV (otomatis coba delimiter umum)
try:
    df = pd.read_csv(RAW)
except Exception:
    with open(RAW, "r", encoding="utf-8", errors="ignore") as f:
        sample = f.read(4096)
    if sample.count(";") > sample.count(",") and sample.count(";") >= sample.count("\t"):
        sep = ";"
    elif sample.count("\t") > sample.count(","):
        sep = "\t"
    else:
        sep = ","
    df = pd.read_csv(RAW, sep=sep)

# 2) Deteksi kolom Time, CoMX, CoMY, CoMZ
colmap = {c: norm(c) for c in df.columns}

def find_col(cands):
    for orig, n in colmap.items():
        for cand in cands:
            if n == cand or cand in n:
                return orig
    return None

time_col = find_col(["time", "t", "timestamp", "sec", "seconds"]) or df.columns[0]
comx_col = find_col(["comx", "centerofmassx", "cmx", "cogx"])
comy_col = find_col(["comy", "centerofmassy", "cmy", "cogy"])
comz_col = find_col(["comz", "centerofmassz", "cmz", "cogz", "comheight", "height", "z"])

print("Detected columns:")
print("  Time:", time_col)
print("  CoMX:", comx_col)
print("  CoMY:", comy_col)
print("  CoMZ:", comz_col)

# 3) Konversi ke numeric & sort waktu
for c in [time_col, comx_col, comy_col, comz_col]:
    if c is not None and c in df.columns:
        df[c] = pd.to_numeric(df[c], errors="coerce")

df = df.dropna(subset=[time_col]).sort_values(time_col).reset_index(drop=True)

# 4) Heuristik: kalau sepertinya ms, ubah ke detik
t_span = df[time_col].iloc[-1] - df[time_col].iloc[0]
if t_span > 10000 and (df[time_col].diff().median() or 0) < 1.0:
    df[time_col] = df[time_col] / 1000.0

# 5) Pilih jendela 10 detik dengan range CoMZ terbesar
duration = 10.0
if comz_col is None or df[time_col].iloc[-1] - df[time_col].iloc[0] <= duration:
    sidx, eidx = 0, len(df) - 1
else:
    best_rng = -np.inf
    sidx, eidx = 0, min(1, len(df) - 1)
    for i in range(len(df)):
        t0 = df.loc[i, time_col]
        m = (df[time_col] >= t0) & (df[time_col] <= t0 + duration)
        if m.sum() < 3:
            continue
        vals = df.loc[m, comz_col].dropna()
        if vals.empty:
            continue
        rng = float(vals.max() - vals.min())
        if rng > best_rng:
            best_rng = rng
            idxs = df.index[m]
            sidx, eidx = idxs.min(), idxs.max()

print(f"Window index range: {sidx} -> {eidx}")
sub = df.iloc[sidx:eidx+1].copy()

# 6) Reset waktu ke 0
sub[time_col] = sub[time_col] - sub[time_col].iloc[0]

# 7) Shift CoMZ supaya minimum = 45
if comz_col is None:
    raise RuntimeError("Kolom CoMZ tidak ditemukan di CSV.")

zmin = sub[comz_col].min(skipna=True)
k = 45.0 - float(zmin)        # konstanta yang ditambah ke seluruh CoMZ
sub[comz_col + "_min45"] = sub[comz_col] + k

print("Original min CoMZ in window:", zmin)
print("Added constant k:", k)
print("New min CoMZ:", sub[comz_col + "_min45"].min())

# 8) Simpan CSV hasil
sub.to_csv(OUT, index=False)
print("Saved processed CSV to:", OUT)

# 9) Plot CoMZ vs time (opsional)
plt.figure()
plt.plot(sub[time_col].values, sub[comz_col + "_min45"].values)
plt.xlabel("Time (s)")
plt.ylabel(f"{comz_col} (min=45)")
plt.title("Pre-tuning CoMZ (min=45) — best 10 s")
plt.tight_layout()
plt.savefig(PLOT_Z)
print("Saved plot:", PLOT_Z)

# 10) Plot lintasan 3D (kalau X dan Y tersedia)
if comx_col and comy_col and comx_col in sub.columns and comy_col in sub.columns:
    from mpl_toolkits.mplot3d import Axes3D  # noqa
    fig = plt.figure()
    ax = fig.add_subplot(111, projection="3d")
    ax.plot3D(sub[comx_col].values,
              sub[comy_col].values,
              sub[comz_col + "_min45"].values)
    ax.set_xlabel("CoMX")
    ax.set_ylabel("CoMY")
    ax.set_zlabel("CoMZ (min=45)")
    ax.set_title("3D CoM Trajectory (Pre-tuning, min=45)")
    plt.tight_layout()
    plt.savefig(PLOT_3D)
    print("Saved 3D plot:", PLOT_3D)
