function range = getindexrange(totalSamples, index)
    startNum = 1;
    if index == 1
        endNum = totalSamples(index);
    else
        startNum = sum(totalSamples(1:index-1)) + 1;
        endNum = startNum + totalSamples(index) - 1;
    end
    range = startNum:endNum;
end