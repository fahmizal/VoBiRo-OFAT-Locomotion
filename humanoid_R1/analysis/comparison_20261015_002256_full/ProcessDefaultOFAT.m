function metrics=ProcessDefaultOFAT(inputDir,outputDir)
% Compare the latest paired recording, 20261015_002256_full.
% Use raw IMU attitude and the entire recording; do not remove threshold flags.
% Record-time .profile.txt is the configuration evidence, not current source.
root=fileparts(mfilename('fullpath'));
if nargin<1||isempty(inputDir),inputDir=root;end
if nargin<2||isempty(outputDir),outputDir=fullfile(root,'figures');end
if ~isfolder(outputDir),mkdir(outputDir);end
colors=[0 .4470 .7410;.8500 .3250 .0980;.9290 .6940 .1250;.4940 .1840 .5560;.4660 .6740 .1880];
D=readTrial(fullfile(inputDir,'DEFAULT.csv'));
R=readTrial(fullfile(inputDir,'OFAT.csv'));
metrics=[metricRow(D,'Default oval');metricRow(R,'OFAT (recorded profile)')];
writetable(metrics,fullfile(outputDir,'Table10_RMSE_full.csv'));
speedTable=table(["Default";"OFAT"],[mean(D.rawSpeed);mean(R.rawSpeed)], ...
 [std(D.rawSpeed);std(R.rawSpeed)],[min(D.rawSpeed);min(R.rawSpeed)], ...
 [max(D.rawSpeed);max(R.rawSpeed)], ...
 'VariableNames',{'Gait','MeanSpeed_m_s','StdSpeed_m_s','MinSpeed_m_s','MaxSpeed_m_s'});
writetable(speedTable,fullfile(outputDir,'Speed_Table_full.csv'));
speedTable.Duration_s=[D.t(end);R.t(end)];
speedTable.Samples=[numel(D.t);numel(R.t)];
writetable(speedTable,fullfile(outputDir,'Speed_Table_full.csv'));
disp(speedTable);

red=100*(1-[R.rollRms R.pitchRms]./[D.rollRms D.pitchRms]);
snD=-20*log10([D.rollRms D.pitchRms]);snR=-20*log10([R.rollRms R.pitchRms]);
taguchi=table(["CoM Roll";"CoM Pitch"],[D.rollRms;D.pitchRms],snD', ...
 [R.rollRms;R.pitchRms],snR',(snR-snD)',red', ...
 'VariableNames',{'Metric','Default_RMSE_rad','Default_SN_dB','Revised_RMSE_rad','Revised_SN_dB','SN_Gain_dB','RMSE_Reduction_percent'});
writetable(taguchi,fullfile(outputDir,'Table11_SN_full.csv'));
channels={'roll','pitch','speed'};titles={'Center of Mass (CoM) Roll - Lateral Sway','Center of Mass (CoM) Pitch - Sagittal Tilt','Average Walking Speed'};
ylabels={'CoM Roll (rad)','CoM Pitch (rad)','Speed (m/s)'};
for k=1:3
 f=newFig();ax=axes(f);hold(ax,'on');
 plot(ax,D.t,D.(channels{k}),'Color',colors(1,:),'LineWidth',1.5);
 plot(ax,R.t,R.(channels{k}),'Color',colors(2,:),'LineWidth',1.5);
 style(ax,titles{k},ylabels{k},{'Baseline: Default','OFAT'});
 saveFigure(f,outputDir,['Compare_' channels{k}]);
end
meta=struct('window_rule','Timestamp normalized to first row; retain all rows', ...
 'default_samples',numel(D.t),'revised_samples',numel(R.t), ...
 'default_last_time_s',D.t(end),'revised_last_time_s',R.t(end), ...
 'default_median_dt_s',D.dt,'revised_median_dt_s',R.dt, ...
 'speed_smoothing_samples',50,'speed_smoothing_seconds_revised',50*R.dt, ...
 'physical_falls','Not inferred from CSV','fall_source','Threshold flags are not verified physical falls', ...
 'revised_threshold_flags_full',R.flags,'no_rows_removed',true);
fid=fopen(fullfile(outputDir,'metadata_full.json'),'w');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);
disp(metrics);disp(taguchi);fprintf('MATLAB export completed. All evaluation windows <=full recording.\n');
end
function A=readTrial(file,allowShort)
 if nargin<2,allowShort=false;end
 T=readtable(file,'VariableNamingRule','preserve');t=(T.Timestamp_ms-T.Timestamp_ms(1))/1000;
 assert(all(diff(t)>0),'Timestamps must increase.');
 if ~allowShort,assert(t(end)>=11,'Incomplete 11-s recording.');end
 idx=true(size(t));A.t=t(idx);A.dt=median(diff(t));A.roll=T.CoM_Y_Roll(idx);A.pitch=T.CoM_Z_Pitch(idx);A.rawSpeed=T.Speed_m_s(idx);
 assert(all(isfinite([A.roll;A.pitch;A.rawSpeed])),'Nonfinite samples must be investigated.');
 A.speed=movmean(A.rawSpeed,50);A.rollRms=sqrt(mean(A.roll.^2));A.pitchRms=sqrt(mean(A.pitch.^2));
 A.flags=sum(contains(upper(string(T.Fall_Status(idx))),'FALL'));
end
function row=metricRow(A,name)
 row=table(string(name),numel(A.t),A.t(end),A.dt,mean(A.rawSpeed), ...
 sqrt(mean((A.speed-mean(A.rawSpeed)).^2)),A.rollRms,A.pitchRms, ...
 'VariableNames',{'Condition','Samples','LastTime_s','MedianDt_s','MeanSpeed_m_s','SmoothedSpeedRMSE_m_s','RollRMSE_rad','PitchRMSE_rad'});
end
function f=newFig()
 f=figure('Position',[100 100 700 350],'Color','w','Visible','off');
end
function style(ax,heading,ylab,labels)
 grid(ax,'on');title(ax,heading,'FontSize',12,'FontWeight','bold','Color','k');
 xlabel(ax,'Time (s)','FontSize',10,'Color','k');ylabel(ax,ylab,'FontSize',10,'Color','k');
 set(ax,'Color','w','XColor','k','YColor','k','GridAlpha',.3,'FontSize',10);xlim(ax,[0 max(cellfun(@(h) max(h.XData),num2cell(findobj(ax,'Type','line'))))]);
 l=legend(ax,labels,'Location','best','FontSize',9);set(l,'TextColor','k','Color','w');
end
function saveFigure(f,folder,name)
 exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',300,'BackgroundColor','white');
 
 savefig(f,fullfile(folder,[name '.fig']));close(f);
end
