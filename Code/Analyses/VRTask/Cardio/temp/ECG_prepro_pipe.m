
%% Extract ECG files for VRCC
% Read in file from BrainProducts format (vhdr) via eeglab and extract
% relevant parameters.
% 
%
% requires HEPLAB extension for EEGLAB.
% Get it from here: https://github.com/perakakis/HEPLAB/releases
% and put it manually in the plugin folder of your eeglab install.

% 23 Oct 2019 -- Felix Klotzsche -- eioe

%% Set which steps to run:
b_exportTXT = false;
b_filter = true;
b_exportFiltered = false;
b_addRPmarkers = true;

% Plotting:
b_showFilterResult = true;

% other:
b_removePREPpath = true;
%% Prepare environment:
%remove PREP pipeline folder (problem with its findpeaks function):
if b_removePREPpath
    path_fp = which('findpeaks');
    if contains(path_fp, 'PrepPipeline')
        path_fp = strsplit(path_fp, 'findpeaks');
        path_fp = path_fp{1};
        rmpath(path_fp)
        warning([path_fp ' was removed from your current MATLAB path.'])
    end
end

% (set pwd to be the repository folder!)
datFolder = fullfile('.', 'Data', 'VRTask', 'Cardio', 'ExpSubjects');

dirDataTXT = fullfile(datFolder, 'TXTs');
mkdir(dirDataTXT)
dirDataKubios = fullfile(datFolder, 'KubiosExports');
dirDataPeaks = fullfile(datFolder, 'SETwithRPeaks');
mkdir(dirDataPeaks)
dirDataFiltered = fullfile(datFolder, 'Filtered_ecg');
mkdir(dirDataFiltered)
dirDataPeaks = fullfile(datFolder, '02_Peaks');
mkdir(dirDataPeaks)
dirDataPeakEvents = fullfile(dirDataPeaks, 'Events');
mkdir(dirDataPeakEvents)

% Launch eeglab:
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% grab raw files:
files = FileFromFolder(datFolder, [], 'vhdr');

% check if files shall be skipped:
m0.prompt={sprintf('%s\n%s\n%s', ...
        'Do you want to skip files? ', ...
        'If yes enter the according number, ', ...
        'else leave empty.')};
m0.name='More?';
m0.numlines=[1];
m0.defaultanswer=[];
m0.answer = inputdlg(m0.prompt, m0.name, m0.numlines);
if ~isempty(m0.answer)
    firstFile = m0.answer + 1;
else
    firstFile = 1;
end

