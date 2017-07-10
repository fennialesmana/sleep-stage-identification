clear;clc;
fileNames = {'slp01a' 'slp01b' 'slp02a' 'slp02b' 'slp03' 'slp04' ...
            'slp14' 'slp16' 'slp32' 'slp37' 'slp41' 'slp45' 'slp48' ...
            'slp59' 'slp60' 'slp61' 'slp66' 'slp67x'};
classNum = [2 3 4 6];

problem = [1 2 3 5 6 8 9 12 15 16 17]';
%firstCol = [4 4 3 6 3 6 6 2 2 2 3]';
firstCol = [3 3 2 4 2 4 4 1 1 1 2]';
firstExp = [12 19 10 18 25 22 8 11 4 25 10]';
%secondCol = [6 0 4 0 6 0 0 3 0 0 0]';
secondCol = [4 0 3 0 4 0 0 2 0 0 0]';
secondExp = [19 0 8 0 12 0 0 19 0 0 0]';
nIterations = 100;
for iProb=10:11%length(problem)
    path = sprintf('PSOELM_result/PSOELM_%s_result.mat', fileNames{problem(iProb)});
    AllClassesResult = loadmatobject(path, 1);
	
    fprintf('save for %s data, %d class, %d-th experiment\n', fileNames{problem(iProb)}, classNum(firstCol(iProb)), firstExp(iProb));
    gBest = zeros();
    for iItr=1:nIterations
        gBest(iItr) = AllClassesResult(firstCol(iProb)).experimentResult(firstExp(iProb)).iteration(iItr).gBest.fitness;
    end

    % save graphics
    f = figure;
    plot(1:nIterations, gBest);
    ylabel('gBest Fitness'); xlabel('Iteration');
    title(sprintf('[PSOELM] Best Experiment of %s (%d classes)', fileNames{problem(iProb)}, classNum(firstCol(iProb))));
    saveas(f, sprintf('temp/[PSOELM] gBest of %s (%d classes).png', fileNames{problem(iProb)}, classNum(firstCol(iProb))));
    close all;

    if secondCol(iProb) ~= 0
        fprintf('save for %s data, %d class, %d-th experiment\n', fileNames{problem(iProb)}, classNum(secondCol(iProb)), secondExp(iProb));
        gBest = zeros();
        for iItr=1:nIterations
            gBest(iItr) = AllClassesResult(secondCol(iProb)).experimentResult(secondExp(iProb)).iteration(iItr).gBest.fitness;
        end

        % save graphics
        f = figure;
        plot(1:nIterations, gBest);
        ylabel('gBest Fitness'); xlabel('Iteration');
        title(sprintf('[PSOELM] Best Experiment of %s (%d classes)', fileNames{problem(iProb)}, classNum(secondCol(iProb))));
        saveas(f, sprintf('temp/[PSOELM] gBest of %s (%d classes).png', fileNames{problem(iProb)}, classNum(secondCol(iProb))));
        close all;
    end
    
end