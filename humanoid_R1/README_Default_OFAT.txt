PERBANDINGAN DEFAULT vs OFAT - PROJECT D:/webots/humanoid_R1

Buka worlds/Pororo_compare_default_ofat.wbt, jalankan simulasi,
lalu klik area 3D Webots.
SPACE = kedua robot kembali standby dan rekaman CSV ditutup.
L = kedua robot memulai line follower dan membuka rekaman baru.
Default: 500 ms, lateral 18 mm, foot lift 40 mm, DSR 10%, arm gain 1.5.
OFAT lama: 600 ms, lateral 30 mm, foot lift 45 mm, DSR 16%, arm gain 2.0.
Program: controllers/gait_default/gait_default.cpp dan
controllers/gait_ofat/gait_ofat.cpp. Executable sudah tersedia.
Kedua controller perlu gait_profile.hpp serta Framework/managers/vision
dan file pendukung di foldernya; jangan hanya menyalin cpp sendiri.

CSV disimpan otomatis di folder controller masing-masing:
controllers/gait_default/webots_DEFAULT_<tanggal>_<jam>_run001.csv
controllers/gait_ofat/webots_OFAT_<tanggal>_<jam>_run001.csv
File .csv.profile.txt mencatat parameter dan waktu mulai.
Kolom sama dengan logger sebelumnya: Timestamp_ms, foot proxy, CoM roll/
pitch IMU, GPS speed/displacement, flag accelerometer dan joint pitch.
Flag FALL DETECTED bukan verifikasi fisik robot jatuh.
Port command terpisah: Default 12011, OFAT 12012; telemetry 12351/12352.
SET_* diabaikan agar parameter perbandingan tetap terkunci.

World Pororo.wbt asli tidak diubah. World perbandingan memakai robot dan
lintasan dari world project ini, diduplikasi dengan offset y 4 m.
Asset mesh memakai path absolut ke asset yang ditemukan di komputer ini.
World smoke test dan controller comparison_smoke_test adalah alat verifikasi;
pakai world Pororo_compare_default_ofat.wbt untuk eksperimen sebenarnya.
CSV pada test_run_raw adalah uji fungsi, bukan data pengganti hasil paper.
Kedua robot diuji runtime 18 s dengan perintah UDP ke dua port. Penerimaan
UDP dapat berselisih satu timestep; normalkan waktu tiap CSV terhadap sampel
pertama untuk analisis. Keyboard fisik tidak diotomasi.
