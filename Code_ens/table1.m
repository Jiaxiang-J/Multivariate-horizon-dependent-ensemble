clc;clear;
load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat
index = 46:183; %% index in the test period
true = allY_Test(:,:,index);
pred_long = allY_Fore(:,[8,9],index);
err_long = pred_long - true; %% error term
rmse_1_6_long  = sqrt(mean(err_long(1:6,:,:).^2,  'all'));  
% rmse_7_24_long = sqrt(mean(err_long(7:12,:,:).^2, 'all'));  
% rmse_7_12_long = sqrt(mean(err_long(13:24,:,:).^2, 'all')); 
% rmse_13_18_long = sqrt(mean(err_long(15:24,:,:).^2, 'all')); 
rmse_7_24_long = sqrt(mean(err_long(7:24,:,:).^2, 'all'));  
rmse_1_24_long = sqrt(mean(err_long.^2,            'all'));
load short_term(6).mat
pred_short = allY_Fore(:,[8,9],index);
err_short = pred_short - true;
rmse_1_6_short  = sqrt(mean(err_short(1:6,:,:).^2,  'all'));  
% rmse_7_24_short = sqrt(mean(err_short(7:12,:,:).^2, 'all'));   
% rmse_7_12_short = sqrt(mean(err_short(13:24,:,:).^2, 'all')); 
% rmse_13_18_short = sqrt(mean(err_short(15:24,:,:).^2, 'all')); 
rmse_7_24_short = sqrt(mean(err_short(7:24,:,:).^2, 'all'));
rmse_1_24_short = sqrt(mean(err_short.^2,            'all'));
load PER624.mat
pred_per = pred(:,:,index);
err_per = pred_per - true;
rmse_1_6_per  = sqrt(mean(err_per(1:6,:,:).^2,  'all'));  
% rmse_7_24_per = sqrt(mean(err_per(7:12,:,:).^2, 'all'));
% rmse_7_12_per = sqrt(mean(err_per(13:24,:,:).^2, 'all')); 
% rmse_13_18_per = sqrt(mean(err_per(15:24,:,:).^2, 'all')); 
rmse_7_24_per = sqrt(mean(err_per(7:24,:,:).^2, 'all'));
rmse_1_24_per = sqrt(mean(err_per.^2,            'all'));
load NWP.mat
pred_nwp = NWP(:,:,index);
err_nwp = pred_nwp - true;
rmse_1_6_nwp  = sqrt(mean(err_nwp(1:6,:,:).^2,  'all'));  
% rmse_7_24_nwp = sqrt(mean(err_nwp(7:12,:,:).^2, 'all'));  
% rmse_7_12_nwp = sqrt(mean(err_nwp(13:24,:,:).^2, 'all')); 
% rmse_13_18_nwp = sqrt(mean(err_nwp(15:24,:,:).^2, 'all')); 
rmse_7_24_nwp = sqrt(mean(err_nwp(7:24,:,:).^2, 'all'));
rmse_1_24_nwp = sqrt(mean(err_nwp.^2,            'all'));
% load result_lstm_train30.mat
% Y_pred = reshape(Y(:,1,:),[24,2,183]);
% pred_lstm = Y_pred(:,:,index);
% err_lstm = pred_lstm - true;
% rmse_1_6_lstm  = sqrt(mean(err_lstm(1:6,:,:).^2,  'all'));   
% % rmse_7_24_lstm = sqrt(mean(err_lstm(7:12,:,:).^2, 'all'));  
% % rmse_7_12_lstm = sqrt(mean(err_lstm(13:24,:,:).^2, 'all')); 
% % rmse_13_18_lstm = sqrt(mean(err_lstm(15:24,:,:).^2, 'all')); 
% rmse_7_24_lstm = sqrt(mean(err_lstm(7:24,:,:).^2, 'all'));
% rmse_1_24_lstm = sqrt(mean(err_lstm.^2,            'all'));
% load arimaX_24roll_30day.mat
% Y_pred = reshape(Y(:,1,:),[24,2,183]);
% pred_arima = Y_pred(:,:,index);
% err_arima = pred_arima - true;
% rmse_1_6_arima  = sqrt(mean(err_arima(1:6,:,:).^2,  'all'));  
% % rmse_7_24_arima = sqrt(mean(err_arima(7:12,:,:).^2, 'all'));   
% % rmse_7_12_arima = sqrt(mean(err_arima(13:24,:,:).^2, 'all')); 
% % rmse_13_18_arima = sqrt(mean(err_arima(15:24,:,:).^2, 'all')); 
% rmse_7_24_arima = sqrt(mean(err_arima(7:24,:,:).^2, 'all'));
% rmse_1_24_arima = sqrt(mean(err_arima.^2,            'all'));
% load ens1.mat
% pred_ens1 = pred(:,:,index);
% err_ens1 = pred_ens1 - true;
% rmse_1_6_ens1  = sqrt(mean(err_ens1(1:6,:,:).^2,  'all'));   
% % rmse_7_24_ens1 = sqrt(mean(err_ens1(7:12,:,:).^2, 'all'));  
% % rmse_7_12_ens1 = sqrt(mean(err_ens1(13:24,:,:).^2, 'all')); 
% % rmse_13_18_ens1 = sqrt(mean(err_ens1(15:24,:,:).^2, 'all')); 
% rmse_7_24_ens1 = sqrt(mean(err_ens1(7:24,:,:).^2, 'all'));
% rmse_1_24_ens1 = sqrt(mean(err_ens1.^2,            'all'));
load ensemble_es_constrain.mat
pred_ens = mu;
err_ens = pred_ens - true;
rmse_1_6_ens  = sqrt(mean(err_ens(1:6,:,:).^2,  'all'));  
% rmse_7_24_ens = sqrt(mean(err_ens(7:12,:,:).^2, 'all'));  
% rmse_7_12_ens = sqrt(mean(err_ens(13:24,:,:).^2, 'all')); 
% rmse_13_18_ens = sqrt(mean(err_ens(15:24,:,:).^2, 'all')); 
rmse_7_24_ens = sqrt(mean(err_ens(7:24,:,:).^2, 'all'));
rmse_1_24_ens = sqrt(mean(err_ens.^2,            'all'));
load ensemble_test_linear.mat
pred_ens_linear = Yhat;
err_ens_linear = pred_ens_linear - true;
rmse_1_6_ens_linear  = sqrt(mean(err_ens_linear(1:6,:,:).^2,  'all'));  
% rmse_7_24_ens_linear = sqrt(mean(err_ens_linear(7:12,:,:).^2, 'all')); 
% rmse_7_12_ens_linear = sqrt(mean(err_ens_linear(13:24,:,:).^2, 'all')); 
% rmse_13_18_ens_linear = sqrt(mean(err_ens_linear(15:24,:,:).^2, 'all')); 
rmse_7_24_ens_linear = sqrt(mean(err_ens_linear(7:24,:,:).^2, 'all'));
rmse_1_24_ens_linear = sqrt(mean(err_ens_linear.^2,            'all'));