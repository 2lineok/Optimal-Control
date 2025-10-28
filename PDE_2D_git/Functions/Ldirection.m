function [tC] = Ldirection(c)

global pars


pars.c = c;

u = PDE_u(c);

u_omega = compute_integral(u,pars.model.Mesh.Nodes',pars.model.Mesh.Elements');
pars.u_omega = u_omega;
pars.u = u;

J = pars.weig*u_omega'+pars.alpha*pars.weig*((c.^2)');
pars.J=J;

w_reversed = PDE_w(c);

w = -w_reversed(:,end:-1:1);
pars.w=w;
w_omega = compute_integral(w,pars.model.Mesh.Nodes',pars.model.Mesh.Elements');
pars.w_omega = w_omega;
uw = u.*w;
uw_omega = compute_integral(uw,pars.model.Mesh.Nodes',pars.model.Mesh.Elements');
JT=uw_omega+2*pars.alpha*c;
pars.JT=JT;
tC=-uw_omega./(2*pars.alpha);



