clear; clc; close all;

%{
% IMPORT AND SYNCHRONIZE ALL DATA
file_names = {'slp01a', 'slp01b', 'slp02a', 'slp02b', 'slp03', 'slp04', 'slp14', 'slp16', 'slp32', 'slp37', 'slp41', 'slp45', 'slp48', 'slp59', 'slp60', 'slp61', 'slp66', 'slp67x'};
sec_per_epoch = 30;
all_data = [];
data = [];

for i=1:size(file_names, 2)
    fprintf('\n\n%s importing...\n', cell2mat(file_names(i)));
    data = import_data(file_names(i), sec_per_epoch);
    all_data = [all_data;data];
end

save('all_data', 'all_data');
%}

load('all_data');

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