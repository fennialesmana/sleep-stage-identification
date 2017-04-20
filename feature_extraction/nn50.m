function output = nn50(rr_diff)
    output = sum((rr_diff*1000)>50);
end