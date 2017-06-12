function elmModel = testELM(elmModel, feature, target)
    % calculating testing accuracy
    hiddenOutput = (elmModel.inputWeight(:, 1:end-1) * feature')+repmat(elmModel.inputWeight(:, end), 1, size(feature, 1)); % linear combination of hidden output
    hiddenOutput = sigmoid(hiddenOutput); % apply activation function on hidden output
    
    predictedOutput = elmModel.outputWeight * hiddenOutput; % linear combination of predicted output
    predictedOutput = sigmoid(predictedOutput); % apply activation function on predicted output
    
    maxPred = max(predictedOutput);
    predictedClass = zeros(size(predictedOutput, 2), 1);
    for i=1:size(predictedOutput, 2)
        class = find(predictedOutput(:, i) == maxPred(i));
        predictedClass(i) = class(1, 1);
    end
    elmModel.testingAccuracy = sum(predictedClass == vec2ind(target')')/size(predictedOutput, 2) * 100;    

end