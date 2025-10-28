function dy = PDE_w(t,y)
global paras
%This is actually computing -w(x,T-t)

for i = 1:length(y)
    if paras.chip==1
        u_of_x(i) = interp1(paras.t0,paras.u(:,i),paras.tmax-t,'pchip');
    else
        u_of_x(i) = interp1(paras.t0,paras.u(:,i),paras.tmax-t);
    end

end
%Doper should be (del D(x) del)
if paras.chip==1
    dy = paras.Doper*y +1 +(paras.rho-2.*paras.rho.*u_of_x(:)-interp1(paras.t0,paras.c0,paras.tmax-t,'pchip')).*y;
else
    dy = paras.Doper*y +1 +(paras.rho-2.*paras.rho.*u_of_x(:)-interp1(paras.t0,paras.c0,paras.tmax-t)).*y;
    
end
