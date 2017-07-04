function SVMModel = trainSVM(feature, target, kernel)
    if nargin == 2
        kernel = 'linear';
    end
    className = unique(target);
    nClass = length(className);
    SVMModel = cell(nClass,1);
    
    for i=1:nClass
        label = (target==className(i));
        SVMModel{i} = fitcsvm(feature,label, 'KernelFunction', kernel, 'Standardize', true);
    end
end