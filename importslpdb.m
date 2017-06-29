function OutputData = importslpdb(fileName)
% fileName: recording name
% secPerEpoch: amount of seconds in one epoch (value for slpdb is 30)
% usage example: data = import_data('slp01a', 30)
fileName = strcat('slpdb/', cell2mat(fileName));
SEC_PER_EPOCH = 30;
OutputData = [];
fprintf('\n%s DATA IMPORT...\n', fileName);
%% IMPORT HEADER DATA
fprintf('Importing header file...\n');
fid = fopen(strcat(fileName, '.hea'), 'r');
headerFile = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

heaSamplingFreq = strsplit(char(headerFile{3}(1)), '/');
heaSamplingFreq = str2double(cell2mat(heaSamplingFreq(1)));
heaTotalSamples = str2double(cell2mat(headerFile{4}(1)));

heaRecLengthInSec = ceil(heaTotalSamples/heaSamplingFreq);
heaTotalEpoch = ceil(heaRecLengthInSec/SEC_PER_EPOCH);

heaIdx = size(headerFile{1}, 1); % get last line index of file

if cell2mat(headerFile{1}(end-1)) == '#'
    % decease index by 1 for 'slp37.hea',
    % because the last line is not age, gender, and weight information    
    heaIdx = heaIdx - 1;
end

age = headerFile{2}(heaIdx); %age = str2double(cell2mat(header_file{2}(idx)));
gender = headerFile{3}(heaIdx); %gender = cell2mat(header_file{3}(idx));
weight = headerFile{4}(heaIdx); %weight = str2double(cell2mat(header_file{4}(idx)));

% output of "IMPORT HEADER DATA" section: heaTotalEpoch, age, gender, weight
% END OF IMPORT HEADER DATA

%% IMPORT ANNOTATION DATA
fprintf('Importing annotation file...\n');
fid = fopen(strcat(fileName, '.an'), 'r');
anFile = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

% remove header of annotation data (first line)
for i=1:size(anFile, 2)
   anFile{i}(1) = [];
end

% change first epoch's 'start time' into 0:00.000
anTemp = cell2mat(anFile{1}(1));
anTemp(end-2:end) = 48;
anFile{1}(1) = cellstr(anTemp);

anTime = anFile{1}; % waktu dari annotation dalam bentuk cell array
anClass = anFile{7}; % annotation dalam bentuk cell array

% output of "IMPORT ANNOTATION DATA" section: anTime, anClass
% END OF IMPORT ANNOTATION DATA

%% IMPORT RR DATA
fprintf('Importing RR file...\n');
fid = fopen(strcat(fileName, '.rr'), 'r');
rrFile = textscan(fid, '%s%s%s%s%s%*[^\n]');
fclose(fid);

rrConvertedTime = rrFile{1};
for i=1:size(rrConvertedTime, 1);
    rrStartTimeChar = cell2mat(rrConvertedTime(i)); % convert cell into char
    rrStartTimeChar(end-2:end) = 48; % change xx:xx:xx.aaa -> aaa part into 000
    
    rrStartTimeMat = strsplit(char(rrConvertedTime(i)), ':')'; % split start time by ":" into matrix
    rrSecond = str2double(cell2mat(rrStartTimeMat(end))); % get second from the last element
    rrWhichGroup = floor(rrSecond/SEC_PER_EPOCH)*SEC_PER_EPOCH; % epoch grouping
    
    % set epoch grouping
    if rrWhichGroup == 0
        rrStartTimeChar(end-5) = 48;
    elseif rrWhichGroup == 30
        rrStartTimeChar(end-5) = 51;
    end
    rrStartTimeChar(end-4) = 48;
    
    rrConvertedTime(i) = mat2cell(rrStartTimeChar, 1);
end

% ubah nilai rr dari array of cell menjadi array of double
rrNum = zeros(size(rrFile{3}, 1), 1);
for i=1:size(rrFile{3}, 1)
    rrNum(i) = str2double(cell2mat(rrFile{3}(i)));
end

rrTime = rrFile{1};

% output of "IMPORT RR DATA" section:
% rrConvertedTime = start time rr yang dibulatkan ke waktu sesuai epoch
% rrInt = nilai RR dalam bentuk array of double
% rrTIme = start time rr yang tidak dibulatkan
% END OF IMPORT RR DATA

%% VALIDITY CHECK
fprintf('Data Validity Check:\n');
% A. Annotation File Check

