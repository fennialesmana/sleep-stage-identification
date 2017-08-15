function [result, startTime, endTime] = PSOforELM(nFeatures, trainingData, testingData, PSOSettings)
%Running PSO with ELM for feature selection and number of hidden nodes
%optimization
%   Syntax:
%   [result, startTime, endTime] = PSOforELM(nFeatures, trainingData, testingData, PSOSettings)
%
%   Input:
%   *) nFeatures    - total number of features to be selected
%   *) trainingData - training data (Matrix size: total samples X nFeatures)
%   *) testingData  - testing data (Matrix size: total samples X nFeatures)
%   *) PSOSettings  - struct contains PSO parameters, examples:
%                       PSOSettings.MAX_ITERATION = MAX_ITERATION;
%                       PSOSettings.nParticles = 20;
%                       PSOSettings.W = 0.6;
%                       PSOSettings.c1 = 1.2;
%                       PSOSettings.c2 = 1.2;
%                       PSOSettings.Wa = 0.95;
%                       PSOSettings.Wf = 0.05;
%
%   Output:
%   *) result    - struct contains records of PSO ELM result
%   *) startTime - time when the experiment starts
%   *) endTime   - time when the experiment ends

startTime = clock;
%% PSO PARAMETER PREPARATION
nHiddenBits = length(dectobin(size(trainingData, 1))); % max total bits for hidden nodes
populationPosition = rand(PSOSettings.nParticles, nFeatures+nHiddenBits) > 0.5;
for i=1:PSOSettings.nParticles
    while bintodec(populationPosition(i, nFeatures+1:end)) < nFeatures || ...
          bintodec(populationPosition(i, nFeatures+1:end)) > size(trainingData, 1) || ...
          sum(populationPosition(i, 1:nFeatures)) == 0
        populationPosition(i, :) = rand(1, nFeatures+nHiddenBits) > 0.5;
    end
end
populationVelocity = int64(zeros(PSOSettings.nParticles, 1)); % in decimal value

% pBest
pBest(PSOSettings.nParticles).position = [];
pBest(PSOSettings.nParticles).fitness = [];
pBest(PSOSettings.nParticles).trainingAccuracy = [];
pBest(PSOSettings.nParticles).testingAccuracy = [];
for i=1:PSOSettings.nParticles
    pBest(i).position = false(1, nFeatures+nHiddenBits);
    pBest(i).fitness = repmat(-1000000, PSOSettings.nParticles, 1); % max fitness value
    pBest(i).trainingAccuracy = 0;
    pBest(i).testingAccuracy = 0;
end

% gBest
gBest.position = false(1, nFeatures+nHiddenBits); 
gBest.fitness = -1000000; % max fitness value all particle all iteration
gBest.trainingAccuracy = [];
gBest.testingAccuracy = [];
gBest.fromIteration = [];
gBest.fromParticle = [];

% initialize struct data
result(PSOSettings.MAX_ITERATION+1).iteration = [];
result(PSOSettings.MAX_ITERATION+1).populationPosition = [];
result(PSOSettings.MAX_ITERATION+1).pBest = [];
result(PSOSettings.MAX_ITERATION+1).time = [];
result(PSOSettings.MAX_ITERATION+1).trainingAccuracy = [];
result(PSOSettings.MAX_ITERATION+1).testingAccuracy = [];
result(PSOSettings.MAX_ITERATION+1).model = [];
result(PSOSettings.MAX_ITERATION+1).gBest = [];
% END OF PSO PARAMETER PREPARATION

%% INITIALIZATION STEP
%fitness function evaluation
[modelArr, trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest);
gBest = gbestupdate(nFeatures, trainAccArr, testAccArr, populationFitness, populationPosition, gBest, 0);

% save initial data
result(1).iteration = 0;
result(1).populationPosition = populationPosition;
result(1).pBest = pBest;
result(1).time = timeArr;
result(1).trainingAccuracy = trainAccArr;
result(1).testingAccuracy = testAccArr;
result(1).model = modelArr;
result(1).gBest = gBest;
% END OF INITIALIZATION STEP

%% PSO ITERATION
for iteration=1:PSOSettings.MAX_ITERATION
    % Update Velocity
    r1 = rand();
    r2 = rand();
    for i=1:PSOSettings.nParticles
        % calculate velocity value
        positionDec = int64(bintodec(populationPosition(i, :)));
        populationVelocity(i, 1) = PSOSettings.W * populationVelocity(i, 1) + ...
            PSOSettings.c1 * r1 * (bintodec(pBest(i).position) - positionDec) + ...
            PSOSettings.c2 * r2 * (bintodec(gBest.position) - positionDec);
        
        % update particle position
        newPosDec = abs(int64(positionDec + populationVelocity(i, 1)));
        newPosBin = dectobin(newPosDec);
        
        % if the total bits is lower than nFeatures + nHiddenBits, add zeros in front
        if size(newPosBin, 2) < (nFeatures + nHiddenBits)
            newPosBin = [zeros(1, (nFeatures + nHiddenBits)-size(newPosBin, 2)) newPosBin];
        end
        
        % if the number of hidden node is more than the number of samples
        if bintodec(newPosBin(1, nFeatures+1:end)) > size(trainingData, 1) ...
                || size(newPosBin(1, nFeatures+1:end), 2) > nHiddenBits
            newPosBin = [newPosBin(1, 1:nFeatures) dectobin(size(trainingData, 1))];
        end
        
        % if the number of selected features is 0
        while sum(newPosBin(1, 1:nFeatures)) == 0
            newPosBin(1, 1:nFeatures) = rand(1, nFeatures) > 0.5;
        end
        
        % set the new value of position
        populationPosition(i, :) = newPosBin;
    end
    
    % fitness function evaluation
    [modelArr, trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest);
    gBest = gbestupdate(nFeatures, trainAccArr, testAccArr, populationFitness, populationPosition, gBest, iteration+1);

    % save data
    result(iteration+1).iteration = iteration;
    result(iteration+1).populationPosition = populationPosition;
    result(iteration+1).pBest = pBest;
    result(iteration+1).time = timeArr;
    result(iteration+1).trainingAccuracy = trainAccArr;
    result(iteration+1).testingAccuracy = testAccArr;
    result(iteration+1).model = modelArr;
    result(iteration+1).gBest = gBest;
