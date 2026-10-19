# Jalan bergelombang — rekaman mulai 00:41:41, disimpan 00:45:52, 15 Oktober 2026

Paper tidak diubah. Analisis mencakup seluruh rekaman: 5985 sampel per gait, durasi 47.872 s, interval 8 ms. Grafik dibuat dengan MATLAB R2025a.

| Metrik | Default | OFAT |
|---|---:|---:|
| Kecepatan GPS rata-rata (m/s) | 0.140012 | 0.153791 |
| Simpangan baku kecepatan (m/s) | 0.053681 | 0.072774 |
| Kecepatan maksimum (m/s) | 0.388368 | 0.602363 |
| RMSE roll terhadap nol (rad) | 0.113515 | 0.142638 |
| RMSE pitch terhadap nol (rad) | 0.134149 | 0.134953 |

OFAT memiliki rata-rata besar kecepatan GPS 9.84% lebih tinggi, RMSE roll 25.66% lebih besar, dan RMSE pitch 0.60% lebih besar. Besar kecepatan GPS tidak menentukan waktu menyelesaikan putaran karena juga mencakup gerak tubuh selain kemajuan sepanjang garis. Waktu putaran belum dihitung dari rekaman ini.

Tabel memakai data asli. Kurva kecepatan memakai moving average 50 sampel = 0.4 s pada interval 8 ms. Tidak ada baris yang dihapus. Simpangan baku adalah variasi antar-sampel, bukan antar-pengulangan. Roll/pitch adalah sudut IMU; label CoM mengikuti gaya grafik sebelumnya dan bukan pengukuran posisi pusat massa. Flag ambang tidak diperlakukan sebagai jumlah jatuh.

Profil saat perekaman: Default 500 ms, lateral 18 mm, foot lift 40 mm, DSR 10%, arm gain 1.5; OFAT 600 ms, lateral 30 mm, foot lift 45 mm, DSR 16%, arm gain 2.0. Keduanya basic time step 8 ms. Jangan membandingkan langsung hasil ini dengan lintasan datar sebelumnya yang memakai time step 32 ms tanpa mengendalikan perbedaan kondisi.

Jalankan ProcessDefaultOFAT di MATLAB untuk membuat ulang PNG/FIG dan tabel CSV di figures. independent_audit.json memuat sumber dan hash. Nama Table10/Table11 pada keluaran lokal tidak berarti paper telah diubah.
