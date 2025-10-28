function [J, DJ] = Gdirection(u0, K, M, rho, C_time_or_fun, dt,alpha,A,L)

[Usim, tgrid] = Solve_u(u0, K, M, rho, C_time_or_fun, dt,A,L);
[Wsim, ~] = Solve_w(Usim, M, K, rho, C_time_or_fun, dt,A,L);
N=size(Usim,1);
U_int=((M*ones(N,1)).')*Usim;
UW_int=((M*ones(N,1)).')*(Wsim.*Usim);

DJ=UW_int(:)+2*alpha*C_time_or_fun(:);

% time integration
J = trapz(tgrid, U_int)+alpha*trapz(tgrid, C_time_or_fun.^2);
end