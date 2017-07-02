function result = PSOforELM(MAX_ITERATIONS, nParticles, nFeatures, trainingData, testingData, W, c1, c2, Wa, Wf)
% Input parameter initialization
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
%{
result = struct('iteration', 0, ...
                'particle', zeros(nParticles,1), ...
                'nHiddenNodes', zeros(nParticles,1), ...
                'pBest', zeros(nParticles,1), ...
                'time', zeros(nParticles,1), ...
                'trainingAccuracy', zeros(nParticles,1), ...
                'testingAccuracy', zeros(nParticles,1), ...
                'selectedFeatures', cell(nParticles,1), ...
                'gBest', 0);
            %}
nClasses = length(unique([trainingData(:, end); testingData(:, end)]));
fprintf('Running PSO-ELM for %d classes...\n', nClasses);
fprintf('Start at %s\n', datestr(clock));

% gBest.cummulative = zeros(MAX_ITERATIONS, 1);
nHiddenBits = size(decToBin(size(trainingData, 1)), 2);

population_fitness = zeros(nParticles, 1);
velocity = int64(zeros(nParticles, 1)); % in decimal value
pBest_particle = zeros(nParticles, nFeatures+nHiddenBits); % max fitness value
pBest_fitness = repmat(-1000000, nParticles, 1);
gBest.particle = zeros(1, nFeatures+nHiddenBits); % max fitness function all particle all iteration
gBest.fitness = -1000000;

% Population Initialization: [FeatureMask HiddenNode]
population = rand(nParticles, nFeatures+nHiddenBits) > 0.5;
% check and re-random if the value is invalid
for i=1:nParticles
    while binToDec(population(i, nFeatures+1:end)) < nFeatures || ...
          binToDec(population(i, nFeatures+1:end)) > size(trainingData, 1) || ...
          sum(population(i, 1:nFeatures)) == 0
        population(i, :) = rand(1, nFeatures+nHiddenBits) > 0.5;
    end
end

% Calculate Fitness Value:
%featureMask = [1 1 1 1 0  1 1 0 0 1  1 1 1 0 0  0 0];
%featureMask = [1 1 1 1 1  1 1 1 1 1  1 1 1 1 1  1 1];
%fprintf('Initialization\n');

% save result to struct - part 1
result(1).iteration = 0;

%fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
for i=1:nParticles
    tic;
    %fprintf('%8d %15d ', i, binToDec(population(i, nFeatures+1:end)));
    % TRAINING
    maskedTrainingFeature = featuremasking(trainingData, population(i, 1:nFeatures));% prepare the feature data (masking)
    trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = trainELM(binToDec(population(i, nFeatures+1:end)), maskedTrainingFeature, trainingTarget);
    
    % TESTING
    maskedTestingFeature = featuremasking(testingData, population(i, 1:nFeatures));% prepare the feature data (masking)
    testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
    elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
    
    population_fitness(i, 1) = fitness(Wa, Wf, elmModel.testingAccuracy, population(i, 1:nFeatures));
    
    % pBest Update
    if population_fitness(i, 1) > pBest_fitness(i, 1)
        pBest_fitness(i, 1) = population_fitness(i, 1);
        pBest_particle(i, :) = population(i, :);
    end
    endTime = toc;
    
    % print result
    %fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
    %fprintf('%s\n', binToStringOrder(population(i, 1:nFeatures)));
    
    % save result to struct - part 2
    result(1).particle(i) = i;
    result(1).nHiddenNodes(i) = binToDec(population(i, nFeatures+1:end));
    result(1).pBest(i) = pBest_fitness(i, 1);
    result(1).time(i) = endTime;
    result(1).trainingAccuracy(i) = elmModel.trainingAccuracy;
    result(1).testingAccuracy(i) = elmModel.testingAccuracy;
    result(1).elmModel(i) = elmModel;
    result(1).selectedFeatures(i) = {binToStringOrder(population(i, 1:nFeatures))};
    
end

% gBest Update
if max(population_fitness) > gBest.fitness
    found = find(population_fitness == max(population_fitness));
    found = found(1);
    gBest.fitness = max(population_fitness);
    gBest.particle = population(found, :);
end

%fprintf('gBest = %d\n', gBest.fitness);
% save result to struct - part 3
result(1).gBest = gBest;

