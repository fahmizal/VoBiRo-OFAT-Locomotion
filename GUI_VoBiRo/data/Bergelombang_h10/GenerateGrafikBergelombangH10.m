function metrics = GenerateGrafikBergelombangH10(csvFile, outputDir)
% MATLAB R2025a. Scientific figures for the OFAT-optimized h10 terrain trial.
% h10 = 10 mm peak-to-trough (not a 10 mm sinusoidal amplitude).
% Raw samples are retained. No samples are removed based on Fall_Status.
% CoM_* CSV columns are filtered IMU attitude proxies, not CoM positions.
% Foot_Trajectory_Z_* values are a kinematic proxy in logger units, not
% measured foot-to-ground clearance. See README_H10.txt for provenance.
% Usage: GenerateGrafikBergelombangH10
% or: GenerateGrafikBergelombangH10('path/to/DataBergelombang.csv','figures')

root = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(csvFile), csvFile = fullfile(root,'DataBergelombang.csv'); end
if nargin < 2 || isempty(outputDir), outputDir = fullfile(root,'figures'); end
if ~isfolder(outputDir), mkdir(outputDir); end
opts = detectImportOptions(csvFile,'VariableNamingRule','preserve');
T = readtable(csvFile,opts);
required = {'Timestamp_ms','CoM_Y_Roll','CoM_Z_Pitch','Speed_m_s', ...
    'Distance_m','Foot_Trajectory_Z_Left','Foot_Trajectory_Z_Right', ...
    'Hip_Pitch_R','Knee_Pitch_R','Ankle_Pitch_R', ...
    'Hip_Pitch_L','Knee_Pitch_L','Ankle_Pitch_L','Fall_Status'};
assert(all(ismember(required,T.Properties.VariableNames)),'Required CSV columns are missing.');
numeric = T{:,required(1:end-1)};
assert(all(isfinite(numeric(:))),'CSV contains missing or nonfinite numeric values.');
t = (T.Timestamp_ms-T.Timestamp_ms(1))/1000;
assert(all(diff(t)>0),'Timestamps must be strictly increasing; do not sort mixed trials.');
roll=T.CoM_Y_Roll; pitch=T.CoM_Z_Pitch; speed=T.Speed_m_s;
dt=median(diff(t)); smoothSamples=max(1,round(.4/dt));
speedDisplay=movmean(speed,smoothSamples); % 50 samples for this 8 ms recording.
% Exact palette from the user's Arm Swing MATLAB reference.
colors=[0 .4470 .7410; .8500 .3250 .0980; .9290 .6940 .1250; .4940 .1840 .5560];
blue=colors(1,:); orange=colors(2,:); h10Color=colors(1,:); gray=[.72 .72 .72];
% User explicitly selected the blue reference color for all h10 curves.
full=windowMetrics(T,t,true(size(t)),'Full recording');
eleven=windowMetrics(T,t,t<=11,'First 11 s');
metrics=[full;eleven];
writetable(metrics,fullfile(outputDir,'h10_metrics.csv'));
threshold=sum(contains(upper(string(T.Fall_Status)),'FALL'));
meta=struct('terrain_height_mm',10,'wavelength_m',.6,'basic_time_step_ms',8, ...
    'sample_count',height(T),'median_sample_interval_s',dt, ...
    'display_speed_smoothing_samples',smoothSamples, ...
    'logger_threshold_flag_count',threshold, ...
    'logger_threshold_flag_percent',100*threshold/height(T), ...
    'observed_falls',0,'observation_source','Operator confirmation; not inferred from CSV threshold flags', ...
    'gait_period_ms',600,'lateral_swing_mm',30,'foot_lift_mm',45, ...
    'dsr_percent',16,'arm_swing_gain',2.0, ...
    'gait_configuration_source','Operator-confirmed OFAT-Optimized configuration', ...
    'roll_pitch_definition','Filtered IMU attitude proxies in radians; CSV CoM_* headings retained', ...
    'distance_definition','3-D straight-line displacement from initial GPS position; not cumulative path length', ...
    'foot_definition','Kinematic leg-shortening proxy in logger units; not terrain clearance');
