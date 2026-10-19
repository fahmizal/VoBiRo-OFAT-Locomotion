# Perbandingan seluruh rekaman 15 Oktober 2026, 00:22:56

Paper tidak diubah. Semua 3494 sampel per gait dipakai, dari 0 sampai 111.776 detik; interval sampel 32 ms. Grafik dibuat dengan MATLAB R2025a.

| Metrik | Default | OFAT |
|---|---:|---:|
| Durasi (s) | 111.776 | 111.776 |
| Kecepatan rata-rata (m/s) | 0.176723 | 0.193194 |
| Simpangan baku kecepatan (m/s) | 0.063479 | 0.081607 |
| Kecepatan maksimum (m/s) | 0.345890 | 0.512202 |
| RMSE roll terhadap nol (rad) | 0.087521 | 0.107928 |
| RMSE pitch terhadap nol (rad) | 0.133643 | 0.121542 |

OFAT lebih cepat 9.32%, RMSE roll lebih besar 23.32%, dan RMSE pitch lebih kecil 9.05% dibanding Default pada pasangan rekaman ini.

Kecepatan menggunakan kolom Speed_m_s pada CSV. Tabel dihitung dari data asli; grafik kecepatan memakai moving average 50 sampel (1.6 s). Simpangan baku menggambarkan variasi antar-sampel waktu, bukan antar-pengulangan. Semua sampel, termasuk transien, tetap disertakan.

Roll/pitch adalah sudut IMU. Label CoM dipertahankan mengikuti gaya grafik sebelumnya, bukan pengukuran langsung posisi pusat massa. Flag ambang pada CSV bukan bukti robot jatuh; tidak digunakan untuk membuang baris.

Konfigurasi mengikuti profil saat perekaman: Default 500 ms / lateral 18 mm / foot lift 40 mm / DSR 10% / arm gain 1.5; OFAT 600 ms / lateral 30 mm / foot lift 45 mm / DSR 16% / arm gain 2.0.

Jalankan ProcessDefaultOFAT di MATLAB dari folder ini untuk membuat ulang grafik PNG/FIG dan tabel CSV di figures. independent_audit.json menyimpan perhitungan independen dan hash CSV sumber. Nama Table10/Table11 pada keluaran lokal tidak berarti paper telah diedit.
