clc; clear; close all;
addpath Functions
% NOTE:
%   Replace 'your_mesh_file.vtk' with the path to your own VTK surface mesh.
%   The file should be in ASCII VTK format (e.g., cortical surface mesh).
%
%   Example:
%       vtkfile = 'Data/lh_r.pial.vtk';
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



u_stack = cat(2, Uobs{:});
u_max = max(u_stack, [], 'all');
if u_max == 0, error('All-zero observations'); end
for k=1:numel(Uobs)
    Uobs{k} = Uobs{k} / u_max;
end

u0_obs = Uobs{1};
t_years = zeros(numel(obs_files),1);
for k=1:numel(obs_files)
    t_years(k) = parse_years_from_filename(obs_files{k}, obs_files{1});
end




nTotal = numel(Uobs);
nTrain = nTotal - 1;  % last is for test (validation)

Uobs_train = Uobs(1:nTrain);
t_years_train = t_years(1:nTrain);

Uobs_test = Uobs{end};
t_test = t_years(end);




% 3) FEM assembly 
Dfunc = @(x,y,z) 1.0;
[K1, M, ~] = assemble_surfaceFEM_fast(coords, faces, Dfunc); % K for D=1


% 4) Forward solver (IMEX)
substeps_per_year = 30;    
% dt_model = 1/substeps_per_year 


Xall = []; Yall = [];

for k = 1:(numel(t_years_train)-1)
    u_now = Uobs_train{k};
    u_next = Uobs_train{k+1};
    dtk = t_years_train(k+1) - t_years_train(k);


    % left: M*(u_{k+1}-u_k)/dt
    yk = (M*(u_next - u_now)) / dtk;

    % right: [-K1*u,  M*(u.*(1-u))]
    x1 = -K1 * u_now;
    x2 = M * (u_now .* (1 - u_now));

    Xk = [x1, x2];
    Xall = [Xall; Xk];
    Yall = [Yall; yk];
end

% least squares solution
theta_ls = Xall \ Yall;  % [D; rho]
D_ls = theta_ls(1);
rho_ls = theta_ls(2);

fprintf('Coarse LS estimate: D=%.3g, rho=%.3g\n', D_ls, rho_ls);

% fminsearch initial value
theta0 = log([max(D_ls,1e-6), max(rho_ls,1e-6)]);


% 5) (theta → [D,rho] = exp(theta))
u0 = u0_obs;  
obj = @(theta) objective_D_rho(theta, u0, Uobs_train, t_years_train, K1, M, substeps_per_year);
options = optimset('Display','iter','TolX',1e-4,'TolFun',1e-4,'MaxIter',200);
[theta_hat, fval] = fminsearch(obj, theta0, options);
D_hat   = exp(theta_hat(1));
rho_hat = exp(theta_hat(2));

fprintf('\nEstimated parameters:\n   D   = %.6g\n   rho = %.6g\nObjective J = %.6g\n', D_hat, rho_hat, fval);


[K, ~] = deal(D_hat*K1, []); 
u_sim = simulate_to_times(u0, K, M, rho_hat, t_years, substeps_per_year);

Usim = u_sim;
% figure; trisurf(faces, coords(:,1), coords(:,2), coords(:,3), u_last, 'EdgeColor','none');
% axis equal off; colorbar; title(sprintf('Predicted u at t=%.2f yrs (D=%.3g, rho=%.3g)', t_years(end), D_hat, rho_hat));
% view(3);

m = M * ones(size(M,1),1);
A = sum(m);
eps0 = 0.0001;

