clear; clc; close all;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
classNum = [2 3 4 6];
MAX_EXPERIMENT = 25;
MAX_ITERATION = 100;

mkdir('ELMFullFeatureResults');
% load features and targets
hrv = loadmatobject('features/hrv_features_norm.mat', 1);
nFeatures = size(hrv, 2);
target = loadmatobject('features/target.mat', 1);
% load nRecSamples and retrieve selected recording
nRecSamples = loadmatobject('nRecSamples.mat', 1);

for iFile=1:length(fileNames)
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
        allExperiments = zeros(MAX_EXPERIMENT, 3);
        
        for iExp=1:MAX_EXPERIMENT
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
            bestOfExperiment = oneExperiment(oneExperiment(:, 2) == max(oneExperiment(:, 2)), :);
            if length(bestOfExperiment) > 1
                bestOfExperiment = bestOfExperiment(bestOfExperiment(:, 1) == max(bestOfExperiment(:, 1)), :);
                if length(bestOfExperiment) > 1
                    bestOfExperiment = bestOfExperiment(bestOfExperiment(:, 3) == min(bestOfExperiment(:, 3)), :);
                end
            end
            disp('hai');
        end
        
        save(sprintf('%s/%s_%s_%dclasses_raw_result.mat', path, method, fileNames{iFile}, nClasses), 'ExperimentResult', '-v7.3');
    end
end