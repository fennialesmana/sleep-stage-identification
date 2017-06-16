function data = import_data(file_name, sec_per_epoch)
file_name = strcat('slpdb/', cell2mat(file_name));
data = [];
%% IMPORT HEADER DATA
fprintf('%s header data import...\n', file_name);
fid = fopen(strcat(file_name, '.hea'), 'r');
header_file = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

hea_sampling_freq = strsplit(char(header_file{3}(1)), '/');
hea_sampling_freq = str2double(cell2mat(hea_sampling_freq(1)));
hea_total_samples = str2double(cell2mat(header_file{4}(1)));

hea_rec_length_in_sec = ceil(hea_total_samples/hea_sampling_freq);
hea_total_epoch = ceil(hea_rec_length_in_sec/sec_per_epoch);

idx = size(header_file{1}, 1);
if cell2mat(header_file{1}(end-1)) == '#' % for slp37.hea (the last line is not age, gender, and weight information)
    idx = idx - 1;
end
%age = str2double(cell2mat(header_file{2}(idx)));
%gender = cell2mat(header_file{3}(idx));
%weight = str2double(cell2mat(header_file{4}(idx)));
age = header_file{2}(idx);
gender = header_file{3}(idx);
weight = header_file{4}(idx);
% END OF IMPORT HEADER DATA

%% IMPORT ANNOTATION DATA
fprintf('%s annotation data import...\n', file_name);
fid = fopen(strcat(file_name, '.an'), 'r');
annotation_file = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

% hapus line pertama untuk menghilangkan header data
for i=1:size(annotation_file, 2)
   annotation_file{i}(1) = [];
end

% ubah start time epoch pertama menjadi 0:00.000
temp = cell2mat(annotation_file{1}(1));
temp(end-2:end) = 48;
annotation_file{1}(1) = cellstr(temp);
%annotation_file{1}(1) = {'0:00.000'};

% output of import annotation data
an_time = annotation_file{1}; % waktu dari annotation dalam bentuk cell array
an_class = annotation_file{7}; % annotation dalam bentuk cell array
% END OF IMPORT ANNOTATION DATA

%% IMPORT RR DATA
fprintf('%s rr data import...\n', file_name);
fid = fopen(strcat(file_name, '.rr'), 'r');
rr_file = textscan(fid, '%s%s%s%s%s%*[^\n]');
fclose(fid);

converted_time = rr_file{1};
for i = 1:size(converted_time, 1);
    start_time = strsplit(char(converted_time(i)), ':')';% split start time by ":" into matrix
    
    time = cell2mat(converted_time(i)); % convert cell into char
    time(end-2:end) = 48; % change xx:xx:xx.ooo -> ooo part into 000
    
    second = str2double(cell2mat(start_time(end))); % get second from the last element
    temp = floor(second/sec_per_epoch)*sec_per_epoch; % epoch grouping
    
    % set epoch grouping
    if temp == 0
        time(end-5) = 48;
    elseif temp == 30
        time(end-5) = 51;
    end
    time(end-4) = 48;
    
    converted_time(i) = mat2cell(time, 1);
end

% output of import rr data
rr_converted_time = converted_time; % waktu dari rr yang sudah dibulatkan ke waktu sesuai epoch
rr_time = rr_file{1}; % start time dari setiap rr
rr_int = single_numeric_cell_to_matrix(rr_file{3}); % nilai rr dalam bentuk array of double
% END OF IMPORT RR DATA

%% VALIDITY CHECK
fprintf('Conducting validity check of %s data...\n', file_name);
% A. Annotation File Check

% *) generate waktu annotation dalam bentuk matrix ukuran jml epoch X 3
an_time_generated = zeros(hea_total_epoch, 3);
for i=2:hea_total_epoch
   an_time_generated(i, 3) =  an_time_generated(i-1, 3) + sec_per_epoch;
   an_time_generated(i, 2) = an_time_generated(i-1, 2);
   an_time_generated(i, 1) = an_time_generated(i-1, 1);
   if an_time_generated(i, 3) >= 60
       an_time_generated(i, 3) = 0;
       an_time_generated(i, 2) = an_time_generated(i-1, 2) + 1;
       if an_time_generated(i, 2) >= 60
           an_time_generated(i, 2) = 0;
           an_time_generated(i, 1) = an_time_generated(i-1, 1) + 1;
       end
   end
end
% ubah yang tadinya matrix jadi cell supaya mudah di bandingkan dengan rr
an_time_generated_cell = time_matrix_to_cell(an_time_generated);

% *) cek apakah jumlah epoch dari semua data sama
if size(an_time, 1) == hea_total_epoch && size(unique(rr_converted_time), 1) == size(an_time_generated, 1) && hea_total_epoch == size(unique(rr_converted_time), 1)
    fprintf('[Success] hea_total_epoch (%d) == an_time size (%d) == rr_converted_time (%d) == time_generated (%d)\n', hea_total_epoch, size(an_time, 1), size(unique(rr_converted_time), 1), size(an_time_generated, 1));
else
    fprintf('[Warning] hea_total_epoch (%d) != an_time size (%d) != rr_converted_time (%d) != time_generated (%d)\n', hea_total_epoch, size(an_time, 1), size(unique(rr_converted_time), 1), size(an_time_generated, 1));
end

% *) cek jumlah epoch an_time dan hea_total_epoch (hanya sebagai informasi)
if size(an_time, 1) == hea_total_epoch
    time_from_file = time_cell_to_matrix(an_time);
    if sum(sum(an_time_generated == time_from_file)) ~= (hea_total_epoch * 3)
        fprintf('[Failed ] time_generated != an_time\n');
        return
    else
        fprintf('[Success] time_generated == an_time\n');
    end
