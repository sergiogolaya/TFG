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

% Extract patient identifier from filename (assuming a pattern like "patient_X.mat")
[~, patient_id, ~] = fileparts(input_file);

% Toggle for plotting
show_plots = true;  % Set to 'false' to disable plots

% Extract the main struct (assuming it is stored in 'data')
emg_data_struct = data.emg_data_struct;

% Get muscle names from one repetition (assumes all reps have same muscles)
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
    
    % Compute cross-correlation using both methods
    corr_matrix_manual = zeros(num_reps, num_reps);
    corr_matrix_xcorr = zeros(num_reps, num_reps);
    
    for i = 1:num_reps
        for j = i:num_reps
            % Manual cross-correlation
            corr_matrix_manual(i, j) = sum(all_reps_data(i, :) .* all_reps_data(j, :)) / ...
                (sqrt(sum(all_reps_data(i, :) .^ 2)) * sqrt(sum(all_reps_data(j, :) .^ 2)));
            
            % MATLAB's `xcorr` function (zero-lag)
            xcorr_values = xcorr(all_reps_data(i, :), all_reps_data(j, :), 0, 'coeff');
            corr_matrix_xcorr(i, j) = xcorr_values;
            
            % Make matrices symmetric
            corr_matrix_manual(j, i) = corr_matrix_manual(i, j);
            corr_matrix_xcorr(j, i) = corr_matrix_xcorr(i, j);
        end
    end
    
    % Store results in the struct
    crossCorrResults.(muscle_name).manual = corr_matrix_manual;
    crossCorrResults.(muscle_name).xcorr = corr_matrix_xcorr;
    
    % Display results
    fprintf('Cross-correlation matrices for %s:\n', muscle_name);
    disp('Manual Method:');
    disp(corr_matrix_manual);
    disp('xcorr Method:');
    disp(corr_matrix_xcorr);
    
    % Plot heatmaps if show_plots is enabled
    if show_plots
        figure;
        subplot(1,2,1);
        imagesc(corr_matrix_manual);
        colormap jet;
        colorbar;
        title(['Manual Cross-Correlation - ' muscle_name]);
        xlabel('Repetition');
        ylabel('Repetition');
        axis square;
        
        subplot(1,2,2);
        imagesc(corr_matrix_xcorr);
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
