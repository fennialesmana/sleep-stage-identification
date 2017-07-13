clear; clc; close all;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
%{
%% STEP 1: IMPORT AND SYNCHRONIZE ALL DATA
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
SlpdbData = [];
SingleFile = [];
nRecSamples = zeros(length(fileNames), 1);
for i=1:size(fileNames, 2)
    SingleFile = importslpdb(fileNames(i));
    SlpdbData = [SlpdbData;SingleFile];
    nRecSamples(i, 1) = length(SingleFile);
end
save('nRecSamples.mat', 'nRecSamples');
save('SlpdbData.mat', 'SlpdbData');
% END OF STEP 1
%}
%{
%% STEP 2: FEATURE EXTRACTION
SlpdbData = loadmatobject('SlpdbData.mat', 1);
extractfeatures(SlpdbData, 'features/', 'all');
% END OF STEP 2
%}
method = 'PSOELM';

%% STEP 3a: BUILD CLASSIFIER MODEL (OBJECT SPECIFIC RECORDING)
MAX_EXPERIMENT = 25;
classNum = [2 3 4 6];
for iFile=1:length(fileNames)
    for iClass=1:length(classNum)
        ExperimentResult = struct([]);
        for iExp=1:MAX_EXPERIMENT
            fprintf('Building iFile = %d/%d, iClass = %d/%d, iExp = %d/%d\n', iFile, length(fileNames), iClass, length(classNum), iExp, MAX_EXPERIMENT);
            clearvars -except fileNames method MAX_EXPERIMENT classNum iFile iClass ExperimentResult iExp
            nClasses = classNum(iClass); % jumlah kelas ouput

            % load features and targets
            hrv = loadmatobject('features/hrv_features_norm.mat', 1);
            nFeatures = size(hrv, 2);
            target = loadmatobject('features/target.mat', 1);
            target = target(:, nClasses);
            hrv = [hrv target]; % combine features and target

            % load nRecSamples and retrieve selected recording
            nRecSamples = loadmatobject('nRecSamples', 1);
            hrv = hrv(getindexrange(nRecSamples, iFile), :);

            % SPLIT DATA
            % 70% training data and 30% testing data using stratified sampling
            trainingRatio = 0.7;
            trainingData = [];
            testingData = [];
            for i=1:nClasses
                ithClassInd = find(hrv(:, end) == i);
                nithClass = ceil(size(ithClassInd, 1)*trainingRatio);
                trainingData = [trainingData; hrv(ithClassInd(1:nithClass), :)];
                testingData = [testingData; hrv(ithClassInd(nithClass+1:end), :)];
            end
            % END OF SPLIT DATA

            % PARTICLE SWARM OPTIMIZATION (PSO) PROCESS -------------------------------
            PSOSettings.MAX_ITERATION = 100;
            PSOSettings.nParticles = 20;
            PSOSettings.W = 0.6;
            PSOSettings.c1 = 1.2;
            PSOSettings.c2 = 1.2;
            PSOSettings.Wa = 0.95;
            PSOSettings.Wf = 0.05;
            switch method
                case 'PSOELM'
                    [result, startTime, endTime] = PSOforELM(nFeatures, trainingData, testingData, PSOSettings);
                case 'PSOSVM'
                    [result, startTime, endTime] = PSOforSVM(nFeatures, trainingData, testingData, PSOSettings);
            end
            % END OF PARTICLE SWARM OPTIMIZATION (PSO) PROCESS ------------------------

            ExperimentResult(iExp).iterationResult = result;
            ExperimentResult(iExp).startTime = startTime;
            ExperimentResult(iExp).endTime = endTime;
        end
        path = sprintf('%s_raw_result/%s_%s_raw_result', method, method, fileNames{iFile});
        mkdir(path);
        save(sprintf('%s/%s_%s_%dclasses_raw_result.mat', path, method, fileNames{iFile}, nClasses), 'ExperimentResult', '-v7.3');
    end
end
% END OF STEP 3

%{
%% STEP 4: RESULT EXTRACTION
nFiles = length(fileNames);
for iFile=13:15
    %iFile = 14;
    extractresults(sprintf('%s_result/%s_%s_result.mat', method, method, cell2mat(fileNames(iFile))));
end
% END OF STEP 4
%}