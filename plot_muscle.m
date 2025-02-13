% Define the path to the normalized data folder
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Use a file selection dialog to choose the .mat file
[input_file, input_path] = uigetfile(fullfile(base_path, '*.mat'), 'Select Normalized EMG Data File');

% Check if the user canceled the selection
if isequal(input_file, 0)
    error('No file selected');
end

% Load the selected file
full_file_path = fullfile(input_path, input_file);
load(full_file_path);

% Extract the main struct (assuming it is stored in 'data')
emg_data_struct = data.emg_data_struct;

% Get available muscles
muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

% Let the user select a muscle
[muscle_index, is_selected] = listdlg('PromptString', 'Select a muscle:', ...
                                      'SelectionMode', 'single', ...
                                      'ListString', muscles);

% Check if the user made a selection
if ~is_selected
    error('No muscle selected.');
end

% Get the selected muscle name
muscle_name = muscles{muscle_index};

% Get repetition names
reps = fieldnames(emg_data_struct.cut_data_normalized);

% Initialize matrix to store envelope data (num_reps x time_points)
num_reps = length(reps);
all_reps_data = zeros(num_reps, 1000); % Assuming all have 1000 time points

% Extract envelope data from each repetition
for r = 1:num_reps
    rep_name = reps{r};
    all_reps_data(r, :) = emg_data_struct.cut_data_normalized.(rep_name).(muscle_name).envelope;
end

% Plot all repetitions for the selected muscle
figure;
hold on;
colors = lines(num_reps); % Generate distinct colors for each repetition
for r = 1:num_reps
    plot(1:1000, all_reps_data(r, :), 'Color', colors(r, :), 'LineWidth', 1.5);
end
hold off;
title(['EMG Envelopes for ' muscle_name ' (All Repetitions)']);
xlabel('Time Points');
ylabel('EMG Envelope Amplitude');
legend(reps, 'Location', 'Best');
