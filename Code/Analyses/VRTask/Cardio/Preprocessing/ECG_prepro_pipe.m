
%% Extract ECG files for VRCC
% Read in file from BrainProducts format (vhdr) via eeglab and extract
% relevant parameters.
%
%
% requires HEPLAB extension for EEGLAB.
% Get it from here: https://github.com/perakakis/HEPLAB/releases
% and put it manually in the plugin folder of your eeglab install.
% I recommend replacing l.85  in heplab_ecgplot.m with the following 4
% lines to get better scaling of the plotted ECG:
%   sig_span = max(signal) - min(signal);
%   y_spacing = sig_span * 0.1;
%   lims = [min(t) max(t) min(signal) - y_spacing, max(signal) + y_spacing];
%   axis(lims);

% 01 Nov 2019 -- Felix Klotzsche -- eioe

%% Set which steps to run:
b_processRepairedFiles = false; % grab files from subfolder "_repaired"
b_exportTXT = false; % should not be necessary anymore
b_filter = true; % filter te data (0.5 - 40Hz)
b_exportFiltered = false; %save filtered files as TXTs
b_addRPmarkers = true; %add a marker for each R peak

% Plotting:
b_showFilterResult = true;

% other:
b_removePREPpath = true; % avoid masking of findpeaks function if you use PREP

%% Prepare environment:

% make sure you're on the right path:
if ~(contains(pwd, 'VRCC') && exist(fullfile(pwd, '.git'), 'dir'))
    b_done = false;
    m.prompt = sprintf('%s\n%s\n%s\n%s\n', ...
        'Your PWD is on path: ', pwd, ...
        'It should be at the main directory of the centralkollegs18 repository for this script to work.', ...
        'Do you want to continue? Enter (y)es or (n)o');
    m.name='PWD correct?';
    m.numlines=[1];
    m.defaultanswer={'y'};
    while ~b_done
        m.answer = inputdlg(m.prompt, m.name, m.numlines);
        if strcmp(m.answer, 'y')
            b_done = true;
        elseif strcmp(m.answer, 'n')
            b_done = true;
            warning('\n\n%s\n', 'Script execution aborted on user input.')
            return
        end
    end
end

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
dirDataRepaired = fullfile(datFolder, '_repaired');

dirDataTXT = fullfile(datFolder, 'TXTs');
mkdir(dirDataTXT)
%dirDataKubios = fullfile(datFolder, 'KubiosExports');
dirDataFiltered = fullfile(datFolder, '01_Filtered');
mkdir(dirDataFiltered)
dirDataPeaks = fullfile(datFolder, '02_Peaks');
mkdir(dirDataPeaks)
dirDataPeakEvents = fullfile(dirDataPeaks, 'Events');
mkdir(dirDataPeakEvents)
dirDataRaw = fullfile(datFolder, '00_Raw');
mkdir(dirDataRaw)

% Launch eeglab:
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% grab raw files:
if b_processRepairedFiles
    dirDataOrigin = dirDataRepaired;
    files = FileFromFolder(dirDataOrigin, [], 'set');
else
    dirDataOrigin = datFolder;
    files = FileFromFolder(dirDataOrigin, [], 'vhdr');
end

% check if files shall be skipped:
m0.prompt={sprintf('%s\n%s\n%s', ...
    'Do you want to skip files? ', ...
    'If yes enter the according number, ', ...
    'else leave empty.')};
m0.name='More?';
m0.numlines=[1];
m0.defaultanswer=[];
m0.answer = inputdlg(m0.prompt, m0.name, m0.numlines);
if ~isempty(m0.answer{1})
    firstFile = str2num(m0.answer{1}) + 1;
else
    firstFile = 1;
end

