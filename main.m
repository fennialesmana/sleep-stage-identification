clear; clc; close all;

%{
% STEP 1: IMPORT AND SYNCHRONIZE ALL DATA
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
Data = [];
SingleFile = [];
nRecordingSamples = zeros(length(fileNames), 1);
for i=1:size(fileNames, 2)
    SingleFile = importslpdb(fileNames(i));
    Data = [Data;SingleFile];
    nRecordingSamples(i, 1) = length(SingleFile);
end

save('nRecordingSamples.mat', 'nRecordingSamples');
save('Data.mat', 'Data');
%}

%{
% STEP 2: FEATURE EXTRACTION
Data = load('Data.mat');
Data = Data.Data;
extractfeatures(Data, 'features/', 'all');
%}

%{
temp = zeros(10, 4);
classNum = [2 3 4 6];

for cl=1:size(classNum, 2)
for exp=1:10
clearvars -except exp temp cl classNum
clc;
close all;
filename = sprintf('slp02_features2_%dclass_%d', classNum(1, cl), exp);
diary(filename)
diary on
%}

% STEP 3: BUILD CLASSIFIER MODEL USING PSO AND ELM
% nClass = classNum(cl); % jumlah kelas ouput
nClasses = 2;
fprintf('Building classifier model for %d classes...\n', nClasses);
fprintf('Start at %s\n', datestr(clock));

% load features
hrv = load('features/hrv_features_norm.mat');
fieldName = fieldnames(hrv);
hrv = hrv.(fieldName{1});
nFeatures = size(hrv, 2);

% load targets
target = load('features/target.mat');
fieldName = fieldnames(target);
target = target.(fieldName{1});
target = target(:, nClasses);

% combine features and target
hrv = [hrv target];

% load nRecordingSamples
nRecordingSamples = load('nRecordingSamples');
fieldName = fieldnames(nRecordingSamples);
nRecordingSamples = nRecordingSamples.(fieldName{1});

% retrieve selected recording
whichRecording = 1;
hrv = hrv(getindexrange(nRecordingSamples, whichRecording), :);

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

% PARTICLE SWARM OPTIMIZATION (PSO) PROCESS -------------------------------
% PSO parameter initialization
MAX_ITERATIONS = 100;
nParticles = 20;

gBest.cummulative = zeros(MAX_ITERATIONS, 1);
nHiddenBits = size(decToBin(size(trainingData, 1)), 2); %bin2 = de2bi(nSamples);

population_fitness = zeros(nParticles, 1);
velocity = int64(zeros(nParticles, 1)); % in decimal value
pBest_particle = zeros(nParticles, nFeatures+nHiddenBits); % max fitness value
pBest_fitness = repmat(-1000000, nParticles, 1);
gBest.particle = zeros(1, nFeatures+nHiddenBits); % max fitness function all particle all iteration
gBest.fitness = -1000000;

% update velocity parameter
W = 0.6;
c1 = 1.2;
c2 = 1.2;

% Population Initialization: [FeatureMask HiddenNode]
population = rand(nParticles, nFeatures+nHiddenBits) > 0.8;
% check and re-random if the value is invalid
for i=1:nParticles
    nHiddenNodes = binToDec(population(i, nFeatures+1:end));
    while nHiddenNodes < nFeatures || ...
            nHiddenNodes > size(trainingData, 1) || ...
            sum(population(i, 1:nFeatures)) == 0
        population(i, :) = rand(1, nFeatures+nHiddenBits) > 0.8;
    end
end

