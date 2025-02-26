% Combine 5 EMG repetitions using Principal Component Analysis (PCA) with enhanced features

% Define the base directory for normalized EMG data
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Select the .mat file containing the normalized data
[input_file, input_path] = uigetfile(fullfile(base_path, '*.mat'), 'Select Normalized EMG Data File');

% Check if the user canceled the selection
if isequal(input_file, 0)
    error('No file selected');
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

% Initialize structure to store the PCA-combined EMG data
combined_emg_struct = struct();

% Create a figure for visualization
enable_plots = true;
if enable_plots
    figure;
    tiledlayout(length(muscles), 2);
    sgtitle(['EMG Signals Combined Using PCA - ' patient_id]);
end

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
    
    % Apply Principal Component Analysis (PCA)
    [coeff, score, explained] = pca(rep_data);
    pca_signal = score(:, 1); % Use the first principal component
    
    % Store the combined signal
    combined_emg_struct.(muscle_name).envelope = pca_signal;
    combined_emg_struct.(muscle_name).explained_variance = explained(1);
    
    % Plot PCA result if enabled
    if enable_plots
        % Plot First Principal Component
        nexttile;
        plot(pca_signal, 'r', 'LineWidth', 1.5);
        title([muscle_name ' - PCA (PC1)'], 'Interpreter', 'none');
        xlabel('Samples');
        ylabel('Amplitude');
        grid on;
        
        % Plot Explained Variance of Principal Components
        nexttile;
        bar(explained);
        title([muscle_name ' - Explained Variance'], 'Interpreter', 'none');
        xlabel('Principal Component');
        ylabel('Variance Explained (%)');
        grid on;
    end
end

% Define save directory for the combined data
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\pca_combined_emg';

% Create the directory if it does not exist
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Save the PCA-combined EMG data
save_filename = fullfile(save_dir, ['combined_emg_PCA_' patient_id '.mat']);
save(save_filename, 'combined_emg_struct');

fprintf('PCA-combined EMG data saved to: %s\n', save_filename);
