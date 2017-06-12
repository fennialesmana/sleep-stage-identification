function extractFeatures(all_data)
    % FEATURE EXTRACTION
    %{
    % FEATURE EXTRACTION using separated methods
    for i=1:size(all_data, 1)
        timeDomain = extractTimeDomainFeatures(all_data(i).rr);
        geometrical = extractGeometricalFeatures(all_data(i).rr);
        poincare = extractPoincareFeatures(timeDomain.SDSD, timeDomain.SDNN);
        features = struct('timeDomain', timeDomain, 'geometrical', geometrical, 'poincare', poincare);
        all_data(i).features = features;
    end
    %}
    
    [all_data.AVNN] = deal([]);
    [all_data.SDNN] = deal([]);
    [all_data.RMSSD] = deal([]);
    [all_data.SDSD] = deal([]);
    [all_data.NN50] = deal([]);
    [all_data.PNN50] = deal([]);

    [all_data.HRV_TRIANGULAR_IDX] = deal([]);

    [all_data.SD1] = deal([]);
    [all_data.SD2] = deal([]);
    [all_data.SD1_SD2_RATIO] = deal([]);
    [all_data.S] = deal([]);

    [all_data.pLF] = deal([]);
    [all_data.pHF] = deal([]);
    [all_data.LFHFratio] = deal([]);
    [all_data.VLF] = deal([]);
    [all_data.LF] = deal([]);
    [all_data.HF] = deal([]);

    % FEATURE EXTRACTION using class
    for i=1:size(all_data, 1)
        rr_diff = diff(all_data(i).rr);
        all_data(i).AVNN = HRVFeature.AVNN(all_data(i).rr);
        all_data(i).SDNN = HRVFeature.SDNN(all_data(i).rr);
        all_data(i).RMSSD = HRVFeature.RMSSD(rr_diff);
        all_data(i).SDSD = HRVFeature.SDSD(rr_diff);
        all_data(i).NN50 = HRVFeature.NNx(50, rr_diff);
        all_data(i).PNN50 = HRVFeature.PNNx(all_data(i).NN50, size(all_data(i).rr, 2));

        all_data(i).HRV_TRIANGULAR_IDX = HRVFeature.HRV_TRIANGULAR_IDX(all_data(i).rr);

        all_data(i).SD1 = HRVFeature.SD1(all_data(i).SDSD);
        all_data(i).SD2 = HRVFeature.SD2(all_data(i).SDNN, all_data(i).SDSD);
        all_data(i).SD1_SD2_RATIO = HRVFeature.SD1_SD2_RATIO(all_data(i).SD1, all_data(i).SD2);
        all_data(i).S = HRVFeature.S(all_data(i).SD1, all_data(i).SD2);

        [pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = HRVFeature.fft_val_fun(all_data(i).rr,2);
        all_data(i).pLF = pLF;
        all_data(i).pHF = pHF;
        all_data(i).LFHFratio = LFHFratio;
        all_data(i).VLF = VLF;
        all_data(i).LF = LF;
        all_data(i).HF = HF;
    end

    % move features to matrix
    nFeatures = 17;
    hrv = zeros(size(all_data, 1), nFeatures);
    target2 = zeros(size(all_data, 1), 1);
    target3 = zeros(size(all_data, 1), 1);
    target4 = zeros(size(all_data, 1), 1);
    target6 = zeros(size(all_data, 1), 1);
    for i=1:size(all_data, 1)
        hrv(i, 1) = all_data(i).AVNN;
        hrv(i, 2) = all_data(i).SDNN;
        hrv(i, 3) = all_data(i).RMSSD;
        hrv(i, 4) = all_data(i).SDSD;
        hrv(i, 5) = all_data(i).NN50;
        hrv(i, 6) = all_data(i).PNN50;

        hrv(i, 7) = all_data(i).HRV_TRIANGULAR_IDX;

        hrv(i, 8) = all_data(i).SD1;
        hrv(i, 9) = all_data(i).SD2;
        hrv(i, 10) = all_data(i).SD1_SD2_RATIO;
        hrv(i, 11) = all_data(i).S;

        hrv(i, 12) = all_data(i).pLF;
        hrv(i, 13) = all_data(i).pHF;
        hrv(i, 14) = all_data(i).LFHFratio;
        hrv(i, 15) = all_data(i).VLF;
        hrv(i, 16) = all_data(i).LF;
        hrv(i, 17) = all_data(i).HF;

        % class classification
        switch all_data(i).annotation
            case '1'
                target6(i) = 1;
                target4(i) = 1;
                target3(i) = 1;
                target2(i) = 1;
            case '2'
                target6(i) = 2;
                target4(i) = 1;
                target3(i) = 1;
                target2(i) = 1;
            case '3'
                target6(i) = 3;
                target4(i) = 2;
                target3(i) = 1;
                target2(i) = 1;
            case '4'
                target6(i) = 4;
                target4(i) = 2;
                target3(i) = 1;
                target2(i) = 1;
            case 'R'
                target6(i) = 5;
                target4(i) = 3;
                target3(i) = 2;
                target2(i) = 1;
            case 'W'
                target6(i) = 6;
                target4(i) = 4;
                target3(i) = 3;
                target2(i) = 2;
        end
    end
    
    hrv = normalizeData(hrv, -1, 1);
    
    features2class = [hrv target2];
    features3class = [hrv target3];
    features4class = [hrv target4];
    features6class = [hrv target6];
    save('features2class.mat', 'features2class');
    save('features3class.mat', 'features3class');
    save('features4class.mat', 'features4class');
    save('features6class.mat', 'features6class');
end