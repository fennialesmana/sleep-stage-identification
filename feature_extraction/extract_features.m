function features = extract_features(rr)
%rr = [0.508 0.752 0.72 0.728 0.76 0.772 0.8 0.788 0.78 0.74 0.732 0.72 0.74 0.728 0.752 0.82 0.76 0.78 0.82 0.888 1.2 1.06 0.98 0.8 0.72 0.692 0.688 0.66 0.68 1.232 1.028 0.84 0.732 0.708 0.712 0.76 0.88 1.188 0.992 0.888 0.78 0.74 0.752 0.748 0.7 0.7 0.672 0.76 1.268 1.112 1.02 0.888 0.78 0.736 0.748 0.824 0.888 0.828 0.796 0.772 0.76 0.76 0.752 0.756 0.776 0.772 0.756 0.74 0.704 0.68 0.668 0.692 0.756 0.772];
%a = [508 752 720 728 760 772 800 788 780 740 732 720 740 728 752 820 760 780 820 888 1200 1060 980 800 720 692 688 660 680 1232 1028 840 732 708 712 760 880 1188];
rr = rr';
features = zeros(1, 11);

features(1, 1) = avnn(rr);
features(1, 2) = sdnn(rr);
rr_diff = get_rr_diff(rr);
features(1, 3) = rmssd(rr_diff);
features(1, 4) = sdsd(rr);
features(1, 5) = nn50(rr_diff);
features(1, 6) = pnn50(size(rr, 1), features(1, 5));

features(1, 7) = sd1(features(1, 4));
features(1, 8) = sd2(features(1, 4), features(1, 2));
features(1, 9) = sd1_sd2_ratio(features(1, 7), features(1, 8));
features(1, 10) = area_of_ellipse(features(1, 7), features(1, 8));

features(1, 11) = hrv_triangular_index(rr);
end