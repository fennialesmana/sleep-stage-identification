function extractfeatures(SlpdbData, destination, outputFormat)
    % directly save the features
    nSamples = size(SlpdbData, 1);
    nClasses = length(unique([SlpdbData.annotation]));
    hrv = zeros(nSamples, 25);
    target = zeros(nSamples, nClasses);
    target(:, [1 5]) = NaN;
    for i=1:nSamples
        rr_diff = diff(SlpdbData(i).rr);
        hrv(i, 1) = HRVFeature.AVNN(SlpdbData(i).rr);
        hrv(i, 2) = HRVFeature.SDNN(SlpdbData(i).rr);
        hrv(i, 3) = HRVFeature.RMSSD(rr_diff);
        hrv(i, 4) = HRVFeature.SDSD(rr_diff);
        hrv(i, 5) = HRVFeature.NNx(50, rr_diff);
        hrv(i, 6) = HRVFeature.PNNx(hrv(i, 5), size(SlpdbData(i).rr, 2));

        hrv(i, 7) = HRVFeature.HRV_TRIANGULAR_IDX(SlpdbData(i).rr);

        hrv(i, 8) = HRVFeature.SD1(hrv(i, 4));
        hrv(i, 9) = HRVFeature.SD2(hrv(i, 2), hrv(i, 4));
        hrv(i, 10) = HRVFeature.SD1_SD2_RATIO(hrv(i, 8), hrv(i, 9));
        hrv(i, 11) = HRVFeature.S(hrv(i, 8), hrv(i, 9));

        [TP,pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = ...
            HRVFeature.fft_val_fun(SlpdbData(i).rr,2);
        hrv(i, 12) = TP;
        hrv(i, 13) = pLF;
        hrv(i, 14) = pHF;
        hrv(i, 15) = LFHFratio;
        hrv(i, 16) = VLF;
        hrv(i, 17) = LF;
        hrv(i, 18) = HF;
        
        % set class annotation
        switch SlpdbData(i).annotation
            case '1'
                target(i,6) = 1;
                target(i,4) = 1;
                target(i,3) = 1;
                target(i,2) = 1;
            case '2'
                target(i,6) = 2;
                target(i,4) = 1;
                target(i,3) = 1;
                target(i,2) = 1;
            case '3'
                target(i,6) = 3;
                target(i,4) = 2;
                target(i,3) = 1;
                target(i,2) = 1;
            case '4'
                target(i,6) = 4;
                target(i,4) = 2;
                target(i,3) = 1;
                target(i,2) = 1;
            case 'R'
                target(i,6) = 5;
                target(i,4) = 3;
                target(i,3) = 2;
                target(i,2) = 1;
            case 'W'
                target(i,6) = 6;
                target(i,4) = 4;
                target(i,3) = 3;
                target(i,2) = 2;
            otherwise
                fprintf('Invalid Annotation');
                return
        end
    end
    
    hrv( :, ~any(hrv,1) ) = [];
    
    % create new dir if not exists
    dirList = dir;
    isDirExists = 0;
    for i=1:length(dir)
        if dirList(i).isdir && strcmp(dirList(i).name, destination)
            isDirExists = 1;
        end
    end
    
    if ~isDirExists
        mkdir(destination);
    end
    
    % save data into destination
    hrv_features_unorm = hrv;
    hrv_features_norm = normalizedata(hrv, -1, 1);
    if strcmp(outputFormat, 'xlsx') || strcmp(outputFormat, 'all')
        xlswrite(strcat(destination, 'hrv_features_unorm.xlsx'), hrv_features_unorm);
        xlswrite(strcat(destination, 'hrv_features_norm.xlsx'), hrv_features_norm);
        xlswrite(strcat(destination, 'target.xlsx'), target);
    end
    if strcmp(outputFormat, 'mat') || strcmp(outputFormat, 'all')
        save(strcat(destination, 'hrv_features_unorm.mat'), 'hrv_features_unorm');
        save(strcat(destination, 'hrv_features_norm.mat'), 'hrv_features_norm');
        save(strcat(destination, 'target.mat'), 'target');
    end
    
end