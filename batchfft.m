function batchfft(EEG,targetfreq,channame,xlim,ylim)

filepath = '/Users/chennu/Data/Integration_blocked/';

if ischar(EEG)
    EEG = pop_loadset('filename', [EEG '.set'], 'filepath', filepath);
end

%refchannels = [57 100];
refchannels = [];

%chanexcl = [1,8,14,17,21,25,32,38,43,44,48,49,56,57,63,64,68,69,73,74,81,82,88,89,94,95,99,100,107,113,114,119,120,121,125,126,127,128];
chanexcl = [];

statwin = 8;
stattest = 'T2';
% stattest = 'T2CIRC';
% stattest = 'SPEC';
alpha = 0.05;

%% find bad channels
if isfield(EEG.chanlocs,'badchan')
    badchannels = find(cell2mat({EEG.chanlocs.badchan}));
    fprintf('Found %d bad channels:',length(badchannels));
    fprintf(' %d',badchannels);
    fprintf('.\n');
else
    fprintf('No bad channel info found.\n');
    badchannels = [];
end

%% re-refrence
if ~isempty(refchannels)
    EEG = pop_reref(EEG,refchannels,'exclude',badchannels,'keepref','on');
else
        chanlocs = [cell2mat({EEG.chanlocs.X})' cell2mat({EEG.chanlocs.Y})' cell2mat({EEG.chanlocs.Z})'];
        EEG.data = permute(lar(permute(EEG.data,[3 2 1]), chanlocs, badchannels),[3 2 1]);
    %EEG = pop_reref(EEG,[],'exclude',badchannels);
end

% fprintf('Filtering.\n');
% EEG = pop_eegfilt(EEG,48,52,[],1);
% EEG = pop_eegfilt(EEG,98,102,[],1);
% EEG.data = reshape(EEG.data, EEG.nbchan, EEG.pnts, EEG.trials);

%% Calculate single-trial FFT
fprintf('Calculating FFT.\n');
Y = zeros(EEG.nbchan,EEG.pnts,EEG.trials);

for c=1:EEG.nbchan
    for e=1:EEG.trials
        Y(c,:,e) = fft(squeeze(EEG.data(c,:,e)));
    end
end

NFFT = EEG.pnts;
NumUnqiuePoints = ceil((NFFT+1)/2);
Y = Y(:,1:NumUnqiuePoints,:);
freqs = linspace(0,1,NumUnqiuePoints)*(EEG.srate/2);

fprintf('Averaging %d trials.\n', EEG.trials);

%% Averaging

%variance weighted average
if ~isempty(targetfreq)
    filtEEG = pop_eegfilt(EEG, targetfreq(1)-10, targetfreq(end)+10, [], [0], 0, 0, 'fir1', 0);
    filtEEG.data = reshape(filtEEG.data,filtEEG.nbchan,filtEEG.pnts,filtEEG.trials);
    trvar = squeeze(var(permute(filtEEG.data,[2 1 3])));
else
    trvar = squeeze(var(permute(EEG.data,[2 1 3])));
end

avY = zeros(size(EEG.data,1),size(EEG.data,2));
for ch = 1:EEG.nbchan
    for t = 1:EEG.trials
        avY(ch,:) = avY(ch,:) + (EEG.data(ch,:,t) ./ trvar(ch,t));
    end
    avY(ch,:) = avY(ch,:) ./ sum(1./trvar(ch,:));
end

%normal average
%avY = mean(EEG.data,3);

%% Calculate mean FFT

avY = fft(avY')';
avY = avY(:,1:NumUnqiuePoints);
avY = avY/NFFT; %scale magnitude by length of FFT
%avY = avY.^2; %square mag to get power

if rem(NFFT, 2) %multiply power by 2 (except DC comp and nyquist targetfreq, if it exists)
    avY(:,2:end) = avY(:,2:end)*2;
else
    avY(:,2:end-1) = avY(:,2:end-1)*2;
end
mY = abs(avY); %get magnitude

%% Statistical testing
if ~isempty(targetfreq)
    fidx = find(freqs >= targetfreq(1) & freqs <= targetfreq(end));
    
    nidx = fidx(1)-statwin:fidx(end)+statwin;
    nidx = setdiff(nidx,fidx);
    %fprintf('Statistical testing of %.1f-%.1fHz power within %.1f-%.1fHz.\n',freqs(fidx(1)),freqs(fidx(end)),freqs(nidx(1)),freqs(nidx(end)));
    
    fY = squeeze(max(Y(:,fidx,:),[],2));
    F = zeros(EEG.nbchan,1);
    N = EEG.trials;
    
    for ch = 1:EEG.nbchan
        meanfY = mean(fY(ch,:));
        
        if strcmp(stattest,'T2')
            %Hotelling T2 test
            if ch == 1
                fprintf('Running Hotelling T2 test.\n');
            end
            F(ch) = ((N-2)/(2*N-2)) * N * [real(meanfY); imag(meanfY)]' * ...
                inv(cov([real(fY(ch,:))' imag(fY(ch,:))'])) * [real(meanfY); imag(meanfY)];
            df = N-2;
        elseif strcmp(stattest,'T2CIRC')
            %T2circ test
            if ch == 1
                fprintf('Running circular T2 test.\n');
            end
            
            F(ch) = N * (N-1) * (real(meanfY)^2 + imag(meanfY)^2) ...
                / sum( (real(fY(ch,:)) - real(meanfY)).^2 + (imag(fY(ch,:)) - imag(meanfY)).^2 );
            df = 2*N-2;
        elseif strcmp(stattest, 'SPEC')
            %Adjacent spectral window test
            if ch == 1
                fprintf('Running adjacent spectral window test within %.1f-%.1fHz.\n',freqs(nidx(1)),freqs(nidx(end)));
            end
            F(ch) = length(nidx) * ( real(max(avY(ch,fidx)))^2 + imag(max(avY(ch,fidx)))^2 ) ./ ...
                sum(real(avY(ch,nidx)).^2 + imag(avY(ch,nidx)).^2);
            df = 2*length(nidx);
        end
    end
    p = 1 - fcdf(F,2,df);
    
    [~,pmask] = fdr(p,alpha);
    p(pmask ~= 1) = 1;

    %chanincl = EEG.idx1020;
    %    plotchans = setdiff(plotchans,badchannels);
    %    plotchans = intersect(plotchans, find(p < alpha));
    
    plotvals = max(mY(:,fidx),[],2);
    plotvals(chanexcl) = 0;
    plotvals(badchannels) = 0;
    plotvals(p>=alpha) = 0;
    plotchans = setdiff(1:EEG.nbchan,chanexcl);
    %powervals = (powervals - min(powervals)) ./ (max(powervals) - min(powervals));
    fprintf('Plotting topoplot.\n');
    figure; topoplot(plotvals(plotchans),EEG.chanlocs(plotchans), 'maplimits', 'absmax', 'electrodes','labels');
    colorbar
    %p(p>alpha) = 1;
    %p(p ~= 0) = 1 - p(p ~= 0);
    %figure; topoplot(p(plotchans),EEG.chanlocs(plotchans), 'maplimits', [0 1], 'electrodes','labels');
    %colorbar
end

%% Plotting
if exist('channame','var') && ~isempty(channame)
    chanidx = find(strcmpi(channame,{EEG.chanlocs.labels}));
    
    fprintf('Plotting FFT.\n');
    figure; plot(freqs,mY(chanidx,:),'LineWidth',2);
    if exist('xlim', 'var') && ~isempty(xlim)
        set(gca,'XLim',xlim);
    end
    if exist('ylim', 'var') && ~isempty(ylim)
        set(gca,'YLim',ylim);
    end
    
    xlabel('Frequency (Hz)');
    ylabel('Amplitude (uV)');
    title(sprintf('FFT at %s', EEG.chanlocs(chanidx).labels));
    box on
    
    if ~isempty(targetfreq)
        hold on;
        [~, maxidx] = max(mY(chanidx,nidx(1):nidx(end)));
        maxidx = nidx(1)+maxidx-1;
        plot(freqs(maxidx),mY(chanidx,maxidx),'r.', 'MarkerSize',25);
        text(freqs(maxidx)+4,mY(chanidx,maxidx),['Response at ',num2str(freqs(maxidx)), 'Hz']);
        hold off;
    end
end
