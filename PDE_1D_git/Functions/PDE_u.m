function dy = PDE_u(t,y)
%Doper should be (del D(x) del)
global paras
if paras.chip ==1
    dy = paras.Doper*y+ paras.rho*(1-y).*y-interp1(paras.t0,paras.c0,t,'pchip')*y;
else
    dy = paras.Doper*y+ paras.rho*(1-y).*y-interp1(paras.t0,paras.c0,t)*y;
end
