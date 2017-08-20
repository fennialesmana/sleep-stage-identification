%{
Run SVM experiment using full features
%}
clear; clc; close all;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
classNum = [2 3 4 6];

% load features and targets
hrv = loadmatobject('features/hrv_features_norm.mat', 1);
nFeatures = size(hrv, 2);
target = loadmatobject('features/target.mat', 1);

% load nRecSamples
nRecSamples = loadmatobject('nRecSamples', 1);

for iClass=1:length(classNum)
    nClasses = classNum(iClass); % nClasses = total output class
    xlswrite('SVM_result.xlsx', {'File Name', 'Training Acc', 'Testing Acc'}, ...
        sprintf('%d classes', nClasses));
    results = zeros(length(fileNames), 2);
    for iFile=1:length(fileNames)
        features = [hrv target(:, nClasses)];
        % prepare feature
        features = features(getindexrange(nRecSamples, iFile), :);

        % SPLIT DATA
        % 70% training data and 30% testing data using stratified sampling
        trainingRatio = 0.7;
        trainingData = [];
        testingData = [];
        for i=1:nClasses
            ithClassInd = find(features(:, end) == i);
            nithClass = ceil(size(ithClassInd, 1)*trainingRatio);
            trainingData = [trainingData; features(ithClassInd(1:nithClass), :)];
            testingData = ...
                [testingData; features(ithClassInd(nithClass+1:end), :)];
        end
        % END OF SPLIT DATA

        SVMModel = trainSVM(trainingData(:, 1:end-1), ...
            trainingData(:, end), 'RBF');
        trainAcc = testSVM(trainingData(:, 1:end-1), ...
            trainingData(:, end), SVMModel);
        testAcc = testSVM(testingData(:, 1:end-1), ...
            testingData(:, end), SVMModel);
        results(iFile, 1) = trainAcc;
        results(iFile, 2) = testAcc;
        
    end
    xlswrite('SVM_result.xlsx', fileNames', ...
        sprintf('%d classes', nClasses), 'A2');
    xlswrite('SVM_result.xlsx', results, ...
        sprintf('%d classes', nClasses), 'B2');
end
