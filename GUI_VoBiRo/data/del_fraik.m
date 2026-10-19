% =========================================================================
% ANALISIS WALKING SPEED, COM STABILITY, & RMSE (VOBIRO)
% EKSPERIMEN 1 (PERIOD) & 2 (AMPLITUDE) - SEPARATED FIGURES
% =========================================================================
clc; clear; close all;

%% 1. KONFIGURASI NAMA FILE CSV
% Pastikan file-file ini berada di folder yang sama dengan script MATLAB
files_gait = {'data_400.csv', 'data_600.csv', 'data_800.csv', 'data_1000.csv'};
labels_gait = {'Period: 400 ms', 'Period: 600 ms', 'Period: 800 ms', 'Period: 1000 ms'};

files_amp = {'data_amp_10.csv', 'data_amp_20.csv', 'data_amp_30.csv', 'data_amp_40.csv'};
labels_amp = {'Amplitude: 10', 'Amplitude: 20', 'Amplitude: 30', 'Amplitude: 40'};

% Parameter Smoothing untuk RMSE (Error fluktuasi)
window_size = 50; 

%% 2. PROSES DAN PLOT DATA
disp('Memproses Data Eksperimen 1 (Period/Gait)...');
[Tabel_RMSE_Gait] = processAndPlot(files_gait, labels_gait, window_size, 'Period');

disp('Memproses Data Eksperimen 2 (Amplitude)...');
[Tabel_RMSE_Amp]  = processAndPlot(files_amp, labels_amp, window_size, 'Amplitude');

%% 3. TAMPILKAN TABEL RMSE KE LAYAR (UI TABLE)
fig_tab1 = figure('Name', 'Tabel RMSE - Variasi Period (Gait)', 'Position', [100, 100, 550, 150], 'Color', 'w');
uit1 = uitable(fig_tab1, 'Data', table2cell(Tabel_RMSE_Gait), ...
    'ColumnName', Tabel_RMSE_Gait.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05, 0.05, 0.9, 0.9], ...
    'BackgroundColor', [1 1 1]); 
uit1.ColumnWidth = {130, 110, 130, 130};

fig_tab2 = figure('Name', 'Tabel RMSE - Variasi Amplitudo', 'Position', [100, 320, 550, 150], 'Color', 'w');
uit2 = uitable(fig_tab2, 'Data', table2cell(Tabel_RMSE_Amp), ...
    'ColumnName', Tabel_RMSE_Amp.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05, 0.05, 0.9, 0.9], ...
    'BackgroundColor', [1 1 1]); 
uit2.ColumnWidth = {130, 110, 130, 130};

disp('====================================================');
disp('PROSES SELESAI. GRAFIK DAN TABEL BERHASIL DIBUAT!');
disp('====================================================');

