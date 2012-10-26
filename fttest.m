function [stat,cond1data,cond2data,fidx,chanidx] = fttest(EEG,foi,alpha,doplot)

loadpaths

if ~exist('alpha','var') || isempty(alpha)
    alpha = 0.05;
elseif ~isnumeric(alpha) || length(alpha) > 1
    error('Alpha level must be a numeric scalar');
end

cond1 = 'stimulation';
cond2 = 'baseline';
ttesttype = 1;
ttestalpha = alpha;

if ~isnumeric(foi) || length(foi) > 2
    error('Frequency of interest must be a numeric scalar or range.');
end

if ~exist('doplot','var') || isempty(doplot)
    doplot = true;
end

fprintf('\nCOMPARING %s TO %s: t-test type = %d; alpha = %.3f.\n\n', cond1,cond2,ttesttype,ttestalpha);

if ischar(EEG)
    EEG = pop_loadset('filename', [EEG '.set'], 'filepath', filepath);
end

chanlocs = EEG.chanlocs;
cond1data = EEG;

%% select baseline
cond2data = pop_select(cond1data,'time',[cond1data.xmin 0]);
cond1data = pop_select(cond1data,'time',[0 cond1data.xmax]);

%% prepare for fieldtrip

cond1data = convertoft(cond1data);
cond2data = convertoft(cond2data);

%% fieldtrip frequency analysis

if size(cond1data.trial{1},2) > size(cond2data.trial{1},2)
    padlen = size(cond1data.trial{1},2)/cond1data.fsample;
    fprintf('Padding out %s to %.1f sec.\n',cond2,padlen);
    
    cond1data = calcmft(cond1data);
    cond2data = calcmft(cond2data,padlen);
elseif size(cond1data.trial{1},2) < size(cond2data.trial{1},2)
    padlen = size(cond2data.trial{1},2)/cond2data.fsample;
    fprintf('Padding out %s to %.1f sec.\n',cond1,padlen);
    
    cond1data = calcmft(cond1data,padlen);
    cond2data = calcmft(cond2data);
else
    cond1data = calcmft(cond1data);
    cond2data = calcmft(cond2data);
end

if sum(~(cond1data.freq == cond2data.freq)) > 0
    error('Frequency bins of conditions are not identical!');
end

if length(foi) == 1
    fidx = find(abs(cond1data.freq-foi) == min(abs(cond1data.freq-foi)));
elseif length(foi) == 2
    frange = find(cond1data.freq >= foi(1) & cond1data.freq <= foi(2));
    [dummy,maxidx] = max(max( cond1data.meanpwr(:,frange)-cond2data.meanpwr(:,frange), [],1));
    fidx = frange(1)-1+maxidx;
end

%% fieldtrip statistical analysis
cfg = [];
cfg.method           = 'montecarlo';
cfg.parameter        = 'powspctrm';
cfg.frequency        = [cond1data.freq(fidx) cond1data.freq(fidx)];
cfg.correctm         = 'cluster';
cfg.clusteralpha     = alpha;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 2;
cfg.tail             = ttesttype;
cfg.clustertail      = ttesttype;
cfg.alpha            = ttestalpha;
cfg.numrandomization = 1000;
% prepare_neighbours determines what sensors may form clusters
cfg_neighb.method    = 'distance';
cfg_neighb.neighbourdist = 4;
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, cond1data);

if strcmp(cond2,'baseline')
    cfg.statistic = 'depsamplesT';
    ntrials = size(cond1data.powspctrm,1);
    design = zeros(2,2*ntrials);
    design(1,:) = [ones(1,ntrials) ones(1,ntrials)+1];
    design(2,:) = [1:ntrials 1:ntrials];
    cfg.ivar     = 1;
    cfg.uvar     = 2;
else
    cfg.statistic = 'indepsamplesT';
    design = [ones(1,size(cond1data.powspctrm,1)) ones(1,size(cond2data.powspctrm,1))+1];
    cfg.ivar = 1;
end
cfg.design   = design;
cfg.feedback = 'textbar';

[stat] = ft_freqstatistics(cfg, cond1data, cond2data);

stat.diffcond = cond1data.meanpwr - cond2data.meanpwr;
stat.chanlocs = chanlocs;

if isfield(stat,'posclusters')
    for p = 1:length(stat.posclusters)
        fprintf('Cluster %d: t = %.2f, p = %.3f\n', p, stat.posclusters(p).clusterstat, stat.posclusters(p).prob);
    end
end

