% Combinar 5 repeticiones de EMG en una sola y visualizar los resultados

% Definir el directorio base donde se encuentran los datos normalizados
base_path = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\normalized';

% Seleccionar el archivo .mat con los datos normalizados
[input_file, input_path] = uigetfile(fullfile(base_path, '*.mat'), 'Select Normalized EMG Data File');

% Verificar si el usuario canceló la selección
if isequal(input_file, 0)
    error('No file selected');
end

% Cargar el archivo seleccionado
full_file_path = fullfile(input_path, input_file);
load(full_file_path);

% Obtener el identificador del paciente desde el nombre del archivo
[~, patient_id, ~] = fileparts(input_file);

% Obtener lista de músculos
muscles = fieldnames(emg_data_struct.cut_data_normalized.rep_1);

% Obtener nombres de repeticiones
reps = fieldnames(emg_data_struct.cut_data_normalized);
num_reps = length(reps);

% Inicializar estructura para almacenar los datos combinados
combined_emg_struct = struct();

% Crear una figura para visualizar los resultados
figure;
tiledlayout(length(muscles), 1);
sgtitle('Señales de EMG combinadas (Media de 5 repeticiones)');

% Iterar sobre cada músculo
for m = 1:length(muscles)
    muscle_name = muscles{m};
    
    % Inicializar matriz para almacenar las repeticiones
    sample_length = length(emg_data_struct.cut_data_normalized.rep_1.(muscle_name).envelope);
    rep_data = zeros(sample_length, num_reps);
    
    % Extraer los datos de todas las repeticiones
    for i = 1:num_reps
        rep_data(:, i) = emg_data_struct.cut_data_normalized.(reps{i}).(muscle_name).envelope;
    end
    
    % Calcular la media de las repeticiones
    combined_signal = mean(rep_data, 2);
    combined_emg_struct.(muscle_name).envelope = combined_signal;
    
    % Graficar la señal combinada
    nexttile;
    plot(combined_signal, 'LineWidth', 1.5);
    title(muscle_name, 'Interpreter', 'none');
    xlabel('Muestras');
    ylabel('Amplitud');
    grid on;
end

% Definir directorio para guardar el archivo combinado
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';

% Crear el directorio si no existe
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Guardar el archivo combinado con el identificador del paciente
save_filename = fullfile(save_dir, ['combined_emg_' patient_id '.mat']);
save(save_filename, 'combined_emg_struct');

fprintf('Datos combinados guardados en: %s\n', save_filename);
