function dataimport(filename)

filepath = '/Users/chennu/Data/Integration_blocked/';
chanlocdir = '/Users/chennu/Work/EGI/';
chanlocfile = 'GSN-HydroCel-129.sfp';

stimparam = load('param.mat');

fprintf('Importing data from %s%s.\n', filepath, filename);

EEG = pop_readegi([filepath filename]);

fprintf('Importing chanlocs from %s%s.\n', chanlocdir, chanlocfile);
EEG = fixegilocs(EEG,[chanlocdir chanlocfile]);
EEG.stimparam = stimparam;
EEG = eeg_checkset( EEG );

fprintf('Filtering.\n');
EEG = pop_eegfilt(EEG,5,0);
EEG = pop_eegfilt(EEG,0,200);
% notchlist = [50 100 150 200];
% notchwidth = 5;
% for f = notchlist
%     fprintf('\nNotch filtering between %d-%dHz.\n', f-notchwidth, f+notchwidth);
%     EEG = pop_eegfilt(EEG,f-notchwidth,f+notchwidth,[],1);
% end

fprintf('Epoching and baselining.\n');
%EEG = pop_epoch( EEG, {'STRT'}, [0 20], 'newname', setname);
EEG = pop_epoch( EEG, {'TRIG'}, [0 1], 'newname', filename);
EEG = pop_rmbase(EEG,[],[1 EEG.pnts]);

%EEG = eeg_detrend(EEG);

EEG = eeg_checkset( EEG );
fprintf('Saving set %s%s.set.\n',filepath,filename);
pop_saveset(EEG,'filename', filename, 'filepath', filepath);
