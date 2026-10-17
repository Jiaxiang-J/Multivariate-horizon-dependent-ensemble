clc; clear;
%% all results should divide by 15 to get the PCE result table.
gamma_list = [0.2 0.5 0.8]; %% quantile list
sites      = [8,9]; %% idx to pick loc
idx_eval_full = 46:183; %% index for test period
idx_eval_ens  = 1:138;   % index for ens

models = {
    struct('name','airu_l',     'power_prefix','power_airu_l',        'loader',@load_long)
    struct('name','airu_s',     'power_prefix','power_airu_s',        'loader',@load_short)
    struct('name','nwp',        'power_prefix','power_nwp',           'loader',@load_nwp)
    struct('name','ens_linear', 'power_prefix','power_ensemble_linear','loader',@load_ens_linear)
    struct('name','ens_es',     'power_prefix','power_ensemble_es_unconstrain',   'loader',@load_ens_es)
    struct('name','per',        'power_prefix','power_per',           'loader',@load_per)
    struct('name','arima',        'power_prefix','power_arima',           'loader',@load_arima)
};

load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat allY_Test
Y_true = allY_Test(:,:,idx_eval_full);
wp_true = ws2wp_func(Y_true);                               

Z = norminv(gamma_list);
results = [];

load timesfm_quantile_results.mat
mu_2 = quantile(:,:,:,3);
load power_timefm_q020_quantile.mat
power_2 = mu_power;
mu_5 = quantile(:,:,:,5);
load power_timefm_q050_quantile.mat
power_5 = mu_power;
mu_8 = quantile(:,:,:,8);
load power_timefm_q080_quantile.mat
power_8 = mu_power;

load tabpfn_quantile_results.mat
mu_2 = quantile(:,:,:,2);
mu_5 = quantile(:,:,:,5);
mu_8 = quantile(:,:,:,8);
load power_tab_q020_quantile.mat
power_2 = mu_power;
load power_tab_q050_quantile.mat
power_5 = mu_power;
load power_tab_q080_quantile.mat
power_8 = mu_power;

PCE_vec  = get_pce_vector(mu_2, Y_true, power_2, wp_true, 0.2);
PCE_loc8_n = mean(PCE_vec(:,1,:), [1 2 3], 'omitmissing');
PCE_loc9_n = mean(PCE_vec(:,2,:), [1 2 3], 'omitmissing');
PCE_mean_n = mean(PCE_vec, [1 2 3], 'omitmissing');

for m = 1:numel(models)
    mdl = models{m};
    is_ens = any(strcmp(mdl.name, {'ens_es','ens_linear'}));
    idx_use = iff(is_ens, idx_eval_ens, idx_eval_full); %% if name in the list, pick ens idx, if not, pick full idx.

   
    [mu_ws, sigma_ws] = mdl.loader(sites, idx_use);

    % assert(size(mu_ws,3) == size(Y_true,3), '[%s] (138)', mdl.name);
    % assert(isequal(size(mu_ws), size(sigma_ws)), '[%s] mu,sigma ', mdl.name);
    % assert(size(mu_ws,2) == size(Y_true,2), '[%s] ', mdl.name);

    for gi = 1:numel(gamma_list)
        g   = gamma_list(gi);
        z   = Z(gi);
        tag = round(g*100);

        Y_pred = mu_ws + z .* sigma_ws;   
        f_wp = sprintf('%s_q%03d_quantile.mat', mdl.power_prefix, tag);
        S = load(f_wp);                   
        wp_pred_raw = S.mu_power;         
        wp_pred = take_sites(wp_pred_raw(:, :, idx_use), sites);

        %assert(size(Y_pred,3)==size(Y_true,3) && size(wp_pred,3)==size(wp_true,3), ...
        %       '[%s]  roll ', mdl.name);

        PCE_vec  = get_pce_vector(Y_pred, Y_true, wp_pred, wp_true, g);
        PCE_loc8 = mean(PCE_vec(:,1,:), [1 2 3], 'omitmissing');
        PCE_loc9 = mean(PCE_vec(:,2,:), [1 2 3], 'omitmissing');
        PCE_mean = mean(PCE_vec, [1 2 3], 'omitmissing');


        fprintf('[%s] gamma=%.2f  PCE=%.6f\n', mdl.name, g, PCE_mean, PCE_loc8, PCE_loc9);
        results = [results; {mdl.name, g, PCE_mean, PCE_loc8, PCE_loc9}]; 
    end
