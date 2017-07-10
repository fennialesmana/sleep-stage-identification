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
        
        bestIdx = find(temp(:, 2) == max(temp(:, 2)));
        if length(bestIdx) > 1
            bestIdx = bestIdx(temp(bestIdx, 4) == max(temp(bestIdx, 4)));
            if length(bestIdx) > 1
                bestIdx = bestIdx(temp(bestIdx, 3) == max(temp(bestIdx, 3)));
                if length(bestIdx) > 1
                    bestIdx = bestIdx(temp(bestIdx, 5) == min(temp(bestIdx, 5)));
                    if length(bestIdx) > 1
                        minLength = sum(tempCell{bestIdx(1)} == ' ');
                        minIdx = bestIdx(1);
                        for i=2:length(bestIdx)
                            if sum(tempCell{bestIdx(i)} == ' ') < minLength
                                minLength = sum(tempCell{bestIdx(i)} == ' ');
                                minIdx = bestIdx(i);
                            end
                        end
                        bestIdx = minIdx;
                    end
                end
            end
        end
        
        %to-do: plot the best index
        xlswrite(fName, {'BEST EXPERIMENT'}, cName, sprintf('G%d', bestIdx+1));
        %disp('hai');
    end
end