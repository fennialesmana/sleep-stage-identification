function output = time_matrix_to_cell(time_matrix)
    output = cell(size(time_matrix, 1), 1);
    for i = 1:size(time_matrix, 1)
        if(time_matrix(i, 1) == 0) %kalo jamnya 0
            output(i) = cellstr(strcat(sprintf('%d',time_matrix(i, 2)), sprintf(':%02d.000',time_matrix(i, 3))));
        else
            temp = strcat(sprintf('%d', time_matrix(i, 1)), sprintf(':%02d',time_matrix(i, 2)));
            output(i) = cellstr(strcat(temp, sprintf(':%02d.000',time_matrix(i, 3))));
        end
        
        
    end
end