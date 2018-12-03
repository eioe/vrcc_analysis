%------------------
% Load data
cd ..\..\..
load Data\dummyDiodeData_03_withDelays.mat
pport = [EEG.event.latency];
pport = pport(2:end);
pport = reshape(pport,[length(pport),1]);
diode = EEG.data(2,:);
diode = reshape(diode,[length(diode),1]);
%------------------

%------------------
% Create output matrix
dif = [];

% Define threshold factor
tfac = 2;

% Loop through parallel port activation
for i = 1:length(pport)
    
    % Timestamp for parallel port (PP) activation
    ppval = pport(i,1);
    
    % Calculate diode threshold from mean diode signal
    thresh = tfac * mean(diode(ppval - 100: ppval + 100));
          
    % Find first signal value in interval which exceeds threshold
    index = find(diode(ppval - 100: ppval + 100) > thresh, 1);
    
    % Different strategy: Diode signal leads to large increase in value
    % Find value which is largest factorial increase over previous value
    % Leads to identical results
    %----------------
    % [M,I] = max(diode(ppval-99:ppval+100)./diode(ppval-100:ppval+99));
    % divalfac = ppval - 100 + I;
    % dif(i,4) = divalfac;
    %----------------
    
    % Define timestamp for detected event
    dival = ppval - 100 + index - 1;
    
    % Save output values
    dif(i,1) = ppval;
    
    % If no fititng value could be found in interval, set missing
    if isempty(dival)
        dif(i,2) = "NA";
        dif(i,3) = "NA";
    else
        dif(i,2) = dival;
        dif(i,3) = dival - ppval;
    end
end
%------------------




