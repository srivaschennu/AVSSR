function EEG = epochdata(basename,sweepcode,doica)

loadpaths

keepica = true;

if ~exist('doica','var') || isempty(doica)
    doica = false;
end

if ischar(basename)
    EEG = pop_loadset('filename', [basename '_orig.set'], 'filepath', filepath);
else
    EEG = basename;
end

fprintf('Epoching and baselining.\n');

switch sweepcode
    case 1
        EEG = pop_epoch( EEG, {'STRT'}, [-7 13]);
    case 2
        EEG = pop_epoch( EEG, {'TRIG'}, [0 1]);
        doica = true;
end

EEG = pop_rmbase(EEG,[],[2 EEG.pnts]);

EEG = eeg_checkset( EEG );

if ischar(basename)
    if doica
        EEG.setname = [basename '_epochs'];
        EEG.filename = [basename '_epochs.set'];
    else
        EEG.setname = basename;
        EEG.filename = [basename '.set'];
    end
    
    if doica == true && keepica == true && exist([filepath EEG.filename],'file') == 2
        oldEEG = pop_loadset('filepath',filepath,'filename',EEG.filename,'loadmode','info');
        if isfield(oldEEG,'icaweights') && ~isempty(oldEEG.icaweights)
            fprintf('Loading existing info from %s%s.\n',filepath,EEG.filename);
            
            keepchan = [];
            for c = 1:length(EEG.chanlocs)
                if ismember({EEG.chanlocs(c).labels},{oldEEG.chanlocs.labels})
                    keepchan = [keepchan c];
                end
            end
            EEG = pop_select(EEG,'channel',keepchan);
            
            EEG.icaact = oldEEG.icaact;
            EEG.icawinv = oldEEG.icawinv;
            EEG.icasphere = oldEEG.icasphere;
            EEG.icaweights = oldEEG.icaweights;
            EEG.icachansind = oldEEG.icachansind;
            EEG.reject.gcompreject = oldEEG.reject.gcompreject;
            EEG.rejchan = oldEEG.rejchan;
        end
    end
    
    fprintf('Saving set %s%s.\n',filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', filepath);
end