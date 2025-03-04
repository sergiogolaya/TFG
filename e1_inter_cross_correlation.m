% Define the path to the combined EMG data directory
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';
% Define the save directory for results
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\inter_cross_correlation';

show_console_output = true;
show_plots = true;

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
    
    % Extract subject ID from filename (matches pattern: "pX")
    subject_match = regexp(file_name, 'processed_(p\d+)_normalized', 'tokens');
    if isempty(subject_match)
        warning('Could not extract subject ID from filename: %s', file_name);
        continue;
    end
    subject_id = subject_match{1}{1}; % Extract "pX"
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

% Get muscle names from the first subject (assuming consistency)
first_subject_data = subjects_data.(subject_ids{1});
muscles = fieldnames(first_subject_data);

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Extract weighted envelope data for each subject
    all_subjects_data = zeros(num_subjects, 1000); % Assuming all have 1000 time points
    
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
        
        % Normalize envelope using standard deviation
        if any(std_dev ~= 0)  % Avoid division by zero
            weighted_envelope = envelope ./ std_dev;
        else
            weighted_envelope = envelope; % If std_dev is zero, keep original
        end
        
        % Store weighted envelope
        all_subjects_data(s, :) = weighted_envelope;
    end
    
    % Compute cross-correlation across subjects
    corr_matrix_xcorr = zeros(num_subjects, num_subjects);
    max_lag = 50; % Allow up to ±50 time shift samples
    
    for i = 1:num_subjects
        for j = i:num_subjects
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
    
    % Plot heatmap with subject IDs
    if show_plots
        figure;
        imagesc(corr_matrix_xcorr, [0.6 1]);
        colormap jet;
        colorbar;
        title(['xcorr Cross-Correlation Between Subjects (Weighted) - ' muscle_name]);
        xlabel('Subject');
        ylabel('Subject');
        xticks(1:num_subjects);
        yticks(1:num_subjects);
        xticklabels(subject_ids);
        yticklabels(subject_ids);
        axis square;

        % Save figure
        saveas(gcf, fullfile(save_dir, [muscle_name, '_cross_correlation.png']));
        print(gcf, fullfile(save_dir, [muscle_name, '_cross_correlation.png']), '-dpng', '-r300');
        close(gcf);
    end
end

% Ensure the directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Save results
save_filename = fullfile(save_dir, 'crossCorrResults_subjects_weighted.mat');
save(save_filename, 'crossCorrResults');

fprintf('Cross-correlation results (weighted by std_dev) saved to: %s\n', save_filename);
