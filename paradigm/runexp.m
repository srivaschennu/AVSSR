function runexp(paramfile)

tStart = tic;

fprintf('Loading parameters.\n');

%load common parameters
load('param.mat');

%load stimulation specific parameters
stimparam = load(paramfile);

choice = questdlg('Connect to Net Station?','runexp','Yes','No','Yes');

switch choice
    case 'Yes'
        if exist('nshost','var') && ~isempty(nshost)
            %connect to netstation
            fprintf('Connecting to NetStation at %s:%d.\n', nshost, nsport);
            [nsstatus, nserror] = NetStation('Connect',nshost,nsport);
            if nsstatus ~= 0
                fprintf('ERROR: Could not connect to NetStation host %s:%d.\n%s\n', ...
                    nshost, nsport, nserror);
                return;
            end
            NetStation('Synchronize');
        end
    case 'No'
    otherwise
end

if stimparam.LEST || stimparam.REST
    %connect to DMX
    fprintf('Initialising audio.\n');
    InitializePsychSound
    
    if PsychPortAudio('GetOpenDeviceCount') == 1
        PsychPortAudio('Close',0);
    end
    
    audiodevices = PsychPortAudio('GetDevices',3);
    outdevice = strcmp('DMX 6Fire USB ASIO Driver',{audiodevices.DeviceName});
    pahandle = PsychPortAudio('Open',audiodevices(outdevice).DeviceIndex,[],[],f_sample,2);
    
    %construct amplitude modulated wave for left ear
    if stimparam.LEST == 1
        fprintf('Left ear: Fs %dHz, Fc %dHz, Fm %dHz.\n', f_sample,stimparam.LEFC,stimparam.LEFM);
        leftdata = amfm(f_sample,stimparam.LEFC,stimparam.LEFM,sweepon);
    else
        leftdata = zeros(f_sample*sweepon,1);
    end
    
    %construct amplitude modulated wave for right ear
    if stimparam.REST == 1
        fprintf('Right ear: Fs %dHz, Fc %dHz, Fm %dHz.\n', f_sample,stimparam.REFC,stimparam.REFM);
        rightdata = amfm(f_sample,stimparam.REFC,stimparam.REFM,sweepon);
    else
        rightdata = zeros(f_sample*sweepon,1);
    end
    
    %concatenate right ear and left ear stimulation
    stimdata = cat(2,leftdata,rightdata);
    
    %prepare audio buffer
    PsychPortAudio('FillBuffer',pahandle,stimdata');

    mb_handle = msgbox({'Ensure that:','','-  Inset earphone jack is connected to the Terratec box, NOT the laptop',...
        '- "Waveplay 1/2" volume in the panel below is set to -18dB'},'AVSSR','warn');
    boxpos = get(mb_handle,'Position');
    set(mb_handle,'Position',[boxpos(1) boxpos(2)+125 boxpos(3) boxpos(4)]); 
    system('C:\Program Files\TerraTec\DMX6FireUSB\DMX6FireUSB.exe');
    if ishandle(mb_handle)
        uiwait(mb_handle);
    end
    
end

if stimparam.LIST || stimparam.RIST
    %connect to goggles controller
    fprintf('Connecting to goggles port 0x%s.\n', gogglesport);
    gogglesport = hex2dec(gogglesport);
    
    gogglesportobj = io32;
    gogglesportstatus = io32(gogglesportobj);
    
    if gogglesportstatus ~= 0
        fprintf('Could not open goggles port.\n');
        return;
    end
    
    %initialise googles and set up mode
    io32(gogglesportobj,gogglesport,0);
    mb_handle = msgbox('Put goggles on participant and press OK to continue.','Message');
    uiwait(mb_handle);
    
    if stimparam.LIST == 1 && stimparam.RIST == 0
        fprintf('Left eye on.\n');
        visual_state = 1;
    elseif stimparam.LIST == 0 && stimparam.RIST == 1
        fprintf('Right eye on.\n');
        visual_state = 2;
    elseif stimparam.LIST == 1 && stimparam.RIST == 1
        fprintf('Left and right eyes on.\n');
        visual_state = 3;
    end
    
    mb_handle = msgbox({'Put goggles on participant and press OK to continue.'},'AVSSR','warn');
    if ishandle(mb_handle)
        uiwait(mb_handle);
    end
end
 
%start recording
NetStation('StartRecording');

%starttime and stoptime relative to inittime
begintime = 1;
inittime = GetSecs;

%send begin marker containing stimulation parameters
cmdstr = 'NetStation(''Event'', ''BGIN'', GetSecs, 0.001';
fnlist = fieldnames(stimparam);
for fn = 1:length(fnlist)
    cmdstr = [cmdstr ', ''' fnlist{fn} ''', ' num2str(getfield(stimparam,fnlist{fn}))];
end
cmdstr = [cmdstr ');'];
eval(cmdstr);

%wait till begintime
while GetSecs < inittime + begintime
end

fprintf('Starting stimulation: %d runs with %d sweeps of %d sec.\n', ...
    numruns, numsweeps, sweepon);

fprintf('Run/Sweep: 00/00');
for run = 1:numruns
    for sweep = 1:numsweeps
        fprintf('\b\b\b\b\b%02d/%02d', run, sweep);
        
        starttime = GetSecs;
        stoptime = GetSecs + sweepon;
                
        if stimparam.LEST || stimparam.REST
            %start sound
            starttime = PsychPortAudio('Start',pahandle,1,0,1);
            stoptime = starttime + sweepon;
        end
        
        if stimparam.LIST || stimparam.RIST
            %start googles
            io32(gogglesportobj,gogglesport,visual_state);
        end
        
        %send start marker
        NetStation('Event', 'STRT', starttime, 0.001, 'RNUM',run,'SNUM',sweep);
        
        %send first trigger
        markertime = starttime;
        NetStation('Event', 'TRIG', starttime);
        
        %wait till stoptime
        while GetSecs <= stoptime
            if GetSecs - markertime >= markerinterval && GetSecs + 0.1 <= stoptime
                markertime = GetSecs;
                NetStation('Event', 'TRIG', markertime);
            end
        end
        
        if stimparam.LIST || stimparam.RIST
            %stop goggles
            io32(gogglesportobj,gogglesport,0);
        end
        
        %send stop marker
        NetStation('Event','STOP', GetSecs, 0.001, 'RNUM',run,'SNUM',sweep);
        
        stoptime = GetSecs + sweepoff;
        
        %wait for 'sweepoff' seconds
        while GetSecs <= stoptime
        end
    end
    
    stoptime = GetSecs + runoff;
    
    %wait for 'runoff' seconds
    while GetSecs <= stoptime
    end
end
fprintf('\n');

fprintf('Stopping stimulation.\n');

%stop recording
NetStation('StopRecording');

%close serial port
if stimparam.LIST || stimparam.RIST
    %close goggles port
    clear io32
end

%close audio device
if stimparam.LEST || stimparam.REST
    PsychPortAudio('Close',pahandle);
end

fprintf('Run took %.1f minutes.\n', toc(tStart) / 60);