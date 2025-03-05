% Compute cross-correlation between DTW-aligned EMG signals across subjects
% Process all .mat files in the combined_dtw_emg directory.

clear; clc; close all;

show_console_output = true;
show_plots = true;

% Define the path to the DTW-aligned combined EMG data directory
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\dtw_combined_emg';

% Define the save directory for results
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\results\dtw_inter_cross_correlation';

% Ensure the save directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Get all .mat files in the directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Ensure there are files to process
if isempty(file_list)
    error('No .mat files found in the specified directory.');
end

% Initialize a structure to store cross-correlation results
crossCorrResults = struct();

% Load all subject data
subjects_data = struct();
subject_ids = {}; % Store extracted subject IDs

for f = 1:length(file_list)
    file_name = file_list(f).name;
    full_path = fullfile(data_dir, file_name);
    
    % Extract subject ID from filename
    subject_match = regexp(file_name, 'p(\d+)_normalized', 'tokens');
    if isempty(subject_match)
        warning('Could not extract subject ID from filename: %s', file_name);
        continue;
    end
    subject_id = ['p' subject_match{1}{1}]; % Extract "pX"
    subject_ids{end+1} = subject_id; % Store for axis labels
    
    % Load the correct structure
    loaded_data = load(full_path);
    
    % Check if 'combined_emg_struct' exists in the file
    if isfield(loaded_data, 'combined_emg_struct')
        emg_data = loaded_data.combined_emg_struct;
    else
        warning('Variable combined_emg_struct not found in file: %s', file_name);
        continue;
    end
    
    % Store the subject's data
    subjects_data.(subject_id) = emg_data;
end

% Convert subject IDs to a column cell array for consistent sorting
subject_ids = subject_ids(:);
num_subjects = length(subject_ids);

% Check if there are valid subjects
if num_subjects < 2
    error('Not enough valid subjects for correlation analysis.');
end

% Get muscle names from the first subject (assuming consistency)
first_subject_data = subjects_data.(subject_ids{1});
muscles = fieldnames(first_subject_data);

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Extract envelope data for each subject
    num_samples = length(subjects_data.(subject_ids{1}).(muscle_name).envelope);
    all_subjects_data = NaN(num_subjects, num_samples); % Initialize with NaNs

    valid_subjects = 0; % Track valid subjects for this muscle

    for s = 1:num_subjects
        subj_id = subject_ids{s};
        
        % Check if the subject has the muscle field
        if ~isfield(subjects_data.(subj_id), muscle_name)
            warning('Muscle %s not found for subject %s. Skipping...', muscle_name, subj_id);
            continue;
        end
        
        % Extract envelope and std_dev
        envelope = subjects_data.(subj_id).(muscle_name).envelope;
        std_dev = subjects_data.(subj_id).(muscle_name).std_dev;
        
        % Check for zero standard deviation and avoid division
        if all(std_dev == 0) || all(envelope == 0)
            warning('Muscle %s for subject %s has zero variance. Skipping...', muscle_name, subj_id);
            continue;
        end

        % Normalize envelope using standard deviation
        weighted_envelope = envelope;
        if any(std_dev ~= 0)  % Avoid division by zero
            weighted_envelope = envelope ./ std_dev;
        end
        
        % Store weighted envelope
        all_subjects_data(s, :) = weighted_envelope;
        valid_subjects = valid_subjects + 1;
    end

    % Ensure there are at least two valid subjects for correlation
    if valid_subjects < 2
        warning('Not enough valid subjects for muscle %s. Skipping...', muscle_name);
        continue;
    end
    
    % Remove NaN rows (subjects with missing data)
    all_subjects_data = all_subjects_data(~any(isnan(all_subjects_data), 2), :);

    % Compute cross-correlation across subjects
    corr_matrix_xcorr = zeros(valid_subjects, valid_subjects);
    max_lag = 50; % Allow up to ±50 time shift samples
    
    for i = 1:valid_subjects
        for j = i:valid_subjects
            % Compute cross-correlation with time shifts
            [xcorr_values, lags] = xcorr(all_subjects_data(i, :), all_subjects_data(j, :), max_lag, 'coeff');
            
            % Find the highest correlation value within the allowed time shifts
            [best_corr, ~] = max(xcorr_values);
            
            % Store the best correlation value in the matrix
            corr_matrix_xcorr(i, j) = best_corr;
            corr_matrix_xcorr(j, i) = best_corr; % Ensure symmetry
        end
    end

    % Extract non-diagonal values
    non_diag_values = corr_matrix_xcorr(~eye(valid_subjects));

    % Compute mean and standard deviation of cross-correlation values
    mean_corr = mean(non_diag_values, 'omitnan');
    std_corr = std(non_diag_values, 'omitnan');
    
    % Store results in the struct
    crossCorrResults.(muscle_name).xcorr = corr_matrix_xcorr;
    crossCorrResults.(muscle_name).mean_corr = mean_corr;
    crossCorrResults.(muscle_name).std_corr = std_corr;

    % Display results if enabled
    if show_console_output
        fprintf('Muscle: %s\n', muscle_name);
        fprintf('Mean correlation (excluding diagonal): %.4f\n', mean_corr);
        fprintf('Standard deviation: %.4f\n\n', std_corr);
    end
    
    % Plot heatmap with subject IDs
    if show_plots
        figure;
        imagesc(corr_matrix_xcorr, [0.6 1]);
        colormap jet;
        colorbar;
        title(['Cross-Correlation Between Subjects (DTW) - ' muscle_name]);
        xlabel('Subject');
        ylabel('Subject');
        axis square;

        % Save figure
        saveas(gcf, fullfile(save_dir, [muscle_name, '_dtw_cross_correlation.png']));
        close(gcf);
    end
end

% Save results
save_filename = fullfile(save_dir, 'dtw_crossCorrResults_subjects_weighted.mat');
save(save_filename, 'crossCorrResults');

fprintf('DTW cross-correlation results (weighted by std_dev) saved to: %s\n', save_filename);
