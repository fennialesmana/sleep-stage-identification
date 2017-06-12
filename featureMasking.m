function maskedFeature = featureMasking(feature, mask)
    % prepare the feature data (masking)
    maskedFeature = zeros(size(feature, 1), sum(mask));
    j = 1;
    for i=1:sum(mask)
        if mask(1, i) == 1
           maskedFeature(:, j) = feature(:, i);
           j = j + 1;
        end
    end
end