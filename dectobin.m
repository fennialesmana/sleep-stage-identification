function bin = dectobin(dec)
%Convert decimal to binary
%   Syntax:
%   bin = dectobin(dec)
%
%   Input:
%   *) dec    - decimal value
%
%   Output:
%   *) bin    - logical of 1 X total bits
    bin = logical(double(dec2bin(dec)) - 48);
end