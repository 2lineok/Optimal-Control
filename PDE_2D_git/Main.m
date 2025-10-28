close all;clc;clear all
addpath Functions
ii=1
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

% Create the figure once and use it to update visualizations
hFig = figure; % Create the figure handle

% Define the NIfTI file name within each subject folder
fileName = 'av45.nii/av45.nii';  % Expected .nii file format

% We choosed the middle slice (48th slice)
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
    % Update the figure without creating new ones


    % Subplot 1: Original slice image
    ax(1) = subplot(2, 3, 1);
    imagesc(sliceData, [min(sliceData(:)), max(sliceData(:))]);
    %colormap(gray);  % Grayscale colormap
    hold on;
    axis equal;
    axis tight;
    set(gca, 'YDir', 'normal');
    title('Original Slice');

    
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
    
    % Visualize contours on a separate figure for clarity

    ax(2) = subplot(2,3,2);
    imagesc(sliceData, [min(sliceData(:)), max(sliceData(:))]); % Display brain slice
    %colormap(gray);
    % axis equal; axis tight; hold on;
    set(gca, 'YDir', 'normal');
    
    title(['Brain Image with ROI (Slice ' num2str(sliceNumber) ')']);
    hold on; axis equal;
    for i = 1:length(bd1)
        plot(bd1{i}, bd2{i}, 'b', 'LineWidth', 2);
    end
    legend('ROI Contour');
    
    
    ax(3) = subplot(2,3,3);
    hold on
    for i = 1:length(bd1)
        plot(bd1{i}, bd2{i}, 'b', 'LineWidth', 2);
    end
    legend('ROI Contour');
    % winsize = get(0, 'ScreenSize'); % Get full screen size
    %         set(gcf,'Position',winsize); 
    %         set(gcf, 'PaperPositionMode', 'auto')


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
    
    % Visualize the generated triangular mesh
    % figure;
    % triplot(tr);
    % title(['Triangular Mesh (Slice ' num2str(sliceNumber) ')']);
    % axis equal;
    
    % Create a PDE model
    model = createpde;
    
    % Import the geometry from the mesh
    geometryFromMesh(model, tnodes, telements);
    
    % Generate a finer mesh
    Hmax = 5; % Maximum edge length for smaller triangles
    mesh = generateMesh(model, 'Hmax', Hmax);
    
    % Get the geometry from the model
    geom = model.Geometry;
    
    % Subplot 4: Mesh visualization
    ax(4) = subplot(2, 3, 4);
    pdemesh(model);
    title(['Finer FEM Mesh with Hmax = ' num2str(Hmax)]);
    axis equal;
    
    % Subplot 5: FEM model plot
    ax(5) = subplot(2, 3, 5);  
    pdegplot(model, 'FaceLabels', 'on');
    title(['FEM Model (Slice ' num2str(sliceNumber) ')']);
    axis equal;

    % FEM mesh node coordinates (2D)
    femX = model.Mesh.Nodes(1, :);
    femY = model.Mesh.Nodes(2, :);
    
    % Create grid for 2D image (matching x, y order)
    [yGrid, xGrid] = meshgrid(1:size(sliceData, 2), 1:size(sliceData, 1));
    
    % Interpolation
    interpolatedData2D = interp2(yGrid, xGrid, sliceData, femX, femY, 'linear', 0);
    
    % Visualization of interpolated data
    ax(6) = subplot(2, 3, 6);
    pdeplot(model, 'XYData', interpolatedData2D, 'ColorMap', 'jet');  % Jet colormap
    title('Interpolated Data on FEM Mesh (2D)');
    axis equal;
    
    % Set colormap for the last subplot (subplot 6) to 'jet'
    %colormap(ax(1), 'gray');
    %colormap(ax(2), 'gray');
    %colormap(ax(6), 'jet');
    
    % Ensure the title and updates reflect the current slice number
    sgtitle(sprintf("Slice number = %d",j))
    winsize = [144.0000  400  720.0000  300.0000];


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
        
    
        %diff_is=norm((paras.omega' + 2*paras.alpha*tC))
        pars.c0=beta*c_old+(1-beta)*C_tilda;
    
    
    
        
        
     
    if flag ==1
        break;
    end
    sprintf("This is norm of c_old-c0 %d",norm(pars.c0-c_old))
    JT=pars.JT;
    sprintf("This is del J norm %d",norm(JT))
    if norm(pars.c0-c_old)<1.e-11 || norm(JT)<1.e-4
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




for j=48%1:96

    
    max_iter=  200;
    
    
    while_max = 40;
    
    Jall = [];
    
    beta=0.5;
    
    sprintf("This is average value for C %d",pars.weig*pars.c0'/tmax) 
    for i = 1:max_iter
        i
        c_old = pars.c0;
        
        if i ==1    
        figure(90)
        subplot(2,3,1)
        plot(pars.tlist,pars.c0)
        xlabel('t'); ylabel('C_0(t)')
        xlim([tmin tmax]);
        ylim([0 max(pars.c0)*1.5]);

	    title(sprintf('alpha = %d',(pars.alpha)))
        
        end
          
      
        C_tilda=Ldirection(c_old);
        if i==1
                
            this_u_initial=pars.u;   
	        this_w_initial=pars.w;  
        
            figure(99); 
        
            plot_i = 0;
            for i2 = 1:round((size(pars.u,2)-1)/3):size(pars.u,2)
                plot_i = plot_i+1;
                subplot(2,4,plot_i)

		        time_integral = trapz(pars.tlist(1:i2), pars.u(:, 1:i2), 2);
                pdeplot(pars.model, 'XYData', time_integral(:));
                set(gca,'Ydir','reverse')
                axis off
                box on; axis tight; axis equal;
		        colormap('jet');
                title(['t = ' num2str(pars.tlist(i2))])
                if plot_i==1
                    cmax = max(trapz(pars.tlist(1:end), pars.u(:, 1:end), 2))+0.01;
                    cmin = 0;
                end
            clim([cmin cmax])
            end
        
        
        
        
        figure(90);subplot(2,3,2)
        plot(pars.tlist,pars.u_omega)
        xlabel('t'); ylabel('\int_{\Omega} u dx')
        xlim([tmin tmax]);
        title(['J = ' num2str(pars.J)])
        
        figure(90);subplot(2,3,3)
        plot(pars.tlist,pars.w_omega)
        xlabel('t'); ylabel('\int_{\Omega} w dx')
        xlim([tmin tmax]);
        title(['del J = ' num2str(norm(pars.JT))])
    
        end
     
        Jall(i) = pars.J;
        pars.c0=beta*c_old+(1-beta)*C_tilda;
    
    
    
        
        
     
        if flag ==1
            break;
        end
        sprintf("This is norm of c_old-c0 %d",norm(pars.c0-c_old))
        JT=pars.JT;
        sprintf("This is del J norm %d",norm(JT))

        if norm(pars.c0-c_old)<1.e-11 || norm(JT)<1.e-4
            disp('The optimizer is obtained.')
            break;
        end

        sprintf("This is average value for C %d",pars.weig*pars.c0'/tmax) 
    end
    
    
    figure(99); 
    
    plot_i = 0;
    for i = 1:round((size(pars.u,2)-1)/3):size(pars.u,2)
        plot_i = plot_i+1;
        subplot(2,4,plot_i+4)

	    colormap('jet');
		time_integral = trapz(pars.tlist(1:i), pars.u(:, 1:i), 2);
        pdeplot(pars.model, 'XYData', time_integral(:));

        set(gca,'Ydir','reverse')
        axis off
        box on; axis tight; axis equal; 
        title(['t = ' num2str(pars.tlist(i))])
        clim([cmin cmax])
        colormap("jet")
        winsize = [144.0000  400  720.0000  320.0000];
            set(gcf,'Position',winsize); 
            set(gcf, 'PaperPositionMode', 'auto')
            %fn_name = [mfilename];
            %fn_eps = [fn_name 'u.eps'];
            %print(gcf,'-depsc',fn_eps,'-r300');
            %fn_fig = [fn_name 'u.fig'];
            fn_name = mfilename;  
            fn_fig = fullfile(path, [fn_name sprintf('u_nor.fig')]);
            savefig(fn_fig);      
        
    end
    
    sprintf("This is final average value for C %d",pars.weig*pars.c0'/tmax) 
    figure(90)
    subplot(2,3,4)
    plot(pars.tlist,pars.c0)
    xlabel('t'); ylabel('optimized C(t)')
    xlim([tmin tmax]);
    %axis([0 max(pars.tlist) -0.01 pars.A+0.01])
    title(['alpha = ' num2str(pars.alpha)])
    
    figure(90);subplot(2,3,5)
    plot(pars.tlist,pars.u_omega)
    xlabel('t'); ylabel('\int_{\Omega} u dx')
    xlim([tmin tmax]);
    title(['J = ' num2str(pars.J)])
      % axis([0 max(pars.tlist) 0.5 0.9])
     
    figure(90);subplot(2,3,6)
    plot(pars.tlist,pars.w_omega)
    xlabel('t'); ylabel('\int_{\Omega} w dx')
    xlim([tmin tmax]);
    title(['del J = ' num2str(norm(pars.JT))])
    winsize = [144.0000  400  720.0000  480.0000];
            set(gcf,'Position',winsize); 
            set(gcf, 'PaperPositionMode', 'auto')
            %fn_name = [mfilename];
            %fn_eps = [fn_name '.eps'];
            %print(gcf,'-depsc',fn_eps,'-r300');
            %fn_fig = [fn_name '.fig'];
    
            fn_name = mfilename;  
            fn_fig = fullfile(path, [fn_name sprintf('_nor.fig')]);
            savefig(fn_fig);   
            fn_name = mfilename;  
            fn = fullfile(path, [fn_name sprintf('_nor.mat')]);

save(fn, '-v7.3'); 

end


