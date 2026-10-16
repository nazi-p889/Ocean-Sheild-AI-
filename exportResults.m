function T = exportResults(S, filePath)
% EXPORTRESULTS  Write CTI + risk results to CSV for GIS ingestion.
%
%   T = exportResults(S, filePath)
%
%   S        : application state struct
%   filePath : full path of the output CSV
%
%   Returns the table T that was written.

    N = numel(S.CTI);
    T = table((1:N)', S.data.cableLon, S.data.cableLat, ...
              S.CTI, S.CTI_peak, string(S.riskCat), ...
        'VariableNames',{'SegmentID','Lon','Lat','CTI','CTI_Peak','RiskCategory'});

    writetable(T, filePath);
end