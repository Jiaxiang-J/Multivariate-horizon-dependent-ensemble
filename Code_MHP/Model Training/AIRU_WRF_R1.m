clc;
clear;

%{
This is the code to Run AIRU-WRF model. 
before start, prepare your data in this way and save them in data.mat:

input:
1. Ws_Mea:   Wind Speed Measurement.
                    size: T-by-N, T: number of time N: number of spatial locations

2. allVari: all NWP Variables.
                size: T-by-M-by-N  M: number of variables.
                note: if you create some new variables, you should add the variables in allVari

3. LatValue_vec / LonValue_vec: Latitude and longitude value vector
                size: N-by-1

%}

% load ../../../data/data_winter_hour.mat
load data_test_hour.mat

Ws_Mea = Ws_Mea_h;

LonValue_test = LonValue_vec(1:9);
LatValue_test = LatValue_vec(1:9);
allVari_test = allVari_h(:, :, 1:9);

LonValue_train = LonValue_vec(8:9);
LatValue_train = LatValue_vec(8:9);
allVari_train = allVari_h(:, :, [8, 9]);
%% parameters setting
fore_hrs = 24;      % forecast hours (hour)
roll_hrs = 24;       % rolling window hour (hour)
r = roll_hrs;     % rolling horizons (10 minutes)
d = 4;
train_days = 10;     % # of days to train model in each roll
num_train = train_days*24;  % # of training data size
num_ini = 90 * 24;
num_test  = fore_hrs;      % # of forecast
thresholdCorr = 0.9;    % threshold of correlation to pick the variables 

indi_multi = 1; % indicator include multiplicative component?
indi_fourier = 0; % indicator include fourier series?
season_length = 24;  % Adjust this to the correct season length for your data
fourier_order = 24;  % Number of Fourier terms

[num_data, num_sites_train]=size(Ws_Mea); 
num_roll = floor((num_data-num_test-num_ini)/r+1);  % calculate how many rolls 
% num_roll = 6*24*1;
% num_roll = 20;

% allData = struct();z
% for i = 1:num_sites_train
%     fieldName = ['allError', site_name{i}];  
%     allData.(fieldName) = zeros(num_roll,2,D); 
% end

%% GP input for train and test
t_train = linspace(1,num_train,num_train)';
X_trainGP = [];
for i = 1:num_sites_train
    X_trainGP = [X_trainGP; [repmat([LonValue_train(i) LatValue_train(i)], num_train, 1) t_train]];
end

num_sites_test = length(LonValue_test);
t_test = linspace(num_train+1,(num_train+num_test),num_test)';
X_testGP = [];
for i = 1:num_sites_test
    X_testGP = [X_testGP; [repmat([LonValue_test(i) LatValue_test(i)], num_test, 1) t_test]];
end
X_testGP = double(X_testGP);

%% run each roll
idxLR = [2,3,4,5,6,7];        % this is the index of variables you are going to include      
allLagP = [];
allLagAr = [];
allNWPinfo = cell(num_roll,1);
allLogLik_gp_train = nan(num_roll,1);
allNLL_gp_train    = nan(num_roll,1);
allRes_mu_train      = nan(num_train, num_sites_train, num_roll);
allRes_postgp_train  = nan(num_train, num_sites_train, num_roll);
allError = nan(num_test, num_sites_train, num_roll);
allError_NWP = nan(num_test, num_sites_train, num_roll);
allY_Test = nan(num_test, num_sites_train, num_roll);
maes = nan(fore_hrs, num_sites_train);
maes_nwp = nan(fore_hrs, num_sites_train);
allY_Fore = nan(num_test, num_sites_test, num_roll);
allY_int = nan(num_test, 2, num_sites_test, num_roll);
allVariance = nan(num_test*num_sites_test, num_test*num_sites_test, num_roll);
allY_NWP = nan(num_test, num_sites_test, num_roll);

