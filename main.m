clear; clc; close all;

%{
% STEP 1: IMPORT AND SYNCHRONIZE ALL DATA
file_names = {'slp01a', 'slp01b', 'slp02a', 'slp02b', 'slp03', 'slp04', 'slp14', 'slp16', 'slp32', 'slp37', 'slp41', 'slp45', 'slp48', 'slp59', 'slp60', 'slp61', 'slp66', 'slp67x'};
sec_per_epoch = 30;
data = [];
single_file = [];

for i=1:size(file_names, 2)
    fprintf('\n%s importing...\n', cell2mat(file_names(i)));
    single_file = import_data(file_names(i), sec_per_epoch);
    data = [data;single_file];
end

save('data.mat', 'data');
%}

nFeature = 18;
%{
% STEP 2: FEATURE EXTRACTION
data = load('data.mat');
data = data.data;
extractFeatures(data, nFeature, 'features250/', 'all');
%}

nClass = 3; % jumlah kelas ouput
fprintf('Building classifier model for %d classes...\n', nClass);
fprintf('Start at %s\n', datestr(clock));
% STEP 3: BUILD CLASSIFIER MODEL USING PSO AND ELM
switch nClass
    case 2
        hrv = load('features2/normalized_hrv_2_class.mat');
        hrv = hrv.normalized_hrv_2_class;
    case 3
        hrv = load('features2/normalized_hrv_3_class.mat');
        hrv = hrv.normalized_hrv_3_class;
    case 4
        hrv = load('features2/normalized_hrv_4_class.mat');
        hrv = hrv.normalized_hrv_4_class;
    case 6
        hrv = load('features2/normalized_hrv_6_class.mat');
        hrv = hrv.normalized_hrv_6_class;
end
hrv = hrv(1:599, :);
% SPLIT DATA
% 70% training data and 30% testing data using stratified sampling
trainingRatio = 0.7;
trainingData = [];
testingData = [];
for i=1:nClass
    ithClassInd = find(hrv(:, end) == i);
    nithClass = ceil(size(ithClassInd, 1)*trainingRatio);
    trainingData = [trainingData; hrv(ithClassInd(1:nithClass), :)];
    testingData = [testingData; hrv(ithClassInd(nithClass+1:end), :)];
end

% PARTICLE SWARM OPTIMIZATION (PSO) PROCESS
% PSO parameter initialization
max_iteration = 100;
gBest.cummulative = zeros(max_iteration, 1);
nParticle = 20;
nTrainData = size(trainingData, 1);
nBit = size(decToBin(nTrainData), 2); %bin2 = de2bi(nSamples);

population_fitness = zeros(nParticle, 1);
velocity = int64(zeros(nParticle, 1)); % in decimal value
pBest_particle = zeros(nParticle, nFeature+nBit); % max fitness value
pBest_fitness = repmat(-1000000, nParticle, 1);
gBest.particle = zeros(1, nFeature+nBit); % max fitness function all particle all iteration
gBest.fitness = -1000000;

% update velocity parameter
W = 0.6;
c1 = 1.2;
c2 = 1.2;

% Population Initialization: [FeatureMask HiddenNode]
population = rand(nParticle, nFeature+nBit) > 0.8;
% check whether the value is more than sample data
for i=1:nParticle
    % loop selama nHiddenNode < nFeature || nHiddenNode > nTrainData || nFeature selected == 0
    while binToDec(population(i, nFeature+1:end)) < nFeature || binToDec(population(i, nFeature+1:end)) > size(trainingData, 1) || sum(population(i, 1:nFeature)) == 0
        population(i, :) = rand(1, nFeature+nBit) > 0.8;
    end
end

