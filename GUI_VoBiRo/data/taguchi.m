% =========================================================================
% HITUNG RMSE & TAGUCHI S/N RATIO (PERBANDINGAN DEFAULT VS OPTIMAL)
% =========================================================================
clc; clear; close all;

% 1. MASUKKAN NAMA FILE CSV ABANG DI SINI
file_default = 'def2.csv';  % <--- Ganti dengan nama file kondisi Default
file_optimal = 'opt.csv';  % <--- Ganti dengan nama file kondisi Optimal
window_size = 50; 

% Fungsi untuk menghitung RMSE dan S/N Ratio
function [rmse_spd, rmse_rl, rmse_pt, sn_spd, sn_rl, sn_pt] = hitung_metrik(filename, w_size)
    opts = detectImportOptions(filename);
    opts.VariableNamingRule = 'preserve';
    T = readtable(filename, opts);

    time_data = (T.Timestamp_ms / 1000.0) - (T.Timestamp_ms(1) / 1000.0);   
    idx_valid = time_data <= 11;

    raw_speed = T.Speed_m_s(idx_valid); 
    com_roll  = T.CoM_Y_Roll(idx_valid); 
    com_pitch = T.CoM_Z_Pitch(idx_valid);  

    raw_speed(isnan(raw_speed)) = 0; 
    avg_speed = mean(raw_speed);

    smoothed_speed = movmean(raw_speed, w_size);
    rmse_spd = sqrt(mean((smoothed_speed - avg_speed).^2));
    rmse_rl  = sqrt(mean((com_roll - 0).^2));
    rmse_pt  = sqrt(mean((com_pitch - 0).^2));

    sn_spd = -10 * log10(rmse_spd^2);
    sn_rl  = -10 * log10(rmse_rl^2);
    sn_pt  = -10 * log10(rmse_pt^2);
end

% 2. EKSEKUSI PERHITUNGAN
try
    [d_rmse_spd, d_rmse_rl, d_rmse_pt, d_sn_spd, d_sn_rl, d_sn_pt] = hitung_metrik(file_default, window_size);
    [o_rmse_spd, o_rmse_rl, o_rmse_pt, o_sn_spd, o_sn_rl, o_sn_pt] = hitung_metrik(file_optimal, window_size);
    
    % 3. TAMPILKAN HASIL KE COMMAND WINDOW
    disp('================================================================================');
    disp('       HASIL PERBANDINGAN STATISTIK TAGUCHI (DEFAULT VS OPTIMAL)                ');
    disp('================================================================================');
    disp('METRIK           |     KONDISI DEFAULT (BASELINE)   |      KONDISI OPTIMAL      ');
    disp('--------------------------------------------------------------------------------');
    fprintf('Walking Speed    | RMSE: %.4f  (S/N: %5.2f dB) | RMSE: %.4f  (S/N: %5.2f dB)\n', d_rmse_spd, d_sn_spd, o_rmse_spd, o_sn_spd);
    fprintf('CoM Roll (Y)     | RMSE: %.4f  (S/N: %5.2f dB) | RMSE: %.4f  (S/N: %5.2f dB)\n', d_rmse_rl, d_sn_rl, o_rmse_rl, o_sn_rl);
    fprintf('CoM Pitch (Z)    | RMSE: %.4f  (S/N: %5.2f dB) | RMSE: %.4f  (S/N: %5.2f dB)\n', d_rmse_pt, d_sn_pt, o_rmse_pt, o_sn_pt);
    disp('================================================================================');
    disp('Tinggal salin angka-angka di atas ke dalam tabel LaTeX Anda, Bang!');

catch ME
    disp(['ERROR: Pastikan nama file sudah benar dan file ada di folder yang sama. Detail: ' ME.message]);
end