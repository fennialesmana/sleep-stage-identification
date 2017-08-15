function Data = loadmatobject(fileName, index)
%Load .mat object by index
%   Syntax:
%   Data = loadmatobject(dir, index)
%
%   Input:
%   *) fileName - file name
%   *) index    - index of .mat's variable to be returned
%
%   Output:
%   *) Data  - index-th variable returned

    Data = load(fileName);
    fieldName = fieldnames(Data);
    Data = Data.(fieldName{index});
end