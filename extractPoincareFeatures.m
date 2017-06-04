function output = extractPoincareFeatures(sdsd, sdnn)
    output.SD1 = (sdsd^2)/2;
    output.SD2 = 2*(sdnn^2)-(sdsd^2)/2;
    output.SD1_SD2_RATIO = output.SD1/output.SD2;
    output.S = pi*output.SD1*output.SD2;
end