end


%% write the results in the table. uncomment it if needed
T = cell2table(results, 'VariableNames', {'model','gamma','PCE_mean','PCE_loc8','PCE_loc9'});
save('PCE_results_138rolls_new.mat','T');
writetable(T, 'PCE_results_138rolls.csv');
disp('--- Done. All models compared on the same 138-roll window ---');


function [mu_ws, sigma_ws] = load_long(sites, idx_use)
    load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat allY_Fore allVariance
    mu_ws_full = allY_Fore;                         
    mu_ws = take_sites(mu_ws_full(:, :, idx_use), sites); 

    D = size(allVariance,1); S = D/24; R = size(allVariance,3);
    std_all = zeros(24, S, R);
    for r = 1:R
        Sig = allVariance(:,:,r); 
        for s = 1:S
            rows = (24*(s-1)+1):(24*s);
            std_all(:, s, r) = sqrt(max(diag(Sig(rows, rows)),0));
        end
    end
    sigma_ws = take_sites(std_all(:, :, idx_use), sites);  
end

function [mu_ws, sigma_ws] = load_short(sites, idx_use)
    load short_term(6).mat allY_Fore std_Fore
    mu_ws    = take_sites(allY_Fore(:, :, idx_use), sites);
    sigma_ws = take_sites(std_Fore(:,  :, idx_use), sites);
end

function [mu_ws, sigma_ws] = load_nwp(sites, idx_use)
    load NWP.mat NWP sigma_nwp
    mu_ws    = take_sites(NWP(:,      :, idx_use), sites); 
    sigma_ws = take_sites(sigma_nwp(:, :, idx_use), sites);
end

function [mu_ws, sigma_ws] = load_ens_linear(~, idx_use)
    load ensemble_test_linear.mat Yhat std_pred
    mu_ws    = Yhat(:,     :, idx_use);  
    sigma_ws = std_pred(:, :, idx_use);  
end

function [mu_ws, sigma_ws] = load_ens_es(~, idx_use)
    load ensemble_es_constrain_unconstrain.mat mu Sigma
    mu_ws = mu(:, :, idx_use);          
    T = size(Sigma, 4);
    std_es = zeros(24,2,T);
    for t = 1:T
        C1 = squeeze(Sigma(1, :, :, t));  std_es(:,1,t) = sqrt(max(diag(C1),0));
        C2 = squeeze(Sigma(2, :, :, t));  std_es(:,2,t) = sqrt(max(diag(C2),0));
    end
    sigma_ws = std_es(:, :, idx_use);     
end

function [mu_ws, sigma_ws] = load_per(~, idx_use)
    load PER624.mat pred sigma_h
    mu_ws    = pred(:,    :, idx_use);  
    sigma_ws = sigma_h(:, :, idx_use);  
end

function [mu_ws, sigma_ws] = load_arima(~, idx_use)
    load arimaX_24roll_30day.mat
    num_horizon = 24;
    num_loc = 2;
    num_roll = size(Y, 3);
    Y_pred = reshape(Y(:,1,:),[24,2,183]);
    Y_lower = reshape(Y(:, 3, :), [num_horizon, num_loc, num_roll]);
    Y_upper = reshape(Y(:, 4, :), [num_horizon, num_loc, num_roll]);
    Y_true = reshape(Y(:, 2, :), [num_horizon, num_loc, num_roll]);
    % Convert 95% CI width to standard deviation
    z = 1.96;
    Y_std = (Y_upper - Y_lower) ./ (2 * z);
    Y_std(Y_std <= 0) = NaN;  
    mu_ws    = Y_pred(:,    :, idx_use);  
    sigma_ws = Y_std(:, :, idx_use);
end

function B = take_sites(A, sites)
    if size(A,2) >= 3 %% if file contain more than 2, take site index to refer to E05/E06
        B = A(:, sites, :);
    elseif size(A,2) == 2 %% if exactly 2 loc, then already E05/E06
        B = A; 
    else
        error('=%d %s ', size(A,2), mat2str(sites));
    end
end

function y = iff(cond, a, b)
    if cond, y = a; else, y = b; end
end
