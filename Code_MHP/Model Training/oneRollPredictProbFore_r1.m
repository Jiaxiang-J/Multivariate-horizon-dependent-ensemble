function [y_pred, y_pred_res, S_obs, S_latent, y_int, ...
          res_mu_train, res_postgp_train, gprMdl1, debugInfo] ...
    = oneRollPredictProbFore_r1(X_trainGP, X_trainLR, X_testGP, X_testLR, y_train)

    %==============================================================
    % Step 1. Linear regression for mean calibration
    %==============================================================
    [b, ~, res] = regress(y_train, X_trainLR);

    y_pred_res   = X_testLR * b;
    res_mu_train = res;

    %==============================================================
    % Step 2. Standardize GP predictors manually
    %==============================================================
    Xmu  = mean(X_trainGP, 1);
    Xsig = std(X_trainGP, 0, 1);

    Xsig(Xsig == 0) = 1;

    X_train_std = (X_trainGP - repmat(Xmu, size(X_trainGP,1), 1)) ...
                ./ repmat(Xsig, size(X_trainGP,1), 1);

    X_test_std  = (X_testGP - repmat(Xmu, size(X_testGP,1), 1)) ...
                ./ repmat(Xsig, size(X_testGP,1), 1);

    %==============================================================
    % Step 3. Fit GP on residuals
    % IMPORTANT: turn off built-in Standardize
    %==============================================================
    opts = statset('fitrgp');

    gprMdl1 = fitrgp( ...
        X_train_std, res, ...
        'FitMethod', 'exact', ...
        'KernelFunction', 'ardsquaredexponential', ...
        'Standardize', 0, ...
        'OptimizerOptions', opts, ...
        'Verbose', 0);

    % training fit
    g_train = predict(gprMdl1, X_train_std);
    res_postgp_train = res - g_train;

    % test prediction
    [y_pred_GP, y_sd, y_int_GP] = predict(gprMdl1, X_test_std);

    y_pred = y_pred_res + y_pred_GP;
    y_int  = y_pred_res + y_int_GP;

    %==============================================================
    % Step 4. Reconstruct covariance consistently
    %==============================================================
    kfcn = gprMdl1.Impl.Kernel.makeKernelAsFunctionOfXNXM(gprMdl1.Impl.ThetaHat);

    Kxx = kfcn(X_train_std, X_train_std);
    Kxz = kfcn(X_train_std, X_test_std);
    Kzz = kfcn(X_test_std,  X_test_std);

    sig2 = gprMdl1.Sigma.^2;
    nTrain = size(X_train_std,1);
    nTest  = size(X_test_std,1);

    A = Kxx + sig2 * eye(nTrain);

    S_latent = Kzz - Kxz' * (A \ Kxz);
    S_obs    = S_latent + sig2 * eye(nTest);

    S_latent = (S_latent + S_latent') / 2;
    S_obs    = (S_obs + S_obs') / 2;

    %==============================================================
    % Step 5. Save debug info
    %==============================================================
    thetaHat = gprMdl1.Impl.ThetaHat;
    numDim   = size(X_trainGP, 2);

    debugInfo = struct();
    debugInfo.Xmu = Xmu;
    debugInfo.Xsig = Xsig;
    debugInfo.ThetaHat = thetaHat;
    debugInfo.Sigma2 = sig2;
    debugInfo.y_sd_from_predict = y_sd;
    debugInfo.manual_sd_obs = sqrt(max(diag(S_obs), 0));
    debugInfo.manual_sd_latent = sqrt(max(diag(S_latent), 0));

    % learned length scales in standardized space
    debugInfo.logLengthScale = thetaHat(1:numDim);
    debugInfo.lengthScale = exp(thetaHat(1:numDim));

    % convert back to raw units
    debugInfo.lengthScale_raw = debugInfo.lengthScale .* Xsig;

    if length(thetaHat) > numDim
        debugInfo.logSignalStd = thetaHat(numDim+1);
        debugInfo.signalStd = exp(thetaHat(numDim+1));
        debugInfo.signalVar = debugInfo.signalStd^2;
    end

end

function [Xmu, Xsig] = localGetPredictorStandardization(gprMdl1, X_trainGP)

    % Default fallback
    Xmu  = mean(X_trainGP, 1);
    Xsig = std(X_trainGP, 0, 1);

    % Avoid divide-by-zero
    Xsig(Xsig == 0) = 1;

    % Try public/common properties first
    if isprop(gprMdl1, 'PredictorLocation')
        tmp = gprMdl1.PredictorLocation;
        if ~isempty(tmp)
            Xmu = tmp;
        end
    end

    if isprop(gprMdl1, 'PredictorScale')
        tmp = gprMdl1.PredictorScale;
        if ~isempty(tmp)
            Xsig = tmp;
            Xsig(Xsig == 0) = 1;
        end
    end

    % Some versions may store them internally
    try
        if isprop(gprMdl1.Impl, 'PredictorLocation')
            tmp = gprMdl1.Impl.PredictorLocation;
            if ~isempty(tmp)
                Xmu = tmp;
            end
        end
    catch
    end

    try
        if isprop(gprMdl1.Impl, 'PredictorScale')
            tmp = gprMdl1.Impl.PredictorScale;
            if ~isempty(tmp)
                Xsig = tmp;
                Xsig(Xsig == 0) = 1;
            end
        end
    catch
    end

end

function yScale = localGetResponseScale(gprMdl1, res)

    % fallback
    yScale = std(res);

    if yScale == 0
        yScale = 1;
    end

    % public/common property
    if isprop(gprMdl1, 'ResponseScale')
        tmp = gprMdl1.ResponseScale;
        if ~isempty(tmp)
            yScale = tmp;
            if yScale == 0
                yScale = 1;
            end
            return;
        end
    end

    % internal property
    try
        if isprop(gprMdl1.Impl, 'ResponseScale')
            tmp = gprMdl1.Impl.ResponseScale;
            if ~isempty(tmp)
                yScale = tmp;
                if yScale == 0
                    yScale = 1;
                end
                return;
            end
        end
    catch
    end

end