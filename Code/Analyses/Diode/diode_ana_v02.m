

%% Load File for VRCC
% Read in file from BrainProducts format (vhdr) via eeglab and transform in
% usable shape. 
% 

% 8 Jan 2018 -- Felix Klotzsche -- eioe
%%

% get file manually (expects to be in centalkollegs18/Code/Analyses/Diode)
[fname fpath] = uigetfile(fullfile('../../../Data/VRTask/Cardio', '*.vhdr'), ...
    'select VHDR file');

% request setname:
fprintf('\n\n ########################## \n');
fprintf('Enter Setname: \n');
setname = input('Confirm with ENTER.\n', 's');

% load eeglab:
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% load file:
EEG = pop_loadbv(fpath, fname);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
% low-pass filter (FIR, 20Hz):
EEG = pop_eegfiltnew(EEG, [], 50); %, 330, 0, [], 1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',setname,'gui','off'); 
eeglab redraw;


pport = [EEG.event.latency];
pport = pport(2:end);
pport = reshape(pport,[length(pport),1]);
diode = EEG.data(2,:);
diode = reshape(diode,[length(diode),1]);

% Create output matrix
dif = [];

% Define threshold factor
tfac = 2;
% define sliding window:
tmin = 50;
tmax = 50;

% Loop through parallel port activation
for i = 1:length(pport)
    
    % Timestamp for parallel port (PP) activation
    ppval = pport(i,1);
    
    curSig = diode(ppval-tmin : ppval+tmax);
    
    % Calculate diode threshold from mean diode signal
    %thresh = tfac * mean(diode(ppval - 180: ppval + 20));
    threshMin = median(curSig) - 2*std(curSig);
    threshMax = median(curSig) + 2*std(curSig);
          
    % Find first signal value in interval which exceeds threshold
    index = find((curSig < threshMin | curSig > threshMax), 1);
    
    % Different strategy: Diode signal leads to large increase in value
    % Find value which is largest factorial increase over previous value
    % Leads to identical results
    %----------------
    % [M,I] = max(diode(ppval-99:ppval+100)./diode(ppval-100:ppval+99));
    % divalfac = ppval - 100 + I;
    % dif(i,4) = divalfac;
    %----------------
    
    % Define timestamp for detected event
    dival = ppval - tmin + index - 1;
    
    % Save output values
    dif(i,1) = ppval;
    
    % If no fititng value could be found in interval, set missing
    if isempty(dival)
        dif(i,2) = -1;
        dif(i,3) = -1;
    else
        dif(i,2) = dival;
        dif(i,3) = dival - ppval;
    end
end


for i=1:size(dif,1) 
    n_events = length(EEG.event);
    EEG.event(n_events+1).type = '235';
    EEG.event(n_events+1).latency = dif(i,2);
    EEG.event(n_events+1).urevent=n_events+1;
end
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[setname '_epo'],'gui','off');
EEG = pop_epoch( EEG, {'S  1'}, [-0.5 0.5], 'newname', '70hz epochs', 'epochinfo', 'yes');
eeglab redraw;
erpel = mean(EEG.data(2,:,:), 3);
plot([1:1000/EEG.srate:1000], erpel);

starts = find(strcmp('S  1', {EEG.event.type}));
ends = find(strcmp('S  2', {EEG.event.type}));
slat = [EEG.event(starts).latency];
elat = [EEG.event(ends).latency];
trigDist = mean(elat-slat);

hold on
vline([500 500+trigDist*1000/EEG.srate])