function [ HEP ] = setRPeak2LocMax(HEP)
%setRPeakToLocMax Loops over marked R Peaks and corrects them to be the
%local maximum in the array RP+/- 200 samples.

% 2019: eioe

for i=1:length(HEP.qrs)
    RP = HEP.qrs(i);
    dat = HEP.ecg(RP-200:RP+200,1);
    [~, idx] = max(dat);
    disp(idx);
    HEP.qrs(i) = HEP.qrs(i) - 201 + idx;
end


end

