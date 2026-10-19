% =========================================================================
% SCRIPT MATLAB: REAL-TIME TUNING VALIDATION (FOOT TRAJECTORY Z)
% =========================================================================
clear; clc; close all;

% 1. PENGATURAN FONT & GRAFIK STANDAR JURNAL
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');

disp('Pilih file CSV hasil rekaman Real-Time Tuning Anda...');
[filename, pathname] = uigetfile('*.csv', 'Pilih File CSV Real-Time Tuning');
if isequal(filename, 0), disp('Dibatalkan'); return; end

% 2. BACA DATA
T = readtable(fullfile(pathname, filename));

% Normalisasi waktu ke detik (dimulai dari 0)
time = (T.Timestamp_ms - T.Timestamp_ms(1)) / 1000;

% Penghalusan natural agar grafik tidak berbentuk anak tangga kasar
smooth_val = 3; 
z_left  = smoothdata(T.Foot_Trajectory_Z_Left, 'movmean', smooth_val);
z_right = smoothdata(T.Foot_Trajectory_Z_Right, 'movmean', smooth_val);

% 3. PLOTTING GRAFIK
fig = figure('Name', 'Real-Time Tuning Validation', 'Position', [100, 150, 900, 400], 'Color', 'w');
hold on; grid on; box on;

% Plot Kaki Kiri (Biru) dan Kanan (Merah)
p_left  = plot(time, z_left, 'b-', 'LineWidth', 1.8);
p_right = plot(time, z_right, 'r-', 'LineWidth', 1.8);

% 4. PENGATURAN AXES & LABEL
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Foot Trajectory Z (cm)', 'FontSize', 12, 'FontWeight', 'bold');
title('Real-Time Tuning Validation: Continuous Foot Trajectory Tracking', 'FontSize', 13, 'FontWeight', 'bold');

% Legenda
legend([p_left, p_right], {'Left Foot (Blue)', 'Right Foot (Red)'}, ...
    'FontSize', 10, 'Location', 'northeast', 'TextColor', 'k', 'Color', 'w');

% Atur limit X dari awal sampai akhir sesi
xlim([0 max(time)]);
% Beri sedikit ruang di atas gelombang tertinggi
ylim([0 max(max(z_left), max(z_right)) + 1]); 

% 5. EXPORT GAMBAR
exportgraphics(fig, 'Graph_RealTime_Tuning.png', 'Resolution', 300);
disp('--> Sukses! Gambar Real-Time Tuning telah disimpan.');