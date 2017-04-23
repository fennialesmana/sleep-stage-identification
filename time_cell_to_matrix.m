function output = time_cell_to_matrix(time_cell)
output = zeros(size(time_cell, 1), 3);
for i = 1:size(time_cell, 1)
    start_time = strsplit(char(time_cell(i)), ':')';
    start_time_size = size(start_time, 1);
    
    if start_time_size == 2
        output(i, 1) = 0;
        output(i, 2) = str2num(cell2mat(start_time(1)));
        output(i, 3) = str2num(cell2mat(start_time(2)));
    elseif start_time_size == 3
        output(i, 1) = str2num(cell2mat(start_time(1)));
        output(i, 2) = str2num(cell2mat(start_time(2)));
        output(i, 3) = str2num(cell2mat(start_time(3)));
    end
end    

end