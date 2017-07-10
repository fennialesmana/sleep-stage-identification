function [result, startTime, endTime] = PSOforSVM(MAX_ITERATION, nParticles, nFeatures, trainingData, testingData, W, c1, c2, Wa, Wf)
%% INPUT PARAMETER INITIALIZATION
%MAX_ITERATIONS = 100;
%nParticles = 20;
%nFeatures = 18; % total all features to be selected
%trainingData = matrix nTrainingSamples X nFeatures
%testingData = matrix nTestingSamples X nFeatures
% update velocity parameter 
%W = 0.6;
%c1 = 1.2;
%c2 = 1.2;
% fitness parameter
%Wa = 0.95;
%Wf = 0.05;
% END OF INPUT PARAMETER INITIALIZATION

%nClasses = length(unique([trainingData(:, end); testingData(:, end)]));
%fprintf('Running PSO-ELM for %d classes...\n', nClasses);
%fprintf('Start at %s\n', datestr(clock));
startTime = clock;

%% PSO PARAMETER PREPARATION
% Population Initialization: [FeatureMask]
populationPosition = rand(nParticles, nFeatures) > 0.5;
% check and re-random if the value is invalid:
for i=1:nParticles
    while sum(populationPosition(i, 1:nFeatures)) == 0
        populationPosition(i, :) = rand(1, nFeatures) > 0.5;
    end
end
populationFitness = zeros(nParticles, 1);
populationVelocity = int64(zeros(nParticles, 1)); % in decimal value

pBestPosition = false(nParticles, nFeatures);
pBestFitness = repmat(-1000000, nParticles, 1); % max fitness value

gBest.position = false(1, nFeatures);
gBest.fitness = -1000000; % max fitness value all particle all iteration
% END OF PSO PARAMETER PREPARATION

%% INITIALIZATION STEP
% save result to struct - part 1
result(1).iteration = 0;
%result(1).nParticles = nParticles;

%fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
for i=1:nParticles
    tic;
    %fprintf('%8d %15d ', i, binToDec(population(i, nFeatures+1:end)));
    % TRAINING
    maskedTrainingFeature = featuremasking(trainingData, populationPosition(i, :)); % remove unselected features
    SVMModels = trainSVM(maskedTrainingFeature, trainingData(:,end));
    trainAcc = testSVM(maskedTrainingFeature, trainingData(:,end), SVMModels);
    
    % TESTING
    maskedTestingFeature = featuremasking(testingData, populationPosition(i, :)); % remove unselected features
    testAcc = testSVM(maskedTestingFeature, testingData(:,end), SVMModels);
    
    populationFitness(i, 1) = fitness(Wa, Wf, testAcc, populationPosition(i, :));
    
    % pBest Update
    if populationFitness(i, 1) > pBestFitness(i, 1)
        pBestFitness(i, 1) = populationFitness(i, 1);
        pBestPosition(i, :) = populationPosition(i, :);
    end
    endT = toc;
    
    % print result
    %fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
    %fprintf('%s\n', binToStringOrder(population(i, 1:nFeatures)));
    
    % save result to struct - part 2
    result(1).particlePosition(i, :) = populationPosition(i, :);
    result(1).pBest(i) = pBestFitness(i, 1);
    result(1).time(i) = endT;
    result(1).trainingAccuracy(i) = trainAcc;
    result(1).testingAccuracy(i) = testAcc;
    result(1).SVMModels{i} = SVMModels;
end

% gBest Update
if max(populationFitness) > gBest.fitness
    found = find(populationFitness == max(populationFitness));
    if length(found) > 1 % if have the same gBest fitness value, get the max of testAcc
        maxTestAcc = max(result(1).testingAccuracy(found));
        found = found(result(1).testingAccuracy(found) == maxTestAcc);
        if length(found) > 1 % if have the same testAcc, get the max of trainAcc
            maxTrainAcc = max(result(1).trainingAccuracy(found));
            found = found(result(1).trainingAccuracy(found) == maxTrainAcc);
            if length(found) > 1 % if have the same trainAcc, get the min of selected features
                minLength = sum(result(1).selectedFeatures{found(1)} == ' ');
                minIdx = found(1);
                for i=2:length(found)
                    if sum(result(1).selectedFeatures{found(i)} == ' ') < minLength
                        minLength = sum(result(1).selectedFeatures{found(i)} == ' ');
                        minIdx = found(i);
                    end
                end
                found = minIdx;
            end
        end
    end
    gBest.fitness = max(populationFitness);
    gBest.position = populationPosition(found, :);
    gBest.whichIteration = 0;
    gBest.whichParticle = found;
end
%fprintf('gBest = %d\n', gBest.fitness);
% save result to struct - part 3
result(1).gBest = gBest;
% END OF INITIALIZATION STEP

