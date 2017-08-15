function dec = bintodec(bin)
%Convert binary to decimal
%   Syntax:
%   dec = bintodec(bin)
%
%   Input:
%   *) bin    - logical of 1 X total bits
%
%   Output:
%   *) dec    - decimal value of inputted binary
    dec = bin2dec(char(double(bin) + 48));
end