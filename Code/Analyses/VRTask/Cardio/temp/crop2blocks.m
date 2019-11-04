function EEG = crop2blocks(EEG)
%CROP2BLOCKS Crop VRCC data to data recorded during the experimental
%blocks.
%
%   Aloows you to get rid of noisy data recorded before/after the start/end
%   of the session and during the breaks.
%   It uses following heuristic to do that:
%
%   Marker 'S 11' >>> indicates beginning of each trial
%
%   Time of first event -10s: Start of session
%   Time of last event +10s: End of session
%   Calculate latencies between S11 markers
%   Use beginning and end of top 5 latencies as start/end of breaks


offsetStart = 1;
offsetEnd = 8; % longer as it also has to embrace the length of the last trial.

idx_trialStarts = find(ismember({EEG.event.type}, {'S 11'}));
idx_first = idx_trialStarts(1);
idx_last = idx_trialStarts(end);
sessStartLat = EEG.event(idx_first).latency - offsetStart * EEG.srate;
sessEndLat = EEG.event(idx_last).latency + offsetEnd * EEG.srate;


trialStarts = [EEG.event(idx_trialStarts).latency];
tDiffTrialStarts = trialStarts(2:end) - trialStarts(1:end-1);
if verLessThan('matlab', '9.1')
    [diffs idx] = sort(tDiffTrialStarts, 'descend');   
else
    [diffs idx] = maxk(tDiffTrialStarts, 5);
end


breakParts = [];
for i = 1:5
    breakParts(i,1) = trialStarts(idx(i)) + offsetEnd * EEG.srate;
    breakParts(i,2) = trialStarts(idx(i)+1) - offsetStart * EEG.srate;
end

% add part before session start and after its end:
breakParts(end+1,:) = [1 sessStartLat];
breakParts(end+1,:) = [sessEndLat length(EEG.times)];

% Crop off everything:
EEG = eeg_eegrej(EEG, breakParts); % remove data


end

