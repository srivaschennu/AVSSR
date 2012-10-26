function plotcomp(basename,freqband)

loadpaths

filename = [basename '_epochs.set'];
EEG = pop_loadset('filename', filename, 'filepath', filepath);

data = (EEG.icaweights*EEG.icasphere)*reshape(EEG.data(EEG.icachansind,:,:), length(EEG.icaweights(1,:)), EEG.trials*EEG.pnts);
data = reshape( data, size(data,1), EEG.pnts, EEG.trials);
[spectra,freqs] = spectopo(data,EEG.pnts,EEG.srate,'plot','off');

meanpwr = zeros(size(spectra,1),2);
meanpwr(:,1) = meanpwr(:,1) + mean(spectra(:,freqs >= freqband(1) & freqs <= freqband(2)),2);
meanpwr(:,2) = meanpwr(:,2) + mean(spectra(:,freqs >= (freqband(1)-1) & freqs <= (freqband(2)-1)),2);


meanpwr = meanpwr(:,1) - meanpwr(:,2);
mpwridx = find(meanpwr > 0);
meanpwr = meanpwr(mpwridx);
[~,sortorder] = sort(meanpwr,'descend');
sortorder = mpwridx(sortorder);

rejectic(basename,'sortorder',sortorder');