fid=fopen(fullfile(outputDir,'h10_metadata.json'),'w');
assert(fid~=-1,'Cannot create metadata file.'); fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true)); fclose(fid);

% Figure 1: speed, with raw data and clearly identified display smoothing.
f=newFigure('H10 walking speed',[750 450]); ax=axes(f); hold(ax,'on');
plot(ax,t,speed,'Color',gray,'LineWidth',.5);
plot(ax,t,speedDisplay,'Color',h10Color,'LineWidth',2.5);
styleAxes(ax); xlabel(ax,'Time (s)'); ylabel(ax,'Speed (m/s)');
title(ax,'Walking Speed on Undulating Terrain (h10 = 10 mm)');
whiteLegend(ax,{'Raw GPS speed','0.4-s moving mean'});
xlim(ax,[0 t(end)]); saveFigure(f,outputDir,'H10_Speed');

% Figure 2: raw IMU attitude data, without smoothing or removal of flags.
f=newFigure('H10 body attitude',[800 600]); tiledlayout(f,2,1,'TileSpacing','compact');
ax=nexttile;plot(ax,t,roll,'Color',h10Color,'LineWidth',1.5);styleAxes(ax);
ylabel(ax,'Body roll (rad)');title(ax,'Body Attitude on Undulating Terrain (h10 = 10 mm)');xlim(ax,[0 t(end)]);
ax=nexttile;plot(ax,t,pitch,'Color',h10Color,'LineWidth',1.5);styleAxes(ax);
xlabel(ax,'Time (s)');ylabel(ax,'Body pitch (rad)');xlim(ax,[0 t(end)]);
saveFigure(f,outputDir,'H10_Attitude');

% Figure 3: displacement (the logger does not export cumulative travel).
f=newFigure('H10 GPS displacement',[750 450]);ax=axes(f);
plot(ax,t,T.Distance_m,'Color',h10Color,'LineWidth',1.5);styleAxes(ax);
xlabel(ax,'Time (s)');ylabel(ax,'Displacement from start (m)');
title(ax,'GPS Displacement on Undulating Terrain');xlim(ax,[0 t(end)]);
saveFigure(f,outputDir,'H10_Displacement');

% Figure 4: fixed middle-of-record 4-s window; no selection by outcome.
zoomStart=floor(max(0,(t(end)-4)/2));zoomEnd=min(t(end),zoomStart+4);
f=newFigure('H10 foot proxy',[800 450]);ax=axes(f);hold(ax,'on');
plot(ax,t,T.Foot_Trajectory_Z_Left,'Color',blue,'LineWidth',1.5);
plot(ax,t,T.Foot_Trajectory_Z_Right,'Color',orange,'LineWidth',1.5);styleAxes(ax);
xlabel(ax,'Time (s)');ylabel(ax,'Kinematic foot-height proxy (logger units)');
title(ax,'Left and Right Foot Kinematic Proxies (h10)');
whiteLegend(ax,{'Left','Right'});xlim(ax,[zoomStart zoomEnd]);
saveFigure(f,outputDir,'H10_FootProxy');

% Figure 5: measured joint signs are retained, without mirroring one leg.
f=newFigure('H10 joint angles',[800 700]);tiledlayout(f,3,1,'TileSpacing','compact');
pairs={'Hip_Pitch_L','Hip_Pitch_R';'Knee_Pitch_L','Knee_Pitch_R';'Ankle_Pitch_L','Ankle_Pitch_R'};
names={'Hip pitch (rad)','Knee pitch (rad)','Ankle pitch (rad)'};
for i=1:3
    ax=nexttile;hold(ax,'on');
    plot(ax,t,T.(pairs{i,1}),'Color',blue,'LineWidth',1.5);
    plot(ax,t,T.(pairs{i,2}),'Color',orange,'LineWidth',1.5);
    styleAxes(ax);ylabel(ax,names{i});xlim(ax,[zoomStart zoomEnd]);
    if i==1,title(ax,'Sagittal Joint Responses on Undulating Terrain');whiteLegend(ax,{'Left','Right'});end
    if i==3,xlabel(ax,'Time (s)');end
