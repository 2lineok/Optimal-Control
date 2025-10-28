function [Usim, tgrid] = Solve_u(u0, K, M, rho, C_time_or_fun, dt,A,L)
tol = 1e-8;    % CG tolerance
maxit = 200;   % max iterations

    Ncols = length(C_time_or_fun);
    Nsteps = Ncols - 1;


    nvars = numel(u0);
    Usim = zeros(nvars, Nsteps+1);
    tgrid = (0:Nsteps) * dt;  % time grid

    Usim(:,1) = u0;

    u = u0;







for n = 1:Nsteps
    f = rho * u .* (1-u) - C_time_or_fun(n) * u;   % explicit reaction
    rhs = M*u + dt*(M*f);

    % Conjugate gradient with preconditioner
    [u,flag,relres,iter] = pcg(A, rhs, tol, maxit, L, L');

    if flag ~= 0
        warning('PCG did not fully converge at step %d (relres=%e, iter=%d)', ...
                 n, relres, iter);
    end

    Usim(:,n+1) = u;
end


end
