function Data = loadmatobject(dir, index)
    Data = load(dir);
    fieldName = fieldnames(Data);
    Data = Data.(fieldName{index});
end