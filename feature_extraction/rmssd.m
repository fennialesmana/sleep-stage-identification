function output = rmssd(rr_diff)
    output = sqrt(sum((rr_diff.^2))/size(rr_diff, 1));
end