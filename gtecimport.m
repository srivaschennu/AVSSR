function gtecimport(y, eventinfo, segidx, samplingRate, savename)

filepath = 'D:\Data\Integration\';
%montagepath = 'D:\EGI\';
tempfile = [filepath 'temp.mat'];
savefile = [filepath savename '.mat'];

fprintf('Adding trigger channel.\n');
eventidx = intersect(find(cell2mat(eventinfo(3,:)) == segidx), strmatch('TRIG',eventinfo(1,:), 'exact'));
y(end+1,cell2mat(eventinfo(4,eventidx))) = 1;
save(tempfile, 'y');

fprintf('Loading data.\n');
P_C_S=data;
P_C_S=load(P_C_S,tempfile);
P_C_S.SamplingFrequency=samplingRate;

%Trigger
New_tm{1}={P_C_S.NumberChannels 1 'l' 90 1};
SamplesBefore=0;
SamplesAfter=P_C_S.SamplingFrequency;
Uncomplete=0;
ChannelExclude=[];
fprintf('Triggering data.\n');
P_C_S=gBStrigger(P_C_S,New_tm,SamplesBefore,SamplesAfter,Uncomplete,ChannelExclude);
fprintf('Generated %d trials.\n', length(P_C_S.TrialNumber));

fprintf('Deleting trigger channel.\n');
TrialExclude=[];
ChannelExclude=[P_C_S.NumberChannels];
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%baseline
fprintf('Baseline correction.\n');
P_C_S = bc(P_C_S,[0 1]);

fprintf('Saving %s.\n', savefile);
save(savefile,'P_C_S');