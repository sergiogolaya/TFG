% Define the directories
data_dir = 'C:\Users\sergi\Documents\CEU\TFG\medidas\patients\combined_emg';
save_dir = 'C:\Users\sergi\Documents\CEU\TFG\results\mean';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% Get all .mat files in the directory
file_list = dir(fullfile(data_dir, '*.mat'));

% Define mapping between descriptive muscle names and struct field names
muscle_names_map = {
    'Biceps Brachii', 'muscle_1';
    'Triceps Brachii', 'muscle_2';
    'Front Deltoid', 'muscle_3';
    'Trapezius', 'muscle_4';
    'Lateral Deltoid', 'muscle_5';
    'Posterior Deltoid', 'muscle_6';
    'Palmaris Longus', 'muscle_7';
    'Extensor Carpi Radialis', 'muscle_8'
};

% Initialize storage for EMG data
subject_data = {};

% Loop through all .mat files to load data
for i = 1:length(file_list)
    file_path = fullfile(data_dir, file_list(i).name);
    loaded_data = load(file_path);
    emg_struct = loaded_data.combined_emg_struct;

    if i == 1
        muscle_fields = fieldnames(emg_struct);
        num_muscles = numel(muscle_fields);
        num_samples = size(emg_struct.(muscle_fields{1}).envelope, 1);
        subject_data = zeros(num_samples, length(file_list), num_muscles);
    end

    for m = 1:num_muscles
        subject_data(:, i, m) = emg_struct.(muscle_fields{m}).envelope;
    end
end

% Initialize result structure
emg_results = struct();
emg_results.time_vector = linspace(0, 100, num_samples);

% Define movement phases with specific colors
phases = {
    'Reach',     [0, 12],     [0.9, 0.8, 0.8];   % light pink
    'Grasp',     [12, 50],    [0.8, 0.9, 0.8];   % light green
    'Transport', [50, 80],    [0.8, 0.85, 0.95]; % light blue
    'Release',   [80, 100],   [0.95, 0.95, 0.85];% light yellow
};

% Store all muscle means for the combined plot
combined_means = [];

% Process each muscle
for m = 1:num_muscles
    muscle_mean = mean(subject_data(:,:,m), 2);
    muscle_std  = std(subject_data(:,:,m), 0, 2);

    emg_results.(muscle_fields{m}).mean = muscle_mean;
    emg_results.(muscle_fields{m}).std_dev = muscle_std;

    idx = find(strcmp(muscle_names_map(:,2), muscle_fields{m}), 1);
    if ~isempty(idx)
        muscle_name = muscle_names_map{idx, 1};
    else
        muscle_name = strrep(muscle_fields{m}, '_', ' ');
    end

    % Plot individual muscle figure
    figure('Position', [100, 100, 1200, 800]);
    hold on;

    % Plot ± std
    fill([emg_results.time_vector, fliplr(emg_results.time_vector)], ...
         [muscle_mean + muscle_std; flipud(muscle_mean - muscle_std)], ...
         'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    % Plot mean
    plot(emg_results.time_vector, muscle_mean, 'b', 'LineWidth', 2);

    ax = gca;
    ylim(ax, [0 0.8]);  % o ajusta si necesitas más alto
    yl = ylim(ax);      % se actualiza al nuevo rango manual

    for p = 1:size(phases, 1)
        range = phases{p, 2};
        color = phases{p, 3};
        fill(ax, [range(1), range(2), range(2), range(1)], ...
                  [yl(1), yl(1), yl(2), yl(2)], ...
                  color, 'FaceAlpha', 0.8, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        text(mean(range), yl(2)*0.95, phases{p,1}, ...
             'HorizontalAlignment', 'center', ...
             'FontSize', 10, 'Color', [0.2 0.2 0.2]);
    end

    set(ax, 'Children', flipud(get(ax, 'Children')));
    hold off;

    xlabel('% Reach and Grasp Cycle', 'FontSize', 16);
    ylabel('Normalized EMG Activity', 'FontSize', 16);
    title(['Representative EMG Profile - ', muscle_name], 'FontSize', 18);
    legend({'Mean EMG', '± Std Dev'}, 'Location', 'best', 'FontSize', 14);
    grid on;

    saveas(gcf, fullfile(save_dir, [muscle_fields{m}, '_emg_curve.png']));
    print(gcf, fullfile(save_dir, [muscle_fields{m}, '_emg_curve.png']), '-dpng', '-r300');
    close(gcf);

    % Store for combined plot
    combined_means = [combined_means; muscle_mean'];
end

% Save the structured EMG results
save(fullfile(save_dir, 'representative_emg_curve.mat'), 'emg_results');
disp('Representative EMG curves computed and saved.');

% --------- Combined plot with all muscles ---------
figure('Position', [200, 200, 1200, 800]);
hold on;

colors = lines(num_muscles);
legend_labels = {};

for m = 1:num_muscles
    plot(emg_results.time_vector, emg_results.(muscle_fields{m}).mean, ...
         'LineWidth', 1.8, 'Color', colors(m, :));
    idx = find(strcmp(muscle_names_map(:,2), muscle_fields{m}), 1);
    if ~isempty(idx)
        legend_labels{end+1} = muscle_names_map{idx, 1};
    else
        legend_labels{end+1} = strrep(muscle_fields{m}, '_', ' ');
    end
end

% Shading movement phases
ax = gca;
ylim(ax, [0 0.8]);  % o ajusta si necesitas más alto
yl = ylim(ax);      % se actualiza al nuevo rango manual
for p = 1:size(phases, 1)
    range = phases{p, 2};
    color = phases{p, 3};
    fill(ax, [range(1), range(2), range(2), range(1)], ...
              [yl(1), yl(1), yl(2), yl(2)], ...
              color, 'FaceAlpha', 0.8, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    text(mean(range), yl(2)*0.1, phases{p,1}, ...
         'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', [0.2 0.2 0.2]);
end

set(ax, 'Children', flipud(get(ax, 'Children')));
xlabel('% Reach and Grasp Cycle', 'FontSize', 16);
ylabel('Normalized EMG Activity', 'FontSize', 16);
title('Combined Representative EMG Curves', 'FontSize', 18);
legend(legend_labels, 'Location', 'northeast', 'FontSize', 12);
grid on;

saveas(gcf, fullfile(save_dir, 'combined_emg_curve.png'));
print(gcf, fullfile(save_dir, 'combined_emg_curve.png'), '-dpng', '-r300');
close(gcf);