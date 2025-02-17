clear; clc; close all;
% Define input and output directories
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\postprocessed';
output_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Create output directory if it does not exist
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Toggle to enable (true) or disable (false) plotting
show_plots = true;

% Get list of .mat files in the input directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Define the number of interpolation points (100% scale)
num_points = 101;  % Normalized time axis from 0 to 100%

% Loop through each .mat file
for f = 1:length(file_list)
    % Load the .mat file
    file_name = file_list(f).name;
    file_path = fullfile(data_dir, file_name);
    fprintf('Processing: %s\n', file_name);
    data = load(file_path);
    
    % Ensure the structure exists
    if ~isfield(data, 'emg_data_struct') || ~isfield(data.emg_data_struct, 'cut_data')
        fprintf('Skipping %s (missing expected structure)\n', file_name);
        continue;
    end
    
    % Copy structure for normalized data
    data.emg_data_struct.cut_data_normalized = data.emg_data_struct.cut_data;

    % Get the repetitions and muscles
    reps = fieldnames(data.emg_data_struct.cut_data);
    muscles = fieldnames(data.emg_data_struct.cut_data.(reps{1}));

    % Initialize plotting variables
    first_rep = reps{1};
    first_muscle = muscles{1};
    original_plot_data = [];
    normalized_plot_data = [];

    % Loop through repetitions
    for r = 1:length(reps)
        rep_name = reps{r};

        % Loop through muscles
        for m = 1:length(muscles)
            muscle_name = muscles{m};

            % Extract the envelope data
            envelope_data = data.emg_data_struct.cut_data.(rep_name).(muscle_name).envelope;

            % Check if data is valid
            if isempty(envelope_data)
                fprintf('Skipping %s -> %s (empty data)\n', rep_name, muscle_name);
                continue;
            end

            % Generate the original time axis (assuming equal spacing)
            original_time = linspace(0, 100, length(envelope_data));

            % Generate the new normalized time axis
            num_points = 1000;  % Increase resolution
            normalized_time = linspace(0, 100, num_points);

            % Perform interpolation
            normalized_envelope = interp1(original_time, envelope_data, normalized_time, 'linear');

            % Store the normalized data
            data.emg_data_struct.cut_data_normalized.(rep_name).(muscle_name).envelope = normalized_envelope;

            % Store data for plotting if this is the first rep & muscle
            if r == 1 && m == 1
                original_plot_data = envelope_data;
                normalized_plot_data = normalized_envelope;
            end
        end
    end

    % Save the new .mat file in the output directory
    new_file_name = strrep(file_name, '.mat', '_normalized.mat');
    new_file_path = fullfile(output_dir, new_file_name);
    save(new_file_path, '-struct', 'data');
    fprintf('Saved: %s\n', new_file_name);

    % Plot original vs. normalized envelope (first repetition & muscle)
     if show_plots && ~isempty(original_plot_data) && ~isempty(normalized_plot_data)
        figure;
    
        % Plot the original envelope (no x-axis adjustment)
        subplot(2,1,1);
        plot(original_plot_data, 'b');
        title(sprintf('Original Envelope - %s (%s)', first_muscle, file_name), 'Interpreter', 'none');
        xlabel('Number of Samples'); % Label x-axis as number of samples
        ylabel('Envelope Amplitude');
        grid on;
    
        % Plot the normalized envelope (0-100% x-axis)
        subplot(2,1,2);
        plot(linspace(0, 100, num_points), normalized_plot_data, 'r');
        title(sprintf('Normalized Envelope - %s (%s)', first_muscle, file_name), 'Interpreter', 'none');
        xlabel('Repetition Completion (%)'); 
        ylabel('Envelope Amplitude');
        grid on;
    end

end

fprintf('All files processed successfully!\n');
