load('W_store.mat');
ensl_short = W_store(46:183,:,1);
load ensemble_es_constrain.mat
alpha = alpha(:);
T = 24;
D = 138;
time  = (1:T)';
ws = nan(D,T);
wl = nan(D,T);
for d = 1: D
    for t = 1:T
        ws(d,t) = exp(-alpha(d)*t);
        wl(d,t) = 1 - ws(d,t);
    end
end 
color_set = [0.8941 0.1020 0.1098
                    0.2157 0.4941 0.7216
                    0.3020 0.6863 0.2902
                    0.5961 0.3059 0.6392
                    1.0000 0.4980 0.0000
                    1.0000 1.0000 0.2000
                    0.6510 0.3373 0.1569];
w_short_agg = mean(ws,1);
w_long_agg = mean(wl,1);
ens_short_agg = mean(ensl_short,1);
figure('Position',[100,100,1200,600]); % 白背景更干净

hold on;
plot(time, ens_short_agg, ...
    'Color', color_set(2,:), ...
    'Marker', 's', ...
    'LineWidth', 3.5, ...
    'MarkerSize', 13, ...
    'MarkerFaceColor', color_set(2,:), ...
    'MarkerEdgeColor', color_set(2,:), ...
    'DisplayName', 'ENS-L weight for STM');

plot(time, w_short_agg, ...
    'Color', color_set(5,:), ...
    'Marker', '^', ...
    'LineWidth', 3.5, ...
    'MarkerSize', 13, ...
    'MarkerFaceColor', color_set(5,:), ...
    'MarkerEdgeColor', color_set(5,:), ...
    'DisplayName', 'MHP-ENS weight for STM');

xlabel('Forecast Horizon (hours)', 'FontSize', 30, 'FontName', 'Times New Roman');
ylabel('Weight', 'FontSize', 30, 'FontName', 'Times New Roman');

legend('Location', 'northeast', 'FontSize', 20, 'Box', 'on');

xlim([1 24]);
ylim([0 1]);
xticks(1:1:24);   

ax = gca;
ax.FontSize = 22;           
ax.LineWidth = 2.2;        
ax.TickDir = 'out';        
ax.Box = 'off';           
ax.XColor = [0.1 0.1 0.1]; 
ax.YColor = [0.1 0.1 0.1];


set(gcf,'Renderer','painters'); 
%print('weight_fig.png', '-dpng', '-r300');


