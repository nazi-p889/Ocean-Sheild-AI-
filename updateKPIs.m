function updateKPIs(kpi, S)
% UPDATEKPIS  Refresh the four KPI labels at the bottom of the dashboard.
%
%   updateKPIs(kpi, S)
%
%   kpi : 1×4 array of uilabel handles
%   S   : application state struct

    kpi(1).Text = sprintf('%.3f', mean(S.CTI));
    kpi(2).Text = sprintf('%.3f', max(S.CTI));
    kpi(3).Text = sprintf('%d', sum(string(S.riskCat) == "Critical"));
    kpi(4).Text = sprintf('%.3f', max(S.CTI_peak));

    peak = max(S.CTI_peak);
    if peak >= S.cfg.ctiThresholds(3)
        kpi(4).FontColor = [1.00 0.35 0.35];
    elseif peak >= S.cfg.ctiThresholds(2)
        kpi(4).FontColor = [1.00 0.75 0.25];
    else
        kpi(4).FontColor = [0.30 0.90 0.60];
    end
end