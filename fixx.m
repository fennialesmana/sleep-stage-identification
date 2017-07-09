clear;clc;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
classNum = [2 3 4 6];
for iFile=1:length(fileNames)
    fName = sprintf('log/PSOELM_extracted_result/PSOELM_%s_result/PSOELM_%s_result.xlsx', fileNames{iFile}, fileNames{iFile});
    for iClass=1:length(classNum)
        cName = sprintf('%d classes', classNum(iClass));
        temp = xlsread(fName, cName, 'A2:E26');
        
        bestIdx = -1;
        maxGBestIdx = find(temp(:, 2) == max(temp(:, 2)));
        if length(maxGBestIdx) > 1
            maxTestIdx = find(temp(maxGBestIdx, 4) == max(temp(maxGBestIdx, 4)));
            maxGBestIdx = maxGBestIdx(maxTestIdx);
            if length(maxGBestIdx) > 1
                maxTrainIdx = find(temp(maxGBestIdx, 3) == max(temp(maxGBestIdx, 3)));
                maxGBestIdx = maxGBestIdx(maxTrainIdx);
                if length(maxGBestIdx) > 1
                    minHiddenIdx = find(temp(maxGBestIdx, 5) == min(temp(maxGBestIdx, 5)));
                    maxGBestIdx = maxGBestIdx(minHiddenIdx);
                    if length(maxGBestIdx) > 1
                        minLength = length(tempCell{maxGBestIdx(1)});
                        bestIdx = maxGBestIdx(1);
                        for i=2:length(maxGBestIdx)
                            if length(tempCell{maxGBestIdx(i)}) < minLength
                                minLength = length(tempCell{maxGBestIdx(i)});
                                bestIdx = maxGBestIdx(i);
                            end
                        end
                        
                    else
                        bestIdx = maxGBestIdx;
                    end
                else
                    bestIdx = maxGBestIdx;
                end
            else
                bestIdx = maxGBestIdx;
            end
        else
            bestIdx = maxGBestIdx;
        end
        
        %to-do: plot the best index
        xlswrite(fName, {'BEST EXPERIMENT'}, cName, sprintf('G%d', bestIdx+1));
        %disp('hai');
    end
end