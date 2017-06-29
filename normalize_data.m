function data = normalizedata(data, lowerLimit, upperLimit)
    % data normalization: using min max normalization
    % data = nSamples X nFeatures;
    % lowerLimit = -1;
    % upperLimit = 1;
    E = (upperLimit-lowerLimit) + lowerLimit;
    for i=1:size(data(:, 1:end-1), 2)
        minVal = min(data(:, i));
        maxVal = max(data(:, i));
        data(:, i) = ( (data(:, i)-minVal) ./ (maxVal + minVal) ) .* repmat(E, size(data(:, i)));
    end
end