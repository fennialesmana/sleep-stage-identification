function extractresults(path)
    header = {'Experiment', 'gBestFitness', 'TrainAcc', 'TestAcc', 'HiddenNodes', 'SelectedFeatures'};
    AllClassesResult = loadmatobject(path, 1);
    fileName = strsplit(path, '/');
    fileName = cell2mat(fileName(end));
    recName = strsplit(fileName, '.');
    recName = cell2mat(recName(1));
    mkdir(recName);
    nClasses = length(AllClassesResult);
    nExperiments = length(AllClassesResult(1).experimentResult);
    
    for iClass=1:nClasses
        totalClass = AllClassesResult(iClass).totalClass;
        %fprintf('%5s %5s %15s %15s %15s %15s %15s\n', 'Class', 'Exp', 'gBestFitness', 'TrainAcc', 'TestAcc', 'HiddenNodes', 'SelectedFeatures');
        temp = zeros(nExperiments, length(header)-1);
        tempCell = cell(nExperiments, 1);
        for iExp=1:nExperiments
            result = AllClassesResult(iClass).experimentResult(iExp);
            whichIteration = result.iteration(end).gBest.whichIteration;
            whichParticle = result.iteration(end).gBest.whichParticle;
            
            gBestFitness = result.iteration(end).gBest.fitness;
            trainAcc = result.iteration(whichIteration+1).trainingAccuracy(whichParticle);
            testAcc = result.iteration(whichIteration+1).testingAccuracy(whichParticle);
            nHiddenNodes = result.iteration(whichIteration+1).nHiddenNodes(whichParticle);
            selectedFeatures = result.iteration(whichIteration+1).selectedFeatures(whichParticle);
            
            temp(iExp, 1) = iExp;
            temp(iExp, 2) = gBestFitness;
            temp(iExp, 3) = trainAcc;
            temp(iExp, 4) = testAcc;
            temp(iExp, 5) = nHiddenNodes;
            tempCell(iExp, 1) = selectedFeatures;
            %fprintf('%5d %5d %15d %15d %15d %15d %15s\n', totalClass, iExp, gBestFitness, trainAcc, testAcc, nHiddenNodes, cell2mat(selectedFeatures));
        end
        
        xlswrite(sprintf('%s/%s.xlsx', recName, recName), header, sprintf('%d classes', totalClass), 'A1');
        xlswrite(sprintf('%s/%s.xlsx', recName, recName), temp, sprintf('%d classes', totalClass), 'A2');
        xlswrite(sprintf('%s/%s.xlsx', recName, recName), tempCell, sprintf('%d classes', totalClass), 'F2');
        
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
        xlswrite(sprintf('%s/%s.xlsx', recName, recName), {'BEST EXPERIMENT'}, sprintf('%d classes', totalClass), sprintf('G%d', bestIdx+1));

        nIterations = length(AllClassesResult(iClass).experimentResult(bestIdx).iteration)-1;
        gBest = zeros();
        for iItr=1:nIterations
            gBest(iItr) = AllClassesResult(iClass).experimentResult(bestIdx).iteration(iItr).gBest.fitness;
        end
        
        % save graphics
        fName = strsplit(recName, '_');
        f = figure;
        plot(1:nIterations, gBest);
        ylabel('gBest Fitness'); xlabel('Iteration');
        title(sprintf('[%s] Best Experiment of %s (%d classes)', cell2mat(fName(1)), cell2mat(fName(2)), totalClass));
        saveas(f, sprintf('%s/[%s] gBest of %s (%d classes).png', recName, cell2mat(fName(1)), cell2mat(fName(2)), totalClass));
        close all;
        %fprintf('\n');
    end
end