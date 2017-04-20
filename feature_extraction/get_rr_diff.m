function output = get_rr_diff(rr)
    output = zeros(size(rr, 1)-1, 1);
    for j=1:size(output, 1)
        output(j) = rr(j+1)-rr(j);
    end
end