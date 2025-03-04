% Define the directories
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\results\mean';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Get all .mat files in the directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Define mapping between descriptive muscle names and struct field names
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

% Initialize storage for EMG data
subject_data = {}; 

% Loop through all .mat files to load data
for i = 1:length(file_list)
    % Load the current .mat file
    file_path = fullfile(data_dir, file_list(i).name);
    loaded_data = load(file_path);
    
    % Directly access combined_emg_struct
    emg_struct = loaded_data.combined_emg_struct;
    
    % Get the field names (muscle labels)
    if i == 1
        muscle_fields = fieldnames(emg_struct);
        num_muscles = numel(muscle_fields);
        num_samples = size(emg_struct.(muscle_fields{1}).envelope, 1); % Assuming 1000 time points
        
        % Initialize storage array (samples x subjects x muscles)
        subject_data = zeros(num_samples, length(file_list), num_muscles);
    end
    
    % Extract the envelope for each muscle and store it
    for m = 1:num_muscles
        subject_data(:,i,m) = emg_struct.(muscle_fields{m}).envelope;
    end
end

% Initialize structured storage
emg_results = struct();
emg_results.time_vector = linspace(0, 100, num_samples); % Normalize time cycle

% Process each muscle separately
for m = 1:num_muscles
    % Compute mean and standard deviation across subjects
    muscle_mean = mean(subject_data(:,:,m), 2);
    muscle_std = std(subject_data(:,:,m), 0, 2);
    
    % Store results in structured format
    emg_results.(muscle_fields{m}).mean = muscle_mean;
    emg_results.(muscle_fields{m}).std_dev = muscle_std;
    
    % Find the corresponding descriptive muscle name
    idx = find(strcmp(muscle_names_map(:,2), muscle_fields{m}), 1);
    if ~isempty(idx)
        muscle_name = muscle_names_map{idx, 1}; % Use descriptive name for plotting
    else
        muscle_name = strrep(muscle_fields{m}, '_', ' '); % Default to struct field name
    end
    
    % Generate plot with dynamic std shading
    figure('Position', [100, 100, 1200, 800]); % Set figure size to 1200x800 pixels
    hold on;
    
    % Plot mean envelope
    plot(emg_results.time_vector, muscle_mean, 'b', 'LineWidth', 2);
    
    % Plot standard deviation as shaded area (using computed std at each time point)
    fill([emg_results.time_vector, fliplr(emg_results.time_vector)], ...
         [muscle_mean + muscle_std; flipud(muscle_mean - muscle_std)], ...
         'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    
    hold off;
    xlabel('% Reach and Grasp Cycle', 'FontSize', 16);
    ylabel('Normalized EMG Activity', 'FontSize', 16);
    title(['Representative EMG Profile - ', muscle_name], 'FontSize', 18);
    legend({'Mean EMG', '± Std Dev'}, 'Location', 'best', 'FontSize', 14);
    grid on;
    
    % Save figure as high-resolution PNG (300 DPI)
    saveas(gcf, fullfile(save_dir, [muscle_fields{m}, '_emg_curve.png']));
    print(gcf, fullfile(save_dir, [muscle_fields{m}, '_emg_curve.png']), '-dpng', '-r300'); % Save with 300 DPI
    close(gcf);
end

% Save the structured EMG results in a .mat file
save(fullfile(save_dir, 'representative_emg_curve.mat'), 'emg_results');

disp('Representative EMG curves computed and saved with high resolution.');