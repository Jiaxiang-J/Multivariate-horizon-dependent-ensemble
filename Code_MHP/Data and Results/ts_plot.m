clc;
clear;
%% ensemble prob is the final ensemble model.
load('ensemble_es_constrain.mat');
%load('ensemble_prob_fall.mat','mu_all','sigma_all','all_y_true');
rng(123); 
load('corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat');
all_y_true = allY_Test(:,:,46:183);
%load('fall-results_1-12_winter_hour_train60_multi1_th50.mat','allY_NWP','allY_Fore');
nwp_2 = allY_NWP(:,[8,9],46:183); % 8,9

site = 1; % 8
nwp_site1 = reshape(permute(nwp_2, [1, 3, 2]), [], 2); %third is 2 / 10
nwp_site1 = nwp_site1(:,site);

nwp_site2 = reshape(permute(nwp_2, [1, 3, 2]), [], 2); %third is 2 / 10
nwp_site2 = nwp_site2(:,2);

%  [4392 x 2]
mu_site1 = reshape(permute(mu, [1, 3, 2]), [], 2); 
mu_site1 = mu_site1(:, site); % 

S = Sigma;
sz = size(S);
if isequal(sz, [2, 24, 24, 138])
    % 已是 [loc, hour, hour, day]
elseif isequal(sz, [24, 24, 2, 138])
    % 是 [hour, hour, loc, day] -> 交换到 [loc, hour, hour, day]
    S = permute(S, [3, 1, 2, 4]);
else
    error('Unexpected size(Sigma) = %s, expected 2x24x24x138 or 24x24x2x138.', mat2str(sz));
end

L = size(S,1);  % 2
H = size(S,2);  % 24
D = size(S,4);  % 138

sigma1 = zeros(H, L, D);  % (24 × 2 × 138)

for d = 1:D
    for l = 1:L
        C = squeeze(S(l, :, :, d));  % 24×24
        var_diag = diag(C);
        var_diag(var_diag < 0) = 0;

        sigma1(:, l, d) = sqrt(var_diag);
    end
end

sigma_site1 = reshape(permute(sigma1, [1, 3, 2]), [], 2); 
sigma_site1 = sigma_site1(:, site); % 

y_true_site1 = reshape(permute(all_y_true, [1, 3, 2]), [], 2);
y_true_site2 = y_true_site1(:, 2);
y_true_site1 = y_true_site1(:, site); % 

% 
start_time = datetime(2020, 03, 16, 1, 0, 0); %  2020-11-17-1
%start_time = datetime(2020, 11, 17, 1, 0, 0);
time_interval = hours(1); % 

% 
time_series = start_time + (0:(24 * 138  - 1))' * time_interval; % [4392 x 1] 183
%time_series = start_time + (0:(24 * 14  - 1))' * time_interval;
%  144 
%subset_idx = 24*(20-1)+1:24*(20+7); % 
%subset_idx = 24*(1-1)+1:24*30;
%subset_idx = 1:24*14;
subset_idx = 24*(104-45):24*(111-45);
time_points_subset = time_series(subset_idx);
mu_subset = mu_site1(subset_idx);
sigma_subset = sigma_site1(subset_idx);
y_true_subset = y_true_site1(subset_idx);
y_true_subset2 = y_true_site2(subset_idx);
nwp_subset = nwp_site1(subset_idx);
nwp_subset2 = nwp_site2(subset_idx);



color_set1 = [...
    0.8941 0.1020 0.1098;   % 
    0.2157 0.4941 0.7216;   % 
    0.3020 0.6863 0.2902;   % 
    0.5961 0.3059 0.6392;   % 
    1.0000 0.4980 0.0000;   % 
    1.0000 1.0000 0.2000;   % 
    0.6510 0.3373 0.1569];  % 
base_colors = repmat(color_set1(1:5,:), 2, 1);  % 52  101
light_factor = 0.7;  % 0 = , 1 = 
light_colors = base_colors + (1-base_colors)*light_factor;
color_set = [0.8941 0.1020 0.1098
                    0.2157 0.4941 0.7216
                    0.3020 0.6863 0.2902
                    0.5961 0.3059 0.6392
                    1.0000 0.4980 0.0000
                    1.0000 1.0000 0.2000
                    0.6510 0.3373 0.1569];
figure('Position',[100,100,1400,600]);

fill([time_points_subset; flipud(time_points_subset)], ...
     [mu_subset + 1.645 * sigma_subset; flipud(max(mu_subset - 1.645 * sigma_subset,0))], ...
     'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', '90% PI');


hold on;
%for i = 1:num_scen
%    plot(time_points_subset, scenarios_mc(:,i), ...
%         '-', ...
%         'LineWidth',    1, ...
%         'Color',        light_colors(i,:), ...
%         'HandleVisibility','off');  
%    hold on;
%end
plot(time_points_subset, mu_subset,'-',marker='^', Color=color_set(2,:), LineWidth= 3, MarkerFaceColor='none',DisplayName= 'Point Forecasts');



hold on;

%plot(time_points_subset, nwp_subset, Color = color_set(2,:),LineWidth=2, DisplayName ='NWP at E05');
%plot(time_points_subset, nwp_subset2, Color = color_set(5,:), LineWidth= 2, DisplayName= 'NWP at E06');
%plot(time_points_subset, genai_mu_subset, '-r', 'LineWidth', 1.5, 'DisplayName', 'GenAIRU-WRF');

plot(time_points_subset, y_true_subset, 'x', 'MarkerSize', 8, 'DisplayName', 'Observations',Color=color_set(5,:),LineWidth = 1.5);
% 
%title('Probabilistic Prediction - E05');
set(gca, 'FontSize', 18);
xlabel('Time','FontSize',20);
ylabel('Wind Speed (m/s)','FontSize',20);
legend('Location', 'northwest',FontSize=20);
legend show
set(legend, 'Interpreter', 'tex')
grid on;

% 
start_time = time_points_subset(1) - hours(12); %  12 
end_time = time_points_subset(end) + hours(12); %  12 
xlim([time_points_subset(1), time_points_subset(end)]);

%  x 
xtick_positions = time_points_subset(13):hours(24*1):time_points_subset(end); % change freq of the tick
xticks(xtick_positions); % 
xticklabels(datestr(xtick_positions, 'yyyy-mm-dd HH:MM')); % set formula

%print('ws05.png', '-dpng', '-r300')



function [std_tensor] = get_std(allVariance)

    Y_var = allVariance;

    [num_rollls] = size(Y_var, 3);
    std_tensor = zeros(24, 2, num_rollls);

    for i = 1:num_rollls

        covariance_matrix = Y_var(:, :, i);
        covariance_matrix = (covariance_matrix + covariance_matrix') / 2;
        std_vector = sqrt(diag(covariance_matrix));
        std_tensor(:,:, i) = reshape(std_vector, [24, 2]);
    end    

end