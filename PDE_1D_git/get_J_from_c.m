function [J,eta] = get_J_from_c(c)

global pars

tic

if ~isempty(pars.opts)
[t,u]=ode45(@PDE_u,pars.t0,pars.u0,pars.opts);   
else
    [t,u]=ode45(@PDE_u,pars.t0,pars.u0);   
end

toc

u_omega = zeros(size(u,1),1);

for i = 1:size(u,1)
    u_omega(i,1) = (u(i,:)*pars.MassMatrix_x*ones(size(u,2),1));
end

pars.u = u;


%figure(10);plot(u')



J = ones(size(u_omega,1),1).'*pars.MassMatrix_t*u_omega + pars.alpha*c*pars.MassMatrix_t*c';




if nargout==1, return; end
    

%figure(1)
%subplot(1,3,1)
%plot(t,pars.c0)
%xlabel('t'); ylabel('c0')

%figure(1)
%subplot(1,3,2)
%[t2,x2] = meshgrid(t,pars.xmesh);
%mesh(t2',x2',u)
%xlabel('t'); ylabel('x'),zlabel('u')


tic
if ~isempty(pars.opts)
[t,w_reversed] = ode45(@PDE_w,pars.t0,pars.wmax,pars.opts);   
else
   [t,w_reversed] = ode45(@PDE_w,pars.t0,pars.wmax);  
end
toc


tw = pars.tmax-t;


w = -w_reversed(end:-1:1,:);


pars.w = w;

%subplot(1,3,3)
%mesh(t2',x2',w)
%xlabel('t'); ylabel('x'),zlabel('w')



uw = u.*w;

%subplot(2,3,4)
%mesh(t2',x2',uw)
%xlabel('t'); ylabel('x'),zlabel('uw')



uw_omega = zeros(size(u,1),1);

for i = 1:size(u,1)
    uw_omega(i) = (u(i,:)*pars.MassMatrix_x*w(i,:).');
end


[uw_omega_sort,ind] = sort(uw_omega,'ascend');
ind_thres = round(pars.B/pars.A/pars.h)+1;

Achi = pars.A*double((uw_omega<=uw_omega_sort(ind_thres)))';


eta = Achi-pars.c0;


%subplot(2,3,5)
 
%plot(t,Achi)
%xlabel('t'); ylabel('Achi')

%subplot(2,3,6)

%plot(t,eta)
%xlabel('t'); ylabel('eta')
%title(['J = ' num2str(J)])