end
% END OF PSO ITERATION
endTime = clock;
end

function [modelArr, trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest)
    modelArr(PSOSettings.nParticles).inputWeight = []; % ELM Specific
    modelArr(PSOSettings.nParticles).outputWeight = []; % ELM Specific
    trainAccArr = zeros(PSOSettings.nParticles, 1);
    testAccArr = zeros(PSOSettings.nParticles, 1);
    timeArr = zeros(PSOSettings.nParticles, 1);
    populationFitness = zeros(PSOSettings.nParticles, 1);
    for i=1:PSOSettings.nParticles
        tic;
        % TRAINING
        maskedTrainingFeature = featuremasking(trainingData, populationPosition(i, 1:nFeatures)); % remove unselected features
        trainingTarget = full(ind2vec(trainingData(:,end)'))'; % prepare the target data (example: transformation from 4 into [0 0 0 1 0 0])
        [Model, trainAcc] = trainELM(maskedTrainingFeature, trainingTarget, bintodec(populationPosition(i, nFeatures+1:end)));

        % TESTING
        maskedTestingFeature = featuremasking(testingData, populationPosition(i, 1:nFeatures)); % remove unselected features
        testingTarget = full(ind2vec(testingData(:,end)'))'; % prepare the target data (example: transformation from 4 into [0 0 0 1 0 0])
        testAcc = testELM(maskedTestingFeature, testingTarget, Model);

        populationFitness(i, 1) = fitness(PSOSettings.Wa, PSOSettings.Wf, testAcc, populationPosition(i, 1:nFeatures));

        % pBest update
        ischanged = 0;
        if populationFitness(i, 1) > pBest(i).fitness
            ischanged = 1;
        elseif populationFitness(i, 1) == pBest(i).fitness
            if pBest(i).testingAccuracy < testAcc
                ischanged = 1;
            elseif pBest(i).trainingAccuracy < trainAcc
                ischanged = 1;
            elseif sum(pBest(i).position(1, 1:nFeatures)) > ...
                    sum(populationPosition(i, 1:nFeatures))
                ischanged = 1;
            elseif bintodec(pBest(i).position(1, nFeatures+1:end)) > ...
                    bintodec(populationPosition(i, nFeatures+1:end))
                ischanged = 1;
            end
        end
        if ischanged
            pBest(i).fitness = populationFitness(i, 1);
            pBest(i).position = populationPosition(i, :);
            pBest(i).trainingAccuracy = trainAcc;
            pBest(i).testingAccuracy = testAcc;
        end
        % end of pBest update
        
        modelArr(i) = Model;
        timeArr(i) = toc;
        trainAccArr(i) = trainAcc;
        testAccArr(i) = testAcc;
    end
end

function gBest = gbestupdate(nFeatures, trainAccArr, testAccArr, populationFitness, populationPosition, gBest, iteration)
    if max(populationFitness) >= gBest.fitness
        found = find(populationFitness == max(populationFitness));
        if length(found) > 1 % if have the same gBest fitness value, get the max of testAcc
            found = found(testAccArr(found) == max(testAccArr(found)));
            if length(found) > 1 % if have the same testAcc, get the max of trainAcc
                found = found(trainAccArr(found) == max(trainAccArr(found)));
                if length(found) > 1 % if have the same trainAcc, get the min of selected features
                    found = found(sum(populationPosition(found, 1:nFeatures), 2) == min(sum(populationPosition(found, 1:nFeatures), 2)));
                    if length(found) > 1 % if have the same selected feature, get the min of hidden node
                        hn = zeros(length(found), 1);
                        for i=1:length(found)
                            hn(i, 1) = bintodec(populationPosition(found(i), nFeatures+1:end));
                        end
                        found = found(hn == min(hn));
                        if length(found) > 1
                            found = found(1);
                        end
                    end
                end
            end
        end
        gBest.fitness = populationFitness(found);
        gBest.position = populationPosition(found, :);
        gBest.trainingAccuracy = trainAccArr(found);
        gBest.testingAccuracy = testAccArr(found);
        gBest.fromIteration = iteration;
        gBest.fromParticle = found;
    end
end