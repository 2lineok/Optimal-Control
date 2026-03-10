clc; clear; close all;
addpath Functions
% NOTE:
%   Replace 'your_mesh_file.vtk' with the path to your own VTK surface mesh.
%   The file should be in ASCII VTK format (e.g., cortical surface mesh).
%
%   ⚠️ The actual mesh file is not included in this repository.

vtkfile = 'your_mesh_file.vtk';  % <-- Specify your .vtk mesh file here
[coords, faces] = read_vtk_ascii(vtkfile);
N = size(coords,1);
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

u_stack = cat(2, Uobs{:});
u_max = max(u_stack, [], 'all');
if u_max == 0, error('All-zero observations'); end
for k=1:numel(Uobs)
    Uobs{k} = Uobs{k} / u_max;
end
u0 = Uobs{1};


Dfunc = @(x,y,z) 1.0; 
[K, M, ~] = assemble_surfaceFEM_fast(coords, faces, Dfunc); % K for D=1


substeps_per_year = 30;
Tfinal = 8;
maxit = 100000
dt = 1 / substeps_per_year 
tgrid = 0:dt:Tfinal;             
Nsteps = round(Tfinal * substeps_per_year);
C_time_or_fun = 0.1*ones(Nsteps+1,1);


% Diffusion and reaction parameters
% NOTE: D and rho values are obtained from inverse_problem.m.
D   = 0.16285;
K   = D * K;
rho = 0.00183069;
C_old = zeros(Nsteps+1,1);
alpha = 5*1e5
time_step_update=1/(4*alpha)


A = M + dt*K;    % sparse SPD matrix
% incomplete Cholesky factorization
L = ichol(A, struct('type','ict','droptol',1e-4));


for iter = 1:maxit
    % Gradient direction compute. As you can see in the remark from the paper, it is exactly same with Linear Combination Adjoint Method.
    [J, DJ] = Gdirection(u0, K, M, rho, C_time_or_fun, dt, alpha,A,L);

    % Update
    C_time_or_fun = C_time_or_fun(:) - time_step_update * DJ(:);

    % Compute the Norm
    diff_norm = norm(C_time_or_fun - C_old);
    grad_norm = norm(DJ);

    fprintf('Iter %3d: ||C - C_old|| = %.3e, ||DJ|| = %.3e\n', iter, diff_norm, grad_norm);

    % crieteria
    if diff_norm < 1e-9
        disp('The optimizer is obtained.');
        break;
    end

    % Update C_old
    C_old = C_time_or_fun;

    avgC = trapz(tgrid, C_time_or_fun) / Tfinal;
    fprintf('         Average value for C = %.6e\n', avgC);
end
fprintf('         Average value for C = %.6e\n', avgC);


alpha_str = sprintf('%.2e', alpha)             
tsu_str   = sprintf('%.2e', time_step_update)  


filename = sprintf('data_alpha%s_ts%s.mat', alpha_str, tsu_str)
save(filename, 'C_time_or_fun', 'rho', 'D', 'alpha', 'tgrid', 'time_step_update');



