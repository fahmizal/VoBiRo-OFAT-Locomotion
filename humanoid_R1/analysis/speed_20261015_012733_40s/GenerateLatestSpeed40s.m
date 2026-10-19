function results=GenerateLatestSpeed40s()
% First 40 seconds from the latest paired recording (20261015_012733); raw statistics.
root=fileparts(mfilename('fullpath')); outputDir=fullfile(root,'figures');
if ~isfolder(outputDir),mkdir(outputDir);end
colors=[0 .4470 .7410;.8500 .3250 .0980];
results=table();
for terrain="Latest"
 f=figure('Position',[100 100 700 350],'Color','w','Visible','off'); ax=axes(f);hold(ax,'on');
 for j=1:2
  tags=["DEFAULT","OFAT"]; T=readtable(fullfile(root,terrain+"_"+tags(j)+".csv"),'VariableNamingRule','preserve');
  t=(T.Timestamp_ms-T.Timestamp_ms(1))/1000;
  assert(all(diff(t)>0)&&t(end)>=40,'Incomplete/nonmonotonic recording');
  idx=t<=40;t=t(idx);v=T.Speed_m_s(idx);assert(all(isfinite(v)));
  dt=median(diff(t));window=round(1.6/dt);
  plot(ax,t,movmean(v,window),'Color',colors(j,:),'LineWidth',1.5);
  row=table(terrain,tags(j),numel(t),t(end),dt,mean(v),std(v),min(v),max(v),window, ...
   'VariableNames',{'Terrain','Gait','Samples','Duration_s','SampleInterval_s','MeanSpeed_m_s','StdSpeed_m_s','MinSpeed_m_s','MaxSpeed_m_s','SmoothingSamples'});
  results=[results;row];
 end
 grid(ax,'on');title(ax,'Walking Speed Magnitude','FontSize',12,'FontWeight','bold','Color','k');
 xlabel(ax,'Time (s)','FontSize',10,'Color','k');ylabel(ax,'Speed (m/s)','FontSize',10,'Color','k');
 set(ax,'Color','w','XColor','k','YColor','k','GridAlpha',.3,'FontSize',10);xlim(ax,[0 40]);xticks(ax,0:5:40);
 legend(ax,{'Baseline: Default','OFAT'},'Location','best','FontSize',9,'TextColor','k','Color','w');
 name=fullfile(outputDir,'Speed_'+terrain+'_40s');
 exportgraphics(f,name+'.png','Resolution',300,'BackgroundColor','white');
 
 savefig(f,name+'.fig');close(f);
end
writetable(results,fullfile(outputDir,'Speed_Comparison_40s.csv'));disp(results);
end
