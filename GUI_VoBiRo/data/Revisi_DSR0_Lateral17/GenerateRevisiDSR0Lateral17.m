function metrics=GenerateRevisiDSR0Lateral17(inputDir,outputDir)
% MATLAB R2025a. All metrics use only normalized time <= 11 s.
% Joint revised trial: DSR 0%, lateral 17 mm, period 600 ms,
% foot lift 45 mm, arm gain 2.0; operator confirmed oval track/no falls.
% Supplemental overlays are protocol-separated, not isolated OFAT evidence.
root=fileparts(mfilename('fullpath'));
if nargin<1||isempty(inputDir),inputDir=root;end
if nargin<2||isempty(outputDir),outputDir=fullfile(root,'figures');end
if ~isfolder(outputDir),mkdir(outputDir);end
colors=[0 .4470 .7410;.8500 .3250 .0980;.9290 .6940 .1250;.4940 .1840 .5560;.4660 .6740 .1880];
D=readTrial(fullfile(inputDir,'default full.csv'));
R=readTrial(fullfile(inputDir,'Dsrbaru_lateralbaru.csv'));
metrics=[metricRow(D,'Default oval');metricRow(R,'Revised DSR 0%, lateral 17 mm oval')];
writetable(metrics,fullfile(outputDir,'Table10_RMSE_11s.csv'));
red=100*(1-[R.rollRms R.pitchRms]./[D.rollRms D.pitchRms]);
snD=-20*log10([D.rollRms D.pitchRms]);snR=-20*log10([R.rollRms R.pitchRms]);
taguchi=table(["CoM Roll";"CoM Pitch"],[D.rollRms;D.pitchRms],snD', ...
 [R.rollRms;R.pitchRms],snR',(snR-snD)',red', ...
 'VariableNames',{'Metric','Default_RMSE_rad','Default_SN_dB','Revised_RMSE_rad','Revised_SN_dB','SN_Gain_dB','RMSE_Reduction_percent'});
writetable(taguchi,fullfile(outputDir,'Table11_SN_11s.csv'));
channels={'roll','pitch','speed'};titles={'Center of Mass (CoM) Roll - Lateral Sway','Center of Mass (CoM) Pitch - Sagittal Tilt','Average Walking Speed'};
ylabels={'CoM Roll (rad)','CoM Pitch (rad)','Speed (m/s)'};
for k=1:3
 f=newFig();ax=axes(f);hold(ax,'on');
 plot(ax,D.t,D.(channels{k}),'Color',colors(1,:),'LineWidth',1.5);
 plot(ax,R.t,R.(channels{k}),'Color',colors(2,:),'LineWidth',1.5);
 style(ax,titles{k},ylabels{k},{'Baseline: Default','Revised: OFAT'});
 saveFigure(f,outputDir,['Compare_' channels{k}]);
end
for k=1:2
 f=newFig();ax=axes(f);plot(ax,R.t,R.(channels{k}),'Color',colors(1,:),'LineWidth',1.5);
 style(ax,titles{k},ylabels{k},{'DSR 0%, lateral 17 mm (oval)'});
 saveFigure(f,outputDir,['Revised_' channels{k}]);
end
groups={{'DSR4.csv','DSR81.csv','DSR12.csv','DSR16.csv'}, ...
 {'data_amp_10.csv','data_amp_20.csv','data_amp_30.csv','data_amp_40.csv'}};
labels={{'DSR: 4% (initial)','DSR: 8% (initial)','DSR: 12% (initial)','DSR: 16% (initial)'}, ...
 {'Lateral: 10 mm (initial)','Lateral: 20 mm (initial)','Lateral: 30 mm (initial)','Lateral: 40 mm (initial)'}};
names={'DSR','Lateral'};
for g=1:2
 trials=cell(1,5);rows=cell(1,5);
 for i=1:4
  trials{i}=readTrial(fullfile(inputDir,groups{g}{i}),true);rows{i}=metricRow(trials{i},labels{g}{i});
 end
 trials{5}=R;rows{5}=metricRow(R,'Joint DSR 0%, lateral 17 mm (oval)');
 summary=vertcat(rows{:});summary.Protocol=[repmat("Initial straight-track OFAT",4,1);"Joint revised oval trial"];
 writetable(summary,fullfile(outputDir,['Table_' names{g} '_with_joint_trial_11s.csv']));
 for k=1:2
  f=newFig();ax=axes(f);hold(ax,'on');
  for i=1:5
   ls='-';if i==5,ls='--';end
   plot(ax,trials{i}.t,trials{i}.(channels{k}),'Color',colors(i,:),'LineStyle',ls,'LineWidth',1.5);
  end
  style(ax,[names{g} ' Trials and Revised Combined Trial'],ylabels{k},[labels{g},{'Joint: DSR 0%, lateral 17 mm (oval)'}]);
  saveFigure(f,outputDir,['Supplement_' names{g} '_' channels{k}]);
 end
end
meta=struct('window_rule','Timestamp normalized to first row; retain t <= 11 s', ...
 'default_samples',numel(D.t),'revised_samples',numel(R.t), ...
 'default_last_time_s',D.t(end),'revised_last_time_s',R.t(end), ...
 'default_median_dt_s',D.dt,'revised_median_dt_s',R.dt, ...
 'speed_smoothing_samples',50,'speed_smoothing_seconds_revised',50*R.dt, ...
 'revised_physical_falls',0,'fall_source','Operator observation, not accelerometer threshold flags', ...
 'revised_threshold_flags_11s',R.flags,'no_rows_removed',true);
fid=fopen(fullfile(outputDir,'metadata_11s.json'),'w');fprintf(fid,'%s',jsonencode(meta,PrettyPrint=true));fclose(fid);
disp(metrics);disp(taguchi);fprintf('MATLAB export completed. All evaluation windows <=11 s.\n');
end
function A=readTrial(file,allowShort)
 if nargin<2,allowShort=false;end
 T=readtable(file,'VariableNamingRule','preserve');t=(T.Timestamp_ms-T.Timestamp_ms(1))/1000;
 assert(all(diff(t)>0),'Timestamps must increase.');
 if ~allowShort,assert(t(end)>=11,'Incomplete 11-s recording.');end
 idx=t<=11;A.t=t(idx);A.dt=median(diff(t));A.roll=T.CoM_Y_Roll(idx);A.pitch=T.CoM_Z_Pitch(idx);A.rawSpeed=T.Speed_m_s(idx);
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
 set(ax,'Color','w','XColor','k','YColor','k','GridAlpha',.3,'FontSize',10);xlim(ax,[0 11]);
 l=legend(ax,labels,'Location','best','FontSize',9);set(l,'TextColor','k','Color','w');
end
function saveFigure(f,folder,name)
 exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',300,'BackgroundColor','white');
 exportgraphics(f,fullfile(folder,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
 savefig(f,fullfile(folder,[name '.fig']));close(f);
end
