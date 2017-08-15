function testAcc = testELM(feature, target, ELMModel)
%Test Extreme Learning Machine (ELM) model
%   Syntax:
%   testAcc = testELM(feature, target, ELMModel)
%
%   Input:
%   *) feature  - feature collection (Matrix Size: total samples X total features)
%   *) target   - target of each sample (Matrix Size: total samples X total classes). Example: class 4 -> target is [0 0 0 1].
%   *) ELMModel - ELMModel generated from trainELM() function
%
%   Output:
%   *) testAcc  - testing accuracy

    hiddenOutput = (ELMModel.inputWeight(:, 1:end-1) * feature')+repmat(ELMModel.inputWeight(:, end), 1, size(feature, 1)); % linear combination of hidden output
    hiddenOutput = sigmoid(hiddenOutput); % apply activation function on hidden output
    
    predictedOutput = ELMModel.outputWeight * hiddenOutput; % linear combination of predicted output
    predictedOutput = sigmoid(predictedOutput); % apply activation function on predicted output
    
    maxPred = max(predictedOutput);
    predictedClass = zeros(size(predictedOutput, 2), 1);
    for i=1:size(predictedOutput, 2)
        class = find(predictedOutput(:, i) == maxPred(i));
        predictedClass(i) = class(1, 1);
    end
    testAcc = sum(predictedClass == vec2ind(target')')/size(predictedOutput, 2) * 100;    
end