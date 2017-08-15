clear; clc; close all;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};

%{
%% STEP 1: IMPORT AND SYNCHRONIZE ALL DATA
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

% Output of this step:
% 1. nRecSamples.mat -> 18 x 1 matrix contains number of samples each file
% 2. SlpdbData.mat   -> 10154 x 1 struct contains synchronized data

% END OF STEP 1
%}

%{
%% STEP 2: FEATURE EXTRACTION
SlpdbData = loadmatobject('SlpdbData.mat', 1);
extractfeatures(SlpdbData, 'features/', 'all');

% Output of this step:
% 1. hrv_features_unorm.xlsx
% 2. hrv_features_norm.xlsx
% 3. target.xlsx
% 4. hrv_features_unorm.mat
% 5. hrv_features_norm.mat
% 6. target.mat
% END OF STEP 2
%}
method = 'PSOSVM';
classNum = [2 3 4 6];
MAX_EXPERIMENT = 25;
MAX_ITERATION = 100;

%{
%% STEP 3: BUILD CLASSIFIER MODEL (OBJECT SPECIFIC RECORDING)
for iFile=1:length(fileNames)
    path = sprintf('%s_raw_result/%s_%s_raw_result', method, method, fileNames{iFile});
    mkdir(path);
    for iClass=1:length(classNum)
        ExperimentResult = struct([]);
        for iExp=1:MAX_EXPERIMENT
            fprintf('Building iFile = %d/%d, iClass = %d/%d, iExp = %d/%d\n', iFile, length(fileNames), iClass, length(classNum), iExp, MAX_EXPERIMENT);
            clearvars -except fileNames method MAX_EXPERIMENT classNum iFile iClass ExperimentResult iExp path MAX_EXPERIMENT MAX_ITERATION
            nClasses = classNum(iClass); % nClasses = total output class

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

            % PARTICLE SWARM OPTIMIZATION (PSO) PROCESS
            PSOSettings.MAX_ITERATION = MAX_ITERATION;
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
            % END OF PARTICLE SWARM OPTIMIZATION (PSO) PROCESS

            ExperimentResult(iExp).iterationResult = result;
            ExperimentResult(iExp).startTime = startTime;
            ExperimentResult(iExp).endTime = endTime;
        end
        
        save(sprintf('%s/%s_%s_%dclasses_raw_result.mat', path, method, fileNames{iFile}, nClasses), 'ExperimentResult', '-v7.3');
    end
end
% END OF STEP 3
%}

%{
%% STEP 4: RESULT EXTRACTION
extractresults('PSOELM_raw_result', 18, classNum, MAX_EXPERIMENT, MAX_ITERATION);
% END OF STEP 4
%}