for iteration=1:MAX_ITERATIONS
    %fprintf('\nIteration %d of %d\n', iteration, MAX_ITERATIONS);
    % save result to struct - part 1
    result(iteration+1).iteration = iteration;
    
    % Update Velocity
    r1 = rand();
    r2 = rand();
    for i=1:nParticles
        % calculate velocity value
        particleDec = int64(binToDec(population(i, :)));
        velocity(i, 1) = W * velocity(i, 1) + c1 * r1 * (binToDec(pBest_particle(i, :)) - particleDec) + c2 * r2 * (binToDec(gBest.particle) - particleDec);
        
        % update particle position
        newPosDec = abs(int64(particleDec + velocity(i, 1)));
        newPosBin = decToBin(newPosDec);
        
        % if the total bits is lower than nFeatures + nBits, add zeros in front
        if size(newPosBin, 2) < (nFeatures + nHiddenBits)
            newPosBin = [zeros(1, (nFeatures + nHiddenBits)-size(newPosBin, 2)) newPosBin];
        end
        
        % if the number of hidden node is more than the number of samples
        if binToDec(newPosBin(1, nFeatures+1:end)) > size(trainingData, 1) ...
                || size(newPosBin(1, nFeatures+1:end), 2) > nHiddenBits
            newPosBin = [newPosBin(1, 1:nFeatures) decToBin(size(trainingData, 1))];
        end
        
        % if the number of selected features is 0
        if sum(newPosBin(1, 1:nFeatures)) == 0
            newPosBin = [ones(1, nFeatures) newPosBin(1, nFeatures+1:end)];
        end
        
        % set the value
        population(i, :) = newPosBin;
    end
    
    % Calculate Fitness Value
    %fprintf('%8s %15s %15s %15s %15s %15s %20s\n', 'Particle', 'nHiddenNode', 'pBest', 'Time', 'TrainAcc', 'TestAcc', 'SelectedFeatures');
    for i=1:nParticles
        tic;
        %fprintf('%8d %15d ', i, binToDec(population(i, nFeatures+1:end)));
        % TRAINING
        maskedTrainingFeature = featuremasking(trainingData, population(i, 1:nFeatures));% prepare the feature data (masking)
        trainingTarget = full(ind2vec(trainingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
        elmModel = trainELM(binToDec(population(i, nFeatures+1:end)), maskedTrainingFeature, trainingTarget);

        % TESTING
        maskedTestingFeature = featuremasking(testingData, population(i, 1:nFeatures));% prepare the feature data (masking)
        testingTarget = full(ind2vec(testingData(:,end)'))';% prepare the target data (transformation from 4 into [0 0 0 1 0 0])
        elmModel = testELM(elmModel, maskedTestingFeature, testingTarget);
        
        population_fitness(i, 1) = fitness(Wa, Wf, elmModel.testingAccuracy, population(i, 1:nFeatures));

        % pBest Update
        if population_fitness(i, 1) > pBest_fitness(i, 1)
            pBest_fitness(i, 1) = population_fitness(i, 1);
            pBest_particle(i, :) = population(i, :);
        end
        endTime = toc;
        
        %fprintf('%15d %15d %15d %15d %4s', pBest_fitness(i, 1), endTime, elmModel.trainingAccuracy, elmModel.testingAccuracy, ' ');
        %fprintf('%s\n', binToStringOrder(population(i, 1:nFeatures)));
        % save result to struct - part 2
        result(iteration+1).particle(i) = i;
        result(iteration+1).nHiddenNodes(i) = binToDec(population(i, nFeatures+1:end));
        result(iteration+1).pBest(i) = pBest_fitness(i, 1);
        result(iteration+1).time(i) = endTime;
        result(iteration+1).trainingAccuracy(i) = elmModel.trainingAccuracy;
        result(iteration+1).testingAccuracy(i) = elmModel.testingAccuracy;
        result(iteration+1).elmModel(i) = elmModel;
        result(iteration+1).selectedFeatures(i) = {binToStringOrder(population(i, 1:nFeatures))};
    end

    % gBest Update
    if max(population_fitness) > gBest.fitness
        found = find(population_fitness == max(population_fitness));
        found = found(1);
        gBest.fitness = max(population_fitness);
        gBest.particle = population(found, :);
    end
    
    % fprintf('gBest = %d\n', gBest.fitness);
    % save result to struct - part 3
    result(iteration+1).gBest = gBest;
    
    %gBest.cummulative(iteration, 1) = gBest.fitness;
end

%fprintf('Selected Feature = %s\n', binToStringOrder(gBest.particle(1, 1:nFeatures)));
%fprintf('n Hidden Node = %d\n', binToDec(gBest.particle(1, nFeatures+1:end)));

%plot(gBest.cummulative);
fprintf('Finish at %s\n', datestr(clock));
end