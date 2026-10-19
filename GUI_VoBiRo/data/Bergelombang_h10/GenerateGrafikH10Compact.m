function GenerateGrafikH10Compact(csvFile,outputDir)
% Single-column, side-by-side attitude figure, matching the paper's style.
% Shows the first 11 s; full-record statistics still use all 108.296 s.
root=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(csvFile),csvFile=fullfile(root,'DataBergelombang.csv');end
if nargin<2 || isempty(outputDir),outputDir=fullfile(root,'figures');end
if ~isfolder(outputDir),mkdir(outputDir);end
T=readtable(csvFile,'VariableNamingRule','preserve');
t=(T.Timestamp_ms-T.Timestamp_ms(1))/1000;
assert(all(diff(t)>0),'Timestamps must increase.');
idx=t<=11;
referencePanels(T,t,idx,outputDir);
% User-selected blue from the pasted MATLAB reference (first palette row).
% Scale reference typography for a readable single-column figure.
h10Color=[0 .4470 .7410]; paperScale=.9;
fontName=get(groot,'DefaultAxesFontName');
% Render at twice the manuscript width, like the source MATLAB figures.
% The paper scales this to 3.5 inches; typography and strokes scale together.
f=figure('Color','w','Visible','off','Units','inches','Position',[1 1 7 2.7]);
for k=1:2
    ax=axes(f,'Position',[.075+(k-1)*.50 .30 .405 .53]);hold(ax,'on');
    if k==1
        y=T.CoM_Y_Roll;lab='Roll (rad)';heading='Body Roll - Lateral Sway';panel='(a)';
    else
        y=T.CoM_Z_Pitch;lab='Pitch (rad)';heading='Body Pitch - Sagittal Tilt';panel='(b)';
    end
    plot(ax,t(idx),y(idx),'Color',h10Color,'LineWidth',1.2);
    grid(ax,'on');box(ax,'on');xlim(ax,[0 11]);xticks(ax,0:11);
    set(ax,'Color','w','XColor','k','YColor','k','GridAlpha',.3, ...
        'GridColor',[.65 .65 .65],'FontName',fontName,'FontSize',10*paperScale,'LineWidth',.5);
    if k==1,ylim(ax,[-.4 .4]);yticks(ax,-.4:.1:.4);else,ylim(ax,[-.5 .1]);yticks(ax,-.5:.1:.1);end
    xlabel(ax,'Time (s)','FontName',fontName,'FontSize',10*paperScale,'Color','k');
    ylabel(ax,lab,'FontName',fontName,'FontSize',10*paperScale,'Color','k');
    title(ax,heading,'FontName',fontName,'FontSize',9,'FontWeight','bold','Color','k');
    l=legend(ax,{'OFAT: h10'},'Location','northeast','FontSize',6.5, ...
        'TextColor','k','Color','w','Box','on');
    set(l,'FontName',fontName,'ItemTokenSize',[12 5],'EdgeColor',[.75 .75 .75]);
end

% Add preview annotations only after both standalone panels are exported.
% MATLAB includes existing figure annotations when exporting an axes.
for k=1:2
    if k==1,panel='(a)';else,panel='(b)';end
    annotation(f,'textbox',[.075+(k-1)*.50 .015 .405 .12], ...
        'String',panel,'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'EdgeColor','none','FontName','Times New Roman','FontSize',16,'Color','k');
end
exportgraphics(f,fullfile(outputDir,'H10_Attitude_Compact.png'),'Resolution',300,'BackgroundColor','white');
exportgraphics(f,fullfile(outputDir,'H10_Attitude_Compact.pdf'),'ContentType','vector','BackgroundColor','white');
savefig(f,fullfile(outputDir,'H10_Attitude_Compact.fig'));close(f);
fprintf('Compact h10 roll/pitch figure generated in MATLAB. Window: first 11 s.\n');
end

function referencePanels(T,t,idx,outputDir)
% Exact figure/plot/typography settings from the user's Arm Swing script.
% CoM labels follow the CSV/reference convention; these are IMU attitudes,
% as explicitly explained in the manuscript (not spatial CoM measurements).
names={'H10_Roll_Panel','H10_Pitch_Panel'};
headings={'Center of Mass (CoM) Roll - Lateral Sway', ...
          'Center of Mass (CoM) Pitch - Sagittal Tilt'};
labels={'CoM Roll (rad)','CoM Pitch (rad)'};
values={T.CoM_Y_Roll,T.CoM_Z_Pitch};
for k=1:2
    f=figure('Name',names{k},'Position',[100 100 700 350], ...
        'Color','w','Visible','off');
    ax=axes(f);hold(ax,'on');grid(ax,'on');
    plot(ax,t(idx),values{k}(idx),'LineWidth',1.5,'Color',[0 .4470 .7410]);
    title(ax,headings{k},'FontSize',12,'FontWeight','bold','Color','k');
    xlabel(ax,'Time (s)','FontSize',10,'Color','k');
    ylabel(ax,labels{k},'FontSize',10,'Color','k');
    set(ax,'Color','w','XColor','k','YColor','k','GridAlpha',.3,'FontSize',10);
    xlim(ax,[0 11]);xticks(ax,0:11);
    if k==1,ylim(ax,[-.4 .4]);yticks(ax,-.4:.1:.4);else,ylim(ax,[-.5 .1]);yticks(ax,-.5:.1:.1);end
    lgd=legend(ax,{'h10: OFAT-Optimized'},'Location','best','FontSize',9);
    set(lgd,'TextColor','k','Color','w');
    exportgraphics(ax,fullfile(outputDir,[names{k} '.png']),'Resolution',300,'BackgroundColor','white');
    exportgraphics(ax,fullfile(outputDir,[names{k} '.pdf']),'ContentType','vector','BackgroundColor','white');
    savefig(f,fullfile(outputDir,[names{k} '.fig']));close(f);
end
end
