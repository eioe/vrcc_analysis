
%% Load File for VRCC
% Read in file from BrainProducts format (vhdr) via eeglab and transform in
% usable shape. 
% 

% 14 Feb 2019 -- Felix Klotzsche -- eioe
%%

% get file manually (expects to be in centalkollegs18/Code/Data/VRTask/Cardio)
[fname fpath] = uigetfile(fullfile('../../../../../Data/VRTask/Cardio', ...
    '*.vhdr'), ...
    'select VHDR file');

% request setname:
fprintf('\n\n ########################## \n');
fprintf('Enter Setname: \n');
setname = input('Confirm with ENTER.\n', 's');

% load eeglab:
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% load file:
EEG = pop_loadbv(fpath, fname);
% delete channel 'Photodiode':
EEG = pop_select( EEG,'channel',{'ECG'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',setname,...
    'gui','off'); 

% Delete file ending:
fname = strsplit(fname, '.');
fname = fname{1};

% export as TXT file (decrese precision, transpose):
pop_export(EEG,[fpath '/TXTs/' fname '.txt'], ...
    'transpose', 'on', ... 
    'time', 'on', ...  %column with time info
    'elec', 'off', ... %no colnames
    'timeunit', 1);    %time in sec

eeglab redraw;

keyboard;

load([fpath '/KubiosExports/' fname '_hrv.mat'])

 %% Othe rmethod:
    %Get the latencies (data point indices) for all 'A' type events...
A_latencies = Res.HRV.Data.T_RR;

%for each A_latencies add a new event type '1' with a latency of (A_latencies(i)+1.5*EEG.srate)-1...
for i=1:length(A_latencies)
    n_events=length(EEG.event);
    EEG.event(n_events+1).type='RP';
    EEG.event(n_events+1).latency=(A_latencies(i)*1000)-1;
    EEG.event(n_events+1).urevent=n_events+1;
end

%check for consistency and reorder the events chronologically...
EEG=eeg_checkset(EEG,'eventconsistency');

EEG = pop_saveset(EEG, [fpath '/SETwithRPeaks/' fname]);
