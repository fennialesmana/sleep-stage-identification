function maskedFeature = featureMasking(feature, mask)
% Input:
% feature -> original nSample X nFeature matrix size
% mask -> boolean of 1 X nFeature matrix size
% Output:
% maskedFeature -> matrix size of nSample X nSelectedFeature

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