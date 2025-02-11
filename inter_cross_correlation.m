% Define the directory containing normalized data from all patients
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Get a list of all .mat files in the directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Check if there are any files
if isempty(file_list)
    error('No .mat files found in the directory.');
end

% Initialize a structure to store patient data
patient_data = struct();

% Load all patient data
for f = 1:length(file_list)
    % Load file
    file_name = file_list(f).name;
    file_path = fullfile(file_list(f).folder, file_name);
    load(file_path);
    
    % Extract patient identifier from filename
    [~, patient_id, ~] = fileparts(file_name);
    
    % Store data in struct
    patient_data.(patient_id) = data.emg_data_struct.cut_data_normalized;
end

% Get list of patients
patient_ids = fieldnames(patient_data);

% Select one patient as reference to get muscle and repetition names
ref_patient = patient_ids{1};
muscles = fieldnames(patient_data.(ref_patient).rep_1);
repetitions = fieldnames(patient_data.(ref_patient));

% Initialize a structure to store cross-correlation results
crossCorrResults = struct();

% Define the save directory
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\inter_subject_cross_correlation';

% Ensure the directory exists
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Loop through each muscle
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Loop through each repetition
    for r = 1:length(repetitions)
        rep_name = repetitions{r};
        
        % Collect data from all patients for this muscle and repetition
        num_patients = length(patient_ids);
        all_patients_data = zeros(num_patients, 1000); % Assuming 1000 time points

        for p = 1:num_patients
            patient_id = patient_ids{p};
            all_patients_data(p, :) = patient_data.(patient_id).(rep_name).(muscle_name).envelope;
        end

        % Compute cross-correlation between patients
        corr_matrix = zeros(num_patients, num_patients);
        
        for i = 1:num_patients
            for j = i:num_patients
                % Compute zero-lag cross-correlation (normalized)
                corr_matrix(i, j) = sum(all_patients_data(i, :) .* all_patients_data(j, :)) / ...
                    (sqrt(sum(all_patients_data(i, :) .^ 2)) * sqrt(sum(all_patients_data(j, :) .^ 2)));
                
                % Make symmetric
                corr_matrix(j, i) = corr_matrix(i, j);
            end
        end
        
        % Store results
        crossCorrResults.(muscle_name).(rep_name) = corr_matrix;
        
        % Display results
        fprintf('Cross-correlation matrix for %s - %s:\n', muscle_name, rep_name);
        disp(corr_matrix);
        
        % Plot heatmap
        figure;
        imagesc(corr_matrix);
        colormap jet;
        colorbar;
        title(['Cross-Correlation: ' muscle_name ' - ' rep_name]);
        xlabel('Patient');
        ylabel('Patient');
        axis square;
        xticks(1:num_patients);
        xticklabels(patient_ids);
        yticks(1:num_patients);
        yticklabels(patient_ids);
    end
end

% Save results
save_filename = fullfile(save_dir, 'crossCorrResults_between_patients.mat');
save(save_filename, 'crossCorrResults');

fprintf('Inter-subject cross-correlation results saved to: %s\n', save_filename);
