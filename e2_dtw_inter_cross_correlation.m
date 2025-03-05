% Compute Pearson correlation between DTW-aligned EMG signals across subjects
% Process all .mat files in the dtw_combined_emg directory.

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

% Initialize a structure to store correlation results
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
    
    % Extract raw envelope data for each subject
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
        
        % Extract envelope (WITHOUT standard deviation normalization)
        envelope = subjects_data.(subj_id).(muscle_name).envelope;

        % Skip if envelope is all zeros
        if all(envelope == 0)
            warning('Muscle %s for subject %s has zero signal. Skipping...', muscle_name, subj_id);
            continue;
        end

        % Store envelope data
        all_subjects_data(s, :) = envelope;
        valid_subjects = valid_subjects + 1;
    end

    % Ensure there are at least two valid subjects for correlation
    if valid_subjects < 2
        warning('Not enough valid subjects for muscle %s. Skipping...', muscle_name);
        continue;
    end
    
    % Remove NaN rows (subjects with missing data)
    all_subjects_data = all_subjects_data(~any(isnan(all_subjects_data), 2), :);

    % Compute Pearson correlation across subjects
    corr_matrix_pearson = corr(all_subjects_data', 'Rows', 'complete');

    % Extract non-diagonal values
    non_diag_values = corr_matrix_pearson(~eye(valid_subjects));

    % Compute mean and standard deviation of correlation values
    mean_corr = mean(non_diag_values, 'omitnan');
    std_corr = std(non_diag_values, 'omitnan');
    
    % Store results in the struct
    crossCorrResults.(muscle_name).corr_matrix = corr_matrix_pearson;
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
        imagesc(corr_matrix_pearson, [0.6 1]);
        colormap jet;
        colorbar;
        title(['Pearson Correlation Between Subjects (DTW) - ' muscle_name]);
        xlabel('Subject');
        ylabel('Subject');
        xticks(1:valid_subjects);
        yticks(1:valid_subjects);
        xticklabels(subject_ids);
        yticklabels(subject_ids);
        axis square;

        % Save figure
        saveas(gcf, fullfile(save_dir, [muscle_name, '_dtw_pearson_correlation.png']));
        close(gcf);
    end
end

% Save results
save_filename = fullfile(save_dir, 'dtw_pearsonCorrResults_subjects.mat');
save(save_filename, 'crossCorrResults');

fprintf('DTW Pearson correlation results saved to: %s\n', save_filename);
