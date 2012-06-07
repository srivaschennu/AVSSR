function batchfft2(EEG,targetfreq,stattest,alpha)

loadpaths

if ~exist('alpha','var') || isempty(alpha)
    alpha = 0.05;
end

if ischar(EEG)
    EEG = pop_loadset('filename', [EEG '.set'], 'filepath', filepath);
end

EEG = calcfft(EEG,targetfreq,EEG.pnts);

%% Statistical testing and topoplot

pvals = zeros(EEG.nbchan,1);
teststat = zeros(EEG.nbchan,1);

for ch = 1:EEG.nbchan
    if strcmpi(stattest,'T2')
        N = EEG.trials;

        %Hotelling T2 test
        if ch == 1
            fprintf('Running Hotelling T2 test.\n');
        end
        
        fY = squeeze(max(EEG.Y(ch,EEG.fidx,:),[],2));
        meanfY = mean(fY);
        
        teststat(ch) = ((N-2)/(2*N-2)) * N * [real(meanfY); imag(meanfY)]' * ...
            inv(cov([real(fY)' imag(fY)'])) * [real(meanfY); imag(meanfY)];
        
        teststat(ch) = ((N-2)/(2*N-2)) * teststat(ch);
        df = N-2;
        pvals(ch) = 1 - fcdf(teststat(ch),2,df);
        
    elseif strcmpi(stattest,'T')
        
        if ch == 1
            fprintf('Running T-test.\n');
        end
        
        absY = squeeze(max(abs(EEG.Y(ch,EEG.fidx,:)),[],2));
        
        [~,pvals(ch),~,stats] = ttest(absY,alpha,'right');
        teststat(ch) = stats.tstat;
        
    end
end

[~,pmask] = fdr(pvals,alpha);
pvals(pmask ~= 1) = 1;

plotchans = 1:EEG.nbchan;

fprintf('Plotting topoplot.\n');
figure('Name',mfilename,'Color','white');


% figpos = get(gcf,'Position');
% figpos(3) = figpos(3)*3;
% set(gcf,'Position',figpos);

% subplot(1,3,1);
plotvals = max(EEG.mY(:,EEG.fidx),[],2);
plotvals(pvals >= alpha) = 0;
topoplot(plotvals(plotchans),EEG.chanlocs(plotchans), 'maplimits', 'absmax', 'electrodes','labels');
colorbar
title('Amplitude');

% subplot(1,3,2);
% topoplot(teststat(plotchans),EEG.chanlocs(plotchans), 'maplimits', 'absmax', 'electrodes','labels');
% colorbar
% title('Test Statistic');

% subplot(1,3,3);
%pvals(pvals >= alpha) = alpha;
%pvals(pvals ~= 0) = 1 - pvals(pvals ~= 0);
% 
% topoplot((1-pvals(plotchans)),EEG.chanlocs(plotchans), 'maplimits', [1-alpha 1], 'electrodes','labels');
% h = colorbar; set(h,'YTick',[1-alpha 1],'YTickLabel',{num2str(alpha),'0'});
% title('Significance');

%% FFT Plotting
while true
    dlgopt.Resize='on';
    dlgopt.WindowStyle='normal';
    answers = inputdlg({'Enter chan/comp to FFT:','Enter frequency range to plot:','Enter amplitude range to plot:'},...
        mfilename,1,{'','5 100','0 0.2'},dlgopt);
    
    if isempty(answers)
        return;
    end
    
    channame = answers{1};
    chanidx = find(strcmpi(channame,{EEG.chanlocs.labels}));
    xlim = str2double(answers{2});
    ylim = str2double(answers{3});
    
    %     figure;
    %     scatter(real(fY(chanidx,:)),imag(fY(chanidx,:)));
    
    fprintf('Plotting FFT.\n');
    figure('Name',mfilename,'Color','white');
    plotspec = EEG.mY(chanidx,:);
    plot(EEG.freqbins,plotspec,'LineWidth',1.5);
    
    set(gca,'FontSize',14);
    if exist('xlim', 'var') && ~isempty(xlim)
        set(gca,'XLim',xlim);
    end
    if exist('ylim', 'var') && ~isempty(ylim)
        set(gca,'YLim',ylim);
    end
    
    xlabel('Frequency (Hz)','FontSize',14);
    ylabel('Amplitude (uV)','FontSize',14);
    
    title(sprintf('FFT of channel %s', EEG.chanlocs(chanidx).labels));
    
    box on
    
    if ~isempty(targetfreq)
        hold on;
        maxidx = EEG.fidx(1) + find(max(EEG.mY(chanidx,EEG.fidx)) == EEG.mY(chanidx,EEG.fidx)) - 1;
        plot(EEG.freqbins(maxidx),plotspec(maxidx),'r.', 'MarkerSize',25);
        text(EEG.freqbins(maxidx)+4,plotspec(maxidx), ...
            sprintf('Response at %.1fHz',EEG.freqbins(maxidx)),'FontSize',14);
        hold off;
    end
end
end

function EEG = calcfft(EEG,targetfreq,nfft)

fftdata = EEG.data;
NumUnqiuePoints = ceil((nfft+1)/2);
freqbins = linspace(0,1,NumUnqiuePoints)*(EEG.srate/2);

%% Calculate single trial FFT
fprintf('Calculating %d-point single trial FFT.\n',nfft);
Y = zeros(size(fftdata,1),nfft,size(fftdata,3));

fftwin = rectwin(size(fftdata,2))';
for c=1:size(fftdata,1)
    for e=1:size(fftdata,3)
        Y(c,:,e) = fft(fftwin .* squeeze(fftdata(c,:,e)), nfft);
    end
end
Y = Y(:,1:NumUnqiuePoints,:);
Y = Y/nfft;
if rem(nfft, 2) %multiply by 2 (except DC comp and nyquist freq, if it exists)
    Y(:,2:end,:) = Y(:,2:end,:)*2;
else
    Y(:,2:end-1,:) = Y(:,2:end-1,:)*2;
end

mY = mean(abs(Y),3);

EEG.Y = Y;
EEG.mY = mY;
EEG.freqbins = freqbins;

EEG.fidx = find(abs(EEG.freqbins-targetfreq(1)) == min(abs(EEG.freqbins-targetfreq(1)))):...
    find(abs(EEG.freqbins-targetfreq(end)) == min(abs(EEG.freqbins-targetfreq(end))));

end
