clear; clc; close all;

% Solicitar archivo de EMG del usuario
[file, path] = uigetfile('*.mat', 'Seleccione el archivo de EMG');
if isequal(file, 0)
    disp('No se seleccionó ningún archivo. Saliendo del programa.');
    return;
end

user_file_path = fullfile(path, file);
user_data = load(user_file_path);

% Verificar si la estructura es válida
if ~isfield(user_data, 'emg_data_struct') || ~isfield(user_data.emg_data_struct, 'cut_data')
    error('El archivo seleccionado no contiene la estructura esperada.');
end

% Normalizar la señal de EMG del usuario
num_points = 1000;
reps = fieldnames(user_data.emg_data_struct.cut_data);
muscles = fieldnames(user_data.emg_data_struct.cut_data.(reps{1}));

for r = 1:length(reps)
    rep_name = reps{r};
    for m = 1:length(muscles)
        muscle_name = muscles{m};
        envelope_data = user_data.emg_data_struct.cut_data.(rep_name).(muscle_name).envelope;

        if isempty(envelope_data)
            continue;
        end
        
        envelope_data = fillmissing(envelope_data, 'linear');
        original_time = linspace(0, 100, length(envelope_data));
        normalized_time = linspace(0, 100, num_points);
        interpolated_envelope = interp1(original_time, envelope_data, normalized_time, 'pchip');
        
        min_val = min(interpolated_envelope);
        max_val = max(interpolated_envelope);
        if max_val > min_val
            normalized_envelope = (interpolated_envelope - min_val) / (max_val - min_val);
        else
            normalized_envelope = interpolated_envelope;
        end
        
        user_data.emg_data_struct.cut_data_normalized.(rep_name).(muscle_name).envelope = normalized_envelope;
    end
end

% Cargar datos de referencia (ya normalizados)
reference_file = 'representative_emg_curve.mat'; % Cambiar según sea necesario
reference_data = load(reference_file);

if ~isfield(reference_data, 'emg_results')
    error('El archivo de referencia no contiene la estructura esperada.');
end

% Comparación mediante correlación cruzada
crossCorrResults = struct();
max_lag = 50; % Permitir hasta ±50 muestras de desplazamiento

for m = 1:length(muscles)
    muscle_name = muscles{m};
    all_reps_data = [];
    
    % Extraer datos normalizados del usuario
    for r = 1:length(reps)
        rep_name = reps{r};
        all_reps_data = [all_reps_data; user_data.emg_data_struct.cut_data_normalized.(rep_name).(muscle_name).envelope];
    end
    
    % Extraer datos de referencia
    reference_envelope = reference_data.emg_results.(muscle_name).mean;
    
    % Calcular correlación cruzada
    num_reps = size(all_reps_data, 1);
    corr_values = zeros(num_reps, 1);
    
    for i = 1:num_reps
        [xcorr_values, lags] = xcorr(all_reps_data(i, :), reference_envelope, max_lag, 'coeff');
        corr_values(i) = max(xcorr_values);
    end
    
    % Guardar resultados
    crossCorrResults.(muscle_name).correlation = corr_values;
    crossCorrResults.(muscle_name).mean_corr = mean(corr_values);
    crossCorrResults.(muscle_name).std_corr = std(corr_values);
end

% Mostrar resultados
disp('Resultados de la correlación cruzada:');
disp(crossCorrResults);

% Graficar la correlación cruzada
figure;
hold on;
muscle_names = fieldnames(crossCorrResults);
bar_data = [];

for i = 1:length(muscle_names)
    bar_data = [bar_data; crossCorrResults.(muscle_names{i}).mean_corr];
end

bar(bar_data);
xticks(1:length(muscle_names));
xticklabels(muscle_names);
ylabel('Correlación cruzada');
title('Comparación de señales de EMG del usuario con datos de referencia');
hold off;
