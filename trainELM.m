function [inputWeight, outputWeight, accuracy] = trainELM(nHiddenNode, feature, target)
%Train Extreme Learning Machine (ELM) model
%   Syntax:
%   [inputWeight, outputWeight, accuracy] = trainELM(nHiddenNode, feature, target)
%
%   Input:
%   *) nHiddenNode: Total hidden node of Single Layer Feedforward Neural Network (Range: 1 ... total training samples)
%   *) feature: Features used for training (Matrix Size: total training samples X total features)
%   *) target: Target of each sample (Matrix Size: total training samples X total classes)
%
%   Output:
%   *) inputWeight: input weight (Matrix Size: nHiddenNode (+1 for bias) X total features)
%   *) outputWeight: output weight (Matrix Size: total classes X nHiddenNode)
%   *) accuracy: accuracy for given input

    inputWeight = rand(nHiddenNode, size(feature, 2)+1);
    hiddenOutput = (inputWeight(:, 1:end-1) * feature')+repmat(inputWeight(:, end), 1, size(feature, 1)); % linear combination of hidden output
    hiddenOutput = sigmoid(hiddenOutput); % apply activation function on hidden output
    
    outputWeight = target' * pinv(hiddenOutput); % estimate output weight
    
    % calculating training accuracy
    predictedOutput = outputWeight * hiddenOutput; % linear combination of predicted output
    predictedOutput = sigmoid(predictedOutput); % apply activation function on predicted output
    
    maxPred = max(predictedOutput);
    predictedClass = zeros(size(predictedOutput, 2), 1);
    for i=1:size(predictedOutput, 2)
        class = find(predictedOutput(:, i) == maxPred(i));
        predictedClass(i) = class(1, 1);
    end
    accuracy = sum(predictedClass == vec2ind(target')')/size(predictedOutput, 2) * 100;
end