clear all;clc;close all
%Data generated from Main.m and use this to plot properly
global paras
load("all_results_data.mat")
addpath Functions


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


