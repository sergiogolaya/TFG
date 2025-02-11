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
    
    % Compute cross-correlation between repetitions
    corr_matrix = zeros(num_reps, num_reps);
    
    for i = 1:num_reps
        for j = i:num_reps
            % Compute zero-lag cross-correlation (normalized)
            corr_matrix(i, j) = sum(all_reps_data(i, :) .* all_reps_data(j, :)) / ...
                (sqrt(sum(all_reps_data(i, :) .^ 2)) * sqrt(sum(all_reps_data(j, :) .^ 2)));
            
            % Make symmetric
            corr_matrix(j, i) = corr_matrix(i, j);
        end
    end
    
    % Store results in the struct
    crossCorrResults.(muscle_name) = corr_matrix;
    
    % Display results
    fprintf('Cross-correlation matrix for %s:\n', muscle_name);
    disp(corr_matrix);
    
    % Plot heatmap if show_plots is enabled
    if show_plots
        figure;
        imagesc(corr_matrix);
        colormap jet;
        colorbar;
        title(['Cross-Correlation Matrix for ' muscle_name]);
        xlabel('Repetition');
        ylabel('Repetition');
        axis square;
    end
    
    % Plot all repetitions in a single plot if show_plots is enabled
    if show_plots
        figure;
        hold on;
        colors = lines(num_reps); % Generate distinct colors for each repetition
        for r = 1:num_reps
            plot(1:1000, all_reps_data(r, :), 'Color', colors(r, :), 'LineWidth', 1.5);
        end
        hold off;
        title(['EMG Envelopes for ' muscle_name ' (All Repetitions)']);
        xlabel('Time Points');
        ylabel('EMG Envelope Amplitude');
        legend(reps, 'Location', 'Best');
    end
end

% Save results in the specified directory
save(fullfile(save_dir, 'crossCorrResults.mat'), 'crossCorrResults');

fprintf('Cross-correlation results saved to: %s\n', fullfile(save_dir, 'crossCorrResults.mat'));
