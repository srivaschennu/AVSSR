function EEG = epochdata(basename)

loadpaths

keepica = true;

if ischar(basename)
    EEG = pop_loadset('filename', [basename '_orig.set'], 'filepath', filepath);
else
    EEG = basename;
end

eventidx = find(strcmp('TRIG',{EEG.event.type}));
eventidx = eventidx(1:5:end);

fprintf('Epoching and baselining.\n');
EEG = pop_epoch( EEG, [], [0 5],'eventindices',eventidx);

EEG = pop_rmbase(EEG,[],[2 EEG.pnts]);

EEG = eeg_checkset( EEG );

if ischar(basename)
    %EEG.setname = [basename '_epochs'];
    %EEG.filename = [basename '_epochs.set'];
    
    EEG.setname = basename;
    EEG.filename = [basename '.set'];
    
%     oldEEG = pop_loadset('filepath',filepath,'filename',EEG.filename);
%     EEG = pop_mergeset(oldEEG,EEG);
%     fprintf('merged data has %d epochs.\n',EEG.trials);
    
    if keepica == true && exist([filepath EEG.filename],'file') == 2
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
        end
    end
    fprintf('Saving set %s%s.\n',filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', filepath);
end