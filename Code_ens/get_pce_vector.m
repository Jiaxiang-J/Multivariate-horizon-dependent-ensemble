function pce = get_pce_vector(ws, ws_true, wp, wp_true, g)
    % Pre-allocate pce with NaN values
    pce = nan(size(ws));

    % Logical index where ws is less than or equal to ws_true
    idx_le = ws <= ws_true;
    
    % Compute pce values for the case when ws is less than or equal to ws_true
    pce(idx_le) = g * (wp_true(idx_le) - wp(idx_le));
    
    % Logical index where ws is greater than ws_true
    idx_gt = ~idx_le;  % Negation of idx_le, covers cases where ws > ws_true

    % Compute pce values for the case when ws is greater than ws_true
    pce(idx_gt) = (1 - g) * (wp(idx_gt) - wp_true(idx_gt));
end