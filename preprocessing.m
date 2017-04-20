clear;clc;

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

total_row = size(line{1});
total_row = total_row(1);
raw = zeros(total_row, 11);
sum_temp = 0;
sec_per_epoch = 30;

for i = 1:total_row
    % data for column 1 - 6
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
    
    % data for column 7
    raw(i, 7) = str2num(cell2mat(line{3}(i)));
    
    % data for column 8:: determine epoch for each data
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

total_epoch = (raw(total_row, 9) * 60 * 60 / sec_per_epoch) + (raw(total_row, 10) * 60 / sec_per_epoch) + (raw(total_row, 11) / sec_per_epoch) + 1;
% create cell array: a = cell(1, 5), a{1} = [1 2 3 4 5]