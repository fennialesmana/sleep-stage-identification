function data = import_data(file_name, sec_per_epoch)
file_name = strcat('data/', cell2mat(file_name));
fprintf('Importing %s data...\n', file_name);

%% IMPORT HEADER DATA
fid = fopen(strcat(file_name, '.hea'), 'r');
header_file = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

sampling_frequency = strsplit(char(header_file{3}(1)), '/');
sampling_frequency = str2num(cell2mat(sampling_frequency(1)));
total_samples = str2num(cell2mat(header_file{4}(1)));

rec_length_in_sec = ceil(total_samples/sampling_frequency);
number_of_epoch = ceil(rec_length_in_sec/30);

idx = size(header_file{1}, 1);
if cell2mat(header_file{1}(end-1)) == '#'
    idx = idx - 1;
end
%age = str2num(cell2mat(header_file{2}(idx)));
%gender = cell2mat(header_file{3}(idx));
%weight = str2num(cell2mat(header_file{4}(idx)));
age = header_file{2}(idx);
gender = header_file{3}(idx);
weight = header_file{4}(idx);
% END OF IMPORT HEADER DATA

%% IMPORT ANNOTATION DATA
fid = fopen(strcat(file_name, '.an'), 'r');
annotation_file = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

% hapus line pertama untuk menghilangkan header
for i=1:size(annotation_file, 2)
   annotation_file{i}(1) = [];
end

% ubah start time epoch pertama menjadi 0:00.000
annotation_file{1}(1) = {'0:00.000'};

% isi data ke annotation
% annotation = struct('time', annotation_file{1}, 'class', annotation_file{7});
an_time = annotation_file{1};
an_class = annotation_file{7};
% END OF IMPORT ANNOTATION DATA

%% IMPORT RR DATA
fid = fopen(strcat(file_name, '.rr'), 'r');
rr_file = textscan(fid, '%s%s%s%s%s%*[^\n]');
fclose(fid);
converted_time = rr_file{1};
for i = 1:size(converted_time, 1);
    start_time = strsplit(char(converted_time(i)), ':')';
    
    time = cell2mat(converted_time(i));
    time(end-2:end) = 48;
    
    second = str2num(cell2mat(start_time(end)));
    temp = floor(second/sec_per_epoch)*sec_per_epoch;
    
    if temp == 0
        time(end-5) = 48;
    elseif temp == 30
        time(end-5) = 51;
    end
    time(end-4) = 48;
    
    converted_time(i) = mat2cell(time, 1);
end
% rr = struct('time', line{1}, 'rr', line{3});
rr_converted_time = converted_time;
rr_time = rr_file{1};
rr_int = single_numeric_cell_to_matrix(rr_file{3});
% END OF IMPORT RR DATA

%% VALIDITY CHECK
fprintf('Conducting validity check of %s data...\n', file_name);
% A. Annotation File Check
% *) cek jumlah epoch
if size(an_time, 1) ~= number_of_epoch
    fprintf('[Failed ] Number of epoch check from duration and number of line\n');
    return
else
    fprintf('[Success] Number of epoch check from duration and number of line\n');
end

% *) cek time
time_counter = zeros(number_of_epoch, 3);
for i=2:number_of_epoch
   time_counter(i, 3) =  time_counter(i-1, 3) + sec_per_epoch;
   time_counter(i, 2) = time_counter(i-1, 2);
   time_counter(i, 1) = time_counter(i-1, 1);
   if time_counter(i, 3) >= 60
       time_counter(i, 3) = 0;
       time_counter(i, 2) = time_counter(i-1, 2) + 1;
       if time_counter(i, 2) >= 60
           time_counter(i, 2) = 0;
           time_counter(i, 1) = time_counter(i-1, 1) + 1;
       end
   end
end

time_from_file = time_cell_to_matrix(an_time);
if sum(sum(time_counter == time_from_file)) ~= (number_of_epoch * 3)
    fprintf('[Failed ] Time generated checking with time from file\n');
    return
