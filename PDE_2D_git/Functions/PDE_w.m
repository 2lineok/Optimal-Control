function w = PDE_w(c)
global pars

model1 = pars.model;
% specify coefficients
setInitialConditions(model1,pars.w0ini);

if ~isempty(pars.Dcoeff)
    specifyCoefficients(model1,'m',0,'d',1,'c',pars.Dcoeff, 'a',@acoeff ,'f',1);
else
    specifyCoefficients(model1,'m',0,'d',1,'c',@Dcoeff, 'a',@acoeff ,'f',1);
end

results = solvepde(model1,pars.tlist);
w = results.NodalSolution;




function result = acoeff(location, state)
global pars

sst = pars.tmax-state.time;
ct = min(max(sst, min(pars.tlist)), max(pars.tlist));
tr = ceil((ct)/pars.h)+1;
result = -(pars.rho-2*pars.rho*interpolateSolution(pars.result_u,location.x,location.y,tr)'-...
    interp1(pars.tlist,pars.c,sst,'pchip'));





function result = Dcoeff(location, state)
% Be careful if change the coefficient which depends on time
D_GM = 0.002;
D_WM = 0.002;

result = D_GM*(sqrt(location.x.^2 + location.y.^2)>0.8) + D_WM*(sqrt(location.x.^2 + location.y.^2)<=0.8);