end
saveFigure(f,outputDir,'H10_Joints');

% Figure 6: full-record composite for supplementary inspection.
f=newFigure('H10 manuscript responses',[1100 800]);tiledlayout(f,3,1,'TileSpacing','compact','Padding','compact');
ax=nexttile;hold(ax,'on');plot(ax,t,speed,'Color',gray,'LineWidth',.4);
plot(ax,t,speedDisplay,'Color',h10Color,'LineWidth',2.5);styleAxes(ax);
ylabel(ax,'Speed (m/s)');title(ax,'(a) Walking Speed');whiteLegend(ax,{'Raw GPS speed','0.4-s moving mean'});xlim(ax,[0 t(end)]);
ax=nexttile;plot(ax,t,roll,'Color',h10Color,'LineWidth',1.5);styleAxes(ax);
ylabel(ax,'Roll (rad)');title(ax,'(b) Body Roll');xlim(ax,[0 t(end)]);
ax=nexttile;plot(ax,t,pitch,'Color',h10Color,'LineWidth',1.5);styleAxes(ax);
ylabel(ax,'Pitch (rad)');xlabel(ax,'Time (s)');title(ax,'(c) Body Pitch');xlim(ax,[0 t(end)]);
saveFigure(f,outputDir,'H10_Responses');
GenerateGrafikH10Compact(csvFile,outputDir);
fprintf('\nMATLAB figures exported to: %s\n',outputDir);disp(metrics);
fprintf('No rows removed. %d logger threshold flags; operator reports no observed falls.\n',threshold);
end

function m=windowMetrics(T,t,idx,name)
v=T.Speed_m_s(idx);r=T.CoM_Y_Roll(idx);p=T.CoM_Z_Pitch(idx);tw=t(idx);d=T.Distance_m(idx);
duration=tw(end)-tw(1);meanSpeed=mean(v);maxSpeed=max(v);stdSpeed=std(v,0);
rollRms=sqrt(mean(r.^2));pitchRms=sqrt(mean(p.^2));
rollStd=std(r,0);pitchStd=std(p,0);meanRoll=mean(r);meanPitch=mean(p);
lastDisplacement=d(end);maxDisplacement=max(d);
m=table(string(name),sum(idx),duration,meanSpeed,maxSpeed,stdSpeed, ...
    rollRms,pitchRms,meanRoll,meanPitch,rollStd,pitchStd,lastDisplacement,maxDisplacement, ...
    'VariableNames',{'Window','Samples','Duration_s','MeanSpeed_m_s','MaxSpeed_m_s','StdSpeed_m_s', ...
    'RollRMS_rad','PitchRMS_rad','MeanRoll_rad','MeanPitch_rad','RollStd_rad','PitchStd_rad', ...
    'FinalDisplacement_m','MaxDisplacement_m'});
end
function f=newFigure(name,pixels)
f=figure('Name',name,'Color','w','Visible','off','Position',[100 100 pixels]);
end
function styleAxes(ax)
grid(ax,'on');box(ax,'on');
set(ax,'Color','w','XColor','k','YColor','k','FontName',get(groot,'DefaultAxesFontName'), ...
    'FontSize',10,'GridAlpha',.3,'LineWidth',.5);
set(ax,'DefaultTextFontName',get(groot,'DefaultTextFontName'),'DefaultTextColor','k','TitleFontSizeMultiplier',1.2,'TitleFontWeight','bold','LabelFontSizeMultiplier',1);
end
function whiteLegend(ax,labels)
l=legend(ax,labels,'Location','best','FontSize',9,'TextColor','k','Color','w');
set(l,'FontName',get(groot,'DefaultAxesFontName'),'EdgeColor',[.3 .3 .3]);
end
function saveFigure(f,outputDir,name)
exportgraphics(f,fullfile(outputDir,[name '.png']),'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(outputDir,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
savefig(f,fullfile(outputDir,[name '.fig']));close(f);
end
