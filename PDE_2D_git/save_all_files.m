clear all
close all
clc


all_data = struct();  % 전체 결과를 담을 구조체



loadFile = 'Data/002_S_0413/Main_avg_data_v1_nor.mat';
load(loadFile)


u_omega = compute_integral(this_u_initial, pars.model.Mesh.Nodes', pars.model.Mesh.Elements');
w_omega = compute_integral(this_w_initial, pars.model.Mesh.Nodes', pars.model.Mesh.Elements');
uw_omega = compute_integral(this_u_initial .* this_w_initial, pars.model.Mesh.Nodes', pars.model.Mesh.Elements');
JT = uw_omega + 2 * pars.alpha * c_avg;
U_int = cumtrapz(pars.tlist(:),u_omega(:), 1);
J=cumtrapz(pars.tlist(:),u_omega(:)+pars.alpha*c_avg^2, 1);
JJ=cumtrapz(pars.tlist(:),u_omega(:)+pars.alpha*(pars.c0(:).^2), 1);

idx = 1;
all_data(idx).alpha     = pars.alpha;
all_data(idx).tlist     = pars.tlist;
all_data(idx).c_avg     = c_avg;
all_data(idx).u_omega   = u_omega;
all_data(idx).w_omega   = w_omega;
all_data(idx).uw_omega  = uw_omega;
all_data(idx).J         = J;
all_data(idx).JT        = JT;
all_data(idx).c0        = pars.c0;
all_data(idx).u_star    = pars.u_omega;
all_data(idx).JT_star   = pars.JT;
all_data(idx).J_star    = JJ;


close all
save('all_results_data.mat', 'all_data', '-v7.3');
