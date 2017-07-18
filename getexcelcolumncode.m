function code = getexcelcolumncode(num)
    angka = num;
    code = '';
    while angka > 0
        sisa = mod((angka - 1), 26);
        code = strcat(char(65 + sisa),code);
        angka = floor((angka - sisa)/26);
    end
end