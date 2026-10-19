% =========================================================================
% ANALISIS WALKING SPEED & COM STABILITY DARI DATA CSV WEBOTS VOBIRO
% =========================================================================
clc; clear; close all;

%% 1. KONFIGURASI NAMA FILE CSV
% Ganti nama file ini sesuai dengan file CSV hasil record Webots Abang!
% Pastikan ke-8 file ini berada di satu folder yang sama dengan script .m ini.

% File Eksperimen 1: Pengaruh Gait / Period Time (4 File)
files_gait = {'gait_400ms.csv', 'gait_600ms.csv', 'gait_800ms.csv', 'gait_1000ms.csv'};
labels_gait = {'Period: 400 ms', 'Period: 600 ms', 'Period: 800 ms', 'Period: 1000 ms'};

% File Eksperimen 2: Pengaruh Step Amplitude (4 File)
files_amp = {'amp_10.csv', 'amp_20.csv', 'amp_30.csv', 'amp_40.csv'};
labels_amp = {'Amplitude: 10', 'Amplitude: 20', 'Amplitude: 30', 'Amplitude: 40'};

% Parameter Smoothing (Moving Average)
% Besarkan angkanya jika garis kecepatan (Speed) masih terlihat naik-turun (gergaji)
window_size = 50; 

%% 2. PROSES DAN PLOT DATA
% Memanggil fungsi plot untuk kedua skenario pengujian
[Tabel_RMSE_Gait] = processAndPlot(files_gait, labels_gait, window_size, 'Analisis Variasi Period (Gait)');
[Tabel_RMSE_Amp]  = processAndPlot(files_amp, labels_amp, window_size, 'Analisis Variasi Amplitudo');

%% 3. TAMPILKAN TABEL RMSE KE LAYAR (UI TABLE)
% Tabel Variasi Gait
fig_tab1 = figure('Name', 'RMSE - Variasi Gait/Period', 'Position', [100, 100, 500, 150]);
uit1 = uitable(fig_tab1, 'Data', table2cell(Tabel_RMSE_Gait), ...
    'ColumnName', Tabel_RMSE_Gait.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05, 0.05, 0.9, 0.9]);
uit1.ColumnWidth = {120, 100, 120, 120};

% Tabel Variasi Amplitudo
fig_tab2 = figure('Name', 'RMSE - Variasi Amplitudo', 'Position', [100, 300, 500, 150]);
uit2 = uitable(fig_tab2, 'Data', table2cell(Tabel_RMSE_Amp), ...
    'ColumnName', Tabel_RMSE_Amp.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05, 0.05, 0.9, 0.9]);
uit2.ColumnWidth = {120, 100, 120, 120};

disp('Proses Selesai. Grafik dan Tabel berhasil dibuat!');

%% ========================================================================
% FUNGSI UTAMA PEMROSESAN DATA
% ========================================================================
function [Tabel_RMSE] = processAndPlot(file_list, labels, window_size, fig_title)
    
    num_files = length(file_list);
    rmse_results = cell(num_files, 4);
    colors = lines(num_files); % Generate warna otomatis
    
    % Siapkan Figure Window
    figure('Name', fig_title, 'Position', [150, 150, 900, 800]);
    
    for i = 1:num_files
        % 1. Baca File CSV
        if ~isfile(file_list{i})
            warning(['File tidak ditemukan: ', file_list{i}, '. Pastikan nama file dan foldernya benar!']);
            continue; % Lewati jika file tidak ada
        end
        
        % Baca tabel dari CSV Webots
        T = readtable(file_list{i});
        
        % 2. Ekstrak Kolom Data (Sesuai dengan header dari C++ Webots)
        % Waktu dibagi 1000 agar dari milisecond (ms) menjadi second (s)
        time_data  = T.Timestamp_ms / 1000.0;   
        raw_speed  = T.Speed_m_s;  
        com_roll   = T.CoM_Y_Roll;   
        com_pitch  = T.CoM_Z_Pitch;  
        
        % 3. Smoothing Sinyal Kecepatan (Moving Average)
        smoothed_speed = movmean(raw_speed, window_size);
        
        % 4. Kalkulasi RMSE
        % RMSE Kecepatan (terhadap rata-rata kecepatan aktualnya)
        avg_speed  = mean(smoothed_speed);
        rmse_speed = sqrt(mean((smoothed_speed - avg_speed).^2));
        
        % RMSE CoM (terhadap keseimbangan ideal yaitu 0 Radian)
        rmse_roll  = sqrt(mean((com_roll - 0).^2));
        rmse_pitch = sqrt(mean((com_pitch - 0).^2));
        
        % Simpan hasil ke array
        rmse_results{i, 1} = labels{i};
        rmse_results{i, 2} = round(rmse_speed, 4);
        rmse_results{i, 3} = round(rmse_roll, 4);
        rmse_results{i, 4} = round(rmse_pitch, 4);
        
        % 5. PLOTTING
        % Plot Speed
        subplot(3,1,1); hold on; grid on;
        plot(time_data, smoothed_speed, 'LineWidth', 2, 'Color', colors(i,:));
        title('Smoothed Walking Speed Profile', 'FontSize', 12);
        xlabel('Time (s)'); ylabel('Speed (m/s)');
        
        % Plot CoM Roll
        subplot(3,1,2); hold on; grid on;
        plot(time_data, com_roll, 'LineWidth', 1.5, 'Color', colors(i,:));
        title('Center of Mass (CoM) Roll - Lateral Sway', 'FontSize', 12);
        xlabel('Time (s)'); ylabel('CoM Roll (rad)');
        
        % Plot CoM Pitch
        subplot(3,1,3); hold on; grid on;
        plot(time_data, com_pitch, 'LineWidth', 1.5, 'Color', colors(i,:));
        title('Center of Mass (CoM) Pitch - Sagittal Tilt', 'FontSize', 12);
        xlabel('Time (s)'); ylabel('CoM Pitch (rad)');
    end
    
    % Rapihkan Legend
    subplot(3,1,1); legend(labels, 'Location', 'best');
    subplot(3,1,2); legend(labels, 'Location', 'best');
    subplot(3,1,3); legend(labels, 'Location', 'best');
    
    % Buat format Table Output
    Tabel_RMSE = cell2table(rmse_results, ...
        'VariableNames', {'Kondisi', 'RMSE_Speed', 'RMSE_Roll', 'RMSE_Pitch'});
end