% Calculate Fitness Value:
%featureMask = [1 1 1 1 0  1 1 0 0 1  1 1 1 0 0  0 0];
%featureMask = [1 1 1 1 1  1 1 1 1 1  1 1 1 1 1  1 1];
fprintf('Initialization\n');
fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
for i=1:nParticle
    tic;
    fprintf('%8d %15d ', i, binToDec(population(i, nFeature+1:end)));
    % TRAINING
    maskedTrainingFeature = featureMasking(trainingData, population(i, 1:nFeature));% prepare the feature data (masking)
    trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = trainELM(binToDec(population(i, nFeature+1:end)), maskedTrainingFeature, trainingTarget);
    
    % TESTING
    maskedTestingFeature = featureMasking(testingData, population(i, 1:nFeature));% prepare the feature data (masking)
    testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
    
    population_fitness(i, 1) = fitness(0.95, 0.05, elmModel.testingAccuracy, population(i, 1:nFeature));
    
    % pBest Update
    if population_fitness(i, 1) > pBest_fitness(i, 1)
        pBest_fitness(i, 1) = population_fitness(i, 1);
        pBest_particle(i, :) = population(i, :);
    end
    endTime = toc;
    
    % print result
    fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
    fprintf('%s\n', binToStringOrder(population(i, 1:nFeature)));
end

% gBest Update
if max(population_fitness) > gBest.fitness
    found = find(population_fitness == max(population_fitness));
    found = found(1);
    gBest.fitness = max(population_fitness);
    gBest.particle = population(found, :);
end

fprintf('gBest = %d\n', gBest.fitness);

for iteration=1:max_iteration
    fprintf('\nIteration %d of %d\n', iteration, max_iteration);
    % Update Velocity
    r1 = rand();
    r2 = rand();
    for i=1:nParticle
        % calculate velocity value
        particleDec = int64(binToDec(population(i, :)));
        velocity(i, 1) = W * velocity(i, 1) + c1 * r1 * (binToDec(pBest_particle(i, :)) - particleDec) + c2 * r2 * (binToDec(gBest.particle) - particleDec);
        
        % update particle position
        newPosDec = abs(int64(particleDec + velocity(i, 1)));
        popBin = decToBin(newPosDec);
        
        %if the total bits lower than nFeatures + nBits, add zeros in front
        if size(popBin, 2) < (nFeature + nBit)
            popBin = [zeros(1, (nFeature + nBit)-size(popBin, 2)) popBin];
        end
        
        %if the number of hidden node is more than the number of samples
        if binToDec(popBin(1, nFeature+1:end)) > size(trainingData, 1) || size(popBin(1, nFeature+1:end), 2) > nBit
            popBin = [popBin(1, 1:nFeature) decToBin(size(trainingData, 1))];
        end
        
        %set the value
        population(i, :) = popBin;
    end
    
    % Calculate Fitness Value:
    fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
    for i=1:nParticle
        tic;
        fprintf('%8d %15d ', i, binToDec(population(i, nFeature+1:end)));
        % TRAINING
        maskedTrainingFeature = featureMasking(trainingData, population(i, 1:nFeature));% prepare the feature data (masking)
        trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
        elmModel = trainELM(binToDec(population(i, nFeature+1:end)), maskedTrainingFeature, trainingTarget);

        % TESTING
        maskedTestingFeature = featureMasking(testingData, population(i, 1:nFeature));% prepare the feature data (masking)
        testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
        elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
        
        population_fitness(i, 1) = fitness(0.95, 0.05, elmModel.testingAccuracy, population(i, 1:nFeature));

        % pBest Update
        if population_fitness(i, 1) > pBest_fitness(i, 1)
            pBest_fitness(i, 1) = population_fitness(i, 1);
            pBest_particle(i, :) = population(i, :);
        end
        endTime = toc;
        
        fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
        fprintf('%s\n', binToStringOrder(population(i, 1:nFeature)));
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

fprintf('Selected Feature = %s\n', binToStringOrder(gBest.particle(1, 1:nFeature)));
fprintf('n Hidden Node = %d\n', binToDec(gBest.particle(1, nFeature+1:end)));

plot(gBest.cummulative);
fprintf('Finish at %s\n', datestr(clock));
beep