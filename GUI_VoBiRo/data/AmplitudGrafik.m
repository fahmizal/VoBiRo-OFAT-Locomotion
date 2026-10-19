%% MATLAB Script: VoBiRo Amplitude Variations Analysis (Constant Period = 600 ms)
clear; clc; close all;

%% 1. GLOBAL INITIALIZATION & FONT CONFIGURATION
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultFigureColor', 'w');       
set(0, 'DefaultAxesXColor', 'k');         
set(0, 'DefaultAxesYColor', 'k');         

%% 2. IMPORT CSV DATA
fprintf('Loading amplitude experimental data...\n');
try
    data10 = readtable('data_amp_10.csv');
    data20 = readtable('data_amp_20.csv');
    data30 = readtable('data_amp_30.csv');
    data40 = readtable('data_amp_40.csv');
    fprintf('All datasets successfully loaded!\n\n');
catch ME
    error('Gagal membaca file. Pastikan nama file adalah data_amp_10.csv dst.');
end

%% 3. PRE-PROCESSING (Time Normalization)
t10 = (data10.Timestamp_ms - data10.Timestamp_ms(1)) / 1000;
t20 = (data20.Timestamp_ms - data20.Timestamp_ms(1)) / 1000;
t30 = (data30.Timestamp_ms - data30.Timestamp_ms(1)) / 1000;
t40 = (data40.Timestamp_ms - data40.Timestamp_ms(1)) / 1000;

colors = [0.00, 0.45, 0.74;  % Biru (Amp 10)
          0.85, 0.33, 0.10;  % Jingga (Amp 20)
          0.93, 0.69, 0.13;  % Kuning (Amp 30)
          0.49, 0.18, 0.56]; % Ungu (Amp 40)

%% ========================================================================
%% FIGURE 1: WALKING SPEED PROFILE OVER TIME (AMPLITUDE VARIATIONS)
%% ========================================================================
figure('Name', 'Amplitude Speed Profile', 'Position', [100, 100, 750, 450], 'Color', 'w');
hold on;

plot(t10, data10.Speed_m_s, 'LineWidth', 2, 'Color', colors(1,:));
plot(t20, data20.Speed_m_s, 'LineWidth', 2, 'Color', colors(2,:));
plot(t30, data30.Speed_m_s, 'LineWidth', 2, 'Color', colors(3,:));
plot(t40, data40.Speed_m_s, 'LineWidth', 2, 'Color', colors(4,:));

% --- MODIFIKASI DETEKSI JATUH (BERDASARKAN SPIKE NUMERIK) ---
perubahan_kecepatan = abs(diff(data40.Speed_m_s));
[max_spike, idx_fall_40] = max(perubahan_kecepatan);
idx_fall_40 = idx_fall_40 + 1; 

threshold_spike = 0.05; % Nilai batas minimal perubahan tajam kecepatan

if max_spike > threshold_spike
    % Plot marker lingkaran hitam di titik lonjakan jatuh
    plot(t40(idx_fall_40), data40.Speed_m_s(idx_fall_40), 'ko', 'MarkerSize', 10, 'LineWidth', 2, 'HandleVisibility', 'off');
    
    % Menampilkan teks di sebelah kiri koordinat jatuh agar rapi dan tidak keluar grafik
    text(t40(idx_fall_40) - 0.2, data40.Speed_m_s(idx_fall_40) + 0.05, 'Fall Detected (Amp: 40) \rightarrow', ...
        'Color', 'k', 'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'FontSize', 10);
end
% ------------------------------------------------------------

grid on; box on;
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 12, 'Color', 'k');
ylabel('Walking Speed (m/s)', 'FontSize', 12, 'Color', 'k');
title('Walking Speed Profile under Various Step Amplitudes (Period: 600 ms)', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');
ylim([-1, 1]);

legend({'Amplitude: 10', 'Amplitude: 20', 'Amplitude: 30', 'Amplitude: 40'}, ...
    'FontSize', 10, 'Location', 'best', 'TextColor', 'k', 'Color', 'w');