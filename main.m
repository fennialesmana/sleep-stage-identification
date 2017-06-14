clear; clc; close all;

%{
% IMPORT AND SYNCHRONIZE ALL DATA
file_names = {'slp01a', 'slp01b', 'slp02a', 'slp02b', 'slp03', 'slp04', 'slp14', 'slp16', 'slp32', 'slp37', 'slp41', 'slp45', 'slp48', 'slp59', 'slp60', 'slp61', 'slp66', 'slp67x'};
sec_per_epoch = 30;
all_data = [];
data = [];

for i=1:size(file_names, 2)
    fprintf('\n\n%s importing...\n', cell2mat(file_names(i)));
    data = import_data(file_names(i), sec_per_epoch);
    all_data = [all_data;data];
end

save('all_data', 'all_data');
%}

% feature extraction here
% load('all_data.mat');
% extractFeatures(all_data);

tic;
%hrv = load('features.mat');
hrv = load('features2class.mat');
hrv = hrv.features2class;

% SPLIT DATA
% 70% training data and 30% testing data using stratified sampling
nClasses = 2;
trainingData = [];
testingData = [];
for i=1:nClasses
    ithClassInd = find(hrv(:, end) == i);
    nithClass = ceil(size(ithClassInd, 1)*0.7);
    trainingData = [trainingData; hrv(ithClassInd(1:nithClass), :)];
    testingData = [testingData; hrv(ithClassInd(nithClass+1:end), :)];
end

% Particle Swarm Optimization (PSO) process
nParticles = 5; % ganti-ganti
nFeatures = 17;
maxTrainingDataBin = size(trainingData, 1);
nBits = size(decToBin(maxTrainingDataBin), 2); %bin2 = de2bi(nSamples);

% Population Initialization: [FeatureMask HiddenNode]
population = rand(nParticles, nFeatures+nBits) > 0.8; % check whether the value is more than sample data
for i=1:nParticles
    
    while binToDec(population(i, nFeatures+1:end)) < nFeatures || binToDec(population(i, nFeatures+1:end)) > size(trainingData, 1)
        population(i, :) = rand(1, nFeatures+nBits) > 0.8;
    end
    %fprintf('%d=%d\n', i, binToDec(population(i, nFeatures+1:end)));
end

fitnessValue = zeros(nParticles, 1);
velocity = zeros(nParticles, 1);
pBest_particle = zeros(nParticles, nFeatures+nBits); % max fitness function
pBest_fitness = repmat(-1000000, nParticles, 1);
gBest_particle = zeros(1, nFeatures+nBits); % max fitness function all particle all iteration
gBest_fitness = -1000000;
%featureMask = [1 1 1 1 0  1 1 0 0 1  1 1 1 0 0  0 0];
%featureMask = [1 1 1 1 1  1 1 1 1 1  1 1 1 1 1  1 1];
for i=1:nParticles
    fprintf('ELM training particle %d... number of hidden node: %d\n', i, binToDec(population(i, nFeatures+1:end)));
    % TRAINING
    maskedTrainingFeature = featureMasking(trainingData, population(i, 1:nFeatures));% prepare the feature data (masking)
    trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = trainELM(binToDec(population(i, nFeatures+1:end)), maskedTrainingFeature, trainingTarget);
    
    % TESTING
    maskedTestingFeature = featureMasking(testingData, population(i, 1:nFeatures));% prepare the feature data (masking)
    testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
    fitnessValue(i, 1) = fitness(0.95, 0.05, elmModel.testingAccuracy, population(i, 1:nFeatures));
    
    disp('hai')
end

% pBest Update
for i=1:nParticles
    if fitnessValue(i, 1) > pBest_fitness(i, 1)
        pBest_fitness(i, 1) = fitnessValue(i, 1);
        pBest_particle(i, :) = population(i, :);
    end
end

% gBest Update
if max(fitnessValue) > gBest_fitness
    found = find(fitnessValue == max(fitnessValue));
    found = found(1);
    gBest_fitness = max(fitnessValue);
    gBest_particle = population(found, :);    
end

% Update velocity
W = 0.6;
c1 = 1.2;
c2 = 1.2;
r1 = rand();
r2 = rand();
for i=1:nParticles
    particleDec = binToDec(population(i, :));
    velocity(i, 1) = W * velocity(i, 1) + c1 * r1 * (binToDec(pBest_particle(i, :)) - particleDec) + c2 * r2 * (binToDec(gBest_particle) - particleDec);
    popDec = abs(particleDec + velocity(i, 1));
    popBin = decToBin(popDec);
    %if popBin > size(trainingData, 1)
    %    popDec = size(trainingData, 1);
    %end
    %population(i, :) = 
end
toc;