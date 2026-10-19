% =========================================================================
% SCRIPT MATLAB: KINEMATIC TRAJECTORY VERIFICATION (3 GAMBAR TERPISAH)
% =========================================================================
clear; clc; close all;

set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');

disp('Pilih file CSV TERBARU dari Webots...');
[filename, pathname] = uigetfile('*.csv', 'Pilih File CSV');
if isequal(filename, 0), disp('Dibatalkan'); return; end

T = readtable(fullfile(pathname, filename));
time = (T.Timestamp_ms - T.Timestamp_ms(1)) / 1000;

% Ambil data joint Kanan
hip_r   = rad2deg(smoothdata(T.Hip_Pitch_R, 'gaussian', 5));
knee_r  = rad2deg(smoothdata(T.Knee_Pitch_R, 'gaussian', 5));
ankle_r = rad2deg(smoothdata(T.Ankle_Pitch_R, 'gaussian', 5));

% Ambil data joint Kiri
hip_l   = rad2deg(smoothdata(T.Hip_Pitch_L, 'gaussian', 5));
knee_l  = rad2deg(smoothdata(T.Knee_Pitch_L, 'gaussian', 5));
ankle_l = rad2deg(smoothdata(T.Ankle_Pitch_L, 'gaussian', 5));

% =========================================================================
% 1. GRAFIK HIP ANGLE
% =========================================================================
fig1 = figure('Name', 'Hip Angle', 'Position', [100, 100, 600, 300], 'Color', 'w');
plot(time, hip_l, 'b-', 'LineWidth', 1.8); hold on;
plot(time, hip_r, 'r-', 'LineWidth', 1.8);
grid on; box on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 11, 'Color', 'k');
ylabel('Hip Angle (°)', 'FontSize', 11, 'Color', 'k');
title('Hip Joint Trajectory (Left vs Right)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlim([2 6]); % Zoom detik 2-6
legend({'Left Hip', 'Right Hip'}, 'Location', 'northeast', 'FontSize', 10, 'TextColor', 'k', 'Color', 'w');
exportgraphics(fig1, 'Graph_Hip_Angle.png', 'Resolution', 300);

% =========================================================================
% 2. GRAFIK KNEE ANGLE
% =========================================================================
fig2 = figure('Name', 'Knee Angle', 'Position', [150, 150, 600, 300], 'Color', 'w');
plot(time, knee_l, 'b-', 'LineWidth', 1.8); hold on;
plot(time, knee_r, 'r-', 'LineWidth', 1.8);
grid on; box on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 11, 'Color', 'k');
ylabel('Knee Angle (°)', 'FontSize', 11, 'Color', 'k');
title('Knee Joint Trajectory (Left vs Right)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlim([2 6]); 
legend({'Left Knee', 'Right Knee'}, 'Location', 'northeast', 'FontSize', 10, 'TextColor', 'k', 'Color', 'w');
exportgraphics(fig2, 'Graph_Knee_Angle.png', 'Resolution', 300);

% =========================================================================
% 3. GRAFIK ANKLE ANGLE
% =========================================================================
fig3 = figure('Name', 'Ankle Angle', 'Position', [200, 200, 600, 300], 'Color', 'w');
plot(time, ankle_l, 'b-', 'LineWidth', 1.8); hold on;
plot(time, ankle_r, 'r-', 'LineWidth', 1.8);
grid on; box on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 11, 'Color', 'k');
ylabel('Ankle Angle (°)', 'FontSize', 11, 'Color', 'k');
title('Ankle Joint Trajectory (Left vs Right)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlim([2 6]); 
legend({'Left Ankle', 'Right Ankle'}, 'Location', 'northeast', 'FontSize', 10, 'TextColor', 'k', 'Color', 'w');
exportgraphics(fig3, 'Graph_Ankle_Angle.png', 'Resolution', 300);

disp('--> Sukses! 3 File gambar telah disimpan terpisah (Graph_Hip, Graph_Knee, Graph_Ankle).');