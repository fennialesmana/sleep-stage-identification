function bin = dectobin(dec)
    bin = logical(double(dec2bin(dec)) - 48);
end