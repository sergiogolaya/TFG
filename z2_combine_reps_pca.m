% Combine EMG repetitions using Principal Component Analysis (PCA)
% for all files in the dtw_aligned directory.

clear; clc; close all;

enable_plots = false;

% Define the path to the aligned data folder
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\dtw_aligned';

% Get a list of all .mat files in the directory
file_list = dir(fullfile(base_path, '*.mat'));

% Check if there are any files
if isempty(file_list)
    error('No .mat files found in the directory.');
end

% Define the save directory for PCA-combined EMG data
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\pca_combined_emg';

% Ensure the directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Loop through each file (each patient)
for f = 1:length(file_list)
    % Load file
    file_name = file_list(f).name;
    file_path = fullfile(file_list(f).folder, file_name);
    load(file_path, 'aligned_data'); % Load the correct struct name

    % Extract patient identifier from filename
    [~, patient_id, ~] = fileparts(file_name);

    % Get available muscles
    muscles = fieldnames(aligned_data);

    % Get repetition names (aligned_data contains repetitions per muscle)
    reps = fieldnames(aligned_data.(muscles{1}));
    num_reps = length(reps);

    % Initialize structure to store the PCA-combined EMG data
    combined_emg_struct = struct();

    % Create a figure for visualization (optional)
    if enable_plots
        figure;
        tiledlayout(length(muscles), 2);
        sgtitle(['EMG Signals Combined Using PCA - ' patient_id]);
    end

    % Loop through each muscle
    for m = 1:length(muscles)
        muscle_name = muscles{m};

        % Get the number of samples (assuming all reps have the same length)
        sample_length = length(aligned_data.(muscle_name).(reps{1}).envelope);

        % Initialize a matrix to store all repetitions
        rep_data = zeros(sample_length, num_reps);

        % Extract data from all repetitions
        for i = 1:num_reps
            rep_name = reps{i};
            rep_data(:, i) = aligned_data.(muscle_name).(rep_name).envelope;
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

    % Save the PCA-combined EMG data
    save_filename = fullfile(save_dir, ['combined_emg_PCA_' patient_id '.mat']);
    save(save_filename, 'combined_emg_struct');

    fprintf('PCA-combined EMG data saved to: %s\n', save_filename);
end

fprintf('Processing complete. All patient files have been analyzed.\n');