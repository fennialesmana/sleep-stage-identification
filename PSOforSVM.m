function [result, startTime, endTime] = PSOforSVM(nFeatures, trainingData, testingData, PSOSettings)
%% INPUT PARAMETER INITIALIZATION
% MAX_ITERATIONS = 100;
% nParticles = 20;
% nFeatures = 18; % total all features to be selected
% trainingData = testingData = total samples X nFeatures
% update velocity parameter: W = 0.6; c1 = 1.2; c2 = 1.2;
% fitness parameter: Wa = 0.95; Wf = 0.05;
% END OF INPUT PARAMETER INITIALIZATION

startTime = clock;
%% PSO PARAMETER PREPARATION
% population [FeatureMask]
populationPosition = rand(PSOSettings.nParticles, nFeatures) > 0.5;
for i=1:PSOSettings.nParticles
    while sum(populationPosition(i, 1:nFeatures)) == 0
        populationPosition(i, :) = rand(1, nFeatures) > 0.5;
    end
end
populationVelocity = int64(zeros(PSOSettings.nParticles, 1)); % in decimal value
% pBest
pBest(PSOSettings.nParticles).position = [];
pBest(PSOSettings.nParticles).fitness = [];
pBest(PSOSettings.nParticles).trainingAccuracy = [];
pBest(PSOSettings.nParticles).testingAccuracy = [];
for i=1:PSOSettings.nParticles
    pBest(i).position = false(1, nFeatures);
    pBest(i).fitness = repmat(-1000000, PSOSettings.nParticles, 1); % max fitness value
    pBest(i).trainingAccuracy = 0;
    pBest(i).testingAccuracy = 0;
end

% gBest
gBest.position = false(1, nFeatures); 
gBest.fitness = -1000000; % max fitness value all particle all iteration
gBest.trainingAccuracy = [];
gBest.testingAccuracy = [];
gBest.fromIteration = [];
gBest.fromParticle = [];

% struct data
result(PSOSettings.MAX_ITERATION+1).iteration = [];
result(PSOSettings.MAX_ITERATION+1).populationPosition = [];
result(PSOSettings.MAX_ITERATION+1).pBest = [];
result(PSOSettings.MAX_ITERATION+1).time = [];
result(PSOSettings.MAX_ITERATION+1).trainingAccuracy = [];
result(PSOSettings.MAX_ITERATION+1).testingAccuracy = [];
%result(PSOSettings.MAX_ITERATION+1).model = [];
result(PSOSettings.MAX_ITERATION+1).gBest = [];
% END OF PSO PARAMETER PREPARATION

%% INITIALIZATION STEP
%Fitness Function Evaluation
[trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest);
%[modelArr, trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest);
gBest = gbestupdate(nFeatures, trainAccArr, testAccArr, populationFitness, populationPosition, gBest, 0);

% save data
result(1).iteration = 0;
result(1).populationPosition = populationPosition;
result(1).pBest = pBest;
result(1).time = timeArr;
result(1).trainingAccuracy = trainAccArr;
result(1).testingAccuracy = testAccArr;
%result(1).model = modelArr;
result(1).gBest = gBest;
% END OF INITIALIZATION STEP

%% PSO ITERATION
for iteration=1:PSOSettings.MAX_ITERATION
    %if mod(iteration, 10)==0
    %    fprintf('%s = %d/%d\n', datestr(clock), iteration, PSOSettings.MAX_ITERATION);
    %end
    %fprintf('%s = %d/%d\n', datestr(clock), iteration, PSOSettings.MAX_ITERATION);
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
        
        % if the total bits is lower than nFeatures, add zeros in front
        if size(newPosBin, 2) < nFeatures
            newPosBin = [zeros(1, (nFeatures)-size(newPosBin, 2)) newPosBin];
        end
        
        % if the total bits is higher than nFeatures, get first nFeatures
        if size(newPosBin, 2) > nFeatures
            newPosBin = newPosBin(1, 1:nFeatures);
        end
        
        % if the number of selected features is 0
        while sum(newPosBin(1, 1:nFeatures)) == 0
            newPosBin(1, 1:nFeatures) = rand(1, nFeatures) > 0.5;
        end
        
        % set the new value of position
        populationPosition(i, :) = newPosBin;
    end
    
    % fitness function evaluation
    [trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest);
    %[modelArr, trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest);
    gBest = gbestupdate(nFeatures, trainAccArr, testAccArr, populationFitness, populationPosition, gBest, iteration+1);

    % save data
    result(iteration+1).iteration = iteration;
    result(iteration+1).populationPosition = populationPosition;
    result(iteration+1).pBest = pBest;
    result(iteration+1).time = timeArr;
    result(iteration+1).trainingAccuracy = trainAccArr;
    result(iteration+1).testingAccuracy = testAccArr;
    %result(iteration+1).model = modelArr;
    result(iteration+1).gBest = gBest;
end
% END OF PSO ITERATION
endTime = clock;
end

function [trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest)
%function [modelArr, trainAccArr, testAccArr, timeArr, populationFitness, pBest] = evaluatefitness(PSOSettings, nFeatures, trainingData, testingData, populationPosition, pBest)
    %modelArr(PSOSettings.nParticles).models = [];
    trainAccArr = zeros(PSOSettings.nParticles, 1);
    testAccArr = zeros(PSOSettings.nParticles, 1);
    timeArr = zeros(PSOSettings.nParticles, 1);
    populationFitness = zeros(PSOSettings.nParticles, 1);
    %currIterResult
    for i=1:PSOSettings.nParticles
        tic;
        % TRAINING
        maskedTrainingFeature = featuremasking(trainingData, populationPosition(i, 1:nFeatures)); % remove unselected features
        Model = trainSVM(maskedTrainingFeature, trainingData(:,end), 'RBF');
        trainAcc = testSVM(maskedTrainingFeature, trainingData(:,end), Model);
        
        % TESTING
        maskedTestingFeature = featuremasking(testingData, populationPosition(i, 1:nFeatures)); % remove unselected features
        testAcc = testSVM(maskedTestingFeature, testingData(:,end), Model);

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
            end
        end
        if ischanged
            pBest(i).fitness = populationFitness(i, 1);
            pBest(i).position = populationPosition(i, :);
            pBest(i).trainingAccuracy = trainAcc;
            pBest(i).testingAccuracy = testAcc;
        end
        % end of pBest update
        
        %modelArr(i).models = Model;
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
                    if length(found) > 1 % if have the same selected feature, get the first
                        found = found(1);
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