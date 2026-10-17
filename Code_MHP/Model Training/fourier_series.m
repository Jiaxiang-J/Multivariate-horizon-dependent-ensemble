function result = fourier_series(t, period, K)
    % Generate Fourier series terms up to order K for a given period.
    % :param t: Array of time points
    % :param period: The period of the seasonality
    % :param K: The number of Fourier terms to generate
    % :return: Matrix of Fourier terms

    x = (0:t-1)';  % MATLAB indexing starts at 1, so create an array from 0 to t-1
    
    % Initialize the result matrix
    result = zeros(t, 2*K);  
    
    % Generate sine and cosine terms for each order
    for k = 1:K
        result(:, 2*k-1) = sin(2 * pi * k * x / period);
        result(:, 2*k)   = cos(2 * pi * k * x / period);
    end
end