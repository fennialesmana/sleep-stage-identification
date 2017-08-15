function y = sigmoid(x)
%Calculates sigmoid function
%   Syntax:
%   y = sigmoid(x)
%
%   Input:
%   *) x - input value
%
%   Output:
%   *) y - sigmoid result
    y = 1./(1 + exp(-1.*x));
end