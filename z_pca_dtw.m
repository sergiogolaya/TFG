% Define the directories
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\dtw_pca_analysis';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Get all .mat files (each containing a subject's data)
file_list = dir(fullfile(data_dir, '*.mat'));

% Define the mapping between muscle names and struct fields
muscle_names_map = { ...
    'Biceps Brachii', 'muscle_1'; ...
    'Triceps Brachii', 'muscle_2'; ...
    'Front Deltoid', 'muscle_3'; ...
    'Trapezius', 'muscle_4'; ...
    'Lateral Deltoid', 'muscle_5'; ...
    'Posterior Deltoid', 'muscle_6'; ...
    'Palmaris Longus', 'muscle_7'; ...
    'Extensor Carpi Radialis', 'muscle_8' ...
};

% Initialize storage for subject-averaged EMG data
subject_averages = {}; 

% Load and process each subject
for i = 1:length(file_list)
    % Load subject file
    file_path = fullfile(data_dir, file_list(i).name);
    loaded_data = load(file_path);
    
    % Extract EMG struct
    emg_data_struct = loaded_data.emg_data_struct;
    
    % Get available muscles
    muscle_fields = fieldnames(emg_data_struct.cut_data_normalized.rep_1);
    num_muscles = numel(muscle_fields);
    
    % Get repetition names
    reps = fieldnames(emg_data_struct.cut_data_normalized);
    num_reps = length(reps);
    
    % Initialize storage for aligned signals per subject
    aligned_signals = zeros(1000, num_reps, num_muscles); % Assuming 1000 samples per cycle

    % Process each muscle separately
    for m = 1:num_muscles
        muscle_name = muscle_fields{m};
        
        % Extract all repetitions for this muscle
        rep_signals = zeros(1000, num_reps);
        for r = 1:num_reps
            rep_signals(:,r) = emg_data_struct.cut_data_normalized.(reps{r}).(muscle_name).envelope;
        end

        % Compute median signal as reference
        ref_signal = median(rep_signals, 2);

        % Apply DTW alignment
        for r = 1:num_reps
            aligned_signals(:,r,m) = dtwAlign(rep_signals(:,r), ref_signal);
        end
    end
    
    % Compute subject-averaged EMG per muscle
    subject_avg = squeeze(mean(aligned_signals, 2)); % Average over repetitions
    subject_averages{i} = subject_avg; % Store in cell array
end

% Combine all subjects' aligned EMG profiles
num_subjects = length(subject_averages);
combined_matrix = cat(3, subject_averages{:}); % (samples x muscles x subjects)

% Initialize results struct
emg_results = struct();
emg_results.time_vector = linspace(0, 100, size(combined_matrix,1));

% Process each muscle separately
for m = 1:num_muscles
    % Extract data for this muscle across subjects
    muscle_data = squeeze(combined_matrix(:,m,:)); % (samples x subjects)

    % Compute mean across subjects
    muscle_mean = mean(muscle_data, 2);

    % Apply PCA to extract main EMG patterns
    [coeff, score, ~, ~, explained] = pca(muscle_data);
    main_pattern = score(:,1); % First principal component

    % Store results per muscle
    emg_results.(muscle_fields{m}).pca_pattern = main_pattern;
    emg_results.(muscle_fields{m}).explained_variance = explained;

    % Find descriptive muscle name
    idx = find(strcmp(muscle_names_map(:,2), muscle_fields{m}), 1);
    if ~isempty(idx)
        muscle_name = muscle_names_map{idx, 1};
    else
        muscle_name = strrep(muscle_fields{m}, '_', ' ');
    end
    
    % Plot PCA-Processed EMG for this muscle
    figure('Position', [100, 100, 1200, 800]);
    hold on;
    plot(emg_results.time_vector, main_pattern, 'b', 'LineWidth', 2);
    xlabel('% Reach and Grasp Cycle', 'FontSize', 16);
    ylabel('PCA Processed EMG', 'FontSize', 16);
    title(['PCA-Based EMG Profile - ', muscle_name], 'FontSize', 18);
    legend({'First Principal Component'}, 'Location', 'best', 'FontSize', 14);
    grid on;
    
    % Save figure
    saveas(gcf, fullfile(save_dir, [muscle_fields{m}, '_pca_emg.png']));
    print(gcf, fullfile(save_dir, [muscle_fields{m}, '_pca_emg.png']), '-dpng', '-r300');
    close(gcf);
end

% Save the structured EMG results in a .mat file
save(fullfile(save_dir, 'processed_emg_dtw_pca.mat'), 'emg_results');

disp('DTW and PCA applied to EMG data for each muscle. Results saved.');

%% **Fixed DTW Alignment Function**
function aligned_signal = dtwAlign(signal, ref_signal)
    % Apply Dynamic Time Warping (DTW) to align EMG signals to a reference
    
    % Normalize both signals
    signal = signal / max(abs(signal));
    ref_signal = ref_signal / max(abs(ref_signal));
    
    % Compute DTW alignment
    [~, ix, iy] = dtw(signal, ref_signal);
    
    % Ensure unique indices for interpolation
    [iy, unique_idx] = unique(iy, 'stable');
    ix = ix(unique_idx);
    
    % Use gridded interpolation instead of interp1
    F = griddedInterpolant(double(iy), double(signal(ix)), 'linear', 'none');
    aligned_signal = F(1:length(ref_signal));
    
    % Handle NaNs (caused by out-of-bound interpolation)
    aligned_signal(isnan(aligned_signal)) = mean(aligned_signal, 'omitnan');
end