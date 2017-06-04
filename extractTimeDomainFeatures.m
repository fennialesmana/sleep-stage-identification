function output = extractTimeDomainFeatures(rr)
    rr_diff = diff(rr);
    output.AVNN = mean(rr);
    output.SDNN = std(rr);
    output.RMSSD = sqrt(sum((rr_diff.^2))/size(rr_diff, 2));
    output.SDSD = std(rr_diff);
    output.NN50 = sum((rr_diff*1000)>50);
    output.PNN50 = (output.NN50/(size(rr, 2)-1))*100;
end