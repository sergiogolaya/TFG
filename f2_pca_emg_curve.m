% Define the directories
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\pca_combined_emg';
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\pca_emg_curve';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Get all .mat files in the directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Initialize storage for PCA envelope data
subject_data = [];

% Loop through all .mat files to load PCA envelope data
for i = 1:length(file_list)
    % Load the current .mat file
    file_path = fullfile(data_dir, file_list(i).name);
    loaded_data = load(file_path);
    
    % Check if the expected structure exists
    if isfield(loaded_data, 'combined_emg_struct')
        emg_struct = loaded_data.combined_emg_struct;
    else
        warning(['Skipping file: ', file_list(i).name, ' (No combined_emg_struct found)']);
        continue;
    end
    
    % Get the field names (muscle labels)
    if isempty(subject_data)
        muscle_fields = fieldnames(emg_struct);
        num_muscles = numel(muscle_fields);
        num_samples = size(emg_struct.(muscle_fields{1}).envelope, 1);
        
        % Initialize storage array (samples x subjects x muscles)
        subject_data = zeros(num_samples, length(file_list), num_muscles);
    end
    
    % Extract the PCA envelope for each muscle and store it
    for m = 1:num_muscles
        subject_data(:, i, m) = emg_struct.(muscle_fields{m}).envelope;
    end
end

% Initialize structured storage
emg_results = struct();
emg_results.time_vector = linspace(0, 100, num_samples); % Normalize time cycle

% Process each muscle separately
for m = 1:num_muscles
    % Compute mean and standard deviation across subjects
    muscle_mean = mean(subject_data(:, :, m), 2);
    muscle_std = std(subject_data(:, :, m), 0, 2);
    
    % Store results in structured format
    emg_results.(muscle_fields{m}).mean = muscle_mean;
    emg_results.(muscle_fields{m}).std_dev = muscle_std;
    
    % Generate plot with dynamic std shading
    figure('Position', [100, 100, 1200, 800]);
    hold on;
    
    % Plot mean PCA envelope
    plot(emg_results.time_vector, muscle_mean, 'b', 'LineWidth', 2);
    
    % Plot standard deviation as shaded area
    fill([emg_results.time_vector, fliplr(emg_results.time_vector)], ...
         [muscle_mean + muscle_std; flipud(muscle_mean - muscle_std)], ...
         'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    
    hold off;
    xlabel('% Reach and Grasp Cycle', 'FontSize', 16);
    ylabel('PCA-Processed EMG Activity', 'FontSize', 16);
    title(['PCA-Based EMG Profile - ', strrep(muscle_fields{m}, '_', ' ')], 'FontSize', 18);
    legend({'Mean PCA Envelope', '± Std Dev'}, 'Location', 'best', 'FontSize', 14);
    grid on;
    
    % Save figure as high-resolution PNG
    saveas(gcf, fullfile(save_dir, [muscle_fields{m}, '_pca_emg_curve.png']));
    print(gcf, fullfile(save_dir, [muscle_fields{m}, '_pca_emg_curve.png']), '-dpng', '-r300'); 
    close(gcf);
end

% Save the structured PCA EMG results in a .mat file
save(fullfile(save_dir, 'pca_emg_results.mat'), 'emg_results');

disp('PCA EMG curves computed and saved successfully.');