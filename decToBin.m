function bin = decToBin(dec)
    temp = int64(dec);
    flag = 0;
    j = 1;
    while flag ~= 1
        bin(j) = mod(temp, 2);
        temp = (temp - bin(j))/2;
        j = j + 1;
        if temp == 1
            bin(j) = 1;
            flag = 1;
        end
    end
    bin = fliplr(bin);
end