%% ========================================================================
% FUNGSI UTAMA PEMROSESAN DATA & PLOTTING (SEPARATED FIGURES)
% ========================================================================
function [Tabel_RMSE] = processAndPlot(file_list, labels, window_size, exp_name)
    
    num_files = length(file_list);
    rmse_results = cell(num_files, 4);
    
    % Skema warna custom jurnal
    colors = [0, 0.4470, 0.7410;      % Blue
              0.8500, 0.3250, 0.0980; % Red
              0.9290, 0.6940, 0.1250; % Yellow
              0.4940, 0.1840, 0.5560];% Purple
    
    % Siapkan 3 Figure terpisah untuk masing-masing parameter
    fig_speed = figure('Name', ['Speed Analysis - ' exp_name], 'Position', [100, 100, 700, 350], 'Color', 'w');
    fig_roll  = figure('Name', ['Roll Analysis - ' exp_name], 'Position', [150, 150, 700, 350], 'Color', 'w');
    fig_pitch = figure('Name', ['Pitch Analysis - ' exp_name], 'Position', [200, 200, 700, 350], 'Color', 'w');
    
    for i = 1:num_files
        if ~isfile(file_list{i})
            warning(['File tidak ditemukan: ', file_list{i}, ' -> Dilewati.']);
            % Isi dengan nilai kosong agar tabel tidak error
            rmse_results{i, 1} = labels{i};
            rmse_results{i, 2} = NaN; rmse_results{i, 3} = NaN; rmse_results{i, 4} = NaN;
            continue; 
        end
        
        opts = detectImportOptions(file_list{i});
        opts.VariableNamingRule = 'preserve';
        T = readtable(file_list{i}, opts);
        
        try
            time_data  = T.Timestamp_ms / 1000.0;   
            
            % --- NORMALISASI WAKTU KE DETIK-0 ---
            time_data  = time_data - time_data(1); 
            
            % --- POTONG DATA SAMPAI DETIK 11 ---
            idx_valid  = time_data <= 11;
            time_data  = time_data(idx_valid);
            
            raw_speed  = T.Speed_m_s(idx_valid);  
            com_roll   = T.CoM_Y_Roll(idx_valid);   
            com_pitch  = T.CoM_Z_Pitch(idx_valid);  
        catch
            warning(['Header kolom di file ', file_list{i}, ' tidak sesuai.']);
            continue;
        end
        
        raw_speed(isnan(raw_speed)) = 0; % Proteksi nilai kosong
        
        % Hitung Rata-Rata Mutlak (Absolute Mean)
        avg_speed  = mean(raw_speed);
        
        % Bikin array agar garisnya lurus mendatar dari awal sampai akhir
        flat_speed_array = repmat(avg_speed, length(time_data), 1);
        
        % Kalkulasi RMSE
        smoothed_speed = movmean(raw_speed, window_size);
        rmse_speed = sqrt(mean((smoothed_speed - avg_speed).^2));
        rmse_roll  = sqrt(mean((com_roll - 0).^2));
        rmse_pitch = sqrt(mean((com_pitch - 0).^2));
        
        rmse_results{i, 1} = labels{i};
        rmse_results{i, 2} = round(rmse_speed, 4);
        rmse_results{i, 3} = round(rmse_roll, 4);
        rmse_results{i, 4} = round(rmse_pitch, 4);
        
        color_idx = mod(i-1, size(colors, 1)) + 1;
        
        % --- Plot 1: Kecepatan Rata-Rata ---
        figure(fig_speed); hold on; grid on;
        plot(time_data, flat_speed_array, 'LineWidth', 2.5, 'Color', colors(color_idx,:));
        
        % --- Plot 2: CoM Roll ---
        figure(fig_roll); hold on; grid on;
        plot(time_data, com_roll, 'LineWidth', 1.5, 'Color', colors(color_idx,:));
        
        % --- Plot 3: CoM Pitch ---
        figure(fig_pitch); hold on; grid on;
        plot(time_data, com_pitch, 'LineWidth', 1.5, 'Color', colors(color_idx,:));
    end
    
    % =====================================================================
    % KUSTOMISASI GRAFIK & PENAMBAHAN LEGENDA DI SETIAP FIGURE
    % =====================================================================
    
    % Kustomisasi Figure Speed
    figure(fig_speed);
    title('Average Walking Speed', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    xlabel('Time (s)', 'FontSize', 10, 'Color', 'k'); 
    ylabel('Speed (m/s)', 'FontSize', 10, 'Color', 'k');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridAlpha', 0.3, 'FontSize', 10);
    xlim([0 11]); 
    lgd1 = legend(labels, 'Location', 'best', 'FontSize', 9);
    set(lgd1, 'TextColor', 'k', 'Color', 'w');
    
    % Kustomisasi Figure Roll
    figure(fig_roll);
    title('Center of Mass (CoM) Roll - Lateral Sway', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    xlabel('Time (s)', 'FontSize', 10, 'Color', 'k'); 
    ylabel('CoM Roll (rad)', 'FontSize', 10, 'Color', 'k');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridAlpha', 0.3, 'FontSize', 10);
    xlim([0 11]);
    lgd2 = legend(labels, 'Location', 'best', 'FontSize', 9);
    set(lgd2, 'TextColor', 'k', 'Color', 'w');
    
    % Kustomisasi Figure Pitch
    figure(fig_pitch);
    title('Center of Mass (CoM) Pitch - Sagittal Tilt', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    xlabel('Time (s)', 'FontSize', 10, 'Color', 'k'); 
    ylabel('CoM Pitch (rad)', 'FontSize', 10, 'Color', 'k');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridAlpha', 0.3, 'FontSize', 10);
    xlim([0 11]); 
    lgd3 = legend(labels, 'Location', 'best', 'FontSize', 9);
    set(lgd3, 'TextColor', 'k', 'Color', 'w');
    
    % Buat format Table Output
    Tabel_RMSE = cell2table(rmse_results, ...
        'VariableNames', {'Kondisi', 'RMSE_Speed', 'RMSE_Roll_rad', 'RMSE_Pitch_rad'});
end