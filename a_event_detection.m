%% Load EMG Data
clear; clc; close all;

base_path = 'C:\\Users\\sergi\\Documents\\CEU\\TFG\\medidas\\patients\\raw';
[input_file, ~] = uigetfile(fullfile(base_path, '*.xlsx'), 'Select EMG Data File');
if isequal(input_file, 0)
    error('No file selected');
end
file_path = fullfile(base_path, input_file);
raw_data = readmatrix(file_path);
time_vector = raw_data(:, 1); % Time column
emg_data = raw_data(:, 2:end); % EMG data columns
[num_samples, num_channels] = size(emg_data);

%% Define Parameters
Fs = 2148; % Sampling frequency in Hz
low_cut = 20; % Low cut-off frequency (Hz)
high_cut = 450; % High cut-off frequency (Hz)
order = 4; % Filter order
[b, a] = butter(order/2, [low_cut, high_cut] / (Fs/2), 'bandpass');

% Adaptive Notch Filter for Power Line Interference (50 Hz)
wo = 50 / (Fs/2);
bw = wo / 35;
[bn, an] = iirnotch(wo, bw);

%% Filter and Process EMG Data
filtered_emg = zeros(size(emg_data));
rectified_emg = zeros(size(emg_data));
envelope_emg = zeros(size(emg_data));

for i = 1:num_channels
    emg_data(:, i) = filtfilt(bn, an, emg_data(:, i));
    filtered_emg(:, i) = filtfilt(b, a, emg_data(:, i));
    rectified_emg(:, i) = abs(filtered_emg(:, i));
    [b_env, a_env] = butter(4, 8 / (Fs/2), 'low');
    envelope_emg(:, i) = filtfilt(b_env, a_env, rectified_emg(:, i));
end

%% Store Original Data in Struct
emg_data_struct = struct();
emg_data_struct.time = time_vector;
for i = 1:num_channels
    emg_data_struct.original.(sprintf('muscle_%d', i)).raw = emg_data(:, i);
    emg_data_struct.original.(sprintf('muscle_%d', i)).filtered = filtered_emg(:, i);
    emg_data_struct.original.(sprintf('muscle_%d', i)).rectified = rectified_emg(:, i);
    emg_data_struct.original.(sprintf('muscle_%d', i)).envelope = envelope_emg(:, i);
end

%% Detect Repetitions (Movement Events) Using Adaptive Percentile-Based Thresholding
event_list = [];

for j = 1:num_channels
    % Compute an adaptive percentile dynamically for each muscle
    adaptive_percentile = min(98, max(80, 90 + (std(envelope_emg(:, j)) / mean(envelope_emg(:, j)) - 1) * 10));
    
    % Compute percentile-based threshold for this muscle channel
    percentile_threshold = prctile(envelope_emg(:, j), adaptive_percentile);

    % Apply threshold-based event detection
    above_thresh = envelope_emg(:, j) > percentile_threshold;
    
    % Detect start and end of activity
    diff_signal = diff([0; above_thresh; 0]);
    starts = find(diff_signal == 1);
    ends = find(diff_signal == -1) - 1;
    
    % Ensure indices are within valid range
    starts = starts(starts <= length(time_vector));
    ends = ends(ends <= length(time_vector));

    % Store detected movement events
    event_list = [event_list; starts, ends];
end

% Remove duplicate/overlapping events across channels
event_list = sortrows(event_list);
event_list = event_list(diff([0; event_list(:,1)]) > 0.05 * Fs, :); % Merge very close detections

%% Clustering Approach to Merge Events
average_rep_duration = mean(event_list(:,2) - event_list(:,1));
min_gap = max(0.3 * Fs, min(average_rep_duration * 0.5, 1.0 * Fs));
min_duration = 0.1 * Fs;

if ~isempty(event_list)
    event_centers = mean(event_list, 2);
    Z = linkage(event_centers, 'single');
    cluster_labels = cluster(Z, 'cutoff', min_gap, 'criterion', 'distance');

    unique_clusters = unique(cluster_labels);
    rep_events = [];
    for i = 1:length(unique_clusters)
        cluster_indices = find(cluster_labels == unique_clusters(i));
        cluster_start = min(event_list(cluster_indices, 1));
        cluster_end = max(event_list(cluster_indices, 2));

        if (cluster_end - cluster_start) >= min_duration
            rep_events = [rep_events; cluster_start, cluster_end];
        end
    end
end

