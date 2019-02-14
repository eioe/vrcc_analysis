    % extract event labels and time stamps
    allEventLabels = repmat({'S25'}, 1, length(RTs));
    eventTimeStamp = RTs; %


    % import event markers and latency to EEG.event
    allEventLatency = num2cell((eventTimeStamp-1));
    allUrevent      = num2cell(1:length(allEventLatency));
    EEG.event = struct('type', {}, 'latency',{}, 'urevent',{});
    [EEG.event(1,1:length(allEventLabels)).latency] = allEventLatency{:};
    [EEG.event(1,1:length(allEventLabels)).type]    = allEventLabels{:};
    [EEG.event(1,1:length(allEventLabels)).urevent] = allUrevent{:};
    EEG = eeg_checkset(EEG,'eventconsistency');
    
    
    %% Othe rmethod:
    %Get the latencies (data point indices) for all 'A' type events...
A_latencies=RTs(1:1000);

%for each A_latencies add a new event type '1' with a latency of (A_latencies(i)+1.5*EEG.srate)-1...
for i=1:length(A_latencies);
    n_events=length(EEG.event);
    EEG.event(n_events+1).type='1';
    EEG.event(n_events+1).latency=(A_latencies(i)*1000)-1;
    EEG.event(n_events+1).urevent=n_events+1;
end

%check for consistency and reorder the events chronologically...
EEG=eeg_checkset(EEG,'eventconsistency');