if sum(stat.mask) > 0
    
    %plot spectrum at electrode with larget test statistic
    [dummy,clustmax] = max(stat.stat(stat.mask));
    
    %plot spectrum at electrode with largest signal power
    %[dummy,clustmax] = max(plotvals(stat.mask));
    
    clustchan = stat.label(stat.mask);
    chanidx = find(strcmp(clustchan{clustmax},stat.label));
else
    chanidx = [];
end

%% topoplotting

if ~doplot
    return;
end

fprintf('Plotting topoplot.\n');
figure('Name',mfilename,'Color','white');

% figpos = get(gcf,'Position');
% figpos(3) = figpos(3)*3;
% set(gcf,'Position',figpos);

% subplot(1,3,1);
plotvals = stat.diffcond(:,fidx);
plotvals(~stat.mask) = 0;
topoplot(plotvals,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','labels','pmask',stat.mask);
colorbar
title(sprintf('Power @ %.1fHz',cfg.frequency(1)));

% subplot(1,3,2);
% topoplot(stat.stat,stat.chanlocs, 'maplimits', 'absmax', 'electrodes','labels','pmask',stat.mask);
% colorbar
% title('Test Statistic');
%
% subplot(1,3,3);
% topoplot(1-stat.prob,stat.chanlocs, 'maplimits', [1-ttestalpha 1], 'electrodes','labels','pmask',stat.mask);
% h = colorbar; set(h,'YTick',[1-ttestalpha 1],'YTickLabel',{num2str(ttestalpha),'0'});
% title('Significance');

while true
    if ~isempty(chanidx)
        figure('Name',mfilename,'Color','white');
        plotspec = cond1data.meanpwr(chanidx,:)-cond2data.meanpwr(chanidx,:);
        plot(cond1data.freq,plotspec,'LineWidth',1.5);
        
        if ~exist('ylim','var')
            ylim = [0 plotspec(fidx)*2];
        end
        set(gca,'FontSize',14,'XLim', [cond1data.freq(1) cond1data.freq(end)], 'YLim',ylim);
        
        xlabel('Frequency (Hz)','FontSize',14);
        ylabel('Amplitude (uV)','FontSize',14);
        
        title(sprintf('FFT of channel %s', cond1data.label{chanidx}));
        box on
        
        if ~isempty(foi)
            hold on;
            plot(cond1data.freq(fidx),plotspec(fidx),'r.', 'MarkerSize',25);
            text(cond1data.freq(fidx)+4,plotspec(fidx), ...
                sprintf('Response at %.1fHz',cond1data.freq(fidx)),'FontSize',14);
            hold off;
        end
    end
    
    dlgopt.Resize='on';
    dlgopt.WindowStyle='normal';
    answers = inputdlg({'Enter channel to FFT:','Enter amplitude range to plot:'},...
        mfilename,1,{'','0 0.2'},dlgopt);
    
    if isempty(answers)
        break;
    end
    
    channame = answers{1};
    ylim = str2double(answers{2});
    
    chanidx = find(strcmpi(channame,cond1data.label));
end

%% convert from EEGLAB to FIELDTRIP structure
function EEG = convertoft(EEG)

EEG = eeglab2fieldtrip(EEG,'preprocessing','none');
EEG.elec.pnt = [-EEG.elec.pnt(:,2) EEG.elec.pnt(:,1) EEG.elec.pnt(:,3)];
EEG.elec.elecpos = EEG.elec.pnt;
EEG.elec.chanpos = EEG.elec.elecpos;
EEG.elec.unit = 'cm';

%% calculate multi-taper fourier transform using fieldtrip
function EEG = calcmft(EEG,padlen)

cfg = [];
cfg.output     = 'pow';
cfg.method     = 'mtmfft';
cfg.foi        = 1:0.1:100;
cfg.keeptrials = 'yes';
cfg.taper = 'rectwin';
%cfg.taper = 'dpss';
%cfg.tapsmofrq = 0.143;

if exist('padlen','var')
    cfg.pad = padlen;
end

EEG = ft_freqanalysis(cfg,EEG);

% %% added by Damian to normalise power by the two surrounding bins since we should have a peak not a broadband splodge
% EEGsmooth = EEG.powspctrm;
% 
% for fq = 2:size(EEG.powspctrm,3)-1
%     for fqch = 1:size(EEG.powspctrm,1)
%         EEGsmooth(fqch,:,fq) = EEG.powspctrm(fqch,:,fq) - mean([EEG.powspctrm(fqch,:,fq-1); EEG.powspctrm(fqch,:,fq+1)]);
%     end
% end
%         
% EEG.powspctrm = EEGsmooth;
% %%

EEG.meanpwr = squeeze(mean(EEG.powspctrm,1));