function x = binToStringOrder(bin)
    f = find(bin==1);
    x = [];
    x = strcat(x, sprintf('%d', f(1, 1)));
    for l=2:size(f, 2)
        x = strcat(x, sprintf(' %d', f(1, l)));
    end
end