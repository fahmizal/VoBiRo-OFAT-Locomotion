%% MATLAB Script: VoBiRo Bipedal Robot Period Time Experimental Analysis
% Designed for high-quality scientific paper publication.
% All text is in English, forced to solid black, and legend boxes are white.
clear; clc; close all;

%% 1. GLOBAL INITIALIZATION & FONT CONFIGURATION (Times New Roman, Solid Black)
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultFigureColor', 'w');       % Pure white figure background
set(0, 'DefaultAxesXColor', 'k');         % Force X-axis and ticks to solid black
set(0, 'DefaultAxesYColor', 'k');         % Force Y-axis and ticks to solid black

%% 2. IMPORT CSV DATA
fprintf('Loading experimental data...\n');
try
    data1000 = readtable('data_1000.csv');
    data800  = readtable('data_800.csv');
    data600  = readtable('data_600.csv');
    data400  = readtable('data_400.csv');
    fprintf('All datasets successfully loaded!\n\n');
catch ME
    error('Failed to read CSV files. Ensure the files are in the working directory.');
end

%% 3. PRE-PROCESSING (Time Normalization to Seconds starting from 0)
t1000 = (data1000.Timestamp_ms - data1000.Timestamp_ms(1)) / 1000;
t800  = (data800.Timestamp_ms - data800.Timestamp_ms(1)) / 1000;
t600  = (data600.Timestamp_ms - data600.Timestamp_ms(1)) / 1000;
t400  = (data400.Timestamp_ms - data400.Timestamp_ms(1)) / 1000;

% Professional color palette for lines (high contrast on white background)
colors = [0.00, 0.45, 0.74;  % Blue (1000 ms)
          0.85, 0.33, 0.10;  % Orange (800 ms)
          0.93, 0.69, 0.13;  % Yellow (600 ms)
          0.49, 0.18, 0.56]; % Purple (400 ms)

%% ========================================================================
%% FIGURE 1: WALKING SPEED PROFILE OVER TIME (CLEAN VERSION)
%% ========================================================================
figure('Name', 'Speed Profile', 'Position', [100, 100, 750, 450], 'Color', 'w');
hold on;

plot(t1000, data1000.Speed_m_s, 'LineWidth', 2, 'Color', colors(1,:));
plot(t800,  data800.Speed_m_s,  'LineWidth', 2, 'Color', colors(2,:));
plot(t600,  data600.Speed_m_s,  'LineWidth', 2, 'Color', colors(3,:));
plot(t400,  data400.Speed_m_s,  'LineWidth', 2, 'Color', colors(4,:));

