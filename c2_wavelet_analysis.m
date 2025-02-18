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
disp_results = false; % Set to 'false' to disable matrix display

% Get muscle names from one repetition (assumes all reps have same muscles)
muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

% Get repetition names
reps = fieldnames(emg_data_struct.cut_data_normalized);
num_reps = length(reps);

% Initialize a structure to store wavelet cross-correlation results
waveletCorrResults = struct();

% Define the save directory
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\wavelet_cross_correlation';

% Ensure the directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Initialize wavelet cross-correlation matrix
    wavelet_corr_matrix = zeros(num_reps, num_reps);
    
    % Compute wavelet transform for each repetition
    wavelet_coeffs = cell(num_reps, 1);
    
    for r = 1:num_reps
        rep_name = reps{r};
        signal = emg_data_struct.cut_data_normalized.(rep_name).(muscle_name).envelope;
        
        % Compute the continuous wavelet transform (CWT) using Morlet wavelet
        [cfs, ~] = cwt(signal, 'amor');
        wavelet_coeffs{r} = abs(cfs); % Use absolute values to get energy representation
    end
    
    % Compute cross-correlation between wavelet coefficients of different repetitions
    for i = 1:num_reps
        for j = i:num_reps
            % Compute correlation between wavelet coefficient matrices
            corr_value = corr2(wavelet_coeffs{i}, wavelet_coeffs{j});
            
            % Store results in matrix
            wavelet_corr_matrix(i, j) = corr_value;
            wavelet_corr_matrix(j, i) = corr_value; % Ensure symmetry
        end
    end
    
    % Store results in struct
    waveletCorrResults.(muscle_name) = wavelet_corr_matrix;
    
    if disp_results
        % Display results
        fprintf('Wavelet Cross-Correlation Matrix for %s:\n', muscle_name);
        disp(wavelet_corr_matrix);
    end
    
    % Plot heatmap if enabled
    if show_plots
        figure;
        imagesc(wavelet_corr_matrix);
        colormap jet;
        colorbar;
        title(['Wavelet Cross-Correlation - ' muscle_name]);
        xlabel('Repetition');
        ylabel('Repetition');
        axis square;
    end
end

% Construct the filename with the patient identifier
save_filename = fullfile(save_dir, ['waveletCorrResults_' patient_id '.mat']);

% Save results in the specified directory
save(save_filename, 'waveletCorrResults');

fprintf('Wavelet cross-correlation results saved to: %s\n', save_filename);
