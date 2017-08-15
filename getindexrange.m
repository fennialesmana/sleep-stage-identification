function range = getindexrange(nSamplesEachData, index)
%Get range of inputted vector by index. For example [2 3 4 5] is the
%inputted nSamplesEachData and index is 2. Then, the output is [3 4 5].
%Explanation:
%The sum of [2 3 4 5] is 14 (there are 14 items).
%If index = 1, so the output is [1 2] -> total elements are 2
%If index = 2, so the output is [3 4 5] -> total elements are 3
%If index = 3, so the output is [6 7 8 9] -> total elements are 4
%If index = 4, so the output is [10 11 12 13 14] -> total elements are 5
%   Syntax:
%   range = getindexrange(nSamplesEachData, index)
%
%   Input:
%   *) nSamplesEachData - total number of data in each index
%   *) index            - index to be retrieved
%
%   Output:
%   *) range - a vector contains ordered number of associated index

    if sum(index > length(nSamplesEachData)) >= 1
        disp('Index limit exceeded');
        return
    end
    range = [];
    for i=1:length(index)
        if index(i) == 1
            startNum = 1;
            endNum = nSamplesEachData(index(i));
        else
            startNum = sum(nSamplesEachData(1:index(i)-1)) + 1;
            endNum = startNum + nSamplesEachData(index(i)) - 1;
        end
        range = [range startNum:endNum];
    end
end