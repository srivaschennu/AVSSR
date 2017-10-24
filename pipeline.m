function pipeline(basename)

loadpaths

% dataimport(basename);
% epochdata(basename,4);
% rejartifacts([basename '_epochs'],1,4);
% computeic([basename '_epochs']);
% epochdata(basename,1);
rejectic(basename);
rejartifacts([basename '_clean'],2,4);
rereference(basename,3);

EEG = pop_loadset('filepath',filepath,'filename',[basename '.set']);

fttest(EEG,36);
fttest(EEG,78);
fttest(EEG,44);
fttest(EEG,84);

fttest(EEG,[15 17])
fttest(EEG,[19 21])

end