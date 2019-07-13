

% check files for markers:

datFolder = '.\Data\VRTask\Cardio\ExpSubjects\';
files = FileFromFolder(datFolder, [], 'vhdr');
marker = 'S 41';
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

for f=1:size(files,1)

    setname = files(f).name;

    % load file:
    EEG = pop_loadbv(datFolder, setname);
    % delete channel 'Photodiode':
    EEG = pop_select( EEG,'channel',{'ECG'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',setname,...
        'gui','off'); 

    %% This section is for debugging / uncommnet for proper analysis
    markerCount = (sum(strcmp({EEG.event.type}, marker)));
    markerCountS42 = (sum(strcmp({EEG.event.type}, 'S 42')));
    fprintf([setname ' -- Found Marker ' marker ' %i times.'], markerCount);
    markerCountStruct(f).file = setname;
    markerCountStruct(f).count = markerCount;
    markerCountStruct(f).countS42 = markerCountS42;
    
end