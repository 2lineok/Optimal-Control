clc; clear; close all;
addpath Functions
% NOTE:
%   Replace 'your_mesh_file.vtk' with the path to your own VTK surface mesh.
%   The file should be in ASCII VTK format (e.g., cortical surface mesh).
%
%   ⚠️ The actual mesh file is not included in this repository.

vtkfile = 'your_mesh_file.vtk';  % <-- Specify your .vtk mesh file here
[coords, faces] = read_vtk_ascii(vtkfile);
N = size(coords,1)

% 2) Observation files (earliest = initial state, last = validation)
% NOTE:
%   Replace the paths below with your own observation .txt files.
%   Each file name includes a timestamp in the format YYYYMMDDHHMMSS,
%   which can be converted to datetime for temporal ordering.
obs_files = {
    'your_observation_file_1.txt'
    'your_observation_file_2.txt'
    'your_observation_file_3.txt'
    'your_observation_file_4.txt'
    'your_observation_file_5.txt'
};

Uobs = cell(numel(obs_files),1);
for k = 1:numel(obs_files)
    if ~isfile(obs_files{k})
        error('Missing file: %s', obs_files{k});
    end
    u = readmatrix(obs_files{k});
    if numel(u) ~= N
        error('Size mismatch in %s', obs_files{k});
    end
    Uobs{k} = u(:);
end

% normalization
u_stack = cat(2, Uobs{:});
u_max = max(u_stack, [], 'all');
if u_max == 0, error('All-zero observations'); end
for k=1:numel(Uobs)
    Uobs{k} = Uobs{k} / u_max;
end

u_stack = cat(2, Uobs{:});
u_max = max(u_stack, [], 'all');
u_min = min(u_stack, [], 'all');

% ===============================
% Visualization
% ===============================
figure('Position', [100 100 1700 350]);
tiledlayout(1, numel(Uobs), 'Padding', 'compact', 'TileSpacing', 'tight');

% Time labels for visualization
% NOTE: Replace these with the actual years corresponding to your data.
time_labels = {'2011', '2013', '2015', '2017', '2019'};


for k = 1:numel(Uobs)
    nexttile;
    patch('Faces', faces, 'Vertices', coords, ...
          'FaceVertexCData', Uobs{k}, ...
          'FaceColor', 'interp', ...
          'EdgeColor', 'none');
    axis equal off
    view([-90 0])
    caxis([u_min u_max])
    colormap(parula)
    title(sprintf('\\textbf{Year %s}', time_labels{k}), ...
          'Interpreter', 'latex', ...
          'FontSize', 18, ...
          'FontWeight', 'bold')
end


cb = colorbar('east', 'FontSize', 14, 'Ticks', 0:0.2:1);
cb.Label.FontSize = 16;
cb.Position = [0.94, 0.25, 0.02, 0.4];  % [x, y, width, height]

