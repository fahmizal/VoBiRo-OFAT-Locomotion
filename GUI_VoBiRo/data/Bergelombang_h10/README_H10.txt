ANALISIS MATLAB - TERRAIN h10

REVISI TAMPILAN PAPER
Highlight kuning per kata dan kotak hyperlink telah dihilangkan dari paper.
Grafik utama h10 sekarang roll/pitch berdampingan dalam satu kolom,
lebar di paper 3.5 inci (satu kolom), mengikuti contoh grafik pengguna.
Canvas MATLAB 7 x 2.7 inci diperkecil ke 50% di paper; panel lebih mendatar,
garis 1.2 pt pada canvas, tulisan tick/label 9 pt, judul 9 pt,
legenda 6.5 pt di kanan atas, grid tipis terang, penanda panel 16 pt.
Grafik menampilkan 11 s pertama; statistik dalam narasi tetap memakai semua
108.296 s. Grafik lengkap tetap tersedia sebagai keluaran pelengkap.
GenerateGrafikH10Compact.m membuat versi kecil secara terpisah:
  GenerateGrafikH10Compact
GenerateGrafikBergelombangH10 juga memanggil fungsi compact ini.

h10 = tinggi puncak terhadap lembah 10 mm (1 cm), amplitudo sinus 5 mm.
Konfigurasi dikonfirmasi pengguna: OFAT-Optimized, periode 600 ms,
lateral swing 30 mm, foot lift 45 mm, DSR 16%, arm swing gain 2.0.

JALANKAN DI MATLAB
Masuk ke folder yang memuat GenerateGrafikBergelombangH10.m dan CSV:
  GenerateGrafikBergelombangH10
Atau:
  GenerateGrafikBergelombangH10('D:/ROBOT HUMANOID/Simulasi/humanoid_R1/controllers/pengujian/DataBergelombang.csv','figures')

Grafik telah dibuat dengan MATLAB R2025a, bukan renderer pengganti.
Fungsi menyimpan enam grafik dalam PNG 300 dpi, PDF vector, dan FIG editable:
H10_Speed, H10_Attitude, H10_Displacement, H10_FootProxy, H10_Joints,
dan H10_Responses (gabungan tiga panel sebagai pelengkap).
H10_Attitude_Compact adalah preview gabungan dua panel kecil.
Paper kini memakai H10_Roll_Panel.pdf dan H10_Pitch_Panel.pdf secara
terpisah dalam dua subfigure LaTeX; (a)/(b) dibuat oleh subcaption,
seperti grafik asli paper. H10_Attitude_Compact tetap tersedia sebagai preview.
Untuk membuka figure editable:
  openfig('figures/H10_Responses.fig','visible')

GAYA GRAFIK
Mengikuti skrip Arm Swing yang ditempel pengguna: palet RGB MATLAB
biru [0 .4470 .7410], oranye [.8500 .3250 .0980],
kuning [.9290 .6940 .1250], ungu [.4940 .1840 .5560].
h10 memakai biru [0 .4470 .7410] sesuai pilihan eksplisit pengguna.
Kedua panel memiliki judul dan penanda (a)/(b) yang dirujuk pada caption.
Proxy kaki/joint kiri dan kanan memakai biru/oranye dari palet yang sama.
Font mengikuti default MATLAB seperti skrip acuan, latar putih,
teks/axis hitam, GridAlpha 0.3, legenda best berlatar putih.
Grafik pelengkap: tick/label 10 pt, title 12 pt bold, legend 9 pt;
garis attitude 1.5 pt dan speed moving mean 2.5 pt.
Grafik compact memakai ukuran dan penskalaan yang dicatat di atas.
Data dan definisi metrik dipertahankan; speed tetap profil raw/moving mean,
bukan diubah menjadi garis mean konstan seperti eksperimen Arm Swing.
Speed: raw abu-abu dan moving mean 50 sampel (~0.4 s). Statistik tetap
dihitung dari raw. Roll/pitch tidak dismoothing. Tidak ada penghapusan baris.
Grafik proxy kaki/joint memakai jendela tengah rekaman 52-56 s,
dipilih secara deterministik dari durasi rekaman, bukan berdasarkan hasil.

HASIL UTAMA SELURUH REKAMAN
13538 sampel; durasi 108.296 s; interval median 8 ms.
Mean speed = 0.1755553 m/s; max instantaneous speed = 0.626542 m/s.
Speed sample standard deviation = 0.0850030 m/s.
Body roll RMS = 0.1699004 rad; body pitch RMS = 0.1345441 rad.
Mean roll = -0.0126088 rad; mean pitch = -0.1117969 rad.
Roll sample standard deviation = 0.1694381 rad; pitch = 0.0748597 rad.
Final displacement from start = 3.26621 m; maximum displacement = 3.33733 m.
Metrik tambahan untuk 11 s pertama ada di figures/h10_metrics.csv.
Nilai tersebut bukan perbandingan terrain-vs-flat yang matched.

