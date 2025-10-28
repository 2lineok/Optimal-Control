function [W, tgrid] = Solve_w(Usim, M, K, rho, C_time_or_fun, dt,A,L)
% solve_dual_explicit  Explicit Euler for dual equation
%   v_t - div(D grad v) - (rho - 2 rho u(T-t) - C(T-t)) v = 1,
%   Neumann BC, v(x,0)=0.
%
% Inputs:
%   Usim   : n_nodes x (Nsteps+1) matrix, column k is u at t = (k-1)*dt
%   M, K   : FEM mass and stiffness matrices (sparse)
%   rho    : scalar
%   C_time_or_fun : either
%       - vector of length Nsteps+1 containing C at forward times t=0:dt:T, or
%       - function handle C_of_t(t) returning scalar C at time t
%       Note: we will evaluate C at T - t_n for the dual eq.
%   dt     : timestep size (must match Usim)
%
% Outputs:
%   V      : n_nodes x (Nsteps+1) matrix, v at times 0:dt:T
%   tgrid  : 1 x (Nsteps+1) vector
%

    tol = 1e-8;    % CG tolerance
    maxit = 200;   % max iterations
    [n_nodes, Ncols] = size(Usim);
    Nsteps = Ncols - 1;
    T = Nsteps * dt;
    tgrid = (0:Nsteps) * dt;

    % prepare C
    if isa(C_time_or_fun, 'function_handle')
        C_fun = C_time_or_fun;
        use_fun = true;
    else
        C_vec = C_time_or_fun(:);
        if numel(C_vec) ~= Nsteps+1
            error('If C is vector, length must be Nsteps+1 (times 0:dt:T).');
        end
        use_fun = false;
    end

    % allocate
    V = zeros(n_nodes, Nsteps+1);
    v = zeros(n_nodes,1);    % initial condition v(.,0)=0
    V(:,1) = v;




    % time stepping for v
    for n = 1:Nsteps

        % safer: compute idx exactly
        idx_u = Nsteps + 1 - (n-1);  % idx_u in 1..Nsteps+1
        if idx_u < 1 || idx_u > Nsteps+1
            error('Computed u-index out of range: %d', idx_u);
        end
        u_rev = Usim(:, idx_u);      % u evaluated at (T - t_{n-1})  (see note below)

        % C at (T - t_n) -- be consistent with how you pair u and C:
        t_for_C = T - tgrid(n);     % evaluate C at T - t_n
        if use_fun
            Cval = C_fun(t_for_C);
        else
            Cval = C_vec(idx_u);
        end

        % reaction coefficient (use u at T - t_n)
        qn = rho - 2*rho .* u_rev - Cval;  % nodal vector

        % RHS assembly: explicit formula M (v^{n+1}-v^n)/dt = -K v^n + M ( qn .* v^n ) + 1 * M*1
        % -> rhs = -K*v + M*(qn .* v) + M*(1)   (we will multiply by dt and apply M^{-1})
        % RHS: explicit terms
        rhs = M*v + dt*(M*(qn .* v) + M*ones(n_nodes,1));
    
        [v,flag,relres,iter] = pcg(A, rhs, tol, maxit, L, L');
        if flag ~= 0
            warning('PCG did not fully converge at step %d (relres=%e, iter=%d)', ...
                     n, relres, iter);
        end
        % store next
        V(:, n+1) = v;
    end

    W = -fliplr(V);

end