b_stopexec = false;
for isub = firstFile:size(files,1)
    
    % Check if we shall do another round:
    if b_stopexec
        break
    end
    
    setname = files(isub).fname;
    fnameRaw = files(isub).name;

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
    % can probably be deprecated if HEPlab based R peak detection works
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
    if b_filter
        
        ECGdata = EEG.data;
        if b_showFilterResult
            lengthPreview = 30000;
            plot(ECGdata(1:lengthPreview))
            hold on
        end
        % high-pass filter 0.5 Hz:
        [c, d] = butter(2,0.5/(EEG.srate/2), 'high'); 
        ECGdata = filtfilt(c,d,double(ECGdata)); 
        if b_showFilterResult
            plot(ECGdata(1:30000))
            hold on
        end
        % low-pass filter 30 Hz:
        [b, a] = butter(2,30/(EEG.srate/2)); 
        ECGdata = filtfilt(b, a, double(ECGdata)); 
        if b_showFilterResult
             plot(ECGdata(1:lengthPreview))
        end

        % overwrite data:
        EEG.data = ECGdata; 
        % set name:
        if verLessThan('matlab', '9.1')
            nameParts = strsplit(setname, '_');           
        else
            nameParts = strsplit(setname, '_');
        end
        setnameFilt = strcat(char(nameParts(1)), '_filt_ecg_', char(nameParts(2)));
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, ...
            'setname', setnameFilt); 
        
        if b_exportFiltered
            % export as TXT file (decrese precision, transpose):
            fnameFilt = fullfile(dirDataFiltered, strcat(setnameFilt, '.txt'));
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
    end
    
    %% Add event markers for single R Peaks:
    
    EEG = crop2blocks(EEG);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % store changes
    
    pop_heplab(); 

    b_done = false;
    m1.prompt={sprintf('Are you done with R Peak detection? (y)es or (n)o:'), ...
        sprintf('%s\n%s\n%s\n%s\n%s', 'Enter bad segments here. Use matrix style: 1 segment per row; ',...
        'seperate start latency (in s) from end latency by comma; ', ...
        'ex.: ', '3456.012, 3466.002', '4444.123, 44450.200')};
    m1.name='Done?';
    m1.numlines=[1; 20];
    m1.defaultanswer={'no', ''};
    while ~b_done
        answer = inputdlg(m1.prompt, m1.name, m1.numlines);
        if strcmp(answer, 'y')
            b_done = true;
        end
    end
    
    % save info about bad ECG signal stretches to SET:
    EEG.etc.badECG = str2num(answer{2});
    
    % save SET:
    fNamePeaks = strcat(setname, '.set');
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, CURRENTSET);
    EEG = pop_saveset( EEG, 'filename', fNamePeaks, ...
        'filepath', dirDataPeaks);
        
    % export events:
    if sum(strcmp({EEG.event.type}, 'ECG')) > 0
        fNameEvents = fullfile(dirDataPeakEvents, strcat(setname, '.csv'));
        pop_expevents(EEG, fNameEvents, 'samples');
    else
        w1 = warndlg(['No R Peaks have been marked. Nothing exported for ',... 
            setname]);
        waitfor(w1)
    end
    
    % Check if we shall abort:
    b_done = false;
    m2.prompt={sprintf('%s%s\n%s\n%s\n%s', ...
        'Done with subject ', setname, ...
        'Do you want to continue: (y)es or (n)o ', ...
        'y: continue with next subject', 'n: quit script')};
    m2.name='More?';
    m2.numlines=[1];
    m2.defaultanswer={y};
    while ~b_done
        m2.answer = inputdlg(m2.prompt, m2.name, m2.numlines);
        if strcmp(m2.answer, 'y')
            b_done = true;
        elseif strcmp(m2.answer, 'n')
            b_done = true;
            b_stopexec = true;                
        end
    end
    
    
    % Following stuff can prob be discarded.
    
%     % get info from Kubios export:
%     % can prob be deprecated once HEPlab version works

%     fpattern = fullfile(dirDataKubios, ['*' setname '*.mat']);
%     fnameKub = dir(fpattern);
%     fnameKub = fullfile(dirDataKubios, fnameKub.name);
%     
%     dataKubios = load(fnameKub, 'Res');
%     timesRPeak = dataKubios.Res.HRV.Data.T_RR;
%     
%     for i=1:length(timesRPeak)
%         n_events=length(EEG.event);
%         EEG.event(n_events+1).type='RP';
%         % add 1 since latency is in samples, 
%         % i.e. latency 0 (ms) -> sample 1
%         latency = (timesRPeak(i)*EEG.srate) + 1;
%         % check that transformation from time in s to samples is clean:
%         if mod(latency, 1)
%             t_shift = min([rem(latency, 1), 1-rem(latency, 1)]);
%             % our dataset (as of 24 Oct 2019) includes many latencies with 
%             % .5ms which probably stems from downsampling (in Kubios?). 
%             % Visual inspection reveals that rounding does better than 
%             % flooring (eeglab default).
%             latency = round(latency);
%             warning([setname ': R Peak timing was shifted by (ms): ' num2str(t_shift)])
%         end            
%         EEG.event(n_events+1).latency = latency;
%         EEG.event(n_events+1).urevent = n_events+1; 
%     end
% 
%    
    

end