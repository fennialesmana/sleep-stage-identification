function acc = testSVM(feature, target, SVMModels)
    nClasses = length(SVMModels{1}.ClassNames);
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
end