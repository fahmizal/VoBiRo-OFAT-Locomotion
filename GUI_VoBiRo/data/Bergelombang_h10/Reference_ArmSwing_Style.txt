% =========================================================================
% ANALISIS WALKING SPEED & STABILITY - EKSPERIMEN ARM SWING
% =========================================================================
clc; clear; close all;

% 1. KONFIGURASI NAMA FILE CSV (4 File)
files_arm  = {'arm0.5.csv', 'arm1.csv', 'arm1.5.csv', 'arm2.csv'};
labels_arm = {'Arm Gain: 0.5', 'Arm Gain: 1.0', 'Arm Gain: 1.5', 'Arm Gain: 2.0'};
window_size = 50; 

% 2. PROSES DAN PLOT DATA
disp('Memproses Data Eksperimen Arm Swing...');
[Tabel_RMSE] = processAndPlot(files_arm, labels_arm, window_size, 'Arm Swing');

% 3. TAMPILKAN TABEL RMSE KE LAYAR
fig_tab = figure('Name', 'Tabel RMSE - Variasi Arm Swing', 'Position', [100, 100, 550, 150], 'Color', 'w');
uit = uitable(fig_tab, 'Data', table2cell(Tabel_RMSE), ...
    'ColumnName', Tabel_RMSE.Properties.VariableNames, ...
    'Units', 'Normalized', 'Position', [0.05, 0.05, 0.9, 0.9], 'BackgroundColor', [1 1 1]); 
uit.ColumnWidth = {130, 110, 130, 130};
disp('PROSES SELESAI!');

% ========================================================================
function [Tabel_RMSE] = processAndPlot(file_list, labels, window_size, fig_title)
    num_files = length(file_list);
    rmse_results = cell(num_files, 4);
    colors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560];
    
    % Siapkan 3 Figure terpisah
    fig_speed = figure('Name', ['Speed Analysis - ' fig_title], 'Position', [100, 100, 700, 350], 'Color', 'w');
    fig_roll  = figure('Name', ['Roll Analysis - ' fig_title], 'Position', [150, 150, 700, 350], 'Color', 'w');
    fig_pitch = figure('Name', ['Pitch Analysis - ' fig_title], 'Position', [200, 200, 700, 350], 'Color', 'w');
    
    for i = 1:num_files
        if ~isfile(file_list{i})
            warning(['File tidak ditemukan: ', file_list{i}]);
            rmse_results{i, 1} = labels{i}; rmse_results{i, 2} = NaN; rmse_results{i, 3} = NaN; rmse_results{i, 4} = NaN;
            continue; 
        end
        opts = detectImportOptions(file_list{i}); opts.VariableNamingRule = 'preserve';
        T = readtable(file_list{i}, opts);
        try
            time_data = (T.Timestamp_ms / 1000.0) - (T.Timestamp_ms(1) / 1000.0);   
            
            % --- POTONG DATA SAMPAI DETIK 11 ---
            idx_valid = time_data <= 11;
            time_data = time_data(idx_valid);
            raw_speed = T.Speed_m_s(idx_valid); 
            com_roll = T.CoM_Y_Roll(idx_valid); 
            com_pitch = T.CoM_Z_Pitch(idx_valid);  
        catch
            continue;
        end
        raw_speed(isnan(raw_speed)) = 0; 
        avg_speed = mean(raw_speed);
        flat_speed = repmat(avg_speed, length(time_data), 1);
        
        smoothed_speed = movmean(raw_speed, window_size);
        rmse_speed = sqrt(mean((smoothed_speed - avg_speed).^2));
        rmse_roll  = sqrt(mean((com_roll - 0).^2));
        rmse_pitch = sqrt(mean((com_pitch - 0).^2));
        
        rmse_results{i, 1} = labels{i}; rmse_results{i, 2} = round(rmse_speed, 4);
        rmse_results{i, 3} = round(rmse_roll, 4); rmse_results{i, 4} = round(rmse_pitch, 4);
        
        figure(fig_speed); hold on; grid on; plot(time_data, flat_speed, 'LineWidth', 2.5, 'Color', colors(i,:));
        figure(fig_roll); hold on; grid on; plot(time_data, com_roll, 'LineWidth', 1.5, 'Color', colors(i,:));
        figure(fig_pitch); hold on; grid on; plot(time_data, com_pitch, 'LineWidth', 1.5, 'Color', colors(i,:));
    end
    
    % Kustomisasi Figure Speed
    figure(fig_speed);
    title('Average Walking Speed', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    xlabel('Time (s)', 'FontSize', 10, 'Color', 'k'); ylabel('Speed (m/s)', 'FontSize', 10, 'Color', 'k');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridAlpha', 0.3, 'FontSize', 10); xlim([0 11]); 
    lgd1 = legend(labels, 'Location', 'best', 'FontSize', 9); set(lgd1, 'TextColor', 'k', 'Color', 'w');
    
    % Kustomisasi Figure Roll
    figure(fig_roll);
    title('Center of Mass (CoM) Roll - Lateral Sway', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    xlabel('Time (s)', 'FontSize', 10, 'Color', 'k'); ylabel('CoM Roll (rad)', 'FontSize', 10, 'Color', 'k');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridAlpha', 0.3, 'FontSize', 10); xlim([0 11]);
    lgd2 = legend(labels, 'Location', 'best', 'FontSize', 9); set(lgd2, 'TextColor', 'k', 'Color', 'w');
    
    % Kustomisasi Figure Pitch
    figure(fig_pitch);
    title('Center of Mass (CoM) Pitch - Sagittal Tilt', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    xlabel('Time (s)', 'FontSize', 10, 'Color', 'k'); ylabel('CoM Pitch (rad)', 'FontSize', 10, 'Color', 'k');
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k', 'GridAlpha', 0.3, 'FontSize', 10); xlim([0 11]);
    lgd3 = legend(labels, 'Location', 'best', 'FontSize', 9); set(lgd3, 'TextColor', 'k', 'Color', 'w');
    
    Tabel_RMSE = cell2table(rmse_results, 'VariableNames', {'Kondisi', 'RMSE_Speed', 'RMSE_Roll_rad', 'RMSE_Pitch_rad'});
end