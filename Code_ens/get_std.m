function [std_tensor] = get_std(allVariance)

    Y_var = allVariance;

    [num_rollls] = size(Y_var, 3);
    std_tensor = zeros(24, 2, num_rollls);

    for i = 1:num_rollls

        covariance_matrix = Y_var(:, :, i);
        covariance_matrix = (covariance_matrix + covariance_matrix') / 2;
        std_vector = sqrt(diag(covariance_matrix));
        std_tensor(:,:, i) = reshape(std_vector, [24, 2]);
    end    

end