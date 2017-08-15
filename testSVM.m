function acc = testSVM(feature, target, SVMModels)
%Test Support Vector Machines (SVM) model using One VS One
%   Syntax:
%   acc = testSVM(feature, target, SVMModels)
%
%   Input:
%   *) feature   - feature collection (Matrix Size: total samples X total features)
%   *) target    - target of each sample (Matrix Size: total samples X 1)
%   *) SVMModels - SVM model collection, cell size of totalClass classifier
%
%   Output:
%   *) acc       - accuracy

    predicted = predict(SVMModels, feature);
    acc = sum(target == predicted) / length(target) * 100;
end