REVISI PAPER v5 - DSR 0%, LATERAL SWING 17 mm

Konfigurasi dikonfirmasi pengguna: periode 600 ms, lateral 17 mm,
foot lift 45 mm, DSR 0%, arm swing gain 2.0; lintasan oval; tidak ada
jatuh yang teramati. Sumber: Dsrbaru_lateralbaru.csv, tidak diubah.

JENDELA EVALUASI
Semua hasil baru memakai t=(Timestamp_ms-Timestamp_ms(1))/1000 dan t<=11.
Default dan revisi masing-masing 344 sampel, interval 32 ms, t terakhir
10.976 s. Tidak ada pemotongan spike, penghapusan Fall_Status, smoothing
roll/pitch, atau interpolasi. Speed saja memakai movmean 50 sampel untuk
tampilan sesuai lingkar.m (pada 32 ms setara 1.6 s); mean speed memakai raw.
Kanal CoM Roll/Pitch mengikuti penamaan paper dan menyimpan sudut IMU.
Flag accelerometer bukan bukti jatuh. Observasi tidak jatuh dari pengguna.

HASIL PERBANDINGAN 11 DETIK
                         Default       Revisi
Roll RMSE (rad)          0.134349735   0.132613918
Pitch RMSE (rad)         0.189428735   0.190721034
Roll S/N (dB)           17.435263729  17.548217881
Pitch S/N (dB)          14.451082828  14.392028153
Mean raw speed (m/s)     0.168950385   0.167043682
Roll RMSE turun 1.292%; pitch RMSE naik 0.682%.
Delta S/N: roll +0.112954 dB; pitch -0.059055 dB.
Persentase/SN dihitung dari angka presisi penuh, bukan angka tabel dibulatkan.
S/N = -20*log10(RMSE), re-ekspresi hasil n=1, bukan uji signifikansi.

PERUBAHAN NASKAH LANGSUNG
D:/Paper_IEEE Access_fmz VoBiRo v5/access.tex
- Tabel 5: hitung ulang awal lateral memakai t<=11; tambah baris 17 mm*
  dari joint trial oval (DSR juga 0%). Rekaman awal 10 mm hanya 9.312 s;
  tidak dipanjangkan secara artifisial dan keterbatasan tercantum di tabel.
- Tabel 7: hitung ulang awal DSR t<=11; tambah baris 0%* dari joint trial
  yang sama (lateral juga 17 mm). Kedua tabel bukan dua percobaan independen.
- Tabel 9: parameter akhir 17 mm/0%, yang lain tetap 600 ms/45 mm/2.0.
- Tabel 10: RMSE oval Default vs revisi.
- Tabel 11: S/N dan delta dari hasil revisi presisi penuh.
- Figure 19: perbandingan roll/pitch dari data baru, Default sama.
- Grafik awal lateral/DSR dihitung ulang agar sesuai jendela tabel.
- Abstract, metode, IV.B/C/D, dan Conclusion diselaraskan dengan hasil
  yang campuran, tidak mempertahankan klaim lama 12.4%/9.6% atau +1.14/+0.87 dB.
- IV.E h10 tetap hasil lama 30 mm/16%, dibedakan dari revisi oval 17 mm/0%.
  Tidak ada data h10 baru, sehingga tidak dilabeli ulang sebagai konfigurasi revisi.
  IV.E tetap tiga paragraf; tidak ada Tabel XIII baru.

GRAFIK MATLAB
Folder: D:/template elsevier_rev_fahmi/Processing/Versi2/GuiVobiro2/data/Revisi_DSR0_Lateral17
Jalankan GenerateRevisiDSR0Lateral17 lalu ExportInitialOFATPanels.
PNG 300 dpi, PDF vektor, FIG editable; white background, MATLAB palette,
judul 12 pt, label/tick 10 pt, legend 9 pt, LineWidth 1.5, GridAlpha 0.3.
Compare_roll/pitch dipakai Figure 19; Initial_Lateral/DSR dipakai grafik
awal paper. Supplement_Lateral/DSR memakai empat initial curves dan
joint oval curve putus-putus hijau: konteks berbeda, bukan bukti OFAT terisolasi.
Revised_roll/pitch menunjukkan trial baru sendiri dalam biru.

VERIFIKASI
MATLAB dihitung ulang dan dibandingkan dengan Python; hasil cocok <1e-12.
Hash sumber dan data asli dipertahankan. Backup seluruh v5 sebelum revisi
tersedia di outputs/ofat_revision/original_v5_backup pada workspace chat.
