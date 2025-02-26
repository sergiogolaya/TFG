% ==================================================
% Dynamic Time Warping (DTW) Alignment Script
% ==================================================
% This script applies DTW to align EMG data across repetitions
% for each subject and saves the aligned EMG data.
%
% INPUT:  Normalized EMG data (cut_data_normalized struct per subject)
% OUTPUT: DTW-aligned EMG data saved in .mat format
%
% Author: Sergio García Olaya
% ==================================================

clc; clear; close all;

% Define directories
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\aligned_dtw';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Get all normalized data files
file_list = dir(fullfile(data_dir, '*.mat'));

% Loop through each subject's file
for i = 1:length(file_list)
    % Load subject file
    file_path = fullfile(data_dir, file_list(i).name);
    loaded_data = load(file_path);
    
    % Extract EMG struct
    emg_data_struct = loaded_data.emg_data_struct;
    
    % Get available muscles
    muscle_fields = fieldnames(emg_data_struct.cut_data_normalized.rep_1);
    num_muscles = numel(muscle_fields);
    
    % Get repetition names
    reps = fieldnames(emg_data_struct.cut_data_normalized);
    num_reps = length(reps);
    
    % Initialize structure for aligned data
    aligned_data = struct();
    
    % Process each muscle separately
    for m = 1:num_muscles
        muscle_name = muscle_fields{m};
        
        % Extract all repetitions for this muscle
        rep_signals = zeros(1000, num_reps);
        for r = 1:num_reps
            rep_signals(:,r) = emg_data_struct.cut_data_normalized.(reps{r}).(muscle_name).envelope;
        end

        % Compute median signal as reference
        ref_signal = median(rep_signals, 2);

        % Apply DTW alignment
        for r = 1:num_reps
            aligned_data.(muscle_name).(reps{r}).envelope = dtwAlign(rep_signals(:,r), ref_signal);
        end
    end
    
    % Save aligned data
    [~, filename, ~] = fileparts(file_list(i).name);
    save(fullfile(save_dir, ['aligned_' filename '.mat']), 'aligned_data');

    fprintf('DTW-aligned EMG saved for %s\n', filename);
end

disp('DTW alignment completed for all subjects.');

%% **Fixed DTW Alignment Function**
function aligned_signal = dtwAlign(signal, ref_signal)
    % Apply Dynamic Time Warping (DTW) to align EMG signals to a reference
    
    % Normalize both signals
    signal = signal / max(abs(signal));
    ref_signal = ref_signal / max(abs(ref_signal));
    
    % Compute DTW alignment
    [~, ix, iy] = dtw(signal, ref_signal);
    
    % Ensure unique indices for interpolation
    [iy, unique_idx] = unique(iy, 'stable');
    ix = ix(unique_idx);
    
    % Use gridded interpolation instead of interp1
    F = griddedInterpolant(double(iy), double(signal(ix)), 'linear', 'none');
    aligned_signal = F(1:length(ref_signal));
    
    % Handle NaNs (caused by out-of-bound interpolation)
    aligned_signal(isnan(aligned_signal)) = mean(aligned_signal, 'omitnan');
end
