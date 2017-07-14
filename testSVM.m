function acc = testSVM(feature, target, SVMModels)
%Test Support Vector Machines (SVM) model using One VS All
%   Syntax:
%   acc = testSVM(feature, target, SVMModels)
%
%   Input:
%   *) feature: Features used for training (Matrix Size: total training samples X total features)
%   *) target: Target of each sample (Matrix Size: total training samples X 1)
%   *) SVMModels: SVM model collection, cell size of totalClass classifier
%
%   Output:
%   *) acc: accuracy

%{
    nClasses = length(SVMModels);
    predicted = zeros(size(target));
    for i=1:size(feature, 1)
        for k=1:nClasses
            if predict(SVMModels{k},feature(i,:))
                break;
            end
        end
        predicted(i) = k;
    end
    
    acc = sum(target == predicted) / length(target) * 100;
%}

    predicted = predict(SVMModels, feature);
    acc = sum(target == predicted) / length(target) * 100;
end