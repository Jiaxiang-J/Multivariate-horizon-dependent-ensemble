clear; close all; clc
%% load st data
load('short_term(6).mat');           
ys = allY_Fore;
sigma_s = std_Fore;
%% load lt data
load('corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat');  
tmp = allY_Fore;                      
yl = tmp(:,[8,9],:);                 
std = get_std(allVariance); %% get std from covaraince
sigma_l = std(:,[8,9],:);

trueY = allY_Test;                   

%% 
i    = 2;      % location index
j    = 150;    % roll index
lw   = 2;      
mz   = 10;    
hor  = 3;      % hours to aggregate
color_set = [
    0.1216 0.4667 0.7059;  
    1.0000 0.4980 0.0549;   
    0.5804 0.4039 0.7412;   
    0.8902 0.4667 0.7608;   
    0.4980 0.4980 0.4980;  
    0.3    0.3    0.3;      
    0.0902 0.7451 0.8118;  
];
start_time        = datetime(2020,1,30,1,0,0);
time_series       = start_time + hours(0:(24*183-1))';
subset_idx        = (1 + 24*(j-1)) : (24*j);  %% select one roll for fig
x_full            = time_series(subset_idx);    
f_sj     = ys(:,i,j);                 
sigma_sj = squeeze(sigma_s(:,i,j));   
f_lj     = yl(:,i,j);                 
sigma_lj = squeeze(sigma_l(:,i,j));   

z95 = 1.645;
z50 = 0.6745;

lower95_l = f_lj - z95 * sigma_lj;
upper95_l = f_lj + z95 * sigma_lj;
lower75_l = f_lj - z50 * sigma_lj;
upper75_l = f_lj + z50 * sigma_lj;

lower95_s = f_sj - z95 * sigma_sj;
upper95_s = f_sj + z95 * sigma_sj;
lower75_s = f_sj - z50 * sigma_sj;
upper75_s = f_sj + z50 * sigma_sj;

cut_idx = 1:(length(x_full));        %% whether to cut the ts
x_plot        = x_full(cut_idx);       
f_lj_plot     = f_lj(cut_idx);
f_sj_plot     = f_sj(cut_idx);
true_plot     = trueY(cut_idx,i,j);

lower95_l_p   = lower95_l(cut_idx);
upper95_l_p   = upper95_l(cut_idx);
lower75_l_p   = lower75_l(cut_idx);
upper75_l_p   = upper75_l(cut_idx);

lower95_s_p   = lower95_s(cut_idx);
upper95_s_p   = upper95_s(cut_idx);
lower75_s_p   = lower75_s(cut_idx);
upper75_s_p   = upper75_s(cut_idx);

figure('Position',[100,100,1400,600]); hold on

%% fan chart
fill([x_plot; flipud(x_plot)], [upper95_l_p; flipud(lower95_l_p)], color_set(4,:), ...
     'FaceAlpha',0.10,'EdgeColor',color_set(4,:));
fill([x_plot; flipud(x_plot)], [upper75_l_p; flipud(lower75_l_p)], color_set(4,:), ...
     'FaceAlpha',0.20,'EdgeColor',color_set(4,:));

fill([x_plot; flipud(x_plot)], [upper95_s_p; flipud(lower95_s_p)], color_set(7,:), ...
     'FaceAlpha',0.15,'EdgeColor',color_set(7,:));
fill([x_plot; flipud(x_plot)], [upper75_s_p; flipud(lower75_s_p)], color_set(7,:), ...
     'FaceAlpha',0.25,'EdgeColor',color_set(7,:));

hlong = plot(x_plot, f_lj_plot, '-', 'Color',color_set(4,:), 'LineWidth',lw, ...
     'Marker','^','MarkerSize',mz, ...
     'MarkerEdgeColor',color_set(4,:), 'MarkerFaceColor',color_set(4,:), ...
     'DisplayName','Long-term');

hshort = plot(x_plot, f_sj_plot, '-', 'Color',color_set(7,:), 'LineWidth',lw, ...
     'Marker','s','MarkerSize',mz, ...
     'MarkerEdgeColor',color_set(7,:), 'MarkerFaceColor',color_set(7,:), ...
     'DisplayName','Short-term');

maroon = [128, 0, 0]/255;
htrue = plot(x_plot, true_plot, 'p', ...
    'LineStyle',       'none', ...
    'MarkerSize',      mz, ...
    'MarkerEdgeColor', maroon, ...
    'MarkerFaceColor', maroon, ...
    'Color',           maroon, ...
    'DisplayName',     'Ground Truth' );

xlabel('Time','FontSize',15);
ylabel('Hub-height Wind Speed (m/s)','FontSize',15);
set(gca,'FontSize',14); grid on;
legend([hlong, hshort, htrue], 'Location','northwest','FontSize',14);

print('motivation_pi.png', '-dpng', '-r300')

%% if want to generate MAE fig
% hor      = 4;                
% nHorizon = 24/hor;           
% R        = size(mae_s, 3);   
% mae_s = abs(trueY - ys);   
% mae_l = abs(trueY - yl); 
% 
% mae_s_blk = zeros(R, nHorizon);
% mae_l_blk = zeros(R, nHorizon);
% 
% for r = 1:R
%    
%     tmp_s = reshape(mae_s(:, i, r), hor, []);
%     tmp_l = reshape(mae_l(:, i, r), hor, []);
%    
%     mae_s_blk(r, :) = mean(tmp_s, 1);
%     mae_l_blk(r, :) = mean(tmp_l, 1);
% end
% 
% 
% MAE   = [mae_s_blk(:); mae_l_blk(:)];         
% H     = repmat(1:nHorizon, R, 1);             
% H     = H(:);                                  
% H     = [H; H];                               
% 
% Model = [repmat("Short-term Model", R*nHorizon, 1);
%          repmat("Long-term Model",  R*nHorizon, 1)];
% 
% figure('Position',[200,200,1000,400]);
% boxchart(categorical(H), MAE, 'GroupByColor', Model, 'BoxWidth',0.6);
% xlabel('Forecast Horizon (Aggregated by 4 hours)','FontSize',15);
% ylabel('MAE (m/s)','FontSize',15);
% set(gca,'FontSize',14);
% ylim([0 5]);
% legend(unique(Model),'Location','northeast','FontSize',14);
% grid on;

function [std_tensor] = get_std(allVariance)

    Y_var = allVariance;

    [num_rollls] = size(Y_var, 3);
    std_tensor = zeros(24, 9, num_rollls);

    for ii = 1:num_rollls
        covariance_matrix = Y_var(:, :, ii);
        covariance_matrix = (covariance_matrix + covariance_matrix') / 2;
        std_vector = sqrt(diag(covariance_matrix));
        std_tensor(:,:, ii) = reshape(std_vector, [24, 9]);
    end    

end
