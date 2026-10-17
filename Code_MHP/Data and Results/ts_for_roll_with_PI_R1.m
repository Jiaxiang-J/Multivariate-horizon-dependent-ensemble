clear; close all; clc

%% ================================
% Load data
% ================================

load('short_term(6).mat');           
ys = allY_Fore(:,[8,9],:);
sigma_s = std_Fore(:,[8,9],:);

load('corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat');  
yl = allY_Fore(:,[8,9],:);                 

load PER624.mat
y_per = pred;
sigma_per = sigma_h;

std_l_all = get_std(allVariance);
sigma_l = std_l_all(:,[8,9],:);
trueY = allY_Test;  
% load review_more_test_results_hour_train10_multi1_th90.mat
% ys = allY_Fore(:,[8,9],:);
% sigma_s = get_std(allVariance);
% sigma_s = sigma_s(:,[8,9],:);
% trueY = allY_Test;
% load reviewe_more_airu_train60_multi1_th50.mat
% yl = allY_Fore(:,:,:);
% sigma_l = get_std2(allVariance);
% trueY = allY_Test; 
color_set = [
    0.1216 0.4667 0.7059;  
    1.0000 0.4980 0.0549;   
    0.5804 0.4039 0.7412;   
    0.8902 0.4667 0.7608;   
    0.4980 0.4980 0.4980;  
    0.3    0.3    0.3;      
    0.0902 0.7451 0.8118;  
];

R = size(ys, 3);
case_names = ["loc1", "loc2", "avg12"];

min_switch = 3;
max_switch = 12;

best_score = inf;
best_j = NaN;
best_k = NaN;
best_case = "";

all_candidates = [];

for c = 1:length(case_names)

    case_name = case_names(c);

    for r = 1:R

        [y, s, l] = extract_case_data(case_name, r, trueY, ys, yl);

        if any(isnan(y)) || any(isnan(s)) || any(isnan(l))
            continue;
        end

        err_s = abs(y - s);
        err_l = abs(y - l);

        % signed error difference:
        % D < 0: STM closer
        % D > 0: LTM closer
        D = err_s - err_l;

        for k = min_switch:max_switch

            early = 1:k;
            late  = (k+1):24;

            % strict uniform pattern
            if ~all(D(early) < 0)
                continue;
            end

            if ~all(D(late) > 0)
                continue;
            end

            early_margin = mean(-D(early));  % STM advantage
            late_margin  = mean(D(late));    % LTM advantage

            if early_margin < 0.10 || late_margin < 0.10
                continue;
            end

            % avoid extremely large absolute errors if possible
            mean_best_err = mean([err_s(early); err_l(late)]);
            max_best_err  = max([err_s(early); err_l(late)]);

            % score: prefer clean separation but avoid huge errors
            score = ...
                1.5 * mean_best_err + ...
                0.5 * max_best_err  - ...
                1.0 * early_margin  - ...
                1.0 * late_margin   + ...
                0.05 * abs(k - 6);

            all_candidates = [all_candidates; ...
                c, r, k, score, early_margin, late_margin, ...
                mean_best_err, max_best_err];

            if score < best_score
                best_score = score;
                best_j = r;
                best_k = k;
                best_case = case_name;
            end
        end
    end
end

candidate_table = array2table(all_candidates, ...
    'VariableNames', {'case_id','roll','switch_hour','score', ...
    'early_STM_advantage','late_LTM_advantage', ...
    'mean_best_error','max_best_error'});

candidate_table.case_name = case_names(candidate_table.case_id)';
candidate_table = sortrows(candidate_table, 'score');

disp(candidate_table(1:min(20,height(candidate_table)), :));

fprintf('\nBest case = %s\n', best_case);
fprintf('Best roll = %d\n', best_j);
fprintf('Switch after hour = %d\n', best_k);
fprintf('Best score = %.4f\n\n', best_score);

%% ================================
% Plot Figure 1(a): selected roll signed error difference
% ================================

[y, s, l] = extract_case_data("loc2", 111, trueY, ys, yl);

allerr_s = abs(y-s);
allerr_l = abs(y-l);

D_roll_all = allerr_s - allerr_l;
%D_roll = mean(D_roll_all(:,:,46:183),[2,3]);

idx = 46:183;
hours = 1:24;
err_s = trueY(:,:,idx) - ys(:,:,idx);   % 24 x 2 x R
err_l = trueY(:,:,idx) - yl(:,:,idx);
err_per = trueY(:,:,idx) - y_per(:,:,idx);

block_edges = [1 3; 4 6; 7 9; 10 12; 13 15; 16 18; 19 21; 22 24];
nblock = size(block_edges,1);

block_rmse_s = nan(nblock,1);
block_rmse_l = nan(nblock,1);
block_rmse_per = nan(nblock,1);
block_rel_imp = nan(nblock,1);
block_center = nan(nblock,1);
skill_score_stm = nan(nblock,1);
skill_score_ltm = nan(nblock,1);
skill_score_stm_ltm = nan(nblock,1);
block_label = strings(nblock,1);