theta = [1,0,1,0.6];    % initial value for parammeters in airu-wrf
for roll = 1:num_roll

    idx2 = num_ini+(roll-1)*r+1-d*24:num_ini+(roll-1)*r+num_test;
    V = [];
    for i = 1:num_sites_train
        V = [V; [allVari_train(idx2,5, i)  allVari_train(idx2,6, i)]];
    end

    indexTrain = num_ini+(roll-1)*r+1-num_train:num_ini+(roll-1)*r;

    y_train = [];
    for i = 1:num_sites_train
        y_train = [y_train; Ws_Mea(indexTrain, i)];
    end
%% ar   auto regression parts in \mu
    [pacf,lags,bounds] = parcorr(y_train);
    idxAR = find(abs(pacf)<bounds(1));
    arLag = idxAR(1)-2;                         % pick the lag
    allLagAr = [allLagAr arLag];  
    
    y_train_NWP = [];
    for i = 1:num_sites_train
        y_train_NWP = [y_train_NWP; allVari_train(indexTrain, 1, i)];
    end

    % y_train_res = y_train-y_train_NWP;
    y_corrTest = y_train;
    
    y_train_NWP1 = y_train_NWP;    
%% NWP variables in \mu
    corrLagMatrix = [];
    lag = -4:4;   % lag set
    lag = 0;  
    for i = lag
        if roll <= 4
            indexTrainLag = indexTrain;
        else
            indexTrainLag = indexTrain+i;
        end

        X_train1 = [];
        for j = 1:num_sites_train
            X_train1 = [X_train1; allVari_train(indexTrainLag,idxLR, j)];
        end
        dataLagVari = [y_corrTest X_train1];
        corrMatrix = corrcoef(dataLagVari);
        corrLagMatrix = [corrLagMatrix; abs(corrMatrix(1,2:end))];
    end
    [maxCorr, maxCorrLagIndex] = max(corrLagMatrix);
    idxVari = find(maxCorr>thresholdCorr);
    numVari = size(idxVari,2);
    
    if roll == 1
        LagNwp = zeros(1,numVari);
    else
        LagNwp = lag(maxCorrLagIndex(idxVari));
    end

    idxLRnew = idxLR(idxVari);
    allNWPinfo{roll} =[idxLRnew;LagNwp];    
    X_train1 = [];
    for  j = 1:num_sites_train 
        X_train1_temp = [];
        for i = 1:numVari
            X_train1_temp = [X_train1_temp allVari_train(indexTrain+LagNwp(i),idxLRnew(i), j)];
        end
        X_train1 = [X_train1; X_train1_temp];
    end
    
%%     prepare train and test \mu
    if isempty(X_train1)
        X_train2 = [];
    else
        X_train2 = X_train1.*y_train_NWP;
    end

    X_trainLR = [ones(size(X_train1,1),1),X_train1,y_train_NWP1];    
    if indi_multi
        X_trainLR = [ones(size(X_train1,1),1),X_train1,y_train_NWP1,X_train2];    % calibrate NWP input 
    end

    fo_train = repmat(fourier_series(num_train, season_length, fourier_order), num_sites_train, 1);

    if indi_fourier
        X_trainLR = [X_trainLR fo_train];
    end
    
    indexTest = num_ini+ (roll-1)*r+1:num_ini+(roll-1)*r+num_test;
    y_test = [];
    for i = 1:num_sites_train
        y_test = [y_test; Ws_Mea(indexTest, i)];
    end

    y_test_NWP = [];
    for i = 1:num_sites_test
        y_test_NWP = [y_test_NWP; allVari_test(indexTest, 1, i)];
    end    
    y_test_NWP1 = y_test_NWP;

    X_test1 = [];
    for  j = 1:num_sites_test
        X_test1_temp = [];
        for i = 1:numVari
            X_test1_temp = [X_test1_temp allVari_test(indexTest+LagNwp(i),idxLRnew(i), j)];
        end
        X_test1 = [X_test1; X_test1_temp];
    end

    if isempty(X_test1)
        X_test2 = [];
    else
        X_test2 = X_test1.*y_test_NWP;
    end

    X_testLR = [ones(size(X_test1,1),1),X_test1,y_test_NWP1];          % calibrate NWP input
    if indi_multi
        X_testLR = [ones(size(X_test1,1),1),X_test1,y_test_NWP1,X_test2]; 
    end

    fo_test = repmat(fourier_series(num_test, season_length, fourier_order), num_sites_test, 1);

    if indi_fourier
        X_testLR = [X_testLR fo_test];
    end
