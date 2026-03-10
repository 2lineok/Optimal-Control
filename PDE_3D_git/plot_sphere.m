clc; clear; close all;
addpath Functions
fontSize = 30;

% -------------------------------------------------------
% 1) Read surface mesh from VTK file (ASCII format)
% -------------------------------------------------------


% NOTE:
%   Replace 'your_mesh_file.vtk' with the path to your own VTK surface mesh.
%   The file should be in ASCII VTK format (e.g., cortical surface mesh).
%
%   ⚠️ The actual mesh file is not included in this repository.

vtkfile = 'your_mesh_file.vtk';  % <-- Specify your .vtk mesh file here
fid = fopen(vtkfile, 'r');


% -------------------------------------------------------
% 2) Load PET data defined on mesh nodes
% -------------------------------------------------------

% NOTE:
%   Replace the paths below with your own observation .cvs file or .txt file.

petfile = 'your_observation_file_1.txt';
pet_data = readmatrix(petfile);



if fid == -1
    error('Unable to open the VTK file.');
end

% Locate the "POINTS" section
while true
    tline = fgetl(fid);
    if contains(tline, 'POINTS')
        break;
    end
end

parts = strsplit(strtrim(tline));
numPoints = str2double(parts{2});

% Read node coordinates (N x 3)
coords = fscanf(fid, '%f', numPoints * 3);
coords = reshape(coords, 3, numPoints)';

% Locate the "POLYGONS" section
while true
    tline = fgetl(fid);
    if contains(tline, 'POLYGONS')
        break;
    end
end

parts = strsplit(strtrim(tline));
numFaces = str2double(parts{2});

% Read triangular faces
faces_raw = fscanf(fid, '%d', numFaces * 4);
faces_raw = reshape(faces_raw, 4, numFaces)';
faces = faces_raw(:, 2:4) + 1;   % Convert from 0-based (VTK) to 1-based (MATLAB)

fclose(fid);





% Normalize PET values
pet_data = pet_data ./ max(pet_data(:));

% Ensure PET data size matches the mesh
if length(pet_data) ~= numPoints
    error('Mismatch between PET data size and mesh nodes.');
end

% -------------------------------------------------------
% 3) Visualization (three panels)
% -------------------------------------------------------

figure;

% --- Panel 1: Raw PET data at mesh nodes
ax1 = subplot(1,3,1);
scatter3(coords(:,1), coords(:,2), coords(:,3), 5, pet_data, 'filled');
axis equal off;
title(ax1, 'Original PET Node Data', 'FontSize', fontSize);
colormap(ax1, 'jet');

cbar1 = colorbar(ax1);
cbar1.FontSize = fontSize;

% --- Panel 2: FEM surface mesh
ax2 = subplot(1,3,2);
trisurf(faces, coords(:,1), coords(:,2), coords(:,3), ...
    'FaceColor', 'none', 'EdgeColor', [0.3 0.3 0.3]);

axis equal off;
title(ax2, 'FEM Surface Mesh', 'FontSize', fontSize);

% --- Panel 3: PET data mapped onto the mesh
ax3 = subplot(1,3,3);
trisurf(faces, coords(:,1), coords(:,2), coords(:,3), pet_data, ...
    'EdgeColor', 'none');

axis equal off;
camlight headlight;
lighting gouraud;

title(ax3, 'PET Data on Mesh', 'FontSize', fontSize);
colormap(ax3, 'jet');

cbar3 = colorbar(ax3);
cbar3.FontSize = fontSize;

% -------------------------------------------------------
% 4) Adjust colorbar size and position
% -------------------------------------------------------

cbarWidth  = 0.02;
cbarHeight = 0.6;
cbarYpos   = 0.2;

cbar1.Position = [0.35  cbarYpos  cbarWidth  cbarHeight];
cbar3.Position = [0.92  cbarYpos  cbarWidth  cbarHeight];