% --- Compute values ---
for k = 2:numel(Uobs)
    num   = abs(Usim{k} - Uobs{k});
    denom = abs(Uobs{k}) + eps0;
    relerr = num ./ denom;
    Jk = (m.' * relerr) / A;   % relative loss
    fprintf('J at data %d (t=%.2f yrs) = %.6g\n', k, t_years(k), Jk);
end


% ---- Visualization: all times, observed vs simulated vs difference ----
nTimes = numel(t_years);
fig = figure('Name','Observed vs Simulated vs Difference', ...
       'Position',[100 100 1200 250*nTimes]);




for k = 1:nTimes
    % Observed
    subplot(nTimes,3,3*(k-1)+1);
    trisurf(faces, coords(:,1), coords(:,2), coords(:,3), Uobs{k}, ...
            'EdgeColor','none');
    axis equal off; view(3);
    title(sprintf('Observed t=%.2f yrs', t_years(k)));
    colorbar;

    % Simulated
    subplot(nTimes,3,3*(k-1)+2);
    trisurf(faces, coords(:,1), coords(:,2), coords(:,3), Usim{k}, ...
            'EdgeColor','none');
    axis equal off; view(3);
    title(sprintf('Simulated t=%.2f yrs', t_years(k)));
    colorbar;

    % Difference (Observed - Simulated)
    subplot(nTimes,3,3*(k-1)+3);
    diff_field = Uobs{k} - Usim{k};
    trisurf(faces, coords(:,1), coords(:,2), coords(:,3), diff_field, ...
            'EdgeColor','none');
    axis equal off; view(3);
    title(sprintf('Difference t=%.2f yrs', t_years(k)));
    colorbar;
end

filename = sprintf('SimResult_lst_vv3_D%.4g_rho%.4g_fval%.4g.fig', D_hat, rho_hat, fval);
savefig(fig, filename);


% --------- Functions ---------

function J = objective_D_rho(theta, u0, Uobs, t_years, K1, M, substeps_per_year)
    % theta → positive params
    D   = exp(theta(1));
    rho = exp(theta(2));
    K = D * K1;

    % Forward simulate
    Usim = simulate_to_times(u0, K, M, rho, t_years, substeps_per_year);

    N = size(M,1);
    m = M * ones(N,1);       
    A = sum(m); 
    eps0 = 0.0001;             
    J = 0;
    for k = 2:numel(Uobs)
        num   = abs(Usim{k} - Uobs{k});
        denom = abs(Uobs{k}) + eps0;
        relerr = num ./ denom;          
        J = J + (m.' * relerr) / A;      
    end
    J = J./(numel(Uobs)-1);
end


function Usim = simulate_to_times(u0, K, M, rho, t_years, substeps_per_year)
    % IMEX: (M + dt K) u^{n+1} = M u^n + dt M f(u^n), f(u)=rho*u*(1-u)
    A_cache = []; dt_cache = []; 
    u = u0;
    Usim = cell(numel(t_years),1);
    Usim{1} = u0;

    steps_done = 0;
    for k=2:numel(t_years)
        total_steps = round(t_years(k)*substeps_per_year);
        nsteps = total_steps - steps_done;
        if nsteps < 0, error('Non-monotone times'); end
        if nsteps == 0
            Usim{k} = u; continue;
        end

        dt = 1/substeps_per_year;  % year^-1
A = M + dt*K;

% incomplete Cholesky factorization (drop tolerance 조절 가능)
L = ichol(A, struct('type','ict','droptol',1e-3));

tol = 1e-8;    % CG tolerance
maxit = 200;   % max iterations


for n = 1:nsteps
    f = rho * u .* (1-u);   % explicit reaction
    rhs = M*u + dt*(M*f);

    % Conjugate gradient with preconditioner
    [u,flag,relres,iter] = pcg(A, rhs, tol, maxit, L, L');

    if flag ~= 0
        warning('PCG did not fully converge at step %d (relres=%e, iter=%d)', ...
                 n, relres, iter);
    end
end





        steps_done = total_steps;
        Usim{k} = u;
    end
end










function t_rel_years = parse_years_from_filename(fname, ref_fname)
    % from file name YYYYMMDDHHMMSS → datetime
    % example: ..._20160428134956_...
    pat = '\d{14}'; % 14 digits
    tok1 = regexp(fname, pat, 'match', 'once');
    tok0 = regexp(ref_fname, pat, 'match', 'once');
    if isempty(tok1) || isempty(tok0)
        error('Cannot parse timestamp from %s or %s', fname, ref_fname);
    end
    t1 = datetime(tok1, 'InputFormat','yyyyMMddHHmmss');
    t0 = datetime(tok0, 'InputFormat','yyyyMMddHHmmss');
    t_rel_years = years(t1 - t0); % duration in years (double)
end


