function fitnessValue = fitness(Wa, Wf, acc, featureMask)
%Calculate fitness value of PSO
%   Syntax:
%   fitnessValue = fitness(Wa, Wf, acc, featureMask)
%
%   Input:
%   *) Wa           - weight for accuracy
%   *) Wf           - weight for number of features
%   *) acc          - accuracy of evaluated model
%   *) featureMask  - logical of 1 X total bits
%
%   Output:
%   *) fitnessValue    - fitness value result

    fitnessValue = Wa * acc + Wf * (1 - (sum(featureMask)/...
        length(featureMask)));
end