for b = 1:nblock
    hidx = block_edges(b,1):block_edges(b,2);

    e_s_block = err_s(hidx,:,:);
    e_l_block = err_l(hidx,:,:);
    e_per_block = err_per(hidx,:,:);

    block_rmse_s(b) = sqrt(mean(e_s_block(:).^2, 'omitnan'));
    block_rmse_l(b) = sqrt(mean(e_l_block(:).^2, 'omitnan'));
    block_rmse_per(b) = sqrt(mean(e_per_block(:).^2, 'omitnan'));

    % > 0: LTM better; < 0: STM better
    skill_score_stm(b) = 1 - block_rmse_s(b)/block_rmse_per(b);
    skill_score_ltm(b) = 1 - block_rmse_l(b)/block_rmse_per(b);
    skill_score_stm_ltm(b) = 1 - block_rmse_l(b)/block_rmse_s(b);

    block_rel_imp(b) = ...
        ((block_rmse_s(b) - block_rmse_l(b))/block_rmse_l(b));

    block_center(b) = mean(hidx);
    block_label(b) = sprintf('%d-%d', hidx(1), hidx(end));
end

figure('Position',[100,100,900,430]); hold on

plot(block_center, 100*skill_score_stm_ltm, '-o', ...
    'LineWidth', 2.8, ...
    'Color', color_set(3,:), ...
    'MarkerSize', 8, ...
    'MarkerEdgeColor', color_set(3,:), ...
    'MarkerFaceColor', 'w');

yline(0, '--k', ...
    'LineWidth', 1.2);

xlabel('Forecast horizon (hour)', 'FontSize', 15);
ylabel('Skill Score \times 100%', 'FontSize', 15);

xticks(block_center);
xticklabels(block_label);
xlim([block_center(1), block_center(end)])
grid on;
set(gca, ...
    'FontSize', 14, ...
    'LineWidth', 1.1, ...
    'TickDir', 'out', ...
    'GridAlpha', 0.25);

%legend('Location','best', 'Box','off');

% plot(block_center, skill_score_ltm, '-', ...
%     'LineWidth', 2.4, ...,
%     'Color',color_set(7,:),...
%     'Marker','^', ...
%      'MarkerEdgeColor',color_set(7,:), 'MarkerFaceColor',color_set(7,:),...
%     'MarkerSize', 7, 'DisplayName','LTM');

%yline(0, '--k', 'LineWidth', 1.3);

% xlabel('Forecast horizon (hour)', 'FontSize', 15);
% ylabel('RMSE', 'FontSize', 15);
%legend('Location','northwest');
% xticks(block_center);
% xticklabels(block_label);

grid on;
set(gca, 'FontSize', 14);

%print('RMSE.png', '-dpng', '-r300');

function [y, s, l] = extract_case_data(case_name, r, trueY, ys, yl)

    if case_name == "loc1"
        y = trueY(:,1,r);
        s = ys(:,1,r);
        l = yl(:,1,r);

    elseif case_name == "loc2"
        y = trueY(:,2,r);
        s = ys(:,2,r);
        l = yl(:,2,r);

    elseif case_name == "avg12"
        y = mean(trueY(:,1:2,r), 2, 'omitnan');
        s = mean(ys(:,1:2,r), 2, 'omitnan');
        l = mean(yl(:,1:2,r), 2, 'omitnan');

    else
        error('Unknown case name.');
    end

    y = y(:);
    s = s(:);
    l = l(:);
end

function [std_tensor] = get_std(allVariance)

    Y_var = allVariance;
    num_rolls = size(Y_var, 3);
    std_tensor = zeros(24, 9, num_rolls);

    for ii = 1:num_rolls
        covariance_matrix = Y_var(:, :, ii);
        covariance_matrix = (covariance_matrix + covariance_matrix') / 2;
        std_vector = sqrt(diag(covariance_matrix));
        std_tensor(:,:, ii) = reshape(std_vector, [24, 9]);
    end    
end
function [std_tensor] = get_std2(allVariance)

    Y_var = allVariance;
    num_rolls = size(Y_var, 3);
    std_tensor = zeros(24, 2, num_rolls);

    for ii = 1:num_rolls
        covariance_matrix = Y_var(:, :, ii);
        covariance_matrix = (covariance_matrix + covariance_matrix') / 2;
        std_vector = sqrt(diag(covariance_matrix));
        std_tensor(:,:, ii) = reshape(std_vector, [24, 2]);
    end    
end
function crps = gaussian_crps(y, mu, sigma)
    sigma = max(sigma, 1e-6);
    z = (y - mu) ./ sigma;
    Phi = 0.5 * (1 + erf(z ./ sqrt(2)));
    phi = exp(-0.5*z.^2) ./ sqrt(2*pi);
    crps = sigma .* (z .* (2*Phi - 1) + 2*phi - 1/sqrt(pi));
end