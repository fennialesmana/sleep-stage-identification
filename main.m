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
%{
%% STEP 3: BUILD CLASSIFIER MODEL
MAX_EXPERIMENT = 25;
classNum = [2 3 4 6];
mkdir(method);
%for iFile=1:length(fileNames)
iFile = 13; 
    AllClassesResult = ([]);
    for iClass=1:length(classNum)
        ExperimentResult = struct([]);
        for iExp=1:MAX_EXPERIMENT
            fprintf('Building iFile = %d/%d, iClass = %d/%d, iExp = %d/%d\n', iFile, length(fileNames), iClass, length(classNum), iExp, MAX_EXPERIMENT);
            clearvars -except fileNames MAX_EXPERIMENT classNum AllClassesResult ExperimentResult iFile iClass iExp
            %clc; close all;
            whichRecording = iFile;
            nClasses = classNum(iClass); % jumlah kelas ouput
            %nClasses = 2;

            % load features and targets
            hrv = loadmatobject('features/hrv_features_norm.mat', 1);
            nFeatures = size(hrv, 2);
            target = loadmatobject('features/target.mat', 1);
            target = target(:, nClasses);
            hrv = [hrv target]; % combine features and target

            % load nRecSamples and retrieve selected recording
            nRecSamples = loadmatobject('nRecSamples', 1);
            hrv = hrv(getindexrange(nRecSamples, whichRecording), :);

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
            % PSO parameter initialization
            MAX_ITERATIONS = 100; nParticles = 20;
            % update velocity parameter
            W = 0.6; c1 = 1.2; c2 = 1.2;
            % fitness parameter
            Wa = 0.95; Wf = 0.05;
            [result, startTime, endTime] = PSOforELM(MAX_ITERATIONS, nParticles, nFeatures, trainingData, testingData, W, c1, c2, Wa, Wf);
            %result = PSOforSVM(MAX_ITERATIONS, nParticles, nFeatures, trainingData, testingData, W, c1, c2, Wa, Wf);
            % END OF PARTICLE SWARM OPTIMIZATION (PSO) PROCESS ------------------------

            ExperimentResult(iExp).iteration = result;
            ExperimentResult(iExp).startTime = startTime;
            ExperimentResult(iExp).endTime = endTime;
            %beep
        end
        AllClassesResult(iClass).totalClass = classNum(iClass);
        AllClassesResult(iClass).experimentResult = ExperimentResult;
    end
    save(sprintf('%s_%s_result.mat', method, fileNames{iFile}), 'AllClassesResult', '-v7.3');
%end
% END OF STEP 3
%}

%% STEP 4: RESULT EXTRACTION
nFiles = length(fileNames);
for iFile=16:16
    %iFile = 14;
    extractresults(sprintf('%s_result/%s_%s_result.mat', method, method, cell2mat(fileNames(iFile))));
end
% END OF STEP 4