else
    fprintf('[Success] Time generated checking with time from file\n');
end

% *) cek class harus '1', '2', '3', '4', 'W', atau 'R'
distinct_class = char(unique(an_class));
for i=1:size(distinct_class, 1)
    if distinct_class(i) ~= '1' && distinct_class(i) ~= '2' && distinct_class(i) ~= '3' && distinct_class(i) ~= '4' && distinct_class(i) ~= 'W' && distinct_class(i) ~= 'R'
        fprintf('[Failed ] Class member checking\n');
        return
    end
end
fprintf('[Success] Class member checking\n');

% B. RR File Check
% *) cek jumlah epoch berdasarkan data RR interval
if size(unique(rr_converted_time), 1) ~= number_of_epoch
    fprintf('[Warning] Different number of epoch check from Annotation (%d) and RR data (%d)\n', number_of_epoch, size(unique(rr_converted_time), 1));
else
    fprintf('[Success] The same number of epoch check from Annotation and RR data\n');
end
% END OF VALIDITY CHECK

%% SYNCHRONIZE RR AND ANNOTATION DATA
epoch_counter = 1;
rr_counter = 1;
rr_collection = cell(size(an_time, 1), 1);
time_collection = cell(size(an_time, 1), 1);
%converted_time_collection = cell(size(an_time, 1), 1);
for i=1:size(rr_converted_time, 1)
    if strcmp(rr_converted_time(i), an_time(epoch_counter))
        rr_collection{epoch_counter}(rr_counter) = rr_int(i);
        time_collection{epoch_counter}(rr_counter) = rr_time(i);
        %converted_time_collection{epoch_counter}(rr_counter) = rr_converted_time(i);
        rr_counter=rr_counter+1;
    elseif ~strcmp(rr_converted_time(i), an_time(epoch_counter)) && ~strcmp(rr_converted_time(i), an_time(epoch_counter+1))
        while ~strcmp(rr_converted_time(i), an_time(epoch_counter+1))
            epoch_counter = epoch_counter + 1;
        end
        rr_counter=1;
        epoch_counter=epoch_counter+1;
        rr_collection{epoch_counter}(rr_counter) = rr_int(i);
        time_collection{epoch_counter}(rr_counter) = rr_time(i);
        %converted_time_collection{epoch_counter}(rr_counter) = rr_converted_time(i);
        rr_counter=rr_counter+1;
    elseif ~strcmp(rr_converted_time(i), an_time(epoch_counter)) && strcmp(rr_converted_time(i), an_time(epoch_counter+1))
        rr_counter=1;
        epoch_counter=epoch_counter+1;
        rr_collection{epoch_counter}(rr_counter) = rr_int(i);
        time_collection{epoch_counter}(rr_counter) = rr_time(i);
        %converted_time_collection{epoch_counter}(rr_counter) = rr_converted_time(i);
        rr_counter=rr_counter+1;
    end
end
% END OF SYNCHRONIZE RR AND ANNOTATION DATA

%% SYNCHRONIZED DATA VALIDITY CHECK
% cek sum rr interval dari setiap epoch tidak boleh di bawah 28 (menurut slp04 min sum 29 max 30)
for i=number_of_epoch:-1:1
    if sum(rr_collection{i}) < 28 || sum(rr_collection{i}) > 32
        an_time{i} = [];
        rr_collection{i} = [];
        an_class{i} = [];
    end
end
an_time = an_time(~cellfun(@isempty, an_time));
rr_collection = rr_collection(~cellfun(@isempty, rr_collection));
an_class = an_class(~cellfun(@isempty, an_class));
%END OF SYNCHRONIZED DATA VALIDITY CHECK

%% PREPARE THE OUTPUT
data = struct('time', an_time, 'rr', rr_collection, 'annotation', an_class, 'age', age, 'gender', gender, 'weight', weight);
% END OF PREPARE THE OUTPUT
end