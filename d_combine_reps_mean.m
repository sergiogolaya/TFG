% Combine 5 EMG repetitions using the mean and visualize with standard deviation
% Process all .mat files in the specified directory

% Define the base directory for normalized EMG data
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Set this to true to enable plotting, false to disable it
enable_plots = true; 

% Get a list of all .mat files in the directory
mat_files = dir(fullfile(base_path, '*.mat'));

% Check if there are any .mat files in the directory
if isempty(mat_files)
    error('No .mat files found in the directory: %s', base_path);
end

% Define save directory for the combined data
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';

% Create the directory if it does not exist
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Loop through each file in the directory
for file_idx = 1:length(mat_files)
    % Load the current file
    input_file = mat_files(file_idx).name;
    full_file_path = fullfile(base_path, input_file);
    load(full_file_path);
    
    % Extract patient identifier from filename
    [~, patient_id, ~] = fileparts(input_file);
    
    % Get available muscles from one repetition
    muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

    % Get repetition names
    reps = fieldnames(emg_data_struct.cut_data_normalized);
    num_reps = length(reps);

    % Initialize structure to store the combined EMG data
    combined_emg_struct = struct();

    % Create a figure for visualization if enabled
    if enable_plots
        figure;
        % tiledlayout(length(muscles), 1);
        tiledlayout(4, 2);
        % sgtitle(['EMG Signals Combined (Mean ± Std Dev) - ' patient_id]);
    end

    % Loop through each muscle
    for m = 1:length(muscles)
        muscle_name = muscles{m};
        
        % Get the number of samples (assuming all reps have the same length)
        sample_length = length(emg_data_struct.cut_data_normalized.rep_1.(muscle_name).envelope);
        
        % Initialize a matrix to store all repetitions
        rep_data = zeros(sample_length, num_reps);
        
        % Extract data from all repetitions
        for i = 1:num_reps
            rep_data(:, i) = emg_data_struct.cut_data_normalized.(reps{i}).(muscle_name).envelope;
        end
        
        % Compute mean and standard deviation
        combined_signal = mean(rep_data, 2);
        std_dev = std(rep_data, 0, 2); % Standard deviation across repetitions
        
        % Store in the struct
        combined_emg_struct.(muscle_name).envelope = combined_signal;
        combined_emg_struct.(muscle_name).std_dev = std_dev;
        
        % Plot only if plotting is enabled
        if enable_plots
            nexttile;
            time_vector = 1:sample_length;
            fill([time_vector, fliplr(time_vector)], ...
                 [combined_signal - std_dev; flipud(combined_signal + std_dev)], ...
                 [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5); % Shaded region
            
            hold on;
            plot(time_vector, combined_signal, 'b', 'LineWidth', 1.5);
            hold off;
            
            title(muscle_name, 'Interpreter', 'none', 'FontSize', 16);
            xlabel('Samples');
            ylabel('Amplitude');
            grid on;
            legend('Std Dev', 'Mean', 'Location', 'northwest');
            % Ensure MATLAB updates the figure
            drawnow;
        end
    end

    % Save the combined EMG data for this patient
    save_filename = fullfile(save_dir, ['combined_emg_std_' patient_id '.mat']);
    save(save_filename, 'combined_emg_struct');

    fprintf('Combined EMG data saved to: %s\n', save_filename);
    
    % Pause only if plotting is enabled
    if enable_plots
        pause(2); % Adjust if needed
    end
end

fprintf('Processing completed for all files.\n');
