function maskedFeature = featuremasking(feature, mask)
%Retrieve masked features
%   Syntax:
%   maskedFeature = featuremasking(feature, mask)
%
%   Input:
%   *) feature       - feature collection
%      (Matrix size: total samples X total features)
%   *) mask          - logical matrix, 1 means selected, 0 is not selected
%      (Matrix size: 1 X total features)
%   Output:
%   *) maskedFeature - matrix with selected features only
%      (Matrix size: total samples X total selected features

    maskedFeature = zeros(size(feature, 1), sum(mask));
    j = 1;
    for i=1:sum(mask)
        if mask(1, i) == 1
           maskedFeature(:, j) = feature(:, i);
           j = j + 1;
        end
    end
end