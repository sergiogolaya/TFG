clear; clc; close all;

% Define the path to the aligned data folder
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\aligned_dtw';

% Get a list of all .mat files in the directory
file_list = dir(fullfile(base_path, '*.mat'));

% Check if there are any files
if isempty(file_list)
    error('No .mat files found in the directory.');
end

% Define toggles
show_plots = true;  % Set to 'false' to disable plots
show_console_output = false; % Set to 'false' to disable console messages

% Define the save directory
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\intra_cross_correlation';

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

    % Initialize structure to store cross-correlation results
    crossCorrResults = struct();

    % Loop through each muscle
    for m = 1:length(muscles)
        muscle_name = muscles{m};

        % Initialize cross-correlation matrix
        corr_matrix_xcorr = zeros(num_reps, num_reps);
        max_lag = 50; % Allow up to ±50 time shift samples

        % Extract envelope data for all repetitions
        all_reps_data = zeros(num_reps, 1000); % Assuming all have 1000 time points
        for r = 1:num_reps
            rep_name = reps{r};
            all_reps_data(r, :) = aligned_data.(muscle_name).(rep_name).envelope;
        end

        % Compute cross-correlation for all repetitions
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

        % Extract non-diagonal values
        non_diag_values = corr_matrix_xcorr(~eye(num_reps));

        % Compute mean and standard deviation of cross-correlation values
        mean_corr = mean(non_diag_values);
        std_corr = std(non_diag_values);

        % Store results in the struct
        crossCorrResults.(muscle_name).xcorr = corr_matrix_xcorr;
        crossCorrResults.(muscle_name).mean_corr = mean_corr;
        crossCorrResults.(muscle_name).std_corr = std_corr;

        % Display results if enabled
        if show_console_output
            fprintf('Patient: %s | Muscle: %s\n', patient_id, muscle_name);
            fprintf('Mean correlation (excluding diagonal): %.4f\n', mean_corr);
            fprintf('Standard deviation: %.4f\n\n', std_corr);
        end

        % Plot heatmap if enabled
        if show_plots
            figure;
            imagesc(corr_matrix_xcorr, [0.8 1]);
            colormap jet;
            colorbar;
            title(['xcorr Cross-Correlation - ' muscle_name ' | ' patient_id]);
            xlabel('Repetition');
            ylabel('Repetition');
            axis square;
        end
    end

    % Construct the filename with the patient identifier
    save_filename = fullfile(save_dir, ['crossCorrResults_' patient_id '.mat']);

    % Save results in the specified directory
    save(save_filename, 'crossCorrResults');

    % Notify completion if enabled
    if show_console_output
        fprintf('Cross-correlation results saved to: %s\n\n', save_filename);
    end
end

fprintf('Processing complete. All patient files have been analyzed.\n');
