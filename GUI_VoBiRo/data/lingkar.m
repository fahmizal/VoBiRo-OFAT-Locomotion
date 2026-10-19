% =========================================================================
% HITUNG TAGUCHI & PLOT GRAFIK STYLE REFERENSI (OVAL TRACK)
% =========================================================================
clc; clear; close all;

% 1. KONFIGURASI FILE CSV (Ganti sesuai nama file Abang)
file_default = 'default full.csv'; 
file_optimal = 'optfull.csv'; 

window_size = 50; 

% Warna garis (Style MATLAB Default persis seperti gambar referensi)
color_def = [0, 0.4470, 0.7410];      % Biru
color_opt = [0.8500, 0.3250, 0.0980]; % Oranye

% 2. FUNGSI EKSTRAKSI DATA & HITUNG METRIK
function [t, spd, roll, pitch, rmse_spd, rmse_rl, rmse_pt, sn_spd, sn_rl, sn_pt] = processData(filename, w_size)
    opts = detectImportOptions(filename);
    opts.VariableNamingRule = 'preserve';
    T = readtable(filename, opts);
    
    time_raw = (T.Timestamp_ms / 1000.0) - (T.Timestamp_ms(1) / 1000.0);   
    idx_valid = time_raw <= 11; 
    t = time_raw(idx_valid);
    
    raw_spd = T.Speed_m_s(idx_valid); 
    raw_spd(isnan(raw_spd)) = 0; 
    avg_speed = mean(raw_spd);
    spd = movmean(raw_spd, w_size); 
    
    roll  = T.CoM_Y_Roll(idx_valid); 
    pitch = T.CoM_Z_Pitch(idx_valid);  
    
    % Perhitungan RMSE & S/N Ratio
    rmse_spd = sqrt(mean((spd - avg_speed).^2));
    rmse_rl  = sqrt(mean((roll - 0).^2));
    rmse_pt  = sqrt(mean((pitch - 0).^2));
    
    sn_spd = -10 * log10(rmse_spd^2);
    sn_rl  = -10 * log10(rmse_rl^2);
    sn_pt  = -10 * log10(rmse_pt^2);
end

% 3. EKSEKUSI & TAMPILKAN HASIL TAGUCHI
try
    [t_def, spd_def, roll_def, pitch_def, d_r_spd, d_r_rl, d_r_pt, d_s_spd, d_s_rl, d_s_pt] = processData(file_default, window_size);
    [t_opt, spd_opt, roll_opt, pitch_opt, o_r_spd, o_r_rl, o_r_pt, o_s_spd, o_s_rl, o_s_pt] = processData(file_optimal, window_size);
    
    disp('================================================================================');
    disp('       HASIL TAGUCHI S/N RATIO LINTASAN OVAL (DEFAULT VS OPTIMAL)               ');
    disp('================================================================================');
    fprintf('Walking Speed    | Def RMSE: %.4f (S/N: %5.2f dB) | Opt RMSE: %.4f (S/N: %5.2f dB)\n', d_r_spd, d_s_spd, o_r_spd, o_s_spd);
    fprintf('CoM Roll (Y)     | Def RMSE: %.4f (S/N: %5.2f dB) | Opt RMSE: %.4f (S/N: %5.2f dB)\n', d_r_rl, d_s_rl, o_r_rl, o_s_rl);
    fprintf('CoM Pitch (Z)    | Def RMSE: %.4f (S/N: %5.2f dB) | Opt RMSE: %.4f (S/N: %5.2f dB)\n', d_r_pt, d_s_pt, o_r_pt, o_s_pt);
    disp('================================================================================');
    
catch ME
    error('Gagal membaca file CSV. Pastikan nama file benar. Detail: %s', ME.message);
end

% 4. PLOTTING GRAFIK (MEMAKSA BACKGROUND PUTIH & TEKS HITAM)
% --- Plot 1: Speed ---
figure('Name', 'Compare: Speed', 'Position', [100, 100, 600, 350], 'Color', 'w');
hold on; grid on; box on;
plot(t_def, spd_def, 'Color', color_def, 'LineWidth', 1.5);
plot(t_opt, spd_opt, 'Color', color_opt, 'LineWidth', 1.5);
title('Average Walking Speed', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Time (s)', 'FontSize', 12, 'Color', 'k'); ylabel('Speed (m/s)', 'FontSize', 12, 'Color', 'k');
lgd1 = legend({'Baseline: Default', 'Baseline: OFAT'}, 'Location', 'northeast', 'FontSize', 10);
set(lgd1, 'TextColor', 'k', 'Color', 'w'); % Paksa legenda putih dengan teks hitam
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'FontSize', 11, 'GridAlpha', 0.4); 
xlim([0 11]);

% --- Plot 2: Roll ---
figure('Name', 'Compare: Roll', 'Position', [150, 150, 600, 350], 'Color', 'w');
hold on; grid on; box on;
plot(t_def, roll_def, 'Color', color_def, 'LineWidth', 1.5);
plot(t_opt, roll_opt, 'Color', color_opt, 'LineWidth', 1.5);
title('Center of Mass (CoM) Roll - Lateral Sway', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Time (s)', 'FontSize', 12, 'Color', 'k'); ylabel('CoM Roll (rad)', 'FontSize', 12, 'Color', 'k');
lgd2 = legend({'Baseline: Default', 'Baseline: OFAT'}, 'Location', 'northeast', 'FontSize', 10);
set(lgd2, 'TextColor', 'k', 'Color', 'w');
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'FontSize', 11, 'GridAlpha', 0.4); 
xlim([0 11]);

% --- Plot 3: Pitch ---
figure('Name', 'Compare: Pitch', 'Position', [200, 200, 600, 350], 'Color', 'w');
hold on; grid on; box on;
plot(t_def, pitch_def, 'Color', color_def, 'LineWidth', 1.5);
plot(t_opt, pitch_opt, 'Color', color_opt, 'LineWidth', 1.5);
title('Center of Mass (CoM) Pitch - Sagittal Tilt', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
xlabel('Time (s)', 'FontSize', 12, 'Color', 'k'); ylabel('CoM Pitch (rad)', 'FontSize', 12, 'Color', 'k');
lgd3 = legend({'Baseline: Default', 'Baseline: OFAT'}, 'Location', 'northeast', 'FontSize', 10);
set(lgd3, 'TextColor', 'k', 'Color', 'w');
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'FontSize', 11, 'GridAlpha', 0.4); 
xlim([0 11]);