%% PSO ITERATION
for iteration=1:MAX_ITERATION
    %if mod(iteration, 10)==0
    %    fprintf('%s = %d/%d\n', datestr(clock), iteration, MAX_ITERATION);
    %end
    %fprintf('\nIteration %d of %d\n', iteration, MAX_ITERATIONS);
    % save result to struct - part 1
    result(iteration+1).iteration = iteration;
    %result(iteration+1).nParticles = nParticles;
    % Update Velocity
    r1 = rand();
    r2 = rand();
    for i=1:nParticles
        % calculate velocity value
        positionDec = int64(binToDec(populationPosition(i, :)));
        populationVelocity(i, 1) = W * populationVelocity(i, 1) + ...
            c1 * r1 * (binToDec(pBestPosition(i, :)) - positionDec) + ...
            c2 * r2 * (binToDec(gBest.position) - positionDec);
        
        % update particle position
        newPosDec = abs(int64(positionDec + populationVelocity(i, 1)));
        newPosBin = decToBin(newPosDec);
        
        % if the total bits is lower than nFeatures + nHiddenBits, add zeros in front
        if size(newPosBin, 2) < (nFeatures + nHiddenBits)
            newPosBin = [zeros(1, (nFeatures + nHiddenBits)-size(newPosBin, 2)) newPosBin];
        end
        
        % if the number of hidden node is more than the number of samples
        if binToDec(newPosBin(1, nFeatures+1:end)) > size(trainingData, 1) ...
                || size(newPosBin(1, nFeatures+1:end), 2) > nHiddenBits
            newPosBin = [newPosBin(1, 1:nFeatures) decToBin(size(trainingData, 1))];
        end
        
        % if the number of selected features is 0
        while sum(newPosBin(1, 1:nFeatures)) == 0
            newPosBin(1, 1:nFeatures) = rand(1, nFeatures) > 0.5;
        end
        
        % set the value
        populationPosition(i, :) = newPosBin;
    end
    
    % Calculate Fitness Value
    %fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
    for i=1:nParticles
        tic;
        %fprintf('%8d %15d ', i, binToDec(population(i, nFeatures+1:end)));
        % TRAINING
        maskedTrainingFeature = featuremasking(trainingData, populationPosition(i, 1:nFeatures)); % remove unselected features
        trainingTarget = full(ind2vec(trainingData(:,end)'))'; % prepare the target data (example: transformation from 4 into [0 0 0 1 0 0])
        [elmModel, trainAcc] = trainELM(maskedTrainingFeature, trainingTarget, binToDec(populationPosition(i, nFeatures+1:end)));

        % TESTING
        maskedTestingFeature = featuremasking(testingData, populationPosition(i, 1:nFeatures)); % remove unselected features
        testingTarget = full(ind2vec(testingData(:,end)'))'; % prepare the target data (example: transformation from 4 into [0 0 0 1 0 0])
        testAcc = testELM(maskedTestingFeature, testingTarget, elmModel);
        
        populationFitness(i, 1) = fitness(Wa, Wf, testAcc, populationPosition(i, 1:nFeatures));

        % pBest Update
        if populationFitness(i, 1) > pBestFitness(i, 1)
            pBestFitness(i, 1) = populationFitness(i, 1);
            pBestPosition(i, :) = populationPosition(i, :);
        end
        endT = toc;
        
        %fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
        %fprintf('%s\n', binToStringOrder(population(i, 1:nFeatures)));
        % save result to struct - part 2    
        result(iteration+1).nHiddenNodes(i) = binToDec(populationPosition(i, nFeatures+1:end));
        result(iteration+1).selectedFeatures(i) = {binToStringOrder(populationPosition(i, 1:nFeatures))};
        result(iteration+1).pBest(i) = pBestFitness(i, 1);
        result(iteration+1).time(i) = endT;
        result(iteration+1).trainingAccuracy(i) = trainAcc;
        result(iteration+1).testingAccuracy(i) = testAcc;
        result(iteration+1).elmModel(i) = elmModel;
    end

    % gBest Update
    if max(populationFitness) > gBest.fitness
        found = find(populationFitness == max(populationFitness));
        if length(found) > 1 % if have the same gBest fitness value, get the max of testAcc
            maxTestAcc = max(result(iteration+1).testingAccuracy(found));
            found = found(result(iteration+1).testingAccuracy(found) == maxTestAcc);
            if length(found) > 1 % if have the same testAcc, get the max of trainAcc
                maxTrainAcc = max(result(iteration+1).trainingAccuracy(found));
                found = found(result(iteration+1).trainingAccuracy(found) == maxTrainAcc);
                if length(found) > 1 % if have the same trainAcc, get the min of hidden nodes
                    minHidden = min(result(iteration+1).nHiddenNodes(found));
                    found = found(result(iteration+1).nHiddenNodes(found) == minHidden);
                    if length(found) > 1 % if have the same hiddenNodes, get the min of selected features
                        minLength = sum(result(iteration+1).selectedFeatures{found(1)} == ' ');
                        minIdx = found(1);
                        for i=2:length(found)
                            if sum(result(iteration+1).selectedFeatures{found(i)} == ' ') < minLength
                                minLength = sum(result(iteration+1).selectedFeatures{found(i)} == ' ');
                                minIdx = found(i);
                            end
                        end
                        found = minIdx;
                    end
                end
            end
        end
        gBest.fitness = max(populationFitness);
        gBest.position = populationPosition(found, :);
        gBest.whichIteration = iteration;
        gBest.whichParticle = found;
    end
    
    % fprintf('gBest = %d\n', gBest.fitness);
    % save result to struct - part 3
    result(iteration+1).gBest = gBest;
end
% END OF PSO ITERATION

%fprintf('Selected Feature = %s\n', binToStringOrder(gBest.position(1, 1:nFeatures)));
%fprintf('n Hidden Node = %d\n', binToDec(gBest.position(1, nFeatures+1:end)));

%fprintf('Finish at %s\n', datestr(clock));
endTime = clock;
end