%% Manual Selection of Regions
disp('Select the start and end region for each repetition (10 clicks: 5 start-end pairs).');
figure;
hold on;
plot(time_vector, envelope_emg(:, 3), 'b', 'DisplayName', 'EMG Envelope');
ylim([0 max(envelope_emg(:, 3))]); % Dynamically scale y-axis based on actual envelope data
title('Detected Events (After Clustering)' , 'FontSize', 18);
xlabel('Time (s)')
ylabel('EMG Amplitude (V)')

for k = 1:size(rep_events, 1)
    x_patch = [time_vector(rep_events(k, 1)); time_vector(rep_events(k, 2)); 
               time_vector(rep_events(k, 2)); time_vector(rep_events(k, 1))];
    y_patch = [0; 0; 1; 1] * max(envelope_emg(:, 3));
    patch(x_patch, y_patch, 'r', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

[x, ~] = ginput(10); % User selects exactly 10 points (5 start-end pairs)
plot(x, zeros(size(x)), 'gx', 'MarkerSize', 10, 'LineWidth', 2);
hold off;

%% Adjust Repetitions Using First and Last Index in Selected Range
user_selected_reps = [];
for i = 1:2:length(x)-1
    [~, idx_start] = min(abs(time_vector - x(i)));
    [~, idx_end] = min(abs(time_vector - x(i+1)));

    
    % Search for all detected events within the selected range
    valid_starts = rep_events(:,1);
    valid_ends = rep_events(:,2);
    
    indices_in_range = (valid_starts >= idx_start & valid_ends <= idx_end);
    valid_starts_in_range = valid_starts(indices_in_range);
    valid_ends_in_range = valid_ends(indices_in_range);
    
    if isempty(valid_starts_in_range) || isempty(valid_ends_in_range)
        continue; % If there are no events within the range, continue
    end

    % Tke the first and last index within the range
    refined_start = min(valid_starts_in_range);
    refined_end = max(valid_ends_in_range);

    user_selected_reps = [user_selected_reps; refined_start, refined_end];
end

%% Store Cut Data in Struct
emg_data_struct.cut_data = struct();
for rep = 1:size(user_selected_reps, 1)
    for i = 1:num_channels
        idx_start = user_selected_reps(rep, 1);
        idx_end = user_selected_reps(rep, 2);
        
        emg_data_struct.cut_data.(sprintf('rep_%d', rep)).(sprintf('muscle_%d', i)).raw = emg_data(idx_start:idx_end, i);
        emg_data_struct.cut_data.(sprintf('rep_%d', rep)).(sprintf('muscle_%d', i)).filtered = filtered_emg(idx_start:idx_end, i);
        emg_data_struct.cut_data.(sprintf('rep_%d', rep)).(sprintf('muscle_%d', i)).rectified = rectified_emg(idx_start:idx_end, i);
        emg_data_struct.cut_data.(sprintf('rep_%d', rep)).(sprintf('muscle_%d', i)).envelope = envelope_emg(idx_start:idx_end, i);
    end
end

%% Plot Final Trimmed Repetitions from Struct
figure;
hold on;
plot(emg_data_struct.time, emg_data_struct.original.muscle_3.envelope, 'b', 'DisplayName', 'EMG Envelope');
ylim([0 max(emg_data_struct.original.muscle_3.envelope)]); % Dynamically adjust y-axis

% Plot the final trimmed repetitions using the stored struct
if isfield(emg_data_struct, 'cut_data') && ~isempty(fieldnames(emg_data_struct.cut_data))
    num_reps = length(fieldnames(emg_data_struct.cut_data));
else
    warning('No cut data found. Skipping final verification plot.');
    return; % Exit the script to avoid further errors
end

for rep = 1:num_reps
    idx_start = user_selected_reps(rep, 1);
    idx_end = user_selected_reps(rep, 2);

    % Create shaded region for each repetition
    x_patch = [emg_data_struct.time(idx_start); emg_data_struct.time(idx_end); 
               emg_data_struct.time(idx_end); emg_data_struct.time(idx_start)];
    y_patch = [0; 0; 1; 1] * max(emg_data_struct.original.muscle_3.envelope);
    patch(x_patch, y_patch, 'g', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
end

title('Final Adjusted Repetitions (After Manual Selection)', 'FontSize', 18);
xlabel('Time (s)');
ylabel('Amplitude (V)');
legend('EMG Envelope', 'Final Movement Regions');
hold off;

%% Save Struct to .mat File
output_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\postprocessed';
[~, file_name, ~] = fileparts(input_file); % Extract filename without extension
output_file = fullfile(output_path, strcat('processed_', file_name, '.mat'));
save(output_file, 'emg_data_struct');
disp(['Data saved to ', output_file]);