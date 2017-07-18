function extractresultsnew(resultRootFolder, nFeatures, classNum, nExperiments, nIterations)
    %resultRootFolder = 'PSOSVM_raw_result_RBF';
    %nFeatures = 18;
    %classNum = [2 3 4 6];
    %nExperiments = 25;
    %nIterations = 100;
    fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
                'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
                'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};    
    method = strsplit(resultRootFolder, '_');
    method = method{1};
    nClassClassifiers = length(classNum);
    header = [];
    switch method
        case 'PSOELM'
            header = {'Experiment', 'gBestFitness', 'TrainAcc', 'TestAcc', 'HiddenNodes', 'SelectedFeatures'};
        case 'PSOSVM'
            header = {'Experiment', 'gBestFitness', 'TrainAcc', 'TestAcc', 'SelectedFeatures'};
    end
    main_header = header;
    main_header{1} = 'RecordingName';

    % write header for main result
    for i=1:length(classNum)
        xlswrite(sprintf('%s/%s_result.xlsx', resultRootFolder, method), main_header, sprintf('%d classes', classNum(i)));
    end
    
    for iFile=1:length(fileNames) % loop for each file
        eachFileFolder = sprintf('%s/%s_%s_raw_result', resultRootFolder, method, fileNames{iFile});
        for iClass=1:nClassClassifiers
            matFileName = sprintf('%s/%s_%s_%dclasses_raw_result.mat', eachFileFolder, method, fileNames{iFile}, classNum(iClass));
            ExperimentResult = loadmatobject(matFileName, 1);
            
            temp = zeros(nExperiments, length(header)-1);
            nBits = length(ExperimentResult(4).iterationResult(end).gBest.position)-nFeatures;
            gBestParticles = false(nExperiments, nFeatures+nBits);
            tempCell = cell(nExperiments, 1);
            
            % get the last gBest result of each experiment
            for iExp=1:nExperiments
                lastResult = ExperimentResult(iExp).iterationResult(end);
                temp(iExp, 1) = iExp;
                temp(iExp, 2) = lastResult.gBest.fitness;
                temp(iExp, 3) = lastResult.gBest.trainingAccuracy;
                temp(iExp, 4) = lastResult.gBest.testingAccuracy;
                if strcmp(method, 'PSOELM')
                    temp(iExp, 5) = bintodec(lastResult.gBest.position(nFeatures+1:end));
                end
                tempCell(iExp, 1) = {bintostringorder(lastResult.gBest.position)};
                gBestParticles(iExp, :) = lastResult.gBest.position;
            end

            eachFileExcelPath = sprintf('%s/%s_%s_extracted_result.xlsx', eachFileFolder, method, fileNames{iFile});
            xlswrite(eachFileExcelPath, header, sprintf('%d classes', classNum(iClass)), 'A1');
            xlswrite(eachFileExcelPath, temp, sprintf('%d classes', classNum(iClass)), 'A2');
            xlswrite(eachFileExcelPath, tempCell, sprintf('%d classes', classNum(iClass)), sprintf('%s2', getexcelcolumncode(length(header))));
            
            % get the best experiment of each classification
            bestExpIdx = find(temp(:, 2) == max(temp(:, 2)));
            if length(bestExpIdx) > 1 % if have the same gBest fitness value, get the max of testAcc
                bestExpIdx = bestExpIdx(temp(bestExpIdx, 4) == max(temp(bestExpIdx, 4)));
                if length(bestExpIdx) > 1 % if have the same testAcc, get the max of trainAcc
                    bestExpIdx = bestExpIdx(temp(bestExpIdx, 3) == max(temp(bestExpIdx, 3)));
                    if length(bestExpIdx) > 1 % if have the same trainAcc, get the min of selected features
                        bestExpIdx = bestExpIdx(sum(gBestParticles(bestExpIdx, 1:nFeatures), 2) == min(sum(gBestParticles(bestExpIdx, 1:nFeatures), 2)));
                        if length(bestExpIdx) > 1 % if have the same selected feature, check the method used
                            switch method
                                case 'PSOELM'
                                    bestExpIdx = bestExpIdx(temp(bestExpIdx, 5) == min(temp(bestExpIdx, 5)));
                                    if length(bestExpIdx) > 1 % if have the same selected feature, get the first
                                        bestExpIdx = bestExpIdx(1);
                                    end
                                case 'PSOSVM'
                                    bestExpIdx = bestExpIdx(1);
                            end
                        end
                    end
                end
            end

            % mark the best index
            xlswrite(eachFileExcelPath, {'BEST EXPERIMENT'}, sprintf('%d classes', classNum(iClass)), sprintf('%s%d', getexcelcolumncode(length(header)+1), bestExpIdx+1));

            % gather gBest fitness of the best experiment
            gBest = zeros(nIterations, 1);
            for iItr=1:nIterations
                gBest(iItr) = ExperimentResult(bestExpIdx).iterationResult(iItr+1).gBest.fitness;
            end

            % save graphics
            f = figure;
            plot(1:nIterations, gBest);
            ylabel('gBest Fitness'); xlabel('Iteration');
            title(sprintf('[%s] Best Experiment of %s (%d classes)', method, fileNames{iFile}, classNum(iClass)));
            saveas(f, sprintf('%s/[%s] Best Experiment of %s (%d classes).png', eachFileFolder, method, fileNames{iFile}, classNum(iClass)));
            close all;
            
            % save result to main excel
            xlswrite(sprintf('%s/%s_result.xlsx', resultRootFolder, method), [fileNames(iFile) temp(bestExpIdx, 2) temp(bestExpIdx, 3) temp(bestExpIdx, 4) tempCell(bestExpIdx)], sprintf('%d classes', classNum(iClass)), sprintf('A%d', iFile+1));
        end
    end
end