% *) generate waktu annotation dalam bentuk matrix ukuran jml epoch X 3
anTimeGeneratedMat = zeros(heaTotalEpoch, 3);
for i=2:heaTotalEpoch
   anTimeGeneratedMat(i, 3) =  anTimeGeneratedMat(i-1, 3) + SEC_PER_EPOCH;
   anTimeGeneratedMat(i, 2) = anTimeGeneratedMat(i-1, 2);
   anTimeGeneratedMat(i, 1) = anTimeGeneratedMat(i-1, 1);
   if anTimeGeneratedMat(i, 3) >= 60
       anTimeGeneratedMat(i, 3) = 0;
       anTimeGeneratedMat(i, 2) = anTimeGeneratedMat(i-1, 2) + 1;
       if anTimeGeneratedMat(i, 2) >= 60
           anTimeGeneratedMat(i, 2) = 0;
           anTimeGeneratedMat(i, 1) = anTimeGeneratedMat(i-1, 1) + 1;
       end
   end
end
% convert anTimeGeneratedMat into anTimeGeneratedCell for easier comparison
anTimeGeneratedCell = cell(size(anTimeGeneratedMat, 1), 1);
for i = 1:size(anTimeGeneratedMat, 1)
    if(anTimeGeneratedMat(i, 1) == 0) %kalo jamnya 0
        anTimeGeneratedCell(i) = cellstr(strcat(sprintf('%d',anTimeGeneratedMat(i, 2)), sprintf(':%02d.000',anTimeGeneratedMat(i, 3))));
    else
        temp = strcat(sprintf('%d', anTimeGeneratedMat(i, 1)), sprintf(':%02d',anTimeGeneratedMat(i, 2)));
        anTimeGeneratedCell(i) = cellstr(strcat(temp, sprintf(':%02d.000',anTimeGeneratedMat(i, 3))));
    end
end

% *) ANNOTATION FILE CHECK 1 (Total epoch of each data): 
fprintf('  CHECK 1: ');
if heaTotalEpoch == size(anTime, 1) && ...
    size(unique(rrConvertedTime), 1) == size(anTimeGeneratedMat, 1) && ...
    heaTotalEpoch == size(unique(rrConvertedTime), 1)
    fprintf('[SUCCESS] heaTotalEpoch (%d) == size(anTime, 1) (%d) == size(unique(rrConvertedTime), 1) (%d) == size(anTimeGeneratedMat, 1) (%d)\n', heaTotalEpoch, size(anTime, 1), size(unique(rrConvertedTime), 1), size(anTimeGeneratedMat, 1));
else
    fprintf('[WARNING] heaTotalEpoch (%d) != size(anTime, 1) (%d) != size(unique(rrConvertedTime), 1) (%d) != size(anTimeGeneratedMat, 1) (%d)\n', heaTotalEpoch, size(anTime, 1), size(unique(rrConvertedTime), 1), size(anTimeGeneratedMat, 1));
end

% *) ANNOTATION FILE CHECK 2 (Check equality of anTimeGeneratedCell and anTime): 
fprintf('  CHECK 2: ');
if size(anTime, 1) == heaTotalEpoch
    for i=1:heaTotalEpoch
        if ~strcmp(anTimeGeneratedCell{i}, anTime{i})
            fprintf('[FAILED ] anTimeGeneratedCell is NOT EQUAL to anTime\n');
            return
        end
    end
    fprintf('[SUCCESS] anTimeGeneratedCell is EQUAL to anTime\n');
else
    fprintf('[WARNING] size(anTime, 1) (%d) != heaTotalEpoch (%d), anTimeGeneratedCell will be used\n', size(anTime, 1), heaTotalEpoch);
end

% *) ANNOTATION FILE CHECK 3 (Check annotation value must be '1', '2', '3', '4', 'W', 'R', or {'MT', 'M' -> these two will be removed later}): 
fprintf('  CHECK 3: ');
distinctClass = char(unique(anClass));
for i=1:size(distinctClass, 1)
    if distinctClass(i) ~= '1' && distinctClass(i) ~= '2' ...
        && distinctClass(i) ~= '3' && distinctClass(i) ~= '4' ...
        && distinctClass(i) ~= 'W' && distinctClass(i) ~= 'R' ...
        && distinctClass(i) ~= 'M'
    
        fprintf('[WARNING ] Annotation values is NOT OK\n');
        return
    end
end
fprintf('[SUCCESS] Annotation values is OK\n');

% B. RR File Check

% *) RR FILE CHECK 1 (Check equality of size(unique(rrConvertedTime), 1) and heaTotalEpoch):
fprintf('  CHECK 4: ');
if size(unique(rrConvertedTime), 1) ~= heaTotalEpoch
    fprintf('[WARNING] size(unique(rrConvertedTime), 1) (%d) != heaTotalEpoch (%d)\n', size(unique(rrConvertedTime), 1), heaTotalEpoch);
