clear all;clc;close all
addpath Functions
global paras

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

all_data = struct();  % for saving

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

%Initial for u0 and c0
paras.u0=1/2+cos(2*pi*paras.xmesh)./2;
paras.c0 = 2.512566e-02*ones(size(paras.t0)); %Trivial case

TOL=1;
crit_tol=1e-9;
i=1;
beta=0.5;

[t2,x2] = meshgrid(paras.t0,paras.xmesh);
while TOL>crit_tol
    C_old=paras.c0;
    C_tilda=Ldirection(C_old);


    if i==1
        jv=paras.J
        jt=norm(paras.JT)
        figure
        plot(paras.t0,paras.u_omega'+paras.alpha*(paras.c0.^2),'linewidth',3)

        hold on
        idx=1;
        all_data(idx).alpha     = paras.alpha;
        all_data(idx).tlist     = paras.t0;
        all_data(idx).c0        = paras.c0;
        all_data(idx).u    = paras.u;
        all_data(idx).w    = paras.w;
        all_data(idx).u_omega    = paras.u_omega;
        all_data(idx).omega    = paras.omega;
        all_data(idx).JT_star   = paras.JT;

    end
    i=i+1
    paras.c0=beta*C_old+(1-beta)*C_tilda;
    
TOL=norm(C_tilda-C_old,'fro')
C=paras.c0;
sprintf("This is C average %d",C*paras.MassMatrix_t*ones(size(C))'/paras.tmax)
end
C*paras.MassMatrix_t*ones(size(C))'/paras.tmax
i
jv=paras.J
jt=norm(paras.JT)
paras.c0=C_old;
C=paras.c0;

idx=2;
all_data(idx).alpha     = paras.alpha;
all_data(idx).tlist     = paras.t0;
all_data(idx).c0        = paras.c0;
all_data(idx).u    = paras.u;
all_data(idx).w    = paras.w;
all_data(idx).u_omega    = paras.u_omega;
all_data(idx).omega    = paras.omega;
all_data(idx).JT_star   = paras.JT;


save('all_results_data.mat', 'all_data','paras', '-v7.3');



