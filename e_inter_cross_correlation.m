% Define the path to the combined EMG data directory
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';
% Define the save directory for results
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\results\prueba_inter_cross_correlation';

show_console_output = true;
show_plots = true;
num_reps = 5;

% Define excluded subjects
excluded_subjects = {'p23'}; % Add subjects you want to exclude here

% Get all .mat files in the directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Ensure there are files to process
if isempty(file_list)
    error('No .mat files found in the specified directory.');
end

% Initialize a structure to store cross-correlation results
crossCorrResults = struct();

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

% Load all subject data
subjects_data = struct();
subject_ids_original = {}; % Store extracted subject IDs (pX)
subject_ids_mapped = {};  % Store mapped IDs (sX)

s_count = 1; % Counter for sX mapping

for f = 1:length(file_list)
    file_name = file_list(f).name;
    full_path = fullfile(data_dir, file_name);

    % Extract subject ID (pX)
    subject_match = regexp(file_name, 'processed_(p\d+)_normalized', 'tokens');
    if isempty(subject_match)
        warning('Could not extract subject ID from filename: %s', file_name);
        continue;
    end
    subject_id = subject_match{1}{1};

    % Skip excluded subjects
    if ismember(subject_id, excluded_subjects)
        continue;
    end

    % Map to sX format
    subject_ids_original{end+1} = subject_id;  % Original (pX)
    subject_ids_mapped{end+1} = ['s' num2str(s_count)]; % Mapped (sX)
    s_count = s_count + 1;

    % Load the correct structure
    loaded_data = load(full_path);

    if isfield(loaded_data, 'combined_emg_struct')
        emg_data = loaded_data.combined_emg_struct;
    else
        warning('Variable combined_emg_struct not found in file: %s', file_name);
        continue;
    end

    % Store the subject's data
    subjects_data.(subject_ids_mapped{end}) = emg_data;
end

% Update number of subjects after exclusion
num_subjects = length(subject_ids_mapped);

fprintf('Subjects excluded: %s\n', strjoin(excluded_subjects, ', '));
fprintf('Mapped subjects: %s\n', strjoin(subject_ids_mapped, ', '));

% Get muscle names from the first subject (assuming consistency)
muscles = fieldnames(subjects_data.(subject_ids_mapped{1}));

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    all_subjects_data = zeros(num_subjects, 1000); % Assuming all have 1000 time points

    for s = 1:num_subjects
        subj_id = subject_ids_mapped{s};
        if ~isfield(subjects_data.(subj_id), muscle_name)
            warning('Muscle %s not found for subject %s. Skipping...', muscle_name, subj_id);
            continue;
        end

        % Extract envelope and std_dev
        envelope = subjects_data.(subj_id).(muscle_name).envelope;
        std_dev = subjects_data.(subj_id).(muscle_name).std_dev;

        % Normalize envelope using standard deviation
        if any(std_dev ~= 0)
            weighted_envelope = envelope ./ std_dev;
        else
            weighted_envelope = envelope;
        end

        all_subjects_data(s, :) = weighted_envelope;
    end

    % Compute cross-correlation with lags
    corr_matrix_xcorr = zeros(num_subjects, num_subjects);
    max_lag = 25;

    for i = 1:num_subjects
        for j = i:num_subjects
            [xcorr_values, ~] = xcorr(all_subjects_data(i, :), all_subjects_data(j, :), max_lag, 'coeff');
            best_corr = max(xcorr_values);
            corr_matrix_xcorr(i, j) = best_corr;
            corr_matrix_xcorr(j, i) = best_corr; % Symmetric
        end
    end

    % Store results
    crossCorrResults.(muscle_name).xcorr = corr_matrix_xcorr;

    % Display results if enabled
    if show_console_output
        name_idx = find(strcmp(muscle_names(:,2), muscle_name));
        if ~isempty(name_idx)
            muscle_desc = muscle_names{name_idx,1};
        else
            muscle_desc = muscle_name;
        end

        fprintf('Muscle: %s\n', muscle_desc);
        fprintf('Mean correlation (excluding diagonal): %.4f ± %.4f\n', mean(corr_matrix_xcorr(~eye(num_subjects))), std(corr_matrix_xcorr(~eye(num_subjects))));
        % fprintf('Standard deviation: %.4f\n\n', std(corr_matrix_xcorr(~eye(num_subjects))));
    end

    % Plot heatmap if enabled
    if show_plots
        figure('Units', 'pixels', 'Position', [100, 100, 900, 1600]);  % 9:16 vertical
        imagesc(corr_matrix_xcorr, [0.6 1]);
        colormap jet;
        colorbar;
        title(['Cross-Correlation - ' muscle_desc]);
        xlabel('Subjects');
        ylabel('Subjects');
        xticks(1:num_subjects);
        yticks(1:num_subjects);
        xticklabels(subject_ids_mapped);
        yticklabels(subject_ids_mapped);
        axis square;
        saveas(gcf, fullfile(save_dir, [muscle_desc, '_cross_correlation.png']));
        close(gcf);
    end

end

% Save results
save_filename = fullfile(save_dir, 'crossCorrResults_subjects_weighted.mat');
save(save_filename, 'crossCorrResults');

fprintf('Cross-correlation results (with lags) saved to: %s\n', save_filename);

figure('Units', 'pixels', 'Position', [100, 100, 900, 1600]);
set(gcf, 'PaperUnits', 'inches', 'PaperPosition', [0 0 8.27 11.69]);  % A4 vertical

muscle_labels = {};

for m = 1:length(muscles)
    muscle_name = muscles{m};

    if ~isfield(crossCorrResults, muscle_name)
        warning('No se encontró correlación para %s. Saltando...', muscle_name);
        continue;
    end

    idx = find(strcmp(muscle_names(:,2), muscle_name));
    if ~isempty(idx)
        muscle_desc = muscle_names{idx,1};
    else
        muscle_desc = strrep(muscle_name, '_', ' ');
    end
    muscle_labels{end+1} = muscle_desc;

    corr_matrix = crossCorrResults.(muscle_name).xcorr;

    subplot(4, 2, m);
    imagesc(corr_matrix, [0.6 1]);
    colormap jet;
    colorbar;

    title(muscle_desc, 'FontSize', 18);
    axis square;

    xticks(1:num_subjects);
    yticks(1:num_subjects);
    xticklabels(subject_ids_mapped);
    yticklabels(subject_ids_mapped);

    set(gca, 'FontSize', 8);
end

saveas(gcf, fullfile(save_dir, 'all_heatmaps_subplot.png'));
close(gcf);

