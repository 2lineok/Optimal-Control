function [tC] = Ldirection(c)

global paras
if ~isempty(paras.opts)
    [t,u]=ode45(@PDE_u,paras.t0,paras.u0,paras.opts);   
else
    [t,u]=ode45(@PDE_u,paras.t0,paras.u0);   
end

%toc

paras.u = u;


%tic
if ~isempty(paras.opts)
    [t,w_reversed] = ode45(@PDE_w,paras.t0,paras.wmax,paras.opts);   
else
    [t,w_reversed] = ode45(@PDE_w,paras.t0,paras.wmax);  
end
%toc

%The function w_reversed is w_reversed(t,x)
w = -w_reversed(end:-1:1,:);
paras.w = w;

uw_omega = zeros(size(u,1),1);
u_omega = zeros(size(u,1),1);
for i = 1:size(u,1)
    uw_omega(i) = (u(i,:)*paras.MassMatrix_x*w(i,:).');
    u_omega(i,1) = (u(i,:)*paras.MassMatrix_x*ones(size(u,2),1));
end
paras.u_omega=u_omega;

paras.J = ones(size(u_omega,1),1).'*paras.MassMatrix_t*u_omega + paras.alpha*c*paras.MassMatrix_t*c';
paras.JT = (uw_omega' + 2*paras.alpha*c);
paras.omega=uw_omega;

tC=-uw_omega'./(2*paras.alpha);

end