%%
    disp(['the ' num2str(roll) 'th rolling'])
    tic
    [y_pred, y_pred_res, S, S_latent, y_int, ...
    res_mu_train, res_postgp_train, gprMdl1, debugInfo] = ...
    oneRollPredictProbFore_r1( ...
        X_trainGP, X_trainLR, X_testGP, X_testLR, y_train);
    toc
    res_mu_train_mat     = reshape(res_mu_train,     [num_train, num_sites_train]);
    res_postgp_train_mat = reshape(res_postgp_train, [num_train, num_sites_train]);
    Y_fore = reshape(y_pred, [num_test, num_sites_test]);
    Y_fore_res = reshape(y_pred_res, [num_test, num_sites_test]);%% u part
    y_test = reshape(y_test, [num_test, num_sites_train]);  
    y_int = permute(reshape(y_int', [2, num_test, num_sites_test]), [2, 1, 3]);

    Y_fore_nwp = reshape(y_test_NWP, [num_test, num_sites_test]);

    error_cal = y_test - Y_fore(:, [8, 9]);
    error_cal_res = y_test-Y_fore_res(:,[8,9]);%
    error_cal_nwp = y_test - Y_fore_nwp(:, [8, 9]);    

    allError(:, :, roll) = error_cal;
    allError_res(:, :, roll) = error_cal_res;
    allY_Fore(:, :, roll) = Y_fore;
    allY_Fore_res(:, :, roll) = Y_fore_res;
    allY_Test(:, :,roll) = y_test;
    allY_int(:, :, :,roll) = y_int;
    allVariance(:, :, roll) = S;
    allY_NWP(:, :, roll) = Y_fore_nwp;
    allError_NWP(:, :, roll) = error_cal_nwp;    
    allRes_mu_train(:,:,roll)     = res_mu_train_mat;
    allRes_postgp_train(:,:,roll) = res_postgp_train_mat;
    %allLogLik_gp_train(roll) = logLik_gp;
    %allNLL_gp_train(roll)    = nll_gp;
end


for i = 1: fore_hrs
    maes(i, :) = mean(abs(allError((i-1)+1: i, :, :)), [1, 3], 'omitnan'); 
    maes_res(i, :) = mean(abs(allError_res((i-1)+1: i, :, :)), [1, 3], 'omitnan'); 
    maes_nwp(i, :) = mean(abs(allError_NWP((i-1)+1: i, :, :)), [1, 3], 'omitnan');     
end
%% change the name 'short_term(6)'
filename = sprintf('R1_test_results_hour_train%d_multi%d_th%d.mat', train_days, indi_multi, thresholdCorr*100);
if indi_fourier
    filename = sprintf('R1_results_hour_train%d_multi%d_th%d_SL%d_FO%d.mat', train_days, indi_multi, thresholdCorr*100, season_length, fourier_order);
end


save(filename, 'allError', 'allY_Fore', 'allY_Test', 'allVariance', 'allY_int','maes', 'maes_nwp', 'allY_NWP', 'allError_NWP', 'allNWPinfo','allError_res','maes_res','allY_Fore_res','allRes_mu_train', 'allRes_postgp_train','allLogLik_gp_train', 'allNLL_gp_train');
