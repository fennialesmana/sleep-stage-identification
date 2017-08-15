function [ELMModel, trainAcc] = trainELM(feature, target, nHiddenNode)
%Train Extreme Learning Machine (ELM) model
%   Syntax:
%   [ELMModel, trainAcc] = trainELM(feature, target, nHiddenNode)
%
%   Input:
%   *) feature     - feature collection
%      (Matrix size: total samples X total features)
%   *) target      - target of each sample
%      (Matrix size: total samples X total classes)
%       Example: class 4 -> target is [0 0 0 1]
%   *) nHiddenNode - total hidden nodes of ELM
%
%   Output:
%   *) ELMModel.inputWeight  - input weight of ELM
%      (Matrix size: nHiddenNode (+1 for bias) X total features)
%   *) ELMModel.outputWeight - output weight of ELM
%      (Matrix size: total classes X nHiddenNode)
%   *) trainAcc              - training accuracy

    if size(feature, 2) == 0
        fprintf('Someting went wrong, no feature selected.');
        return
    end

    % STEP 1: RANDOMLY ASSIGN INPUT WEIGHT AND BIAS
    minWeight = -1;
    maxWeight = 1;
    inputWeight = (maxWeight-minWeight) .* ...
        rand(nHiddenNode, size(feature, 2)+1) + minWeight;
    
    % STEP 2: CALCULATE THE HIDDEN LAYER OUTPUT MATRIX H
    % linear combination of hidden output
    hiddenOutput = (inputWeight(:, 1:end-1) * feature')+ ...
        repmat(inputWeight(:, end), 1, size(feature, 1));
    % apply activation function on hidden output
    hiddenOutput = sigmoid(hiddenOutput);
    
    % STEP 3: CALCULATE THE OUTPUT WEIGHT B
    % estimate output weight
    outputWeight = target' * pinv(hiddenOutput);
    
    % STEP 4: APPLY MODEL TO TRAINING DATA
    % linear combination of predicted output
    predictedOutput = outputWeight * hiddenOutput;
    % apply activation function on predicted output
    predictedOutput = sigmoid(predictedOutput);
    
    maxPred = max(predictedOutput);
    predictedClass = zeros(size(predictedOutput, 2), 1);
    for i=1:size(predictedOutput, 2)
        class = find(predictedOutput(:, i) == maxPred(i));
        predictedClass(i) = class(1, 1);
    end
    trainAcc = sum(predictedClass == vec2ind(target')')/ ...
        size(predictedOutput, 2) * 100;
    ELMModel.inputWeight = inputWeight;
    ELMModel.outputWeight = outputWeight;
end