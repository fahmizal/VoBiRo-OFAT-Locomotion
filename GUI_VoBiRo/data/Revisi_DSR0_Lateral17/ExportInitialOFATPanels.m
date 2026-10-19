function ExportInitialOFATPanels(folder)
% Rebuild paper's initial sensitivity panels from the verified MATLAB FIGs.
if nargin<1,folder=fullfile(fileparts(mfilename('fullpath')),'figures');end
names={'DSR','Lateral'};channels={'roll','pitch'};
for channel={'roll','pitch','speed'}
 name=['Compare_' channel{1}];f=openfig(fullfile(folder,[name '.fig']),'invisible');
 ax=findobj(f,'Type','axes');legend(ax,{'Baseline: Default','Revised: OFAT'},'Location','best','FontSize',9,'TextColor','k','Color','w');
 exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',300,'BackgroundColor','white');
 exportgraphics(f,fullfile(folder,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
 savefig(f,fullfile(folder,[name '.fig']));close(f);
end
headings={'Center of Mass (CoM) Roll - Lateral Sway','Center of Mass (CoM) Pitch - Sagittal Tilt'};
for g=1:2
 for k=1:2
  f=openfig(fullfile(folder,['Supplement_' names{g} '_' channels{k} '.fig']),'invisible');
  ax=findobj(f,'Type','axes');lines=findobj(ax,'Type','line');
  % Joint revised curve is uniquely dashed; preserve all four initial curves.
  for i=1:numel(lines),if strcmp(lines(i).LineStyle,'--'),delete(lines(i));end,end
  if g==1,labels={'DSR: 4%','DSR: 8%','DSR: 12%','DSR: 16%'};else,labels={'Lateral: 10 mm','Lateral: 20 mm','Lateral: 30 mm','Lateral: 40 mm'};end
  legend(ax,labels,'Location','best','FontSize',9,'TextColor','k','Color','w');
  title(ax,headings{k},'FontSize',12,'FontWeight','bold','Color','k');
  name=['Initial_' names{g} '_' channels{k}];
  exportgraphics(f,fullfile(folder,[name '.png']),'Resolution',300,'BackgroundColor','white');
  exportgraphics(f,fullfile(folder,[name '.pdf']),'ContentType','vector','BackgroundColor','white');
  savefig(f,fullfile(folder,[name '.fig']));close(f);
 end
end
fprintf('Initial sensitivity panels exported with raw t<=11 s data.\n');
end