INTERPRETASI DATA
Pengguna mengonfirmasi tidak ada robot jatuh. CSV memiliki 746 baris
berlabel FALL DETECTED! (5.5104% sampel). Dari pengujian.cpp, label ini
berasal dari threshold accelerometer sesaat dan bukan verifikasi toppling.
Label asli tidak diubah dan tidak dipakai untuk menghapus sampel maupun
menandai kejadian jatuh pada grafik. Jumlah fall yang teramati = 0 adalah
informasi observasi pengguna, bukan jumlah yang dihitung dari kolom ini.

CoM_Y_Roll dan CoM_Z_Pitch sebenarnya menyimpan filtered_imu_roll/pitch
dalam radian. Grafik memberi label body attitude, bukan posisi CoM/ZMP.
RMS terhadap nol termasuk bias postur; bukan simpangan baku osilasi saja.

Distance_m = sqrt(dx^2+dy^2+dz^2) terhadap posisi GPS saat mulai logging.
Ini perpindahan garis lurus 3D, bukan total jarak tempuh ataupun panjang lap.
CSV tidak memiliki koordinat GPS x/y, sehingga jumlah lap dan error lateral
terhadap garis hitam tidak dapat ditentukan dari data ini.

Foot_Trajectory_Z_* = pemendekan kaki dari ekspresi kinematik, memakai
konstanta 9.5, 9.5, 2.5 dalam pengujian.cpp. Unit tidak ditulis eksplisit
pada CSV/code tersebut. Karena itu grafik mempertahankan logger units,
tanpa konversi atau menyatakannya sebagai clearance kaki terhadap terrain.
Joint pitch memakai radian; tanda kanan/kiri dipertahankan sesuai CSV.

PENEMPATAN PAPER
IV.E diringkas menjadi tiga paragraf: setup terrain, hasil utama,
dan observasi/interpretasi. Istilah CoM Roll/Pitch dan RMSE mengikuti
bagian sebelumnya, dengan satu kalimat bahwa kanal ini sudut orientasi IMU.
Tabel XIII (ringkasan h10) dihapus sesuai permintaan pengguna;
angka hasil tetap disampaikan pada narasi IV.E dan CSV metrik pelengkap.
Tambahan ditempatkan pada IV.E, sesudah IV.D Taguchi dan sebelum Conclusion.
Alur: tuning -> perbandingan flat oval -> re-ekspresi metrik -> eksperimen
terrain tambahan. Ini menghindari pemisahan pasangan IV.C dan IV.D yang
membahas dataset perbandingan yang sama.
IV_E_Undulating_Terrain_H10.tex dapat dipakai sebagai snippet editable.
Jika snippet dipasang manual, tambahkan \usepackage{placeins} di preamble;
tambahkan juga \usepackage{subcaption} jika belum ada.
\FloatBarrier memastikan grafik Results tampil sebelum Conclusion.
Paper lengkap yang direvisi tersedia dalam paket paper_h10.
Conclusion dan pernyataan keterbatasan kontak/terrain diselaraskan secara
terbatas dengan tambahan ini. Materi IV.A-D dipertahankan; highlight lama
dinonaktifkan tanpa menghapus teks revisinya.

BATAS HASIL
Satu rekaman h10, tanpa trial default h10 pembanding atau pengulangan.
Tidak ada klaim improvement persen terhadap flat, success rate populasi,
confidence interval, ZMP margin, atau formal stability guarantee.
Setelan kontak h10 yang dibuat pada chat ini: friction 1, bounce 0,
softCFM 1e-5, maxContactJoints 10, single ElevationGrid, timestep 8 ms.
Berbeda dari protokol default-contact paper; dibahas eksplisit pada IV.E.
Sumber data mentah disalin apa adanya. File sumber asli tidak ditimpa.

ACUAN PLOT PAPER TERBARU
Panel H10_Roll_Panel/H10_Pitch_Panel memakai figure terpisah 700 x 350
piksel, judul 12 pt bold, label/tick 10 pt, legenda 9 pt Location best,
LineWidth 1.5, GridAlpha 0.3, warna [0 .4470 .7410] seperti skrip acuan.
Judul dan label CoM mengikuti konvensi CSV/grafik asli; kanal ini tetap
didefinisikan sebagai estimasi attitude IMU pada narasi paper.
PNG/PDF/FIG panel tersebut adalah keluaran utama untuk naskah; preview
H10_Attitude_Compact merupakan komposit dengan tipografi tersendiri.
