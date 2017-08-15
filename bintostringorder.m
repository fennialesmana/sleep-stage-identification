function x = bintostringorder(bin)
%Get the string of inputted logical value whose value is 1.
% For example, the inputted binary is [0 1 1 0 1], the output is '2 3 5'.
%   Syntax:
%   x = bintostringorder(bin)
%
%   Input:
%   *) bin - logical of binary
%
%   Output:
%   *) x   - string of binary index number whose value is 1

    f = find(bin==1);
    x = [];
    x = strcat(x, sprintf('%d', f(1, 1)));
    for l=2:size(f, 2)
        x = strcat(x, sprintf(' %d', f(1, l)));
    end
end