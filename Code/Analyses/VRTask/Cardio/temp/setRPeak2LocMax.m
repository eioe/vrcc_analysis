function [ HEP ] = setRPeak2LocMax(HEP, winsize)
%setRPeakToLocMax Loops over marked R Peaks and corrects them to be the
%local maximum in the array RP+/- 200 samples.

% 2019: eioe

for i=1:length(HEP.qrs)
    RP = HEP.qrs(i);
    if RP < winsize
        dat = HEP.ecg(1:RP+winsize, 1);
    elseif RP + winsize > length(HEP.ecg)
        dat = HEP.ecg(RP-winsize:end);
    else
        dat = HEP.ecg(RP-winsize:RP+winsize,1);
    end
    [~, idx] = max(dat);
    HEP.qrs(i) = HEP.qrs(i) - winsize + idx - 1;
end


end

