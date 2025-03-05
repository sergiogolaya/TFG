% Combinar repeticiones de EMG alineadas usando la media y la desviación estándar
% Procesa todos los archivos .mat en el directorio dtw_aligned.

clear; clc; close all;

enable_plots = true;

% Definir la ruta a la carpeta de datos alineados
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\dtw_aligned';

% Obtener la lista de todos los archivos .mat en el directorio
file_list = dir(fullfile(base_path, '*.mat'));

% Verificar si hay archivos en la carpeta
if isempty(file_list)
    error('No .mat files found in the directory.');
end

% Definir el directorio donde se guardarán los datos combinados
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\dtw_combined_emg';

% Asegurar que el directorio de guardado existe
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Recorrer cada archivo (cada paciente)
for f = 1:length(file_list)
    % Cargar el archivo
    file_name = file_list(f).name;
    file_path = fullfile(file_list(f).folder, file_name);
    load(file_path, 'aligned_data'); % Cargar la estructura correcta

    % Extraer el identificador del paciente del nombre del archivo
    [~, patient_id, ~] = fileparts(file_name);

    % Obtener la lista de músculos disponibles
    muscles = fieldnames(aligned_data);

    % Obtener los nombres de las repeticiones
    reps = fieldnames(aligned_data.(muscles{1}));
    num_reps = length(reps);

    % Inicializar estructura para almacenar los datos combinados
    combined_emg_struct = struct();

    % Crear figura para visualización (opcional)
    if enable_plots
        figure;
        tiledlayout(length(muscles), 1);
        sgtitle(['EMG Signals Combined (Mean ± Std Dev) - ' patient_id]);
    end

    % Recorrer cada músculo
    for m = 1:length(muscles)
        muscle_name = muscles{m};

        % Obtener la cantidad de muestras (suponiendo que todas las repeticiones tienen la misma longitud)
        sample_length = length(aligned_data.(muscle_name).(reps{1}).envelope);

        % Inicializar una matriz para almacenar todas las repeticiones
        rep_data = zeros(sample_length, num_reps);

        % Extraer datos de todas las repeticiones
        for i = 1:num_reps
            rep_name = reps{i};
            rep_data(:, i) = aligned_data.(muscle_name).(rep_name).envelope;
        end

        % Calcular la media y la desviación estándar de las repeticiones
        combined_signal = mean(rep_data, 2);
        std_dev = std(rep_data, 0, 2);

        % Guardar en la estructura de datos combinados
        combined_emg_struct.(muscle_name).envelope = combined_signal;
        combined_emg_struct.(muscle_name).std_dev = std_dev;

        % Graficar si la opción está habilitada
        if enable_plots
            nexttile;
            time_vector = 1:sample_length;
            fill([time_vector, fliplr(time_vector)], ...
                 [combined_signal - std_dev; flipud(combined_signal + std_dev)], ...
                 [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5); % Región sombreada

            hold on;
            plot(time_vector, combined_signal, 'b', 'LineWidth', 1.5);
            hold off;

            title(muscle_name, 'Interpreter', 'none');
            xlabel('Samples');
            ylabel('Amplitude');
            grid on;
            legend('Std Dev', 'Mean', 'Location', 'Best');

            % Asegurar que MATLAB actualiza la figura
            drawnow;
        end
    end

    % Guardar los datos combinados para este paciente
    save_filename = fullfile(save_dir, ['combined_dtw_emg_' patient_id '.mat']);
    save(save_filename, 'combined_emg_struct');

    fprintf('Combined DTW-aligned EMG data saved to: %s\n', save_filename);
end

fprintf('Processing complete. All patient files have been analyzed.\n');
