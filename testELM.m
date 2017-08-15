function testAcc = testELM(feature, target, ELMModel)
%Test Extreme Learning Machine (ELM) model
%   Syntax:
%   testAcc = testELM(feature, target, ELMModel)
%
%   Input:
%   *) feature  - feature collection
%      (Matrix size: total samples X total features)
%   *) target   - target of each sample
%      (Matrix size: total samples X total classes)
%      Example: class 4 -> target is [0 0 0 1]
%   *) ELMModel - ELMModel generated from trainELM() function
%
%   Output:
%   *) testAcc  - testing accuracy
    
    % linear combination of hidden output
    hiddenOutput = (ELMModel.inputWeight(:, 1:end-1) * feature')+ ...
        repmat(ELMModel.inputWeight(:, end), 1, size(feature, 1)); 
    % apply activation function on hidden output
    hiddenOutput = sigmoid(hiddenOutput);
    
    % linear combination of predicted output
    predictedOutput = ELMModel.outputWeight * hiddenOutput;
    % apply activation function on predicted output
    predictedOutput = sigmoid(predictedOutput);
    
    maxPred = max(predictedOutput);
    predictedClass = zeros(size(predictedOutput, 2), 1);
    for i=1:size(predictedOutput, 2)
        class = find(predictedOutput(:, i) == maxPred(i));
        predictedClass(i) = class(1, 1);
    end
    testAcc = sum(predictedClass == vec2ind(target')')/ ...
        size(predictedOutput, 2) * 100;    
end