else
    fprintf('[Warning] total an_time (%d) != total hea_total_epoch (%d), time_generated will be used\n', size(an_time, 1), hea_total_epoch);
end

% *) cek annotation harus '1', '2', '3', '4', 'W', atau 'R' (ada 'MT' dan 'M' juga, nanti diakhir baru dihilangin)
distinct_class = char(unique(an_class));
for i=1:size(distinct_class, 1)
    if distinct_class(i) ~= '1' && distinct_class(i) ~= '2' && distinct_class(i) ~= '3' && distinct_class(i) ~= '4' && distinct_class(i) ~= 'W' && distinct_class(i) ~= 'R' && distinct_class(i) ~= 'M'
        fprintf('[Failed ] Class member checking\n');
        return
    end
end
fprintf('[Success] Class member checking\n');

% B. RR File Check
% *) cek jumlah epoch rr_converted_time dan hea_total_epoch
if size(unique(rr_converted_time), 1) ~= hea_total_epoch
    fprintf('[Warning] total rr_converted_time (%d) != total hea_total_epoch (%d)\n', size(unique(rr_converted_time), 1), hea_total_epoch);
else
    fprintf('[Success] total rr_converted_time (%d) == total hea_total_epoch (%d)\n', size(unique(rr_converted_time), 1), hea_total_epoch);
end
% END OF VALIDITY CHECK

%% SYNCHRONIZE RR AND ANNOTATION DATA
epoch_counter = 1;
rr_counter = 1;
%rr_collection = cell(size(an_time, 1), 1);
%time_collection = cell(size(an_time, 1), 1);
rr_collection = cell(hea_total_epoch, 1);
time_collection = cell(hea_total_epoch, 1);

%converted_time_collection = cell(size(an_time, 1), 1);
for i=1:size(rr_converted_time, 1) % looping for each rr in that file
    if strcmp(rr_converted_time(i), an_time_generated_cell(epoch_counter))
        % jika rr ke i sama dengan an
        rr_collection{epoch_counter}(rr_counter) = rr_int(i);
        time_collection{epoch_counter}(rr_counter) = rr_time(i);
        %converted_time_collection{epoch_counter}(rr_counter) = rr_converted_time(i);
        rr_counter=rr_counter+1;
    elseif ~strcmp(rr_converted_time(i), an_time_generated_cell(epoch_counter)) && ~strcmp(rr_converted_time(i), an_time_generated_cell(epoch_counter+1))
        % jika rr ke i beda dengan an dan dengan an selanjutnya jg beda
        while ~strcmp(rr_converted_time(i), an_time_generated_cell(epoch_counter+1))
            epoch_counter = epoch_counter + 1;
        end
        rr_counter=1;
        epoch_counter=epoch_counter+1;
        rr_collection{epoch_counter}(rr_counter) = rr_int(i);
        time_collection{epoch_counter}(rr_counter) = rr_time(i);
        %converted_time_collection{epoch_counter}(rr_counter) = rr_converted_time(i);
        rr_counter=rr_counter+1;
    elseif ~strcmp(rr_converted_time(i), an_time_generated_cell(epoch_counter)) && strcmp(rr_converted_time(i), an_time_generated_cell(epoch_counter+1))
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
% generate matrix berisi annotation, mengisi time yang tidak ada annotationnya
an_class_generated_cell = cell(size(an_time_generated, 1), 1);
je = 1;
for i=1:size(an_time_generated, 1)
   if strcmp(an_time_generated_cell(i), an_time(je))
       % jika waktunya sama, maka pindahkan annotationnya
       an_class_generated_cell(i) = an_class(je);
       if je < size(an_class, 1)
           je = je + 1;
       end
   else
       % jika waktunya beda, maka isi dengan 'none'
       an_class_generated_cell(i) = {'none'};
   end
end

for i=hea_total_epoch:-1:1
    flag = 0;
    if sum(rr_collection{i}) < 28 || sum(rr_collection{i}) > 32
        % cek sum rr interval dari setiap epoch tidak boleh di bawah 28 (menurut slp04 min sum 29 max 30)
        flag = 1;
        fprintf('row %d epoch %s is removed because rr_collection < 28 || > 32\n', i, an_time_generated_cell{i});
    elseif strcmp(an_class_generated_cell(i), {'none'})
        % buang yg tdk ada annotation
        flag = 1;
        fprintf('row %d epoch %s is removed because no annotation\n', i, an_time_generated_cell{i});
    elseif strcmp(an_class_generated_cell(i), {'MT'}) || strcmp(an_class_generated_cell(i), {'M'})
        % buang yg annotationnya MT atau M
        flag = 1;
        fprintf('row %d epoch %s is removed because the annotation is %s\n', i, an_time_generated_cell{i}, an_class_generated_cell{i});
    end
    
    % kalau data bermasalah, maka data dikosongkan
    if flag == 1
        an_time_generated_cell{i} = [];
        rr_collection{i} = [];
        an_class_generated_cell{i} = [];
    end
end

% menghapus row yang nilainya empty
an_time_generated_cell = an_time_generated_cell(~cellfun(@isempty, an_time_generated_cell));
rr_collection = rr_collection(~cellfun(@isempty, rr_collection));
an_class_generated_cell = an_class_generated_cell(~cellfun(@isempty, an_class_generated_cell));
%END OF SYNCHRONIZED DATA VALIDITY CHECK

%% PREPARE THE OUTPUT
data = struct('filename', file_name, 'time', an_time_generated_cell, 'rr', rr_collection, 'annotation', an_class_generated_cell, 'age', age, 'gender', gender, 'weight', weight);
% END OF PREPARE THE OUTPUT
end