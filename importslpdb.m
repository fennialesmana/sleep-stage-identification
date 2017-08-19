function OutputData = importslpdb(fileName)
%Import and synchronize a slpdb recording
%   Syntax:
%   OutputData = importslpdb(fileName)
%
%   Input:
%   *) fileName   - slpdb file name to be imported. Example: 'slp01a'.
%                   file must be located in 'slpdb' folder,
%                   three file formats needed: .hea, .rr, and .an
%
%   Output:
%   *) OutputData - struct contains synchronized RR and annotation

fileName = strcat('slpdb/', cell2mat(fileName));
SEC_PER_EPOCH = 30; % amount of seconds in one epoch (value for slpdb is 30)
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

age = headerFile{2}(heaIdx);
gender = headerFile{3}(heaIdx);
weight = headerFile{4}(heaIdx);

% output of "IMPORT HEADER DATA" section:
% *) heaTotalEpoch - total epoch according to header data
% *) age           - age of the subject
% *) gender        - gender of the subject
% *) weight        - weight of the subject
% END OF IMPORT HEADER DATA

%% IMPORT ANNOTATION DATA
fprintf('Importing annotation file...\n');
fid = fopen(strcat(fileName, '.an'), 'r');
anFile = textscan(fid, '%s%s%s%s%s%s%s%*[^\n]');
fclose(fid);

% remove header of annotation data (first line)
% remove this string: 'Elapsed time  Sample #  Type  Sub Chan  Num	Aux'
for i=1:size(anFile, 2)
   anFile{i}(1) = [];
end

% change first epoch's 'start time' into 0:00.000
anTemp = cell2mat(anFile{1}(1));
anTemp(end-2:end) = 48;
anFile{1}(1) = cellstr(anTemp);

anTime = anFile{1};
anClass = anFile{7};

% output of "IMPORT ANNOTATION DATA" section:
% *) anTime  - time from annotation file (cell array)
% *) anClass - annotation (cell array)
% END OF IMPORT ANNOTATION DATA

%% IMPORT RR DATA
fprintf('Importing RR file...\n');
fid = fopen(strcat(fileName, '.rr'), 'r');
rrFile = textscan(fid, '%s%s%s%s%s%*[^\n]');
fclose(fid);

rrConvertedTime = rrFile{1};
for i=1:size(rrConvertedTime, 1);
    rrStartTimeChar = cell2mat(rrConvertedTime(i)); % convert cell into char
    rrStartTimeChar(end-2:end) = 48; % xx:xx:xx.aaa -> change 'aaa' part to '000'
    
    % split start time by ":" into matrix
    rrStartTimeMat = strsplit(char(rrConvertedTime(i)), ':')';
    % get seconds from the last element
    rrSecond = str2double(cell2mat(rrStartTimeMat(end)));
    % epoch grouping
    rrWhichGroup = floor(rrSecond/SEC_PER_EPOCH)*SEC_PER_EPOCH;
    
    % set epoch grouping
    if rrWhichGroup == 0
        rrStartTimeChar(end-5) = 48;
    elseif rrWhichGroup == 30
        rrStartTimeChar(end-5) = 51;
    end
    rrStartTimeChar(end-4) = 48;
    
    rrConvertedTime(i) = mat2cell(rrStartTimeChar, 1);
end

% change RR value from 'array of cell' into 'array of double'
rrNum = zeros(size(rrFile{3}, 1), 1);
for i=1:size(rrFile{3}, 1)
    rrNum(i) = str2double(cell2mat(rrFile{3}(i)));
end

rrTime = rrFile{1};

% output of "IMPORT RR DATA" section:
% *) rrConvertedTime - rounded RR start time according to the epoch
%                      example: 1:34:31.328 -> 1:34:30.000
%                               1:50:13.616 -> 1:50:00.000
% *) rrNum           - RR value (array of double)
% *) rrTime          - start time of un-rounded RR
% END OF IMPORT RR DATA

%% VALIDITY CHECK
fprintf('Data Validity Check:\n');
% A. Annotation File Check

