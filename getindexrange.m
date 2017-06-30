function range = getindexrange(totalSamples, index)
    if sum(index > length(totalSamples)) >= 1
        disp('Index limit exceeded');
        return
    end
    range = [];
    for i=1:length(index)
        if index(i) == 1
            startNum = 1;
            endNum = totalSamples(index(i));
        else
            startNum = sum(totalSamples(1:index(i)-1)) + 1;
            endNum = startNum + totalSamples(index(i)) - 1;
        end
        range = [range startNum:endNum];
        % fprintf('%d %d\n', startNum, endNum);
    end
end