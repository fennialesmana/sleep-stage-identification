function data = normalizedata(data, lowerLimit, upperLimit)
%Min Max Data Normalization
%   Syntax:
%   data = normalizedata(data, lowerLimit, upperLimit)
%
%   Input:
%   *) data       - data that will be normalized
%      (Matrix size: total samples X total features)
%   *) lowerLimit - lower limit of value after normalization
%   *) upperLimit - upper limit of value after normalization
%
%   Output:
%   *) data - data after normalization (size is the same as input)

    E = (upperLimit-lowerLimit);
    for i=1:size(data, 2)
        minVal = min(data(:, i));
        maxVal = max(data(:, i));
        data(:, i) = ( (data(:, i)-minVal) ./ (maxVal - minVal) ) .* ...
            repmat(E, size(data(:, i))) + ...
            repmat(lowerLimit, size(data(:, i)));
    end
end