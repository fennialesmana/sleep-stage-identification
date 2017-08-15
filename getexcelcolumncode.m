function code = getexcelcolumncode(num)
%Get excel column code. For example 5 is 'E' and 11 is 'K'.
%   Syntax:
%   code = getexcelcolumncode(num)
%
%   Input:
%   *) num    - number of excel code
%
%   Output:
%   *) code   - excel code for inputted number

    angka = num;
    code = '';
    while angka > 0
        sisa = mod((angka - 1), 26);
        code = strcat(char(65 + sisa),code);
        angka = floor((angka - sisa)/26);
    end
end