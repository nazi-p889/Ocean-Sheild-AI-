function plotDashboard(axCTI, axRisk, axMap, axXAI, S)
% PLOTDASHBOARD  Render the four GIS / analytics panels of OceanShield AI.
%
%   plotDashboard(axCTI, axRisk, axMap, axXAI, S)
%
%   ax* : uiaxes handles
%   S   : application state struct (data, CTI, CTI_peak, riskCat,
%         localContrib, featNames, cfg)

    N = numel(S.CTI);

    % ---------- Panel 1: CTI profile + forecast ----------
    cla(axCTI); hold(axCTI,'on');
    plot(axCTI, 1:N, S.CTI, '-o','LineWidth',2, ...
        'Color',[0.25 0.65 0.95],'MarkerFaceColor',[0.25 0.65 0.95]);
    plot(axCTI, 1:N, S.CTI_peak, '--','LineWidth',1.5, ...
        'Color',[1 0.40 0.40]);
    yline(axCTI, S.cfg.ctiThresholds(1), ':', 'Color',[0.20 0.80 0.40]);
    yline(axCTI, S.cfg.ctiThresholds(2), ':', 'Color',[1.00 0.75 0.20]);
    yline(axCTI, S.cfg.ctiThresholds(3), ':', 'Color',[0.90 0.20 0.20]);
    xlabel(axCTI,'Cable Segment ID');
    ylabel(axCTI,'Cable Threat Index (CTI)');
    legend(axCTI,{'Current CTI','24-h Peak','Low/Mod','Mod/High','High/Crit'}, ...
        'Location','best','TextColor',[0.9 0.9 0.9], ...
        'Color',[0.15 0.18 0.24],'EdgeColor',[0.4 0.45 0.55]);
    ylim(axCTI,[0 1]); grid(axCTI,'on'); hold(axCTI,'off');

    % ---------- Panel 2: risk category bar ----------
    cla(axRisk);
    cats = {'Low','Moderate','High','Critical'};
    counts = zeros(1,4);
    rc = string(S.riskCat);
    for k = 1:4
        counts(k) = sum(rc == cats{k});
    end
    b = bar(axRisk, counts, 0.6, 'FaceColor','flat');
    b.CData = [0.25 0.75 0.40; 0.95 0.80 0.25;
               0.95 0.50 0.20; 0.90 0.20 0.25];
    axRisk.XTick = 1:4;
    axRisk.XTickLabel = cats;
    ylabel(axRisk,'# Segments');
    grid(axRisk,'on');

    % ---------- Panel 3: GIS map ----------
    cla(axMap);
    scatter(axMap, S.data.cableLon, S.data.cableLat, 130, S.CTI, ...
        'filled','MarkerEdgeColor',[0.05 0.05 0.05]);
    hold(axMap,'on');
    plot(axMap, S.data.cableLon, S.data.cableLat, '-', ...
        'Color',[0.70 0.70 0.70],'LineWidth',0.8);
    hold(axMap,'off');
    try, colormap(axMap, turbo); catch, colormap(axMap, jet); end
    cb = colorbar(axMap);
    cb.Color = [0.9 0.9 0.9];
    cb.Label.String = 'CTI'; cb.Label.Color = [0.9 0.9 0.9];
    xlabel(axMap,'Longitude'); ylabel(axMap,'Latitude');
    axis(axMap,'equal'); grid(axMap,'on');

    % ---------- Panel 4: XAI heatmap ----------
    cla(axXAI);
    imagesc(axXAI, S.localContrib);
    axXAI.YDir = 'reverse';
    axXAI.XTick = 1:numel(S.featNames);
    axXAI.XTickLabel = S.featNames;
    axXAI.XTickLabelRotation = 30;
    xlabel(axXAI,'Feature'); ylabel(axXAI,'Segment');
    colormap(axXAI, parula);
    cb2 = colorbar(axXAI);
    cb2.Color = [0.9 0.9 0.9];
    cb2.Label.String = 'Attribution'; cb2.Label.Color = [0.9 0.9 0.9];
end