load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat
index = 46:183;
e_long = allError(1:24,:,index);
%error = allY_Test - allY_Fore(:,[8,9],:);
e_nwp = allError_NWP(1:24,:,index);
load short_term(6).mat
e_short = allY_Test - allY_Fore(:,[8,9],:);
e_short = e_short(1:24,:,index);
% load arimaX_24roll_30day.mat
% e_arima = permute(allError,[2,3,1]);
% e_arima = e_arima(1:24,:,index);
load PER_all.mat
e_per = allY_Test - pred;
e_per = e_per(1:24,:,index);
% load result_lstm_train30.mat
% e_lstm = allY_Test - reshape(Y(:,1,:),[24,2,183]);
% e_lstm = e_lstm(1:24,:,index);
load ensemble_es_constrain.mat
e_ens = allY_Test(:,:,index)- mu;
e_ens = e_ens(1:24,:,:);
load ensemble_test_linear.mat
e_ens_linear = allY_Test(:,:,index)- Yhat;
e_ens_linear = e_ens_linear(1:24,:,:);
% load benchmark1.mat
% e_bench = allY_Test(:,:,index)-fore(:,:,index);
% e_bench = e_bench(1:24,:,:);
%e1_raw, e2_raw : [24  2  183]
%e1_vec = reshape(e_long, [], 1);   % 87841
%e2_vec = reshape(e_ens, [], 1);
%h      = 6;
%[DM, p] = dmtest_modified(e1_vec, e2_vec, h);

mse1  = squeeze( mean( mean( e_ens.^2 , 1), 2) );  % 
mse2  = squeeze( mean( mean( e_short.^2 , 1), 2) ); % change here to get results for other models

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