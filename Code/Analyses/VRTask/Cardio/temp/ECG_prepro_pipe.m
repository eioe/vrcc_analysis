
%% Extract ECG files for VRCC
% Read in file from BrainProducts format (vhdr) via eeglab and extract
% relevant parameters.
% 

% 23 Oct 2019 -- Felix Klotzsche -- eioe

%% Set which steps to run:
b_exportTXT = false;
b_filterAndExp = false;
b_addRPmarkers = false;
b_showFilterResult = false;

%% Prepare environment:
% (set pwd to be the repository folder)
datFolder = fullfile('.', 'Data', 'VRTask', 'Cardio', 'ExpSubjects');

dirDataTXT = fullfile(datFolder, 'TXTs');
mkdir(dirDataTXT)
dirDataPeaks = fullfile(datFolder, 'SETwithRPeaks');
mkdir(dirDataPeaks)
dirDataFiltered = fullfile(datFolder, 'Filtered_ecg');
mkdir(dirDataFiltered)

% Launch eeglab:
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% grab raw files:
files = FileFromFolder(datFolder, [], 'vhdr');

for f=1:size(files,1)

    setname = files(f).fname;
    fnameRaw = files(f).name;

    % load file:
    EEG = pop_loadbv(datFolder, fnameRaw);
    
    % pick ECG channel:
    EEG = pop_select( EEG,'channel',{'ECG'});
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'setname', setname,...
        'gui','off'); 

    %% This section is for debugging / uncommnet for proper analysis
    %     markerCount = (sum(strcmp({EEG.event.type}, marker)));
    %     markerCountS42 = (sum(strcmp({EEG.event.type}, 'S 42')));
    %     fprintf([setname ' -- Found Marker ' marker ' %i times.'], markerCount);
    %     markerCountStruct(f).file = setname;
    %     markerCountStruct(f).count = markerCount;
    %     markerCountStruct(f).countS42 = markerCountS42;    

    %% Export TXTs:
    if b_exportTXT
        % export as TXT file (decrese precision, transpose):
        fnameTXT = fullfile(dirDataTXT, [setname, '.txt']);
        pop_export(EEG, fnameTXT, ...
            'transpose', 'on', ... 
            'time', 'on', ...  %column with time info
            'elec', 'off', ... %no colnames
            'timeunit', 1);    %time in sec
    end

    %% Filter data and export TXT to facilitate T-wave detection:
    
    ECGdata=EEG.data;
    if b_showFilterResult
        lengthPreview = 30000;
        plot(EEG.times(ECGdata(1:lengthPreview))
        hold on
    end
    % high-pass filter 0.5 Hz:
    [c,d]=butter(2,0.5/(EEG.srate/2),'high'); 
    ECGdata=filtfilt(c,d,double(ECGdata)); 
    if b_showFilterResult
        plot(ECGdata(1:30000))
        hold on
    end
    % low-pass filter 30 Hz:
    [b,a]=butter(2,30/(EEG.srate/2)); 
    ECGdata=filtfilt(b,a,double(ECGdata)); 
    if b_showFilterResult
         plot(ECGdata(1:lengthPreview))
    end
    
    % overwrite data:
    EEG.data = ECGdata; 
    nameParts = string(strsplit(setname, '_'));
    setnameFilt = [nameParts(1) '_filt_ecg_' nameParts(2)];
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
        'setname', setnameFilt, ...
        'gui','off'); 
    
    % export as TXT file (decrese precision, transpose):
    fnameFilt = fullfile(dirDataFiltered, [setnameFilt, '.txt']);
    pop_export(EEG, fnameFilt, ...
        'transpose', 'on', ... 
        'time', 'on', ...  %column with time info
        'elec', 'off', ... %no colnames
        'timeunit', 1);    %time in sec

    % old version (shifts data by 1ms imo):
%     tsec=(1:size(ECGdata,2))*(1/EEG.srate);
%     filename=[path '/Filtered_ecg/' 'VRCC_filt_ecg_' subname '.txt'];
%     fid=fopen(filename,'w');
%     fprintf(fid, '%f %f \n', [tsec' ECGdata']');
%     fclose(fid);
end