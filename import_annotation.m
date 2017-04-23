function [annotation, an_time, an_class] = import_annotation(file_name)
fid = fopen(file_name, 'r'); %read data from file
line = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]'); % get first 7 column of the data
fclose(fid); %close the stream

% hapus line pertama kalo di file data ada header
total_line_col = size(line, 2);
for i=1:total_line_col
   line{i}(1) = [];
end

total_row = size(line{1}, 1);
%{
annotations:
01. hour
02. minute
03. second
04. sleep_state:
    1 = stage 1
    2 = stage 2
    3 = stage 3
    4 = stage 4
    W = Wake
    R = REM
%}
%annotation(find(a==7)) = 10

%{
% isi data ke annotation versi 1:: pakai matrix
annotation = zeros(total_row, 4);
for i=1:total_row
    time = strsplit(char(line{1}(i)), ':')';
    time_size = size(time);
    count_time = time_size(1);
    
    for j=3:-1:1
        if j == 1 && time_size(1) == 2
            annotation(i, j) = 0;
        else
            annotation(i, j) = str2num(cell2mat(time(count_time)));
        end
        count_time = count_time - 1;
    end
    
    %if i == 4
    %    annotation(:, i) = line{7};
    %end
end
%}

% isi data ke annotation versi 1:: pakai struct
line{1}(1) = {'0:00.000'};
annotation = struct('time', line{1}, 'class', line{7});
an_time = line{1};
an_class = line{7};
%{annotation.time}'
end