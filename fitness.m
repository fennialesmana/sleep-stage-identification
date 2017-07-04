function fitnessValue = fitness(Wa, Wf, acc, featureMask)
    fitnessValue = Wa * acc + Wf * (1 - (sum(featureMask)/length(featureMask)));
end