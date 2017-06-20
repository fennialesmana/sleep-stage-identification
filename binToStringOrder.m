function x = binToStringOrder(bin)
    f = find(bin==1);
    x = [];
    for l=1:size(f, 2)
        x = strcat(x, sprintf(' %d', f(1, l)));
    end
end