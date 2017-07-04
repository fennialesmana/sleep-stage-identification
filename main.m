clear; clc; close all;
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

%{
gBest_result = zeros(10, 6);
classNum = [2 3 4 6];
for cl=1:size(classNum, 2)
for exp=1:10
clearvars -except exp gBest_result cl classNum
clc;
close all;
filename = sprintf('slp01a_features_%dclass_%d_unorm', classNum(1, cl), exp);
diary(filename)
diary on
%}
whichRecording = 1;
% STEP 3: BUILD CLASSIFIER MODEL USING PSO AND ELM
%nClasses = classNum(cl); % jumlah kelas ouput
nClasses = 2;

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
MAX_ITERATIONS = 100;
nParticles = 20;
% update velocity parameter
W = 0.6;
c1 = 1.2;
c2 = 1.2;
% fitness parameter
Wa = 0.95;
Wf = 0.05;
[result, startTime, endTime] = PSOforELM(MAX_ITERATIONS, nParticles, nFeatures, trainingData, testingData, W, c1, c2, Wa, Wf);
%result = PSOforSVM(MAX_ITERATIONS, nParticles, nFeatures, trainingData, testingData, W, c1, c2, Wa, Wf);
% END OF PARTICLE SWARM OPTIMIZATION (PSO) PROCESS ------------------------

%{
diary off
gBest_result(exp, classNum(cl)) = gBest.fitness;
beep
end
end
xlswrite('featuresslp01a_unorm', gBest_result);
%}