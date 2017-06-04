function output = extractGeometricalFeatures(rr)
    bin_size = 7.812;
    rr = rr.*1000;
    max_val = max(rr);
    min_val = min(rr);
    bin_count = ceil((max_val-min_val)/bin_size);
    %generate edges
    edges = zeros(bin_count+1, 1);
    edges(1) = min_val;
    for i=2:bin_count+1
        edges(i) = edges(i-1) + bin_size;
    end
    %calculate histogram
    N = histcounts(rr, edges);
    %calculate hrv triangular index
    output.TRIANGULAR_INDEX = max(N)/sum(N);
end