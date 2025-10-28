clear all;clc;close all
%Data generated from Main.m and use this to plot properly
load("all_results_data.mat")
global paras
addpath Functions


paras.alpha=100;

opts = odeset('RelTol',1e-10,'AbsTol',1e-12,'Stats','On');
paras.opts = [];
paras.chip = 0;
nt = 400;
nx = 20;
paras.tmax = 42;
paras.xmax = 1;
paras.t0 = linspace(0,paras.tmax,nt+1);
paras.h = paras.t0(2)-paras.t0(1);

paras.rho = 0.012;



paras.xmesh = linspace(0,paras.xmax,nx+1);
paras.dx = paras.xmesh(2)-paras.xmesh(1);

paras.Dofx = 0.002*ones(size(paras.xmesh));


paras.Dc = 0.5*(paras.Dofx(1:end-1)+paras.Dofx(2:end));
paras.Doper = -diag([0 paras.Dc(2:end)+paras.Dc(1:end-1) 0],0) + diag([0 paras.Dc(2:end)],1) + diag([paras.Dc(1:end-1) 0],-1);
paras.Doper(1,1:2) = [-2 2];
paras.Doper(end,end-1:end) = [2 -2];
paras.Doper = paras.Doper/(paras.dx^2);

% Initial for w(T) so it should be 0
paras.wmax = 0*ones(size(paras.xmesh));




n_nodes = length(paras.xmesh);
n_elements = nx;

% Initialize the global mass matrix
Mx = sparse(n_nodes, n_nodes);

% Loop over each element
for e = 1:n_elements
    i = e;
    j = e + 1;
    h = paras.xmesh(j) - paras.xmesh(i);
    
    % Local mass matrix
    Me = (h / 6) * [2, 1; 1, 2];
    
    % Assemble into global mass matrix
    Mx(i:i+1, i:i+1) = Mx(i:i+1, i:i+1) + Me;
end

% Store the mass matrix in paras struct
paras.MassMatrix_x = Mx;





n_nodes = length(paras.t0);
n_elements = nt;

% Initialize the global mass matrix
Mt = sparse(n_nodes, n_nodes);

% Loop over each element
for e = 1:n_elements
    i = e;
    j = e + 1;
    h = paras.h;
    
    % Local mass matrix
    Me = (h / 6) * [2, 1; 1, 2];
    
    % Assemble into global mass matrix
    Mt(i:i+1, i:i+1) = Mt(i:i+1, i:i+1) + Me;
end

% Store the mass matrix in paras struct
paras.MassMatrix_t = Mt;





U_int1 = cumtrapz(paras.t0, all_data(1).u, 1);
U_int2 = cumtrapz(paras.t0, all_data(2).u, 1);
[t2,x2] = meshgrid(paras.t0,paras.xmesh);


J_t1=cumtrapz(paras.t0,all_data(1).u_omega'+all_data(1).alpha*(all_data(1).c0.^2));
J_t2=cumtrapz(paras.t0,all_data(2).u_omega'+all_data(2).alpha*(all_data(2).c0.^2));

subplot(1,2,1)
plot(all_data(1).tlist,all_data(2).c0,'linewidth',3)

xlabel('$t$', 'Interpreter', 'latex','fontsize',18)
ylabel('$C^*$', 'Interpreter', 'latex','fontsize',25)
xlim([min(paras.t0) max(paras.t0)])
%title(sprintf("\\alpha = %d",paras.alpha),'fontsize',18)
set(gca, 'FontSize', 18);


% Plot cumulative integral of u
subplot(1, 2, 2);
surf(t2', x2', U_int1-U_int2)
shading interp 
xlabel('$t$', 'Interpreter', 'latex','fontsize',18)
ylabel('$x$', 'Interpreter', 'latex','fontsize',18)
zlabel('$\int_0^t \delta u(x,s) \, ds$', 'Interpreter', 'latex','fontsize',25)
%title('Cumulative Integral of $u(t,x)$', 'Interpreter', 'latex')
title(sprintf('$\\mathcal{J}(C) - \\mathcal{J}(C^*) = %.4f$', J_t1(end) - J_t2(end)),'Interpreter', 'latex', 'FontSize', 18);
set(gca, 'FontSize', 18);

