clear;clc;
% x = hrv_features_norm(1:5000, 4);
% y = hrv_features_norm(1:5000, 16);
% z = hrv_features_norm(1:5000, 18);
% s = target(1:5000, 2).*10;
% c = target(1:5000, 2).*100;
% scatter3(x,y,z,s,c);

%{
load('fisheriris')
x = meas;
y = zeros(size(species));
for i=1:size(species, 1)
    if strcmp(species(i), 'setosa') == 1
        y(i, 1) = 1;
    elseif strcmp(species(i), 'versicolor') == 1
        y(i, 1) = 2;
    elseif strcmp(species(i), 'virginica') == 1
        y(i, 1) = 3;
    end
end
Model = svmtrain(x, y);
%SVMModel = fitcsvm(x, y, 'KernelFunction', 'rbf');
%}


%% SVM Multiclass Example 
% SVM is inherently one vs one classification. 
% This is an example of how to implement multiclassification using the 
% one vs all approach. 
% TrainingSet=[ 1 10;2 20;3 30;4 40;5 50;6 66;3 30;4.1 42]; 
% TestSet=[3 34; 1 14; 2.2 25; 6.2 63]; 
% GroupTrain=[1;1;2;2;3;3;2;2]; 
%[res1, res2] = multisvm(TrainingSet, GroupTrain, TestSet); 
nClasses = 2;

totalData = 599;
totalData = 10154;
hrv = load('thesis/features/hrv_features_norm.mat');
hrv = hrv.hrv_features_norm;
hrv = hrv(1:totalData, :);

target = load('thesis/features/target.mat');
target = target.target;
target = target(1:totalData, nClasses);

nTrainSample = ceil(totalData*0.7);

TrainingSet = [hrv(1:nTrainSample, :) target(1:nTrainSample, :)];
TestSet = [hrv(nTrainSample+1:end, :) target(nTrainSample+1:end, :)];

SVMModel = trainSVM(TrainingSet(:, 1:end-1), TrainingSet(:, end), 'RBF');
testAcc = testSVM(TestSet(:, 1:end-1), TestSet(:, end), SVMModel);
trainAcc = testSVM(TrainingSet(:, 1:end-1), TrainingSet(:, end), SVMModel);
disp(testAcc);