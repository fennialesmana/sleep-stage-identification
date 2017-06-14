function dec = binToDec(bin)
    pow = 0;
    dec = int64(0);
    for i=size(bin, 2):-1:1
        if bin(i) == 1
            dec = dec + 2^pow;
        end
        pow = pow+1;
    end
end