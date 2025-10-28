clear all
close all
clc

loadFile = 'Data/002_S_0413/Main_avg_data_v1_nor.mat';
load(loadFile)
close all


load("all_results_data.mat")

% ---------- Plot ----------
figure
hold on

legLabels = {'First_data', 'Second_data','etc'};
hLines = [];      

for ii = 1:1
    idx = ii;
    
    % (1) subplot 1
    subplot(1,2,1)
    hold on
    h1 = plot(pars.tlist, all_data(idx).c0, 'LineWidth', 1.5);
    xlabel('$t$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$C^*$', 'Interpreter', 'latex', 'FontSize', 16)
    xlim([tmin tmax])
    %title(sprintf('$\\alpha = %.1e$', pars.alpha), 'Interpreter', 'latex', 'FontSize', 16)

    subplot(1,2,2)
    hold on
    U_int = cumtrapz(pars.tlist(:), all_data(idx).u_omega(:) - all_data(idx).u_star(:), 1);
    h3 = plot(pars.tlist, U_int', 'LineWidth', 1.5);
    xlabel('$t$', 'Interpreter', 'latex', 'FontSize', 16)
    ylabel('$\int_0^t \int_{\Omega} \delta u(x,s)\, dx\, ds$', 'Interpreter', 'latex', 'FontSize', 16)
    xlim([tmin tmax])

    hLines = [hLines; h1];  

end
lgd = legend(hLines, legLabels, ...
    'Interpreter', 'latex', ...
    'FontSize', 14, ...
    'Orientation', 'vertical', ... 
    'Box', 'off');
set(lgd, 'Units', 'normalized', 'Position', [0.88, 0.35, 0.1, 0.3]);














