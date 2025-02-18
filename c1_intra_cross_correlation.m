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

% Extract patient identifier from filename
[~, patient_id, ~] = fileparts(input_file);

% Toggle for plotting
show_plots = true;  % Set to 'false' to disable plots

% Get muscle names from one repetition
muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

% Get repetition names
reps = fieldnames(emg_data_struct.cut_data_normalized);

% Initialize a structure to store cross-correlation results
crossCorrResults = struct();

% Define the save directory
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\intra_cross_correlation';

% Ensure the directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    num_reps = length(reps);
    
    % Initialize matrix to store envelope data (num_reps x time_points)
    all_reps_data = zeros(num_reps, 1000); % Assuming all have 1000 time points
    
    % Extract envelope data from each repetition
    for r = 1:num_reps
        rep_name = reps{r};
        all_reps_data(r, :) = emg_data_struct.cut_data_normalized.(rep_name).(muscle_name).envelope;
    end
    
    % Compute cross-correlation using MATLAB's xcorr function
    corr_matrix_xcorr = zeros(num_reps, num_reps);
    max_lag = 50; % Allow up to ±50 time shift samples
    
    for i = 1:num_reps
        for j = i:num_reps
            % Compute cross-correlation with time shifts
            [xcorr_values, lags] = xcorr(all_reps_data(i, :), all_reps_data(j, :), max_lag, 'coeff');
            
            % Find the highest correlation value within the allowed time shifts
            [best_corr, ~] = max(xcorr_values);
            
            % Store the best correlation value in the matrix
            corr_matrix_xcorr(i, j) = best_corr;
            corr_matrix_xcorr(j, i) = best_corr; % Ensure symmetry
        end
    end
    
    % Store results in the struct
    crossCorrResults.(muscle_name).xcorr = corr_matrix_xcorr;
    
    % Plot heatmap if show_plots is enabled
    if show_plots
        figure;
        imagesc(corr_matrix_xcorr, [0.8 1]);
        colormap jet;
        colorbar;
        title(['xcorr Cross-Correlation - ' muscle_name]);
        xlabel('Repetition');
        ylabel('Repetition');
        axis square;
    end
end

% Construct the filename with the patient identifier
save_filename = fullfile(save_dir, ['crossCorrResults_' patient_id '.mat']);

% Save results in the specified directory
save(save_filename, 'crossCorrResults');

fprintf('Cross-correlation results saved to: %s\n', save_filename);