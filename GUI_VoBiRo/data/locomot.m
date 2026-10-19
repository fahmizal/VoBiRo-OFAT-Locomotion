% =========================================================================
% SCRIPT MATLAB: 3D VIEW LOCOMOTION OF VOBIRO (NATURAL SMOOTHING)
% =========================================================================
clear; clc; close all;

set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');

disp('Memuat data_600.csv...');
try
    T = readtable('data_600.csv');
catch
    [filename, pathname] = uigetfile('*.csv', 'Pilih File data_600.csv');
    if isequal(filename, 0), disp('Dibatalkan'); return; end
    T = readtable(fullfile(pathname, filename));
end

time = (T.Timestamp_ms - T.Timestamp_ms(1)) / 1000;

% 1. PENGHALUSAN NATURAL (Window size diperkecil drastis ke 3)
% Agar efek mekanis (benturan kaki) tetap terlihat dan tidak terlalu "lembut"
smooth_val = 3; 
z_left  = smoothdata(T.Foot_Trajectory_Z_Left, 'movmean', smooth_val);
z_right = smoothdata(T.Foot_Trajectory_Z_Right, 'movmean', smooth_val);
roll    = smoothdata(T.CoM_Y_Roll, 'movmean', smooth_val);

% 2. POSISI KAKI (Kiri = Y positif, Kanan = Y negatif)
y_offset_foot = 3; 
y_left  =  y_offset_foot * ones(size(time));
y_right = -y_offset_foot * ones(size(time));

% 3. REKONSTRUKSI CoM YANG BENAR SECARA FISIKA
y_com = roll * 10; 

% Membersihkan offset data Pitch
pitch_clean = T.CoM_Z_Pitch - mean(T.CoM_Z_Pitch);
pitch_smooth = smoothdata(pitch_clean, 'movmean', smooth_val);

% Membalik arah ayunan (Invert Z-Axis) agar CoM naik saat kaki mengayun
z_com = 15 - (pitch_smooth * 15); 

% 4. PLOTTING 3D TRAJECTORY
fig3D = figure('Name', '3D Locomotion', 'Position', [150, 150, 850, 600], 'Color', 'w');
hold on; grid on; box on;

% Plot Garis
p_left  = plot3(time, y_left, z_left, 'g-', 'LineWidth', 2);
p_right = plot3(time, y_right, z_right, 'r-', 'LineWidth', 2);
p_com   = plot3(time, y_com, z_com, 'b-', 'LineWidth', 2);

% 5. PENGATURAN TAMPILAN
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'ZColor', 'k');
xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Lateral Sway / Offset', 'FontSize', 12, 'FontWeight', 'bold');
zlabel('Z Height / Trajectory', 'FontSize', 12, 'FontWeight', 'bold');
title('3D View Locomotion of VoBiRo (Period: 600 ms)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'k');

% Sudut pandang yang optimal
view(-50, 25); 

% Legenda
legend([p_com, p_right, p_left], ...
    {'CoM Trajectory', 'Foot Right Trajectory', 'Foot Left Trajectory'}, ...
    'Location', 'northeast', 'FontSize', 11, 'TextColor', 'k', 'Color', 'w', 'EdgeColor', 'k');

% Batasi waktu (Zoom 4 detik pertama)
xlim([2 6]); 

% Export otomatis
exportgraphics(fig3D, 'Graph_3D_Locomotion_Natural.png', 'Resolution', 300);
disp('--> Sukses! Gambar 3D dengan tekstur mekanis natural telah disimpan.');