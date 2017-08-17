%{
Run ELM experiment using full feature
%}
clear; clc; close all;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
classNum = [2 3 4 6];
MAX_EXPERIMENT = 25;
MAX_ITERATION = 100;
rootFolder = 'ELM_result';
mkdir(rootFolder);
% load features and targets
hrv = loadmatobject('features/hrv_features_norm.mat', 1);
nFeatures = size(hrv, 2);
target = loadmatobject('features/target.mat', 1);
% load nRecSamples and retrieve selected recording
nRecSamples = loadmatobject('nRecSamples.mat', 1);

for iFile=1:length(fileNames)
    eachFileFolder = sprintf('%s/ELM_%s_result/', rootFolder, fileNames{iFile});
    mkdir(eachFileFolder);
    for iClass=1:length(classNum)
        nClasses = classNum(iClass); % nClasses = total output class
        %targetTemp = target(:, nClasses); % prepare target
        features = [hrv target(:, nClasses)];
        features = features(getindexrange(nRecSamples, iFile), :); % prepare feature
        
        % SPLIT DATA
        % 70% training data and 30% testing data using stratified sampling
        trainingRatio = 0.7;
        trainingData = [];
        testingData = [];
        for i=1:nClasses
            ithClassInd = find(features(:, end) == i);
            nithClass = ceil(size(ithClassInd, 1)*trainingRatio);
            trainingData = [trainingData; features(ithClassInd(1:nithClass), :)];
            testingData = [testingData; features(ithClassInd(nithClass+1:end), :)];
        end
        % END OF SPLIT DATA
        
        minTotalHiddenNodes = nFeatures;
        maxTotalHiddenNodes = size(trainingData, 1);
        allExperiments = zeros(MAX_EXPERIMENT, 4);
        
        for iExp=1:MAX_EXPERIMENT
            tic;
            fprintf('Building iFile = %d/%d, iClass = %d/%d, iExp = %d/%d\n', iFile, length(fileNames), iClass, length(classNum), iExp, MAX_EXPERIMENT);
            oneExperiment = zeros(MAX_ITERATION, 3);
            for iIter=1:MAX_ITERATION
                nHiddenNode = ceil((maxTotalHiddenNodes-minTotalHiddenNodes).*rand()+minTotalHiddenNodes);

                % TRAINING
                trainingTarget = full(ind2vec(trainingData(:,end)'))'; % prepare the target data (example: transformation from 4 into [0 0 0 1 0 0])
                [Model, trainAcc] = trainELM(trainingData(:,1:end-1), trainingTarget, nHiddenNode);

                % TESTING
                testingTarget = full(ind2vec(testingData(:,end)'))'; % prepare the target data (example: transformation from 4 into [0 0 0 1 0 0])
                testAcc = testELM(testingData(:,1:end-1), testingTarget, Model);
                
                oneExperiment(iIter, 1) = trainAcc;
                oneExperiment(iIter, 2) = testAcc;
                oneExperiment(iIter, 3) = nHiddenNode;
            end
            bestOfOneExperiment = oneExperiment(oneExperiment(:, 2) == max(oneExperiment(:, 2)), :);
            if length(bestOfOneExperiment) > 1
                bestOfOneExperiment = bestOfOneExperiment(bestOfOneExperiment(:, 1) == max(bestOfOneExperiment(:, 1)), :);
                if length(bestOfOneExperiment) > 1
                    bestOfOneExperiment = bestOfOneExperiment(bestOfOneExperiment(:, 3) == min(bestOfOneExperiment(:, 3)), :);
                end
            end
            bestOfOneExperiment = bestOfOneExperiment(1, :);
            xlswrite(sprintf('%s/ELM_%s_experiment_%d.xlsx', eachFileFolder, fileNames{iFile}, iExp), {'TrainAcc', 'TestAcc', 'HiddenNode'}, sprintf('%d classes', nClasses));
            xlswrite(sprintf('%s/ELM_%s_experiment_%d.xlsx', eachFileFolder, fileNames{iFile}, iExp), oneExperiment, sprintf('%d classes', nClasses), 'A2')
            timeNeeded = toc;
            allExperiments(iExp, :) = [bestOfOneExperiment timeNeeded];
        end
        
        xlswrite(sprintf('%s/ELM_%s_experiment_result.xlsx', eachFileFolder, fileNames{iFile}), {'TrainAcc', 'TestAcc', 'HiddenNode', 'Time (sec)'}, sprintf('%d classes', nClasses));
        xlswrite(sprintf('%s/ELM_%s_experiment_result.xlsx', eachFileFolder, fileNames{iFile}), allExperiments, sprintf('%d classes', nClasses), 'A2')
        bestOfAllExperiments = allExperiments(allExperiments(:, 2) == max(allExperiments(:, 2)), :);
        if length(bestOfAllExperiments) > 1
            bestOfAllExperiments = bestOfAllExperiments(bestOfAllExperiments(:, 1) == max(bestOfAllExperiments(:, 1)), :);
            if length(bestOfAllExperiments) > 1
                bestOfAllExperiments = bestOfAllExperiments(bestOfAllExperiments(:, 3) == min(bestOfAllExperiments(:, 3)), :);
            end
        end
        bestOfAllExperiments = bestOfAllExperiments(1, :);
        xlswrite(sprintf('%s/ELM_result.xlsx', rootFolder), {'File Name', 'TrainAcc', 'TestAcc', 'HiddenNode', 'Time (sec)'}, sprintf('%d classes', nClasses));
        xlswrite(sprintf('%s/ELM_result.xlsx', rootFolder), fileNames(iFile), sprintf('%d classes', nClasses), sprintf('A%d', iFile+1))
        xlswrite(sprintf('%s/ELM_result.xlsx', rootFolder), bestOfAllExperiments, sprintf('%d classes', nClasses), sprintf('B%d', iFile+1))
    end
end