grid on; box on;
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 12, 'Color', 'k');
ylabel('Walking Speed (m/s)', 'FontSize', 12, 'Color', 'k');
title('Walking Speed Profile under Various Period Times', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

% Kotak legenda putih, bersih tanpa Fall Detected
legend({'Period: 1000 ms', 'Period: 800 ms', 'Period: 600 ms', 'Period: 400 ms'}, ...
    'FontSize', 10, 'Location', 'best', 'TextColor', 'k', 'Color', 'w');
%% ========================================================================
%% FIGURE 2: PERFORMANCE SUMMARY (BAR CHART)
%% ========================================================================
periods_label = categorical({'1000 ms', '800 ms', '600 ms', '400 ms'});
periods_label = reordercats(periods_label, {'1000 ms', '800 ms', '600 ms', '400 ms'});
max_speeds = [max(data1000.Speed_m_s), max(data800.Speed_m_s), max(data600.Speed_m_s), max(data400.Speed_m_s)];

figure('Name', 'Speed Summary', 'Position', [150, 150, 600, 450], 'Color', 'w');
b = bar(periods_label, max_speeds, 'FaceColor', 'flat');
b.CData = colors; 

grid on; box on;
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Period Time (ms)', 'FontSize', 12, 'Color', 'k');
ylabel('Maximum Speed (m/s)', 'FontSize', 12, 'Color', 'k');
title('Comparison of Maximum Speed and Gait Stability', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

% Status labels above bars (Forced to Solid Black font)
text(1, max_speeds(1)+0.01, 'Fall (Too Slow)', 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold');
text(2, max_speeds(2)+0.01, 'Stable (Normal)', 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold');
text(3, max_speeds(3)+0.01, 'Stable (Normal)', 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold');
text(4, max_speeds(4)+0.01, 'Fall (Too Fast)', 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 9, 'FontWeight', 'bold');
ylim([0, max(max_speeds)*1.2]);

%% ========================================================================
%% FIGURE 3: BODY STABILITY ANALYSIS (CoM ROLL & PITCH)
%% ========================================================================
figure('Name', 'CoM Oscillations', 'Position', [200, 200, 800, 600], 'Color', 'w');

subplot(2,1,1);
hold on;
plot(t1000, data1000.CoM_Y_Roll, 'LineWidth', 1.2, 'Color', colors(1,:));
plot(t800,  data800.CoM_Y_Roll,  'LineWidth', 1.2, 'Color', colors(2,:));
plot(t600,  data600.CoM_Y_Roll,  'LineWidth', 1.2, 'Color', colors(3,:));
plot(t400,  data400.CoM_Y_Roll,  'LineWidth', 1.2, 'Color', colors(4,:));
grid on; box on; 
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
ylabel('CoM Roll (rad)', 'FontSize', 11, 'Color', 'k');
title('Center of Mass (CoM) Oscillation Analysis for Body Stability', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');

% ---> KOTAK LEGENDA PUTIH DI SINI ('Color', 'w') <---
legend({'1000 ms', '800 ms', '600 ms', '400 ms'}, 'Location', 'northeast', 'TextColor', 'k', 'Color', 'w');

subplot(2,1,2);
hold on;
plot(t1000, data1000.CoM_Z_Pitch, 'LineWidth', 1.2, 'Color', colors(1,:));
plot(t800,  data800.CoM_Z_Pitch,  'LineWidth', 1.2, 'Color', colors(2,:));
plot(t600,  data600.CoM_Z_Pitch,  'LineWidth', 1.2, 'Color', colors(3,:));
plot(t400,  data400.CoM_Z_Pitch,  'LineWidth', 1.2, 'Color', colors(4,:));
grid on; box on; 
set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
xlabel('Time (s)', 'FontSize', 11, 'Color', 'k');
ylabel('CoM Pitch (rad)', 'FontSize', 11, 'Color', 'k');

%% ========================================================================
%% FIGURE 4: FOOT TRAJECTORY CYCLES (LEFT VS RIGHT) - SOLID LINES & ZOOMED IN
%% ========================================================================
figure('Name', 'Foot Trajectory Solid', 'Position', [250, 250, 850, 600], 'Color', 'w');

% Perbedaan utama: Menggunakan 'r-' bukan 'r--', LineWidth dinaikkan sedikit.

% Period 1000 ms (Zoom di detik 2 sampai 6)
subplot(2,2,1);
plot(t1000, data1000.Foot_Trajectory_Z_Left, 'b-', 'LineWidth', 1.8); hold on;
plot(t1000, data1000.Foot_Trajectory_Z_Right, 'r-', 'LineWidth', 1.8); % GANTI SINI: 'r--' jadi 'r-'
grid on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k'); 
title('Period: 1000 ms', 'Color', 'k'); ylabel('Foot Trajectory Z', 'Color', 'k');
xlim([2 6]); % Tetap dilebarkan seperti sebelumnya
legend({'Left (Blue)', 'Right (Red)'}, 'FontSize', 9, 'TextColor', 'k', 'Color', 'w', 'Location', 'northeast');

% Period 800 ms (Zoom di detik 0 sampai 4)
subplot(2,2,2);
plot(t800, data800.Foot_Trajectory_Z_Left, 'b-', 'LineWidth', 1.8); hold on;
plot(t800, data800.Foot_Trajectory_Z_Right, 'r-', 'LineWidth', 1.8); % GANTI SINI
grid on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k'); 
title('Period: 800 ms', 'Color', 'k');
xlim([0 4]);

% Period 600 ms (Zoom di detik 2 sampai 6)
subplot(2,2,3);
plot(t600, data600.Foot_Trajectory_Z_Left, 'b-', 'LineWidth', 1.8); hold on;
plot(t600, data600.Foot_Trajectory_Z_Right, 'r-', 'LineWidth', 1.8); % GANTI SINI
grid on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k'); 
title('Period: 600 ms', 'Color', 'k'); xlabel('Time (s)', 'Color', 'k'); ylabel('Foot Trajectory Z', 'Color', 'k');
xlim([2 6]);

% Period 400 ms (Zoom di detik 2 sampai 6)
subplot(2,2,4);
plot(t400, data400.Foot_Trajectory_Z_Left, 'b-', 'LineWidth', 1.8); hold on;
plot(t400, data400.Foot_Trajectory_Z_Right, 'r-', 'LineWidth', 1.8); % GANTI SINI
grid on; set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k'); 
title('Period: 400 ms', 'Color', 'k'); xlabel('Time (s)', 'Color', 'k');
xlim([2 6]);

sgtitle('Comparison of Foot Trajectory Cycles (Foot Trajectory Z) Left vs. Right', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'k');