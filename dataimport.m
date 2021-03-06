function dataimport(basename)

loadpaths

filenames = dir(sprintf('%s%s*', filepath, basename));

if isempty(filenames)
    error('No files found to import!\n');
end

mfffiles = filenames(logical(cell2mat({filenames.isdir})));
if length(mfffiles) > 1
    error('Expected 1 MFF recording file. Found %d.\n',length(mfffiles));
else
    filename = mfffiles.name;
    fprintf('\nProcessing %s.\n\n', filename);
    EEG = pop_readegimff(sprintf('%s%s', filepath, filename));
end

EEG = eeg_checkset(EEG);

%%%% PRE-PROCESSING


%Remove excluded channels

chanexcl = [1,8,14,17,21,25,32,38,43,44,48,49,56,63,64,68,69,73,74,81,82,88,89,94,95,99,107,113,114,119,120,121,125,126,127,128];
%chanexcl = [];

fprintf('Removing excluded channels.\n');
EEG = pop_select(EEG,'nochannel',chanexcl);

%Downsample to 250Hz
if EEG.srate > 250
    EEG = pop_resample(EEG,250);
end

%Filter
hpfreq = 1;
lpfreq = 95;
fprintf('Low-pass filtering below %.1fHz...\n',lpfreq);
EEG = pop_eegfiltnew(EEG, 0, lpfreq);
fprintf('High-pass filtering above %.1fHz...\n',hpfreq);
EEG = pop_eegfiltnew(EEG, hpfreq, 0);


fprintf('Removing line noise at 50Hz.\n');
EEG = rmlinenoisemt(EEG);


EEG.setname = sprintf('%s_orig',basename);
EEG.filename = sprintf('%s_orig.set',basename);
EEG.filepath = filepath;

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);
pop_saveset(EEG,'filename', EEG.filename, 'filepath', EEG.filepath);

