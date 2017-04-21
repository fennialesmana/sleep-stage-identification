clear;clc;
tic;
%read data from file
fid = fopen('slp04.txt', 'r');
line = textscan(fid, '%s%s%s%s%s%*[^\n]');
fclose(fid);

%{
slpxxx.txt without header
Data Description:
line{1} -> t0 (start_time) :: USED
line{2} -> b0              :: NOT USED
line{3} -> RR (sec)        :: USED
line{4} -> b1              :: NOT USED
line{5} -> t1 (end_time)   :: USED
%}

total_row = size(line{1}, 1);
sec_per_epoch = 30;
% how to create cell array: a = cell(1, 5), a{1} = [1 2 3 4 5]

%{
% FIRST WAY to get the data ------------------------------------
%{
    in variable name 'raw', will be transformed into:
    idx. column_name
    01. start_hour
    02. start_minute
    03. start_second
    04. end_hour
    05. end_minute
    06. end_second
    07. rr_interval
%}
raw = zeros(total_row, 11);
%sum_temp = 0;
for i = 1:total_row
    % 'data for column 1 - 6'
    start_time = strsplit(char(line{1}(i)), ':')';
    start_time_size = size(start_time);
    count_st = start_time_size(1);
    
    end_time = strsplit(char(line{5}(i)), ':')';
    end_time_size = size(end_time);
    count_et = end_time_size(1);
    
    for j=6:-1:1
        if j <= 3
            if j == 1 && start_time_size(1) == 2
                raw(i, j) = 0;
            else
                raw(i, j) = str2num(cell2mat(start_time(count_st)));
            end
            count_st = count_st - 1;
        else
            if j == 4 && end_time_size(1) == 2
                raw(i, j) = 0;
            else
                raw(i, j) = str2num(cell2mat(end_time(count_et)));
            end
            count_et = count_et - 1;
        end
    end
    
    % data for column 7:: RR
    raw(i, 7) = str2num(cell2mat(line{3}(i)));
    
    % data for column 8:: determine epoch for each data - i-th epoch
    if i == 1
        raw(i, 8) = 1;
    else
        if raw(i, 8) == 0
            %{
                start time before new epoch: 28.xx, 29.xx, 58.xx, 59.xx
                start time of the new epoch: 00.xx, 01.xx, 30.xx, 31.xx            
                
                kemungkinan kondisi kalo ganti epoch:
                - mod(start_time, sec_per_epoch) nya diawali 0,
                    tapi mod start_time atasnya ga boleh 0 juga
                - mod(start_time, sec_per_epoch) nya diawali 1,
                    tapi mod start_time atasnya ga boleh 0 dan
                    mode start_time atasnya ga boleh 1 juga
            %}
            if floor(mod(raw(i, 3), sec_per_epoch)) == 0 && floor(mod(raw(i-1, 3), sec_per_epoch)) ~= 0
                % kondisi kalau dia 0.xx dan atasnya bukan 0.xx
                % kalo mau aman lagi tambahin atasnya lagi bukan 0.xx
                raw(i, 8) = raw(i-1, 8) + 1;
            elseif floor(mod(raw(i, 3), sec_per_epoch)) == 1 && floor(mod(raw(i-1, 3), sec_per_epoch)) ~= 0 && floor(mod(raw(i-1, 3), sec_per_epoch)) ~= 1
                % kondisi kalau dia bukan 1.xx dan atasnya bukan 0.xx dan
                % atasnya bukan 1.xx juga
                raw(i, 8) = raw(i-1, 8) + 1;
            else
                raw(i, 8) = raw(i-1, 8);
            end
        end
    end
    
    % data for column 9 - 11
    raw(i, 9) = raw(i, 1);
    raw(i, 10) = raw(i, 2);
    raw(i, 11) = floor(raw(i, 3)/sec_per_epoch)*sec_per_epoch;
end
%total_epoch = (raw(total_row, 9) * 60 * 60 / sec_per_epoch) + (raw(total_row, 10) * 60 / sec_per_epoch) + (raw(total_row, 11) / sec_per_epoch) + 1;
%}

% SECOND WAY to get the data ------------------------------------
%{
    in variable name 'raw', will be transformed into:
    idx. column_name
    01. start_hour
    02. start_minute
    03. start_second
    07. rr_interval
%}
raw = zeros(total_row, 4);
for i = 1:total_row
    start_time = strsplit(char(line{1}(i)), ':')';
    start_time_size = size(start_time, 1);
    
    % column 1 - 3
    if start_time_size == 2
        raw(i, 1) = 0;
        raw(i, 2) = str2num(cell2mat(start_time(1)));
        raw(i, 3) = str2num(cell2mat(start_time(2)));
    elseif start_time_size == 3
        raw(i, 1) = str2num(cell2mat(start_time(1)));
        raw(i, 2) = str2num(cell2mat(start_time(2)));
        raw(i, 3) = str2num(cell2mat(start_time(3)));
    end
    % str = cell2mat(mysStr)
%     idx = 1;
%     if start_time_size == 2
%         raw(i, 1) = 0;
%     else
%         raw(i, 1) = str2num(cell2mat(start_time(1)));
%         idx=idx+1;
%     end
%     raw(i, 2) = str2num(cell2mat(start_time(idx)));
%     raw(i, 3) = str2num(cell2mat(start_time(idx+1)));
    
    raw(i, 3) = floor(raw(i, 3)/sec_per_epoch)*sec_per_epoch; % change the data
    %column 4
    %here?
end
%column 4:: or here?
raw(:, 4) = str2num(cell2mat(line{3}));

total_epoch = size(unique(raw(:, 1:3), 'rows'), 1);
id = unique(raw(:, 1:3), 'rows');

% for i=1:total_epoch
%     if raw(i, 1:3) == id(i, :)
%         
%     end
% end

toc;