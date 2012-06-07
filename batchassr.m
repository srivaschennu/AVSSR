function batchassr(basename,refchannels,chanidx,xlim,ylim)

filepath = 'D:\Data\Integration\';

if ~exist(filepath,'dir')
    filepath = '';
end

datafile = [filepath basename '.mat'];

fprintf('Loading %s.\n',datafile);
load(datafile);
SamplingFrequency = P_C_S.SamplingFrequency;

[~, badchannels] = findbadtrialschannels(P_C_S);

y = P_C_S.Data;
P_C_S.Data = permute(reref(permute(y,[3 2 1]),refchannels,'exclude',badchannels,'keepref','on'),[3 2 1]);

TrialExclude=[];
ChannelExclude=setdiff(P_C_S.Channels,chanidx);
P_C_S=gBScuttrialschannels(P_C_S,TrialExclude,ChannelExclude);

%Average
Baseline=1;
Smoothing={'none'};
DownSampling=0;
TrialExclude=[];
ChannelExclude=[];
FileName='';
Averaging='simple';
var1=0;
var2=0;
var3=0;
fprintf('Averaging %d trials.\n',length(P_C_S.TrialNumber));
A_O = gBSaverage(P_C_S,Baseline,Smoothing,DownSampling,TrialExclude,ChannelExclude,FileName,Averaging,0,var1,var2,var3);

y=A_O.mean;
save('tempavg.mat','y')

%Load Data
fprintf('Loading average.\n');
P_C_S=data;
P_C_S=load(P_C_S,'tempavg.mat');
P_C_S.SamplingFrequency=SamplingFrequency;

%Spectrum
ActionBegin=1;
RefBegin=[];
IntervalLength=P_C_S.SamplingFrequency;
Window='boxcar';
DownSampling=0;
TrialExclude=[];
ChannelExclude=[];
FileName='';
fprintf('Plotting spectrum.\n');
S_O=gBSspectrum(P_C_S,ActionBegin,RefBegin,IntervalLength,Window,DownSampling,TrialExclude,ChannelExclude,FileName,0);

scrsz = get(0,'ScreenSize');
figdim = [1024 768];
figure('Position',[(scrsz(3)-figdim(1))/2 (scrsz(4)-figdim(2))/2 figdim(1) figdim(2)]);
plot((1:length(S_O.pxx_action)).*S_O.deltafrequency, S_O.pxx_action);

if ~isempty(xlim)
    set(gca,'XLim', xlim);
end
if ~isempty(ylim)
    set(gca,'YLim',ylim);
end

xlabel('Frequency (Hz)');
ylabel('uV^2');
box on
grid on
title(sprintf('Frequency spectrum for %s', basename),'Interpreter','none');

%plotfft(y, P_C_S.SamplingFrequency, xlim, []);