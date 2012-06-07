function EEG = changeref(EEG,badchannels)

% [~, badchannels] = findbadtrialschannels(P_C);
% chanlocs = [P_C.XPosition' P_C.YPosition' P_C.ZPosition'];

%local average reference (laplacian operator)
% P_C.Data = lar(P_C.Data,chanlocs,badchannels);

%common average reference
% Data = permute(P_C.Data,[3 2 1]);
% Data = reref(Data,[],'exclude',badchannels);
% P_C.Data = permute(Data,[3 2 1]);

%linked mastoid reference
if EEG.nbchan == 129
    mastoidchannels = 57;%[57 100];
elseif EEG.nbchan == 257
    mastoidchannels = [94 190];
end

%EEG = pop_reref(EEG,mastoidchannels,'exclude',badchannels,'keepref','on');
EEG = pop_reref(EEG,[],'exclude',badchannels);