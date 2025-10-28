function u = PDE_u(c)
global pars

pars.c = c;
model2 = pars.model;

setInitialConditions(model2,pars.u0ini);
if ~isempty(pars.Dcoeff)
    specifyCoefficients(model2,'m',0,'d',1,'c',pars.Dcoeff, 'a',@acoeff ,'f',0);
else
    specifyCoefficients(model2,'m',0,'d',1,'c',@Dcoeff, 'a',@acoeff ,'f',0);
end



results = solvepde(model2,pars.tlist);

pars.result_u = results;
u = results.NodalSolution;


function result = acoeff(location, state)
global pars
result =  pars.rho*(state.u/pars.K-1)+interp1(pars.tlist,pars.c,state.time,'pchip');



function result = Dcoeff(location, state)
% Be careful if change the coefficient which depends on time
D_GM = 0.002;
D_WM = 0.002;

result = D_GM*(sqrt(location.x.^2 + location.y.^2)>0.8) + D_WM*(sqrt(location.x.^2 + location.y.^2)<=0.8);




