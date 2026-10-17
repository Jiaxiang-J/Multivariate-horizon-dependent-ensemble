clc;
clear;
%% Note: need to load the corresponding file and check the variable name to determine the
%% mean and std, which will be used.
% Some files contain 183 roll, some files contain 138 roll, kindly check
% the file, 138 is from index 46 to 183 in 183 roll.
% For some file with same variable name, e.g. LTM and STM, only load the
% one you need to avoid conflict.
%load ensemble_prob.mat
load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat %% LTM
std_l = get_std(allVariance(24*7+1:24*9,24*7+1:24*9,46:183));
pred1 = nan(24,2,138);
%load short_term(6).mat
%std = std_Fore(:,[8,9],46:183);
std1 = nan(24,2,138);
load arimaX_24roll_30day.mat %%ARIMA-X
num_horizon = 24;
num_loc = 2;
num_roll = size(Y, 3);
Y_pred = reshape(Y(:,1,:),[24,2,183]);
Y_lower = reshape(Y(:, 3, :), [num_horizon, num_loc, num_roll]);
Y_upper = reshape(Y(:, 4, :), [num_horizon, num_loc, num_roll]);
Y_true = reshape(Y(:, 2, :), [num_horizon, num_loc, num_roll]);

Y_pred = Y_pred(:,:,46:183);

% Convert 95% CI width to standard deviation
z = 1.96;
Y_std = (Y_upper - Y_lower) ./ (2 * z);
Y_std(Y_std <= 0) = NaN;
Y_std = Y_std(:,:,46:183); %% Y_pred and Y_std for ARIMA-X
%std = get_std(allVariance(24*7+1:24*9,24*7+1:24*9,:));

%pred1(7:24,:,:) = allY_Fore(7:24,[8,9],46:183);
%std1(7:24,:,:) = std(7:24,:,:);
%load short_term(6).mat %% STM, in second dimension of allY_Fore and std_Fore, 8,9 represent E05, E06 .

load ensemble_swichpoint.mat %% switching point in the ablation ENS-S
std = permute(sigma, [3 2 1]);
pred = permute(mu, [3 2 1]);
true = permute(y_true, [3 2 1]);
%S = allVariance(24*7+1:24*8,24*7+1:24*8,:);
load ensemble_test_linear1.mat %%ENS-L
load PER624.mat %% PER
%load ensemble_test.mat
load ensemble_es_constrain.mat %% MHP-ENS
load NWP.mat
loc = 1;                      
T = size(Sigma, 4);             
std_loc1 = zeros(24, T);
for k = 1:T
    Ck = squeeze(Sigma(loc, :, :, k));  % 24x24
    std_loc1(:, k) = sqrt(diag(Ck));     % 24x1
end

loc = 2;                        
T = size(Sigma, 4);             % 138
std_loc2 = zeros(24, T);

for k = 1:T
    Ck = squeeze(Sigma(loc, :, :, k));  % 24x24
    std_loc2(:, k) = sqrt(diag(Ck));     % 24x1
end

rng(12345,'twister');
index = 1;
for roll = 1:138
    
    %conf_int = allY_int(:,[1,2],9,roll);
    %y_test = allY_Test(:,1,roll+45);
    y_test = Y_true(:,1,roll+45);
    %y_test = true(:,1,roll);
    %y_pred = NWP(:,1,roll+45);
    %y_test = all_y_true(:,index,roll);
    %y_pred = Y_pred(:,index,roll+45);
    %sigma = std1(:,index,roll);
    %sigma = Y_std(:,1,roll+45);
    %sigma = sigma_nwp(:,1,roll+45);

    y_pred = Yhat(:,1,roll); %% change here to reflect different model, same place in E06.
    sigma = std_pred(:,1,roll);

    p = nan(24, 1000);
    for i = 1:24
        p(i, :) = mvnrnd(y_pred(i),sigma(i),1000)';
    end
    for i = 1: 24
	    crpsE05(roll,i) = crps(p(i,:),y_test(i));
        %crpsE06(roll,i) = crps(p(D+i,:),y_test(D+i));
    end

end
index = 2;
for roll = 1:138    
    %conf_int = allY_int(:,[1,2],9,roll);
    %y_test = allY_Test(:,2,roll+45);
    y_test = Y_true(:,2,roll+45);
    %y_test = true(:,2,roll);
    %y_pred = NWP(:,2,roll+45);
    %y_test = all_y_true(:,index,roll);
    %y_pred = Y_pred(:,index,roll+45);
    %sigma = Y_std(:,index,roll+45);
    y_pred = Yhat(:,2,roll);
    sigma = std_pred(:,2,roll);
    %sigma = sigma_nwp(:,2,roll+45);
    p = nan(24, 1000);
    for i = 1:24
        p(i, :) = mvnrnd(y_pred(i),sigma(i),1000)';
    end
    for i = 1: 24
	    crpsE06(roll,i) = crps(p(i,:),y_test(i));
        %crpsE06(roll,i) = crps(p(D+i,:),y_test(D+i));
    end
end
(mean(crpsE06(:,1:6),[1,2],'omitnan')+mean(crpsE05(:,1:6),[1,2],'omitnan'))/2
(mean(crpsE06(:,7:24),[1,2],'omitnan')+mean(crpsE05(:,7:24),[1,2],'omitnan'))/2
(mean(crpsE06,[1,2],'omitnan')+mean(crpsE05,[1,2],'omitnan'))/2