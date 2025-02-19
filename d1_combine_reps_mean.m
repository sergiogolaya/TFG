% Combine 5 EMG repetitions using the mean and visualize with standard deviation

% Define the base directory for normalized EMG data
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Select the .mat file containing the normalized data
[input_file, input_path] = uigetfile(fullfile(base_path, '*.mat'), 'Select Normalized EMG Data File');

% Check if the user canceled the selection
if isequal(input_file, 0)
    error('No file selected.');
end

% Load the selected file
full_file_path = fullfile(input_path, input_file);
load(full_file_path);

% Extract patient identifier from filename
[~, patient_id, ~] = fileparts(input_file);

% Get available muscles from one repetition
muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

% Get repetition names
reps = fieldnames(emg_data_struct.cut_data_normalized);
num_reps = length(reps);

% Initialize structure to store the combined EMG data
combined_emg_struct = struct();

% Create a figure for visualization
figure;
tiledlayout(length(muscles), 1);
sgtitle('EMG Signals Combined (Mean ± Std Dev)');

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Get the number of samples (assuming all reps have the same length)
    sample_length = length(emg_data_struct.cut_data_normalized.rep_1.(muscle_name).envelope);
    
    % Initialize a matrix to store all repetitions
    rep_data = zeros(sample_length, num_reps);
    
    % Extract data from all repetitions
    for i = 1:num_reps
        rep_data(:, i) = emg_data_struct.cut_data_normalized.(reps{i}).(muscle_name).envelope;
    end
    
    % Compute mean and standard deviation
    combined_signal = mean(rep_data, 2);
    std_dev = std(rep_data, 0, 2); % Standard deviation across repetitions
    
    % Store in the struct
    combined_emg_struct.(muscle_name).envelope = combined_signal;
    combined_emg_struct.(muscle_name).std_dev = std_dev;
    
    % Plot the combined signal with standard deviation shading
    nexttile;
    time_vector = 1:sample_length;
    fill([time_vector, fliplr(time_vector)], ...
         [combined_signal - std_dev; flipud(combined_signal + std_dev)], ...
         [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5); % Shaded region
    
    hold on;
    plot(time_vector, combined_signal, 'b', 'LineWidth', 1.5);
    hold off;
    
    title(muscle_name, 'Interpreter', 'none');
    xlabel('Samples');
    ylabel('Amplitude');
    grid on;
    legend('Std Dev', 'Mean', 'Location', 'Best');
end

% Define save directory for the combined data
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';

% Create the directory if it does not exist
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Save the combined EMG data
save_filename = fullfile(save_dir, ['combined_emg_std_' patient_id '.mat']);
save(save_filename, 'combined_emg_struct');

fprintf('PCA-combined EMG data saved to: %s\n', save_filename);
