function OceanShieldAI_GUI
% OCEANSHIELD_GUI  Modern MATLAB GUI for PRISM Predictive Risk Assessment
% of submarine fiber-optic cables (Cable Threat Index - CTI).
%
% Usage:  >> OceanShieldAI_GUI
%
% Requires: MATLAB R2020b or newer (uifigure / uigridlayout / uiaxes)

    %% ---------------- GLOBAL STATE ----------------
    S = struct();
    S.cfg = struct( ...
        'segmentLengthKm', 50, ...
        'numSegments',     40, ...
        'weights', struct( ...
            'ship',       0.30, ...
            'current',    0.15, ...
            'seismic',    0.25, ...
            'bathymetry', 0.10, ...
            'meteo',      0.10, ...
            'cableAge',   0.10), ...
        'ctiThresholds', [0.25 0.50 0.75]);

    S.data       = [];
    S.CTI        = [];
    S.CTI_pred   = [];
    S.CTI_peak   = [];
    S.riskCat    = [];
    S.localContrib = [];
    S.featNames  = {'Ship/AIS','Current','Seismic','Bathymetry','Meteo','CableAge'};

    %% ---------------- MAIN FIGURE ----------------
    fig = uifigure('Name','OceanShield AI — PRISM Predictive Risk Dashboard', ...
        'Position',[80 60 1400 850], 'Color',[0.10 0.12 0.16]);

    mainGrid = uigridlayout(fig, [3 1]);
    mainGrid.RowHeight   = {60, '1x', 160};
    mainGrid.ColumnWidth = {'1x'};
    mainGrid.Padding     = [10 10 10 10];
    mainGrid.RowSpacing  = 8;

    %% ---------------- HEADER ----------------
    hdr = uipanel(mainGrid, 'BackgroundColor',[0.13 0.17 0.24], ...
        'BorderType','none');
    hdrGrid = uigridlayout(hdr, [1 3]);
    hdrGrid.ColumnWidth = {'1x', 220, 220};
    hdrGrid.Padding = [15 5 15 5];

    uilabel(hdrGrid, 'Text','🌊  OceanShield AI  •  PRISM Risk Dashboard', ...
        'FontSize',20, 'FontWeight','bold', ...
        'FontColor',[0.85 0.92 1]);

    btnRun = uibutton(hdrGrid, 'Text','▶  Run Assessment', ...
        'BackgroundColor',[0.20 0.65 0.40], ...
        'FontColor','w', 'FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) runAssessment());

    btnExport = uibutton(hdrGrid, 'Text','💾  Export CSV', ...
        'BackgroundColor',[0.20 0.45 0.75], ...
        'FontColor','w', 'FontWeight','bold', ...
        'ButtonPushedFcn', @(~,~) exportCSV());

    %% ---------------- MIDDLE: 2×2 PLOT GRID ----------------
    midPanel = uipanel(mainGrid, 'BackgroundColor',[0.10 0.12 0.16], ...
        'BorderType','none');
    midGrid = uigridlayout(midPanel, [2 2]);
    midGrid.RowHeight   = {'1x','1x'};
    midGrid.ColumnWidth = {'1x','1x'};
    midGrid.Padding     = [0 0 0 0];
    midGrid.RowSpacing  = 8;
    midGrid.ColumnSpacing = 8;

    axCTI   = uiaxes(midGrid); styleAxes(axCTI,   'CTI Profile & 24-h Predictive Peak');
    axRisk  = uiaxes(midGrid); styleAxes(axRisk,  'Risk Category Distribution');
    axMap   = uiaxes(midGrid); styleAxes(axMap,   'GIS View — Segments Coloured by CTI');
    axXAI   = uiaxes(midGrid); styleAxes(axXAI,   'XAI — Local Feature Attribution');

    %% ---------------- BOTTOM: STATUS + KPI ----------------
    botPanel = uipanel(mainGrid, 'BackgroundColor',[0.13 0.17 0.24], ...
        'BorderType','none');
    botGrid = uigridlayout(botPanel, [2 4]);
    botGrid.RowHeight   = {30, '1x'};
    botGrid.ColumnWidth = {'1x','1x','1x','1x'};
    botGrid.Padding     = [15 10 15 10];

    kpiTitles = {'Mean CTI','Peak CTI','Critical Segments','Max 24-h Forecast'};
    kpiVals   = gobjects(1,4);
    for k = 1:4
        uilabel(botGrid, 'Text', kpiTitles{k}, ...
            'FontColor',[0.65 0.75 0.90], ...
            'FontWeight','bold', 'HorizontalAlignment','center');
    end
    for k = 1:4
        kpiVals(k) = uilabel(botGrid, 'Text','—', ...
            'FontSize',22, 'FontWeight','bold', ...
            'FontColor',[0.30 0.90 0.60], ...
            'HorizontalAlignment','center');
    end

    %% ---------------- AUTO-RUN ON START ----------------
    runAssessment();

    %% ================================================================
    %  CALLBACKS
    % ================================================================
    function runAssessment()
        dlg = uiprogressdlg(fig, 'Title','PRISM Engine', ...
            'Message','Synthesising input feeds...', 'Indeterminate','on');
        drawnow;

        try
            dlg.Message = 'Generating AIS / met-ocean / seismic fields...';
            drawnow;
            generateData();

            dlg.Message = 'Computing Cable Threat Index...';
            drawnow;
            computeCTI();

            dlg.Message = 'Running 24-h predictive forecast...';
            drawnow;
            forecastCTI();

            dlg.Message = 'Computing XAI attributions...';
            drawnow;
            computeXAI();

            dlg.Message = 'Rendering dashboard...';
            drawnow;
            renderPlots();
            updateKPIs();

            dlg.Message = 'Done.';
            pause(0.4);
            close(dlg);
        catch ME
            close(dlg);
            uialert(fig, ME.message, 'PRISM Error');
            rethrow(ME);
        end
    end

    function exportCSV()
        if isempty(S.CTI)
            uialert(fig,'Run the assessment first.','No data'); return;
        end
        [f, p] = uiputfile('OceanShield_CTI_Results.csv','Save results');
        if isequal(f,0), return; end
        N = numel(S.CTI);
        T = table((1:N)', S.data.cableLon, S.data.cableLat, ...
            S.CTI, S.CTI_peak, string(S.riskCat), ...
            'VariableNames',{'SegmentID','Lon','Lat','CTI','CTI_Peak','RiskCategory'});
        try
            writetable(T, fullfile(p,f));
            uialert(fig, sprintf('Saved to:\n%s', fullfile(p,f)), ...
                'Export Complete', 'Icon','success');
        catch ME
            uialert(fig, ME.message, 'Export Failed');
        end
    end

    %% ================================================================
    %  PIPELINE
    % ================================================================
    function generateData()
        N = S.cfg.numSegments;

        % AIS
        d.ais.shipDensity     = abs(randn(N,1)*0.3 + 0.4);
        d.ais.anchoringEvents = poissrnd(1.2, N, 1);
        d.ais.trawlingEvents  = poissrnd(0.8, N, 1);

        % Ocean
        d.ocean.currentSpeed  = abs(0.3 + 0.4*randn(N,1));
        d.ocean.currentShear  = abs(0.05 + 0.1*randn(N,1));

        % Seismic
        d.seismic.magnitude   = 4 + 2*abs(randn(N,1));
        d.seismic.depthKm     = 10 + 20*abs(randn(N,1));
        d.seismic.pga         = 0.05 + 0.1*abs(randn(N,1));

        % Bathymetry
        d.bathy.slopeDeg      = 2 + 8*abs(randn(N,1));
        d.bathy.canyonProx    = abs(randn(N,1));

        % Meteo
        d.meteo.stormIndex    = abs(0.5 + 0.6*randn(N,1));
        d.meteo.waveHeightM   = 1 + 3*abs(randn(N,1));

        % Cable
        d.cable.ageYears      = 5 + 10*rand(N,1);
        d.cable.burialDepthM  = 0.5 + 1.5*rand(N,1);

        % Geometry
        d.cableLon = linspace(-30, 10, N)';
        d.cableLat = 40 + 5*sin(linspace(0, 3*pi, N))';

        S.data = d;
    end

    function computeCTI()
        d = S.data;  N = S.cfg.numSegments;
        nrm = @(x) (x - min(x)) ./ (max(x) - min(x) + eps);

        Sc.ship       = nrm(d.ais.shipDensity + 0.5*d.ais.anchoringEvents + ...
                            0.5*d.ais.trawlingEvents);
        Sc.current    = nrm(d.ocean.currentSpeed + 2*d.ocean.currentShear);
        Sc.seismic    = nrm(d.seismic.pga .* (d.seismic.magnitude/6) .* ...
                            (1./(1+d.seismic.depthKm/10)));
        Sc.bathymetry = nrm(0.6*d.bathy.slopeDeg/10 + 0.4*d.bathy.canyonProx);
        Sc.meteo      = nrm(0.6*d.meteo.stormIndex + 0.4*d.meteo.waveHeightM/5);
        Sc.cableAge   = nrm(0.7*d.cable.ageYears/20 + ...
                            0.3*(1 - d.cable.burialDepthM/2));

        W = S.cfg.weights;
        S.CTI = W.ship*Sc.ship + W.current*Sc.current + W.seismic*Sc.seismic + ...
                W.bathymetry*Sc.bathymetry + W.meteo*Sc.meteo + ...
                W.cableAge*Sc.cableAge;
        S.CTI = min(max(S.CTI,0),1);
        S.Sc  = Sc;

        edges = [0 S.cfg.ctiThresholds 1];
        S.riskCat = discretize(S.CTI, edges, ...
            'categorical', {'Low','Moderate','High','Critical'});
    end

    function forecastCTI()
        N = S.cfg.numSegments;
        horizon = 24;
        P = zeros(N, horizon);
        alpha = 0.85; beta = 0.15;
        trend = gradient(S.CTI);
        P(:,1) = S.CTI;
        for t = 2:horizon
            P(:,t) = alpha*P(:,t-1) + beta*trend + 0.02*randn(N,1);
            P(:,t) = min(max(P(:,t),0),1);
        end
        S.CTI_pred = P;
        S.CTI_peak = max(P, [], 2);
    end

    function computeXAI()
        Sc = S.Sc;
        features = [Sc.ship Sc.current Sc.seismic Sc.bathymetry Sc.meteo Sc.cableAge];
        W = [S.cfg.weights.ship S.cfg.weights.current S.cfg.weights.seismic ...
             S.cfg.weights.bathymetry S.cfg.weights.meteo S.cfg.weights.cableAge];
        lc = features .* W;
        lc = lc ./ (sum(lc,2) + eps);
        S.localContrib = lc;
    end

    %% ================================================================
    %  RENDER
    % ================================================================
    function renderPlots()
        N = S.cfg.numSegments;

        % --- CTI Profile ---
        cla(axCTI);
        hold(axCTI,'on');
        plot(axCTI, 1:N, S.CTI, '-o', 'LineWidth',2, ...
            'MarkerFaceColor',[0.25 0.65 0.95], 'Color',[0.25 0.65 0.95]);
        plot(axCTI, 1:N, S.CTI_peak, '--', 'LineWidth',1.5, ...
            'Color',[1 0.4 0.4]);
        yline(axCTI, S.cfg.ctiThresholds(1), ':', 'Color',[0.2 0.8 0.4]);
        yline(axCTI, S.cfg.ctiThresholds(2), ':', 'Color',[1 0.75 0.2]);
        yline(axCTI, S.cfg.ctiThresholds(3), ':', 'Color',[0.9 0.2 0.2]);
        xlabel(axCTI,'Cable Segment ID');
        ylabel(axCTI,'Cable Threat Index (CTI)');
        legend(axCTI,{'Current CTI','24-h Peak','Low/Mod','Mod/High','High/Crit'}, ...
            'Location','best','TextColor',[0.9 0.9 0.9], ...
            'Color',[0.15 0.18 0.24], 'EdgeColor',[0.4 0.45 0.55]);
        ylim(axCTI,[0 1]); grid(axCTI,'on');
        hold(axCTI,'off');

        % --- Risk bar ---
        cla(axRisk);
        cats = {'Low','Moderate','High','Critical'};
        counts = zeros(1,4);
        rc = string(S.riskCat);
        for k = 1:4
            counts(k) = sum(rc == cats{k});
        end
        b = bar(axRisk, counts, 0.6, 'FaceColor','flat');
        b.CData = [0.25 0.75 0.40; 0.95 0.80 0.25; ...
                   0.95 0.50 0.20; 0.90 0.20 0.25];
        axRisk.XTick = 1:4;
        axRisk.XTickLabel = cats;
        ylabel(axRisk,'# Segments');
        grid(axRisk,'on');

        % --- GIS Map ---
        cla(axMap);
        scatter(axMap, S.data.cableLon, S.data.cableLat, 130, S.CTI, ...
            'filled','MarkerEdgeColor',[0.05 0.05 0.05]);
        hold(axMap,'on');
        plot(axMap, S.data.cableLon, S.data.cableLat, '-', ...
            'Color',[0.7 0.7 0.7], 'LineWidth',0.8);
        hold(axMap,'off');
        colormap(axMap, turbo);
        cb = colorbar(axMap);
        cb.Color = [0.9 0.9 0.9];
        cb.Label.String = 'CTI';
        cb.Label.Color  = [0.9 0.9 0.9];
        xlabel(axMap,'Longitude'); ylabel(axMap,'Latitude');
        axis(axMap,'equal'); grid(axMap,'on');

        % --- XAI heatmap ---
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
        cb2.Label.String = 'Attribution';
        cb2.Label.Color  = [0.9 0.9 0.9];
    end

    function updateKPIs()
        kpiVals(1).Text = sprintf('%.3f', mean(S.CTI));
        kpiVals(2).Text = sprintf('%.3f', max(S.CTI));
        kpiVals(3).Text = sprintf('%d', sum(string(S.riskCat)=="Critical"));
        kpiVals(4).Text = sprintf('%.3f', max(S.CTI_peak));
        % colour code peak
        if max(S.CTI_peak) >= S.cfg.ctiThresholds(3)
            kpiVals(4).FontColor = [1.0 0.35 0.35];
        elseif max(S.CTI_peak) >= S.cfg.ctiThresholds(2)
            kpiVals(4).FontColor = [1.0 0.75 0.25];
        else
            kpiVals(4).FontColor = [0.30 0.90 0.60];
        end
    end

    %% ---------------- AXES STYLING HELPER ----------------
    function styleAxes(ax, ttl)
        ax.Color      = [0.08 0.10 0.14];
        ax.XColor     = [0.80 0.85 0.95];
        ax.YColor     = [0.80 0.85 0.95];
        ax.GridColor  = [0.35 0.40 0.50];
        ax.GridAlpha  = 0.35;
        ax.Title.String = ttl;
        ax.Title.Color  = [0.90 0.95 1.00];
        ax.Title.FontWeight = 'bold';
        ax.FontSize = 10;
        ax.Box = 'on';
    end
end