for isub = firstFile:size(files,1)
    
    % Get subject ID:
    setname = files(isub).fname;
    fnameRaw = files(isub).name;
    
    % Check if there is already output for this subject:
    if exist(fullfile(dirDataPeakEvents, [setname '.csv']), 'file')
        b_done = false;
        m.prompt = sprintf('%s%s\n%s\n%s\n%s\n%s\n%s\n', ...
            'There exists already a file with R peak events for ', setname, ...
            'Do you still want to run the script for this subject?', ...
            'Choose option:',  ...
            '(y)es run subject', ...
            '(s)kip subject and proceed with next, ', ...
            '(a)bort script execution');
        m.name = 'Subject output exists';
        m.numlines = 1;
        m.defaultanswer={};
        while ~b_done
            m.answer = inputdlg(m.prompt, m.name, m.numlines);
            if strcmp(m.answer, 'y')
                b_done = true;
            elseif strcmp(m.answer, 'a')
                b_done = true;
                return
            elseif strcmp(m.answer, 's')
                b_done = true;
                continue
            end
        end
    end
    
    
    % load file:
    if b_processRepairedFiles
        EEG = pop_loadset(fnameRaw, dirDataOrigin);
    else
        EEG = pop_loadbv(dirDataOrigin, fnameRaw);
    end
    
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
        if b_showFilterResult
            lengthPreview = 300*3;
            plot(EEG.data(1:lengthPreview))
            hold on
        end
        
        fprintf('%s\n\n%s\n\n', '#########################################', ...
            'Start filtering...');
        
        %######################
        % Old filtering:
        %######################
        
        % high-pass filter 0.5 Hz:
        %[c, d] = butter(2,0.5/(EEG.srate/2), 'high');
        %ECGdata = filtfilt(c,d,double(ECGdata));
        %         if b_showFilterResult
        %             plot(ECGdata(1:lengthPreview))
        %             hold on
        %         end
        % low-pass filter 30 Hz:
        %[b, a] = butter(2,30/(EEG.srate/2));
        %ECGdata = filtfilt(b, a, double(ECGdata));
        
        %######################
        %######################
        
        % bandpass filter [0.5; 40] Hz
        EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'hicutoff',40,'plotfreqz',0);
        if b_showFilterResult
            plot(EEG.data(1:lengthPreview))
        end
        
        fprintf('%s\n\n%s\n\n', 'Done with filtering...', ...
            '#########################################');
        
        % crop to relevant parts:
        EEG = crop2blocks(EEG);
        
        % flip polarity:
        EEG.data = EEG.data * -1;
        [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG); % store changes
        
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
            
            %######################
            % old version (shifts data by 1ms imo):
            %######################
            %     tsec=(1:size(ECGdata,2))*(1/EEG.srate);
            %     filename=[path '/Filtered_ecg/' 'VRCC_filt_ecg_' subname '.txt'];
            %     fid=fopen(filename,'w');
            %     fprintf(fid, '%f %f \n', [tsec' ECGdata']');
            %     fclose(fid);
            %######################
        end
    end
    
    %% Add event markers for single R Peaks:
    
    if b_addRPmarkers
        
        eeglab redraw;
        
        % get latencies of automatically (via ecglabfast) detected R peaks:
        latsAuto = heplab_fastdetect(EEG.data(1,:), EEG.srate);
                
        pop_heplab();
        % load the latencies of the auto-detected R peaks:
        HEP.qrs = latsAuto;
        % and refresh:
        heplab;
        
        m.prompt = sprintf('%s\n%s\n%s\n%s\n', ...
            'Do you want to force the R peaks onto the local maxima?', ...
            'Choose option:',  ...
            '(y)es', ...
            '(n)o');
        m.name = 'Correct peaks?';
        m.numlines = 1;
        m.defaultanswer={'n'};
        opts.WindowStyle = 'normal';
        b_done = false;
        while ~b_done
            m.answer = inputdlg(m.prompt, m.name, m.numlines, m.defaultanswer, opts);
            if strcmp(m.answer, 'y')
                HEP = setRPeak2LocMax(HEP, 200);
                heplab;
                b_done = true;
            elseif strcmp(m.answer, 'n')
                b_done = true;
            end
        end
        
        b_done = false;
        m1.prompt={sprintf('Are you done with R Peak detection? (y)es or (n)o:'), ...
            sprintf('%s\n%s\n%s\n%s\n%s', 'Enter bad segments here. Use matrix style: 1 segment per row; ',...
            'seperate start latency (in s) from end latency by comma; ', ...
            'ex.: ', '3456.012, 3466.002', '4444.123, 44450.200')};
        m1.name='Done?';
        m1.numlines=[1; 20];
        m1.defaultanswer={'n', ''};
        opts.WindowStyle = 'normal';
        while ~b_done
            answer = inputdlg(m1.prompt, ...
                m1.name, ...
                m1.numlines, ...
                m1.defaultanswer, ...
                opts);
            
            if strcmp(answer{1}, 'y')
                b_done = true;
            end
        end
        
        % save info about bad ECG signal stretches to SET:
        EEG.etc.badECG = str2num(answer{2});
        
        % save info how many R peaks have manually been changed:
        idxRP = strcmp({EEG.event.type}, 'ECG');
        latsMan = [EEG.event(idxRP).latency];
        EEG.etc.RPeaksAuto = latsAuto;
        EEG.etc.RPeaksManual = latsMan;
        EEG.etc.RPeaksCorrectedPercent = 100 * sum(~ismember(latsAuto, latsMan))/length(latsAuto);
        
        % save to CSV:
        discSamples = 0;
        for irow = 1:size(EEG.etc.badECG)
            row = EEG.etc.badECG(irow,:);
            lat = row(2) - row(1);
            discSamples = discSamples + lat;
        end
        summaryCSV = fullfile(dirDataPeaks, 'processing_summary.csv');
        fid = fopen(summaryCSV, 'a+');
        fprintf(fid, '%s,%f,%g\n', setname, EEG.etc.RPeaksCorrectedPercent, discSamples);
        fclose(fid);
        
        
        % save SET:
        fNamePeaks = strcat(setname, '.set');
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, CURRENTSET);
        EEG = pop_saveset( EEG, 'filename', fNamePeaks, ...
            'filepath', dirDataPeaks);
        
        % export events:
        if sum(strcmp({EEG.event.type}, 'ECG')) > 0
            fNameEvents = fullfile(dirDataPeakEvents, strcat(setname, '.csv'));
            pop_expevents(EEG, fNameEvents, 'samples');
            % move raw files to according subfolder:
            f_list = dir(dirDataOrigin);
            for ifile=1:length(f_list)
                ffile = f_list(ifile);
                if strfind(ffile.name, setname)
                    f2mv = fullfile(dirDataOrigin, ffile.name);
                    movefile(f2mv, dirDataRaw)
                    w_msg = sprintf('%s%s%s\n%s', 'Moving the files of ', setname, ' to folder 00_Raw.' , ...
                        ['If you want to rerun this script for this subject, ' ...
                        'please move them back manually to the parent folder ("ExpSubjects")']);
                    w1 = warndlg(w_msg);
                    waitfor(w1)
                end
            end
        else
            w1 = warndlg(['No R Peaks have been marked. Nothing exported for ',...
                setname]);
            waitfor(w1)
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
    
    % clear environment:
    close all;
    ALLEEG = [];
    EEG = [];
    CURRENTSET = [];
    
    % Run another subj or abort?
    if isub < size(files,1)
        m.prompt = sprintf('%s\n%s\n%s\n%s\n', ...
            'Do you want to run another subject?', ...
            'Choose option:',  ...
            '(y)es run another subject', ...
            '(a)bort script execution');
        m.name = 'One more?';
        m.numlines = 1;
        m.defaultanswer={};
        b_done = false;
        while ~b_done
            m.answer = inputdlg(m.prompt, m.name, m.numlines);
            if strcmp(m.answer, 'y')
                b_done = true;
            elseif strcmp(m.answer, 'a')
                b_done = true;
                warning('\n\n%s\n', 'Script execution aborted on user input.')
                return
            end
        end
    end
    
end

fprintf('\n\n%s\n\n%s\n\n', '#########################################', ...
    'All subjects are done.');

