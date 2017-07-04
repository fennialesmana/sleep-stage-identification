function acc = testSVM(feature, target, SVMModel)
    className = unique(target);
    nClass = length(className);
    predicted = zeros(size(target));
    for i=1:size(feature, 1)
        for k=1:nClass
            if(predict(SVMModel{k},feature(i,:))) 
                break;
            end
        end
        predicted(i) = k;
    end
    
    acc = sum(target == predicted) / length(target) * 100;
end