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

% Extract patient identifier from filename (assuming a pattern like "patient_X.mat")
[~, patient_id, ~] = fileparts(input_file);

% Get available muscles from one repetition
muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

% Get repetition names
reps = fieldnames(emg_data_struct.cut_data_normalized);
num_reps = length(reps);

% Initialize structure to store DTW results
dtwResults = struct();

% Define save directory
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\dtw_analysis';

% Ensure the directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Initialize DTW matrix
    dtw_matrix = zeros(num_reps, num_reps);

    % Compute DTW distances between all repetitions
    for i = 1:num_reps
        for j = i:num_reps
            % Extract EMG envelopes for two repetitions
            sig1 = emg_data_struct.cut_data_normalized.(reps{i}).(muscle_name).envelope;
            sig2 = emg_data_struct.cut_data_normalized.(reps{j}).(muscle_name).envelope;

            % Compute DTW distance
            dtw_matrix(i, j) = dtw(sig1, sig2);
            dtw_matrix(j, i) = dtw_matrix(i, j); % Ensure symmetry
        end
    end

    % Store results in structure
    dtwResults.(muscle_name) = dtw_matrix;
    
    % Display results
    fprintf('DTW Distance Matrix for %s:\n', muscle_name);
    disp(dtw_matrix);

    % Plot heatmap of DTW distances
    figure;
    imagesc(dtw_matrix);
    colormap jet;
    colorbar;
    title(['DTW Distance Matrix for ' muscle_name]);
    xlabel('Repetition');
    ylabel('Repetition');
    axis square;
end

% Construct the filename with the patient identifier
save_filename = fullfile(save_dir, ['dtwResults_' patient_id '.mat']);

% Save results in the specified directory
save(save_filename, 'dtwResults');

fprintf('DTW results saved to: %s\n', save_filename);
