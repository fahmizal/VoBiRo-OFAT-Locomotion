# Data terbaru: 15 Oktober 2026, 00:02:07

Paper tidak diubah. Grafik dibuat dengan MATLAB R2025a.
Analisis memakai 11 detik pertama: 344 sampel per gait, interval 32 ms, waktu sampel terakhir 10.976 s. Tidak ada sampel di dalam jendela yang dihapus.

| Metrik | Default | OFAT |
|---|---:|---:|
| Kecepatan rata-rata (m/s) | 0.174585 | 0.186464 |
| Simpangan baku kecepatan (m/s) | 0.063943 | 0.075986 |
| Kecepatan maksimum (m/s) | 0.317611 | 0.428332 |
| RMSE roll terhadap nol (rad) | 0.084148 | 0.103083 |
| RMSE pitch terhadap nol (rad) | 0.132940 | 0.139292 |

OFAT lebih cepat 6.80%; RMSE roll lebih besar 22.50% dan pitch lebih besar 4.78% dibanding Default pada rekaman ini. Simpangan baku kecepatan merupakan variasi antar-sampel, bukan antar-pengulangan.

Kurva kecepatan memakai moving average 50 sampel (1.6 s), sedangkan tabel dihitung dari kecepatan GPS asli. Roll/pitch adalah sudut IMU; label CoM mengikuti grafik sebelumnya, bukan pengukuran langsung posisi CoM. Flag ambang tidak dianggap sebagai kejadian jatuh.

Identitas gait mengikuti profil saat perekaman. Nama node robot tertukar: file DEFAULT menyebut VoBiRo_OFAT dan file OFAT menyebut VoBiRo_Default. Parameter DEFAULT: periode 500 ms, lateral 18 mm, foot lift 40 mm, DSR 10%, arm gain 1.5. Parameter OFAT: periode 600 ms, lateral 30 mm, foot lift 45 mm, DSR 16%, arm gain 2.0.

Jalankan ProcessDefaultOFAT di MATLAB dari folder ini. Keluaran berada di figures. Nama Table10/Table11 hanya nama file analisis; tabel paper tidak diganti. independent_audit.json memuat perhitungan independen dan hash sumber.
