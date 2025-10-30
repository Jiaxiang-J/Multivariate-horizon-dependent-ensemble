clc;
clear;
%load ensemble_prob.mat
load corr-offsite-results_1-12_winter_hour_train60_multi1_th50.mat 
std = get_std(allVariance(24*7+1:24*9,24*7+1:24*9,46:183));
pred1 = nan(24,2,138);
%load short_term(6).mat
%std = std_Fore(:,[8,9],46:183);
std1 = nan(24,2,138);
%load arimaX_24roll_30day.mat
%Y_pred = reshape(Y(:,1,:),[24,2,183]);
%std = get_std(allVariance(24*7+1:24*9,24*7+1:24*9,:));
pred1(7:24,:,:) = allY_Fore(7:24,[8,9],46:183);
std1(7:24,:,:) = std(7:24,:,:);
load short_term(6).mat
std1(1:6,:,:) = std_Fore(1:6,[8,9],46:183);
pred1(1:6,:,:) = allY_Fore(1:6,[8,9],46:183);
%load benchmark1.mat
%std = std_Fore(:,[8,9],:);
%S = allVariance(24*7+1:24*8,24*7+1:24*8,:);
%load ensemble_test_linear1.mat
%load PER624.mat
%load ensemble_test.mat
load ensemble_es_constrain.mat
load NWP.mat
loc = 1;                        % 对应 index 1
T = size(Sigma, 4);             % 138
std_loc1 = zeros(24, T);
for k = 1:T
    Ck = squeeze(Sigma(loc, :, :, k));  % 24x24
    std_loc1(:, k) = sqrt(diag(Ck));     % 24x1
end

loc = 2;                        % 对应 index 1
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
    y_test = allY_Test(:,1,roll+45);
    y_pred = NWP(:,1,roll+45);
    %y_test = all_y_true(:,index,roll);
    %y_pred = fore(:,index,roll);
    %sigma = std1(:,index,roll);
    %sigma = sigma1(:,1,roll);
    sigma = sigma_nwp(:,1,roll+45);
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
    y_test = allY_Test(:,2,roll+45);
    y_pred = NWP(:,2,roll+45);
    %y_test = all_y_true(:,index,roll);
    %y_pred = fore(:,index,roll);
    %sigma = std1(:,index,roll);
    sigma = sigma_nwp(:,2,roll+45);
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