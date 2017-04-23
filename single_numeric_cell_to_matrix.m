function output = single_numeric_cell_to_matrix(rr_cell)
    output = zeros(size(rr_cell, 1), 1);
    for i=1:size(rr_cell, 1)
        output(i) = str2num(cell2mat(rr_cell(i)));
    end
end