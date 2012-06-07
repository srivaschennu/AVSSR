function playsample(ch,fc,fm,len)

fs = 44100;
%connect to DMX
if playrec('isInitialised') == 1
    playrec('reset');
end
playrec('init',fs,0,-1);

if playrec('isInitialised') ~= 1
    fprintf('ERROR: Could not initialise audio device.\n');
    return;
end

if strcmp(ch,'left')
    leftdata = amfm(fs,fc,fm,len);
    rightdata = zeros(fs*len,1);
elseif strcmp(ch,'right')
    leftdata = zeros(fs*len,1);
    rightdata = amfm(fs,fc,fm,len);
end

stimdata = [leftdata rightdata];

playrec('play',stimdata,[1 2]);
playrec('block');
playrec('reset');