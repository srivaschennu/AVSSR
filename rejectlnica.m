function rejectln(filename)

filepath = '/Users/chennu/Data/Integration_blocked/';

global EEG
EEG = pop_loadset('filename', [filename '.set'], 'filepath', filepath);

% find bad channels
if isfield(EEG.chanlocs,'badchan')
    badchannels = find(cell2mat({EEG.chanlocs.badchan}));
    fprintf('Found %d bad channels:',length(badchannels));
    fprintf(' %d',badchannels);
    fprintf('.\n');
else
    fprintf('No bad channel info found.\n');
    badchannels = [];
end

goodchannels = setdiff(1:EEG.nbchan,badchannels);
EEG = pop_runica(EEG, 'icatype','sobi','dataset',1,'chanind',goodchannels,'options',{'extended' 1});

%iccount = 10;
contribthresh = 0.01;
%while true
[~, ~, ~, contrib] = pop_spectopo(EEG, 0, [EEG.xmin EEG.xmax]*1000, 'EEG' , 'freq', 50, ...
    'plotchan', 0, 'icacomps', 1:size(EEG.icaweights,1), 'plot','off');

%[contrib, sortidx] = sort(contrib,'descend');

%     fprintf('\nTop %d ICs with line noise: ', iccount);
%     fprintf('comp%d, ', sortidx(1:iccount-1));
%     fprintf('comp%d\n\n', sortidx(iccount));

%     EEG = VisEd(EEG,2,['[' num2str(sortidx) ']'],{});
%     uiwait

EEG.reject.gcompreject = zeros(1,size(EEG.icaweights,1));
EEG.reject.gcompreject(contrib >= contribthresh) = 1;

fprintf('\n%d ICs marked for rejection: ', sum(EEG.reject.gcompreject));
fprintf('\n\n');
%
%      rejectics = find(EEG.reject.gcompreject);
%     if ~isempty(rejectics)
%         fprintf('comp%d, ',rejectics(1:end-1));
%         fprintf('comp%d\n\n',rejectics(end));
%     end

if sum(EEG.reject.gcompreject) > 0
    EEG = pop_subcomp( EEG, find(EEG.reject.gcompreject), 0);
    EEG = eeg_checkset(EEG);
    EEG.saved = 'no';
    
    %         EEG = VisEd(EEG,1,['[1:' num2str(EEG.nbchan) ']'],{});
    %         uiwait
end

%     choice = questdlg('View ICA components again?', 'rejectica', 'Yes', 'No', 'Yes');
%
%     switch choice
%         case 'Yes'
%         case 'No'
%             break
%         otherwise
%             break
%     end
% end

fprintf('Saving %s%s.set.\n', filepath, filename);
pop_saveset(EEG, 'savemode', 'resave');