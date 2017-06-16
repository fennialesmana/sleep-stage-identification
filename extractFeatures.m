function extractFeatures(data, nFeatures, destination, outputFormat)
    % FEATURE EXTRACTION
    %{
    % prepare the struct
    [data.AVNN] = deal([]);
    [data.SDNN] = deal([]);
    [data.RMSSD] = deal([]);
    [data.SDSD] = deal([]);
    [data.NN50] = deal([]);
    [data.PNN50] = deal([]);

    [data.HRV_TRIANGULAR_IDX] = deal([]);

    [data.SD1] = deal([]);
    [data.SD2] = deal([]);
    [data.SD1_SD2_RATIO] = deal([]);
    [data.S] = deal([]);

    [data.pLF] = deal([]);
    [data.pHF] = deal([]);
    [data.LFHFratio] = deal([]);
    [data.VLF] = deal([]);
    [data.LF] = deal([]);
    [data.HF] = deal([]);
    %}
    
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
    
    % FEATURE EXTRACTION using class
    %{
    % ada simpan ke struct lagi
    for i=1:size(data, 1)
        rr_diff = diff(data(i).rr);
        data(i).AVNN = HRVFeature.AVNN(data(i).rr);
        data(i).SDNN = HRVFeature.SDNN(data(i).rr);
        data(i).RMSSD = HRVFeature.RMSSD(rr_diff);
        data(i).SDSD = HRVFeature.SDSD(rr_diff);
        data(i).NN50 = HRVFeature.NNx(50, rr_diff);
        data(i).PNN50 = HRVFeature.PNNx(data(i).NN50, size(data(i).rr, 2));

        data(i).HRV_TRIANGULAR_IDX = HRVFeature.HRV_TRIANGULAR_IDX(data(i).rr);

        data(i).SD1 = HRVFeature.SD1(data(i).SDSD);
        data(i).SD2 = HRVFeature.SD2(data(i).SDNN, data(i).SDSD);
        data(i).SD1_SD2_RATIO = HRVFeature.SD1_SD2_RATIO(data(i).SD1, data(i).SD2);
        data(i).S = HRVFeature.S(data(i).SD1, data(i).SD2);

        [pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = HRVFeature.fft_val_fun(data(i).rr,2);
        data(i).pLF = pLF;
        data(i).pHF = pHF;
        data(i).LFHFratio = LFHFratio;
        data(i).VLF = VLF;
        data(i).LF = LF;
        data(i).HF = HF;
    end
    
    % move features to matrix
    hrv = zeros(size(data, 1), nFeatures);
    target2 = zeros(size(data, 1), 1);
    target3 = zeros(size(data, 1), 1);
    target4 = zeros(size(data, 1), 1);
    target6 = zeros(size(data, 1), 1);
    for i=1:size(data, 1)
        hrv(i, 1) = data(i).AVNN;
        hrv(i, 2) = data(i).SDNN;
        hrv(i, 3) = data(i).RMSSD;
        hrv(i, 4) = data(i).SDSD;
        hrv(i, 5) = data(i).NN50;
        hrv(i, 6) = data(i).PNN50;

        hrv(i, 7) = data(i).HRV_TRIANGULAR_IDX;

        hrv(i, 8) = data(i).SD1;
        hrv(i, 9) = data(i).SD2;
        hrv(i, 10) = data(i).SD1_SD2_RATIO;
        hrv(i, 11) = data(i).S;

        hrv(i, 12) = data(i).pLF;
        hrv(i, 13) = data(i).pHF;
        hrv(i, 14) = data(i).LFHFratio;
        hrv(i, 15) = data(i).VLF;
        hrv(i, 16) = data(i).LF;
        hrv(i, 17) = data(i).HF;

        % class classification
        switch data(i).annotation
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
    %}
    
    % directly save the features into .xls
    nSamples = size(data, 1);
    hrv = zeros(nSamples, nFeatures);
    target2 = zeros(nSamples, 1);
    target3 = zeros(nSamples, 1);
    target4 = zeros(nSamples, 1);
    target6 = zeros(nSamples, 1);
    for i=1:nSamples
        rr_diff = diff(data(i).rr);
        hrv(i, 1) = HRVFeature.AVNN(data(i).rr);
        hrv(i, 2) = HRVFeature.SDNN(data(i).rr);
        hrv(i, 3) = HRVFeature.RMSSD(rr_diff);
        hrv(i, 4) = HRVFeature.SDSD(rr_diff);
        hrv(i, 5) = HRVFeature.NNx(50, rr_diff);
        hrv(i, 6) = HRVFeature.PNNx(hrv(i, 5), size(data(i).rr, 2));

        hrv(i, 7) = HRVFeature.HRV_TRIANGULAR_IDX(data(i).rr);

        hrv(i, 8) = HRVFeature.SD1(hrv(i, 4));
        hrv(i, 9) = HRVFeature.SD2(hrv(i, 2), hrv(i, 4));
        hrv(i, 10) = HRVFeature.SD1_SD2_RATIO(hrv(i, 8), hrv(i, 9));
        hrv(i, 11) = HRVFeature.S(hrv(i, 8), hrv(i, 9));

        [pLF,pHF,LFHFratio,VLF,LF,HF,f,Y,NFFT] = HRVFeature.fft_val_fun(data(i).rr,2);
        hrv(i, 12) = pLF;
        hrv(i, 13) = pHF;
        hrv(i, 14) = LFHFratio;
        hrv(i, 15) = VLF;
        hrv(i, 16) = LF;
        hrv(i, 17) = HF;
        
        % set class annotation
        switch data(i).annotation
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
    
    % save data before normalization
    unnormalized_hrv = [hrv target6];
    switch outputFormat
        case 'xlsx'
            xlswrite(strcat(destination, 'unnormalized_hrv.xlsx'), unnormalized_hrv)
        case 'mat'
            save(strcat(destination, 'unnormalized_hrv.mat'), 'unnormalized_hrv');
        case 'all'
            xlswrite(strcat(destination, 'unnormalized_hrv.xlsx'), unnormalized_hrv)
            save(strcat(destination, 'unnormalized_hrv.mat'), 'unnormalized_hrv');
    end
    
    %save data after normalization
    normalized_hrv = normalizeData(hrv, -1, 1);
    normalized_hrv_2_class = [normalized_hrv target2];
    normalized_hrv_3_class = [normalized_hrv target3];
    normalized_hrv_4_class = [normalized_hrv target4];
    normalized_hrv_6_class = [normalized_hrv target6];
    switch outputFormat
        case 'xlsx'
            xlswrite(strcat(destination, 'normalized_hrv_2_class.xlsx'), normalized_hrv_2_class)
            xlswrite(strcat(destination, 'normalized_hrv_3_class.xlsx'), normalized_hrv_3_class)
            xlswrite(strcat(destination, 'normalized_hrv_4_class.xlsx'), normalized_hrv_4_class)
            xlswrite(strcat(destination, 'normalized_hrv_6_class.xlsx'), normalized_hrv_6_class)
        case 'mat'
            save(strcat(destination, 'normalized_hrv_2_class.mat'), 'normalized_hrv_2_class');
            save(strcat(destination, 'normalized_hrv_3_class.mat'), 'normalized_hrv_3_class');
            save(strcat(destination, 'normalized_hrv_4_class.mat'), 'normalized_hrv_4_class');
            save(strcat(destination, 'normalized_hrv_6_class.mat'), 'normalized_hrv_6_class');
        case 'all'
            xlswrite(strcat(destination, 'normalized_hrv_2_class.xlsx'), normalized_hrv_2_class)
            xlswrite(strcat(destination, 'normalized_hrv_3_class.xlsx'), normalized_hrv_3_class)
            xlswrite(strcat(destination, 'normalized_hrv_4_class.xlsx'), normalized_hrv_4_class)
            xlswrite(strcat(destination, 'normalized_hrv_6_class.xlsx'), normalized_hrv_6_class)
            save(strcat(destination, 'normalized_hrv_2_class.mat'), 'normalized_hrv_2_class');
            save(strcat(destination, 'normalized_hrv_3_class.mat'), 'normalized_hrv_3_class');
            save(strcat(destination, 'normalized_hrv_4_class.mat'), 'normalized_hrv_4_class');
            save(strcat(destination, 'normalized_hrv_6_class.mat'), 'normalized_hrv_6_class');
    end
    
end