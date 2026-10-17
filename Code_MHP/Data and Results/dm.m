load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat %% long term
index = 46:183;
id1 = 1:6;
id2 = 7:24;
id3 = 1:24;
%% change id1/2/3 based on 1-6, 7-24, 1-24. 
%% Note you need to change the benchmark and ensemble simultaneously
e_long = allError(id2,:,index);
%error = allY_Test - allY_Fore(:,[8,9],:);
e_nwp = allError_NWP(id3,:,index); %% NWP
load short_term(6).mat %% Short term
e_short = allY_Test - allY_Fore(:,[8,9],:);
e_short = e_short(id1,:,index);
load arimaX_24roll_30day.mat %% ARIMAX
e_arima = permute(allError,[2,3,1]);
e_arima = e_arima(id3,:,index);
load PER_all.mat %% PER
e_per = allY_Test - pred;
e_per = e_per(id3,:,index);
% load result_lstm_train30.mat 
% e_lstm = allY_Test - reshape(Y(:,1,:),[24,2,183]);
% e_lstm = e_lstm(id3,:,index);
load ensemble_es_constrain.mat %% ensemble
e_ens = allY_Test(:,:,index)- mu;
e_ens = e_ens(id3,:,:);
% load ensemble_test_linear.mat
% e_ens_linear = allY_Test(:,:,index)- Yhat;
% e_ens_linear = e_ens_linear(id1,:,:);
% load ensemble_es_constrain_independence.mat
% e_ens_ind = allY_Test(:,:,index)- mu;
% e_ens_ind = e_ens_ind(id2,:,:);
% load benchmark1.mat
% e_bench = allY_Test(:,:,index)-fore(:,:,index);
% e_bench = e_bench(1:24,:,:);
%e1_raw, e2_raw : [24  2  183]
%e1_vec = reshape(e_long, [], 1);   % 87841
%e2_vec = reshape(e_ens, [], 1);
%h      = 6;
%[DM, p] = dmtest_modified(e1_vec, e2_vec, h);

load forecast_timesfm.mat %% timesfm
pred1 = pred1;
e_ens_timefm = allY_Test(:,:,index) - pred1;
e_ens_timefm = e_ens_timefm(id3,:,:);

load tabpfn_quantile_results.mat %% tabpfn
e_tab = target(id3,:,:) - pred(id3,:,:);

mse1  = squeeze( mean( mean( e_ens.^2 , 1), 2) );  % 
mse2  = squeeze( mean( mean( e_ens_timefm.^2 , 1), 2) ); % change here to get results for other models

e1_dayErr = sqrt(mse1);   
e2_dayErr = sqrt(mse2);  

% ---  dmtest_modified ---
h = 1;                   
[DM, p] = dmtest_modified(e1_dayErr(:), e2_dayErr(:), h);

d = e1_dayErr(:) - e2_dayErr(:);  

dbar = mean(d);
sd_d = std(d, 1);  
T    = numel(d);
fprintf('T=%d, mean(d)=%.6g, std(d)=%.6g\n', T, dbar, sd_d);