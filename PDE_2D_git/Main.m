close all;clc;clear all
addpath Functions
ii=1 % This is the for subject #.
global pars
%% ----------------------------
%  User Data Configuration
% ----------------------------
% NOTE:
%   Replace 'Data' with the path to your own data directory containing
%   the subject folders (e.g., "002_*").
%   Each folder should contain the required NIfTI (.nii) files.
%
%   Example directory structure:
%       YourProject/
%           ├── main_script.m
%           └── Data/
%               ├── 002_subject1/
%               │     └── av45.nii
%               └── 002_subject2/
%                     └── av45.nii
%
%   ⚠️ The actual data files (.nii) are not included in this repository.
%   Please add your own before running the code.

% Define the base directory path (update this path as needed)
base_path = 'Data';   % <-- Set your local data path here

% Get a list of all matching subdirectories (e.g., 002_*)
subdirs = dir(fullfile(base_path, '002_*'));

% Filter only directories (exclude files)
subdirs = subdirs([subdirs.isdir]);


% Define the NIfTI file name within each subject folder
fileName = 'av45.nii/av45.nii';  % Expected .nii file format

% We chose the middle slice (48th slice)
for j=48%1:96
% Loop through each matching file

    % Construct full file path
    filePath = fullfile(subdirs(ii).folder, subdirs(ii).name)
    path=filePath
    niiFile = fullfile(filePath, fileName)
	
	sprintf("This is when j=%d and ii=%d",j,ii)
    
    % Load the NIfTI file using niftiread (requires MATLAB’s Image Processing Toolbox)
    niiData = niftiread(niiFile);
    
    % Select slice and apply threshold
    sliceNumber = j; % Example slice number
    sliceData = niiData(:, :, sliceNumber);
    
    threshold = 0.1; % Example threshold value
    ROI = sliceData > threshold;
    sliceData=sliceData./(max(max(sliceData)));


    % Overlay the ROI contours on the brain slice
    [c, h] = contour(double(ROI), [0.5, 0.5], 'Visible', 'off');
    
    % Extract contour boundary points
    ind = find(c(1, :) == 0.5);
    bd1 = cell(1, length(ind));
    bd2 = cell(1, length(ind));
    
    for i = 1:length(ind)
        if i < length(ind)
            nind = ind(i)+1:ind(i+1)-1;
        else
            nind = ind(i)+1:size(c, 2);
        end
        bd1{i} = c(1, nind); % x-coordinates
        bd2{i} = c(2, nind); % y-coordinates
    end
    

    
    pgon = polyshape(bd1, bd2);
    % Handle potential issues with empty polygons
    if isempty(pgon.Vertices)
        error('Polyshape is empty. Verify the input boundaries.');
    end
    
    
    % Triangulate the polyshape
    tr = triangulation(pgon);
    
    % Extract nodes and elements for the mesh
    tnodes = tr.Points'; % Node coordinates
    telements = tr.ConnectivityList'; % Connectivity
    

    % Create a PDE model
    model = createpde;
    
    % Import the geometry from the mesh
    geometryFromMesh(model, tnodes, telements);
    
    % Generate a finer mesh
    Hmax = 5; % Maximum edge length for smaller triangles
    mesh = generateMesh(model, 'Hmax', Hmax);
    
    % Get the geometry from the model
    geom = model.Geometry;


    % FEM mesh node coordinates (2D)
    femX = model.Mesh.Nodes(1, :);
    femY = model.Mesh.Nodes(2, :);
    
    % Create grid for 2D image (matching x, y order)
    [yGrid, xGrid] = meshgrid(1:size(sliceData, 2), 1:size(sliceData, 1));
    
    % Interpolation
    interpolatedData2D = interp2(yGrid, xGrid, sliceData, femX, femY, 'linear', 0);
    
    % Define uniform position for all subplots
    pos1 = [0.05, 0.1, 0.27, 0.8]; % Left
    pos2 = [0.36, 0.1, 0.27, 0.8]; % Center
    pos3 = [0.69, 0.1, 0.27, 0.8]; % Right
    
    % Subplot 1: Original slice image
    ax1 = subplot(1, 3, 1);
    imagesc(ax1, sliceData, [min(sliceData(:)), max(sliceData(:))]);
    set(ax1, 'YDir', 'normal'); % Fix flipped Y-axis
    axis(ax1, 'tight');
    axis(ax1, 'equal');
    xlim(ax1, [0, 160]);
    ylim(ax1, [0, 160]);
    colormap(ax1, 'gray');
    title(ax1, 'Original Slice', 'FontSize', 20);
    set(ax1, 'Position', pos1); % Apply uniform position
    
    % Subplot 2: Mesh visualization
    ax2 = subplot(1, 3, 2);
    pdemesh(model, 'Parent', ax2);
    %title(ax2, ['Finer FEM Mesh with Hmax = ' num2str(Hmax)], 'FontSize', 20);
    title(ax2, ['FEM Mesh'], 'FontSize', 20);
    axis(ax2, 'tight');
    axis(ax2, 'equal');
    xlim(ax2, [0, 160]);
    ylim(ax2, [0, 160]);
    set(ax2, 'Position', pos2); % Apply uniform position
    
    % Subplot 3: Interpolated data on FEM mesh
    ax3 = subplot(1, 3, 3);
    interpolatedData2D=interpolatedData2D/max(interpolatedData2D(:));
    pdeplot(model, 'XYData', interpolatedData2D, 'Parent', ax3);
    title(ax3, 'Interpolated Data on FEM Mesh (2D)', 'FontSize', 20);
    axis(ax3, 'tight');
    axis(ax3, 'equal');
    xlim(ax3, [0, 160]);
    ylim(ax3, [0, 160]);
    set(ax3, 'Position', pos3); % Apply uniform position
    
    % Add colorbar and disable uicontextmenu
    cbar = colorbar(ax3);
    cbar.UIContextMenu = []; % Disable right-click menu
    colormap(ax3, 'jet'); % Apply colormap

	






    tmin = 0;
    tmax = 42;
   



    % parameters
    pars.tmax = tmax;
    pars.rho = 0.012;
    pars.K = 1;
    pars.Dcoeff = [];
    pars.alpha = 1000000;
    

    pars.u0ini = @(location) interp2(yGrid, xGrid, sliceData, location.x, location.y, 'linear', 0);
    
    
    pars.w0ini = 0;
    pars.tlist = linspace(tmin,tmax,210+1);
    
   
    
    pars.c0 = (1e-02)*ones(size(pars.tlist));

    pars.h = pars.tlist(2)-pars.tlist(1);
    % prepare quadrature rule weight in time
    % Simpson's rule
    weig = ones(size(pars.tlist));
    weig(2:2:end-1) = 4;
    weig(3:2:end-2) = 2;
    weig = weig/3*pars.h;
    pars.weig = weig;
    
    
    
    
    
    model.SolverOptions.ReportStatistics = 'on';
    applyBoundaryCondition(model,'neumann','Edge',1:model.Geometry.NumEdges);
    pars.model = model; 
    
    max_iter=  20000;
    while_max = 40;
    
    Jall = [];
    
    beta=0.5;
    
    sprintf("This is average value for C %d",pars.weig*pars.c0'/tmax) 
    for i = 1:max_iter
        i
        c_old = pars.c0;
        
          
      
        C_tilda=Ldirection(c_old);
     
        Jall(i) = pars.J;
        pars.c0=beta*c_old+(1-beta)*C_tilda;
    
    
    if flag ==1
        break;
    end
    sprintf("This is norm of c_old-c0 %d",norm(pars.c0-c_old))
    JT=pars.JT;
    sprintf("This is del J norm %d",norm(JT))
    if norm(pars.c0-c_old)<1.e-9
        disp('The optimizer is obtained.')
        break;
    end
         
    sprintf("This is average value for C %d",pars.weig*pars.c0'/tmax) 
    end
    
    

     
        
end

sprintf("This is final average value for C %d",pars.weig*pars.c0'/tmax) 



c_avg=pars.weig*pars.c0'/tmax;
pars.c0 = c_avg*ones(size(pars.tlist));
pars.u0ini = @(location) interp2(yGrid, xGrid, sliceData, location.x, location.y, 'linear', 0);
pars.w0ini = 0;




for j=48

    
    max_iter=  200;
    
    
    while_max = 40;
    
    Jall = [];
    
    beta=0.5;
    
    sprintf("This is average value for C %d",pars.weig*pars.c0'/tmax) 
    for i = 1:max_iter
        i
        c_old = pars.c0;
        
      
        C_tilda=Ldirection(c_old);
        if i==1
                
            this_u_initial=pars.u;   
	        this_w_initial=pars.w;  
        
        end
     
        Jall(i) = pars.J;
        pars.c0=beta*c_old+(1-beta)*C_tilda;
    
    
    
        
        
     
        if flag ==1
            break;
        end
        sprintf("This is norm of c_old-c0 %d",norm(pars.c0-c_old))
        JT=pars.JT;
        sprintf("This is del J norm %d",norm(JT))

        if norm(pars.c0-c_old)<1.e-9
            disp('The optimizer is obtained.')
            break;
        end

        sprintf("This is average value for C %d",pars.weig*pars.c0'/tmax) 
    end
   
    
    sprintf("This is final average value for C %d",pars.weig*pars.c0'/tmax) 

    fn_name = mfilename;  
    fn = fullfile(path, [fn_name sprintf('_avg_data_v%g_nor.mat',svsv)]);
    save(fn, '-v7.3'); 

end

