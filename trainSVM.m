function SVMModels = trainSVM(feature, target, kernel)
%Train Support Vector Machines (SVM) model using One Vs One
%   Syntax:
%   SVMModels = trainSVM(feature, target, kernel)
%
%   Input:
%   *) feature - feature collection (Matrix Size: total samples X total features)
%   *) target  - target of each sample (Matrix Size: total samples X 1)
%   *) kernel  - kernel used for SVM
%
%   Output:
%   *) SVMModels - SVM model collection, cell size of totalClass classifier

    if nargin == 2
        kernel = 'linear';
    end
    
    t = templateSVM('KernelFunction', kernel);
    SVMModels = fitcecoc(feature, target, 'Learners', t);
end