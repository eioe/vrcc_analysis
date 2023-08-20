
%% Short script to quickly extract the stretches of bad ECG data from the 
% EEGLAB structure and write to a csv

% Set this to the main data folde rof the VRCC project folder:
dir_data = 'S:\Meine Bibliotheken\Experiments\CentralKollegs18\centralkollegs18\Data\';
    
dir_data_peaks = fullfile(dir_data, 'VRTask', 'Cardio', 'ExpSubjects', ...
    '02_Peaks');
dir_bad_ecg_times = fullfile(dir_data_peaks, 'TimesBadECG');
if ~exist(dir_bad_ecg_times, 'dir') 
    mkdir(dir_bad_ecg_times);
    fprintf('Created directory: %s', dir_bad_ecg_times);
end

subs = dir(fullfile(dir_data_peaks, '*.set'));

eeglab;

for i = 1:length(subs)
    fname_in = fullfile(dir_data_peaks, subs(i).name);
    data = pop_loadset(fname_in);
    
    % get bad times and convert to ms:
    t_bad_ecg_ms = data.etc.badECG * 1000;
    
    sub = strsplit(subs(i).name, '.');
    sub_txt = [sub{1} '.txt'];
    fname_out = fullfile(dir_bad_ecg_times, sub_txt);
    fid = fopen(fname_out, 'w+');
    header = fprintf(fid, '%s,%s\n', 'start', 'end');
    fclose(fid);
    dlmwrite(fname_out, t_bad_ecg_ms, 'precision', 20, '-append');
end
    
    