% Calculate Fitness Value:
%featureMask = [1 1 1 1 0  1 1 0 0 1  1 1 1 0 0  0 0];
%featureMask = [1 1 1 1 1  1 1 1 1 1  1 1 1 1 1  1 1];
fprintf('Initialization\n');
fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
for i=1:nParticles
    tic;
    fprintf('%8d %15d ', i, binToDec(population(i, nFeatures+1:end)));
    % TRAINING
    maskedTrainingFeature = featuremasking(trainingData, population(i, 1:nFeatures));% prepare the feature data (masking)
    trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = trainELM(binToDec(population(i, nFeatures+1:end)), maskedTrainingFeature, trainingTarget);
    
    % TESTING
    maskedTestingFeature = featuremasking(testingData, population(i, 1:nFeatures));% prepare the feature data (masking)
    testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
    
    population_fitness(i, 1) = fitness(0.95, 0.05, elmModel.testingAccuracy, population(i, 1:nFeatures));
    
    % pBest Update
    if population_fitness(i, 1) > pBest_fitness(i, 1)
        pBest_fitness(i, 1) = population_fitness(i, 1);
        pBest_particle(i, :) = population(i, :);
    end
    endTime = toc;
    
    % print result
    fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
    fprintf('%s\n', binToStringOrder(population(i, 1:nFeatures)));
end

% gBest Update
if max(population_fitness) > gBest.fitness
    found = find(population_fitness == max(population_fitness));
    found = found(1);
    gBest.fitness = max(population_fitness);
    gBest.particle = population(found, :);
end

fprintf('gBest = %d\n', gBest.fitness);

for iteration=1:MAX_ITERATIONS
    fprintf('\nIteration %d of %d\n', iteration, MAX_ITERATIONS);
    % Update Velocity
    r1 = rand();
    r2 = rand();
    for i=1:nParticles
        % calculate velocity value
        particleDec = int64(binToDec(population(i, :)));
        velocity(i, 1) = W * velocity(i, 1) + c1 * r1 * (binToDec(pBest_particle(i, :)) - particleDec) + c2 * r2 * (binToDec(gBest.particle) - particleDec);
        
        % update particle position
        newPosDec = abs(int64(particleDec + velocity(i, 1)));
        popBin = decToBin(newPosDec);
        
        %if the total bits lower than nFeatures + nBits, add zeros in front
        if size(popBin, 2) < (nFeatures + nHiddenBits)
            popBin = [zeros(1, (nFeatures + nHiddenBits)-size(popBin, 2)) popBin];
        end
        
        %if the number of hidden node is more than the number of samples
        if binToDec(popBin(1, nFeatures+1:end)) > size(trainingData, 1) || size(popBin(1, nFeatures+1:end), 2) > nHiddenBits
            popBin = [popBin(1, 1:nFeatures) decToBin(size(trainingData, 1))];
        end
        
        %set the value
        population(i, :) = popBin;
    end
    
    % Calculate Fitness Value
    fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
    for i=1:nParticles
        tic;
        fprintf('%8d %15d ', i, binToDec(population(i, nFeatures+1:end)));
        % TRAINING
        maskedTrainingFeature = featuremasking(trainingData, population(i, 1:nFeatures));% prepare the feature data (masking)
        trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
        elmModel = trainELM(binToDec(population(i, nFeatures+1:end)), maskedTrainingFeature, trainingTarget);

        % TESTING
        maskedTestingFeature = featuremasking(testingData, population(i, 1:nFeatures));% prepare the feature data (masking)
        testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
        elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
        
        population_fitness(i, 1) = fitness(0.95, 0.05, elmModel.testingAccuracy, population(i, 1:nFeatures));

        % pBest Update
        if population_fitness(i, 1) > pBest_fitness(i, 1)
            pBest_fitness(i, 1) = population_fitness(i, 1);
            pBest_particle(i, :) = population(i, :);
        end
        endTime = toc;
        
        fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
        fprintf('%s\n', binToStringOrder(population(i, 1:nFeatures)));
    end

    % gBest Update
    if max(population_fitness) > gBest.fitness
        found = find(population_fitness == max(population_fitness));
        found = found(1);
        gBest.fitness = max(population_fitness);
        gBest.particle = population(found, :);
    end
    fprintf('gBest = %d\n', gBest.fitness);
    gBest.cummulative(iteration, 1) = gBest.fitness;
end

fprintf('Selected Feature = %s\n', binToStringOrder(gBest.particle(1, 1:nFeatures)));
fprintf('n Hidden Node = %d\n', binToDec(gBest.particle(1, nFeatures+1:end)));

%plot(gBest.cummulative);
fprintf('Finish at %s\n', datestr(clock));

%{
diary off
temp(exp, classNum(cl)) = gBest.fitness;
end
end
%}