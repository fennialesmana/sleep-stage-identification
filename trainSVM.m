function SVMModels = trainSVM(feature, target, kernel)
%Train Support Vector Machines (SVM) model using One VS All
%   Syntax:
%   SVMModel = trainSVM(feature, target, kernel)
%
%   Input:
%   *) feature: Features used for training (Matrix Size: total training samples X total features)
%   *) target: Target of each sample (Matrix Size: total training samples X 1)
%   *) kernel: kernel used for SVM
%
%   Output:
%   *) SVMModels: SVM model collection, cell size of totalClass classifier
    if nargin == 2
        kernel = 'linear';
    end
    
    %{
    className = unique(target);
    nClasses = length(className);
    SVMModels = cell(nClasses,1);
    
    for i=1:nClasses
        label = (target==className(i));
        SVMModels{i} = fitcsvm(feature, label, 'KernelFunction', kernel, 'Standardize', true);
    end
    %}
    
    t = templateSVM('KernelFunction', kernel);
    SVMModels = fitcecoc(feature, target, 'Learners', t);
end