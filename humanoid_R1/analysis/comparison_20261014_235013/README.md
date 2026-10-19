# Perbandingan Default dan OFAT — rekaman 14 Oktober 2026, 23:50:13

Paper tidak diubah. Grafik dibuat dengan MATLAB R2025a melalui ProcessDefaultOFAT.m.

Analisis memakai 11 detik pertama sejak awal masing-masing CSV: 344 sampel, interval 0.032 s, sampel terakhir pada 10.976 s. Seluruh sampel dalam jendela dipakai, termasuk transien awal.

| Metrik | Default | OFAT |
|---|---:|---:|
| Kecepatan rata-rata (m/s) | 0.172484 | 0.195152 |
| Simpangan baku kecepatan (m/s) | 0.063448 | 0.082125 |
| Kecepatan maksimum (m/s) | 0.316731 | 0.520604 |
| RMSE roll terhadap nol (rad) | 0.080205 | 0.107443 |
| RMSE pitch terhadap nol (rad) | 0.129427 | 0.142415 |

OFAT memiliki kecepatan rata-rata 13.14% lebih tinggi. RMSE roll naik 33.96% dan RMSE pitch naik 10.04% dibanding Default. Ini hasil satu pasangan rekaman; simpangan baku menunjukkan variasi antar-sampel waktu, bukan variasi antar-pengulangan eksperimen.

Kecepatan memakai kolom speed GPS pada CSV. Kurva kecepatan memakai moving average 50 sampel (1.6 s); statistik tabel dihitung dari data asli tanpa smoothing. Roll/pitch adalah sudut IMU. Label CoM pada grafik dipertahankan mengikuti gaya grafik sebelumnya dan tidak berarti posisi pusat massa diukur langsung. Flag ambang pada CSV tidak dihitung sebagai kejadian jatuh.

Identitas gait mengikuti profile yang tersimpan bersama CSV. Nama node Robot di profile tertukar (DEFAULT bernama VoBiRo_OFAT, OFAT bernama VoBiRo_Default). Parameter yang tercatat:

| Parameter | Default | OFAT |
|---|---:|---:|
| Period (ms) | 500 | 600 |
| Lateral (mm) | 18 | 30 |
| Foot lift (mm) | 40 | 45 |
| DSR (%) | 10 | 16 |
| Arm gain | 1.5 | 2.0 |

File figures/Speed_Table_11s.csv memuat tabel kecepatan. File Table10_RMSE_11s.csv dan Table11_SN_11s.csv hanya merupakan keluaran analisis lokal; penamaannya tidak berarti tabel paper telah diganti. independent_audit.json memuat sumber, hash SHA-256, dan perhitungan independen.

Jalankan `ProcessDefaultOFAT` di MATLAB dari folder ini untuk membuat ulang grafik PNG, PDF, FIG dan tabel CSV di subfolder figures.