else
    fprintf('[SUCCESS] size(unique(rrConvertedTime), 1) (%d) == heaTotalEpoch (%d)\n', size(unique(rrConvertedTime), 1), heaTotalEpoch);
end
% END OF VALIDITY CHECK

%% SYNCHRONIZE RR AND ANNOTATION DATA
epochCounter = 1;
rrCounter = 1;
rrCollection = cell(heaTotalEpoch, 1); % each row contains rr of associated epoch
rrTimeCollection = cell(heaTotalEpoch, 1); % each row contains rr time of associated epoch

for i=1:size(rrConvertedTime, 1) % looping for each rrConvertedTime in that file
    if strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter))
        % jika rr ke-i sama dengan an ke-epoch tsb
        rrCollection{epochCounter}(rrCounter) = rrNum(i);
        rrTimeCollection{epochCounter}(rrCounter) = rrTime(i);
        rrCounter=rrCounter+1;
    elseif ~strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter)) ...
            && ~strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter+1))
        % jika rr ke i beda dengan an dan dengan an selanjutnya jg beda
        while ~strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter+1))
            epochCounter = epochCounter + 1;
        end
        rrCounter=1;
        epochCounter=epochCounter+1;
        rrCollection{epochCounter}(rrCounter) = rrNum(i);
        rrTimeCollection{epochCounter}(rrCounter) = rrTime(i);
        rrCounter=rrCounter+1;
    elseif ~strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter)) ...
            && strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter+1))
        rrCounter=1;
        epochCounter=epochCounter+1;
        rrCollection{epochCounter}(rrCounter) = rrNum(i);
        rrTimeCollection{epochCounter}(rrCounter) = rrTime(i);
        rrCounter=rrCounter+1;
    end
end
% END OF SYNCHRONIZE RR AND ANNOTATION DATA

%% SYNCHRONIZED DATA VALIDITY CHECK
% generate matrix berisi annotation, mengisi time yang tidak ada annotationnya
anClassGeneratedCell = cell(heaTotalEpoch, 1);
je = 1;
for i=1:heaTotalEpoch
   if strcmp(anTimeGeneratedCell(i), anTime(je))
       % jika waktunya sama, maka pindahkan annotationnya
       anClassGeneratedCell(i) = anClass(je);
       if je < size(anClass, 1)
           je = je + 1;
       end
   else
       % jika waktunya beda, maka isi dengan 'none'
       anClassGeneratedCell(i) = {'none'};
   end
end

fprintf('Removing invalid epoch:\n');
isExists = 0;
for i=heaTotalEpoch:-1:1
    flag = 0;
    if sum(rrCollection{i}) < 28 || sum(rrCollection{i}) > 32
        % cek sum rr interval dari setiap epoch tidak boleh di bawah 28 (menurut slp04 min sum 29 max 30)
        flag = 1;
        fprintf('  Epoch %d (time: %s) of %s data is removed because sum of rrCollection is < 28 || > 32\n', i, anTimeGeneratedCell{i}, fileName);
    elseif strcmp(anClassGeneratedCell(i), {'none'})
        % buang yg tdk ada annotation
        flag = 1;
        fprintf('  Epoch %d (time: %s) of %s data is removed because no annotation\n', i, anTimeGeneratedCell{i}, fileName);
    elseif strcmp(anClassGeneratedCell(i), {'MT'}) || strcmp(anClassGeneratedCell(i), {'M'})
        % buang yg annotationnya MT atau M
        flag = 1;
        fprintf('  Epoch %d (time: %s) of %s data is removed because the annotation is %s\n', i, anTimeGeneratedCell{i}, fileName, anClassGeneratedCell{i});
    end
    
    % kalau data bermasalah, maka data dikosongkan
    if flag == 1
        anTimeGeneratedCell{i} = [];
        rrCollection{i} = [];
        anClassGeneratedCell{i} = [];
        isExists = 1;
    end
end

if ~isExists
   fprintf('No invalid epoch\n'); 
end

% menghapus row yang nilainya empty
anTimeGeneratedCell = anTimeGeneratedCell(~cellfun(@isempty, anTimeGeneratedCell));
rrCollection = rrCollection(~cellfun(@isempty, rrCollection));
anClassGeneratedCell = anClassGeneratedCell(~cellfun(@isempty, anClassGeneratedCell));
%END OF SYNCHRONIZED DATA VALIDITY CHECK

%% PREPARE THE OUTPUT
OutputData = struct('filename', fileName, 'time', anTimeGeneratedCell, 'rr', rrCollection, 'annotation', anClassGeneratedCell, 'age', age, 'gender', gender, 'weight', weight);
% END OF PREPARE THE OUTPUT
end