% *) generate annotation time acocrding to total epoch from header file
% *) result: anTimeGeneratedMat -> Matrix size: number of epoch X 3 (h,m,s)
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
    if anTimeGeneratedMat(i, 1) == 0 % when the 'hour' is 0
        anTimeGeneratedCell(i) = ...
            cellstr(strcat(sprintf('%d',anTimeGeneratedMat(i, 2)), ...
            sprintf(':%02d.000',anTimeGeneratedMat(i, 3))));
    else
        temp = strcat(sprintf('%d', anTimeGeneratedMat(i, 1)), ...
            sprintf(':%02d',anTimeGeneratedMat(i, 2)));
        anTimeGeneratedCell(i) = ...
            cellstr(strcat(temp, sprintf(':%02d.000',anTimeGeneratedMat(i, 3))));
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

% *) ANNOTATION FILE CHECK 3 (Check annotation value must be '1', '2', '3',
% '4', 'W', 'R', or {'MT', 'M' -> these two will be removed later}): 
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

% *) RR FILE CHECK 1 (Check equality of size(unique(rrConvertedTime), 1)
% and heaTotalEpoch):
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
rrCollection = cell(heaTotalEpoch, 1); % each row contains RRs of associated epoch
rrTimeCollection = cell(heaTotalEpoch, 1); % each row contains RR time of associated epoch

for i=1:size(rrConvertedTime, 1) % looping for each rrConvertedTime in that file
    if strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter))
        % when i-th RR time is equal to annotation time of current epoch
        rrCollection{epochCounter}(rrCounter) = rrNum(i);
        rrTimeCollection{epochCounter}(rrCounter) = rrTime(i);
        rrCounter=rrCounter+1;
    elseif ~strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter)) ...
            && ~strcmp(rrConvertedTime(i), anTimeGeneratedCell(epochCounter+1))
        % when i-th RR time is not equal to annotation time of current epoch
        % and i-th RR time is not equal to annotation time of the next epoch
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
        % when i-th RR time is not equal to annotation time of current epoch
        % and i-th RR time is equal to annotation time of the next epoch
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
        % set flag to remove incomplete RR data of that epoch by:
        % check the sum of RR interval from each epoch,
        % can't be below 28 or higher than 32
        % (according to slp04 data, min sum is 29 and max is 30)
        flag = 1;
        fprintf('  Epoch %d (time: %s) of %s data is removed because incomplete RR data\n', i, anTimeGeneratedCell{i}, fileName);
    elseif strcmp(anClassGeneratedCell(i), {'none'})
        % set flag to remove no annotation epoch
        flag = 1;
        fprintf('  Epoch %d (time: %s) of %s data is removed because no annotation\n', i, anTimeGeneratedCell{i}, fileName);
    elseif strcmp(anClassGeneratedCell(i), {'MT'}) || ...
            strcmp(anClassGeneratedCell(i), {'M'})
        % set flag to remove 'MT' or 'M' annotation epoch
        flag = 1;
        fprintf('  Epoch %d (time: %s) of %s data is removed because the annotation is %s\n', i, anTimeGeneratedCell{i}, fileName, anClassGeneratedCell{i});
    end
    
    % when the flag is 1, remove the data
    if flag == 1
        anTimeGeneratedCell{i} = [];
        rrCollection{i} = [];
        anClassGeneratedCell{i} = [];
        isExists = 1;
    end
end

% print message if no invalid epoch
if ~isExists
   fprintf('No invalid epoch\n'); 
end

% delete empty row
anTimeGeneratedCell = ...
    anTimeGeneratedCell(~cellfun(@isempty, anTimeGeneratedCell));
rrCollection = rrCollection(~cellfun(@isempty, rrCollection));
anClassGeneratedCell = ...
    anClassGeneratedCell(~cellfun(@isempty, anClassGeneratedCell));
%END OF SYNCHRONIZED DATA VALIDITY CHECK

%% PREPARE THE OUTPUT
OutputData = struct('filename', fileName, 'time', anTimeGeneratedCell, ...
    'rr', rrCollection, 'annotation', anClassGeneratedCell, 'age', age, ...
    'gender', gender, 'weight', weight);
% END OF PREPARE THE OUTPUT
end