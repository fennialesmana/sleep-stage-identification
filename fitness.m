function fitnessValue = fitness(Wa, Wf, acc, featureMask)
    fitnessValue = Wa * acc + Wf * (1 - (sum(featureMask)/size(featureMask, 2)));
end