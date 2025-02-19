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

% Define mapping between descriptive muscle names and struct field names
muscle_names = { ...
    'Biceps Brachii', 'muscle_1'; ...
    'Triceps Brachii', 'muscle_2'; ...
    'Front Deltoid', 'muscle_3'; ...
    'Trapezius', 'muscle_4'; ...
    'Lateral Deltoid', 'muscle_5'; ...
    'Posterior Deltoid', 'muscle_6'; ...
    'Palmaris Longus', 'muscle_7'; ...
    'Extensor Carpi Radialis', 'muscle_8' ...
};

% Let the user select a muscle
[muscle_index, is_selected] = listdlg('PromptString', 'Select a muscle:', ...
                                      'SelectionMode', 'single', ...
                                      'ListString', muscle_names(:,1));

% Check if the user made a selection
if ~is_selected
    error('No muscle selected.');
end

% Get the selected muscle's corresponding field name
selected_muscle_name = muscle_names{muscle_index, 1};
selected_muscle_field = muscle_names{muscle_index, 2};

% Get repetition names
reps = fieldnames(emg_data_struct.cut_data_normalized);
num_reps = length(reps);

% Get the number of time points (assuming all have the same length)
sample_length = length(emg_data_struct.cut_data_normalized.rep_1.(selected_muscle_field).envelope);

% Initialize matrix to store envelope data (num_reps x time_points)
all_reps_data = zeros(num_reps, sample_length);

% Extract envelope data from each repetition
for r = 1:num_reps
    rep_name = reps{r};
    all_reps_data(r, :) = emg_data_struct.cut_data_normalized.(rep_name).(selected_muscle_field).envelope;
end

% Plot all repetitions for the selected muscle
figure;
hold on;
colors = lines(num_reps); % Generate distinct colors for each repetition
for r = 1:num_reps
    plot(1:sample_length, all_reps_data(r, :), 'Color', colors(r, :), 'LineWidth', 1.5);
end
hold off;
title(['EMG Envelopes for ' selected_muscle_name ' (All Repetitions)']);
xlabel('Time Points');
ylabel('EMG Envelope Amplitude');
legend(reps, 'Location', 'Best');
grid on;
