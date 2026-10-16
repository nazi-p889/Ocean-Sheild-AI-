function [CTI, Sc, riskCat] = computeCTI(d, cfg)
% COMPUTECTI  Compute the Cable Threat Index (CTI) by weighted fusion of
% six normalised environmental / operational hazard scores.
%
%   [CTI, Sc, riskCat] = computeCTI(d, cfg)
%
%   d    : struct from generateSyntheticData
%   cfg  : configuration struct with weights + ctiThresholds
%
%   CTI      : N×1 vector in [0,1]
%   Sc       : struct of normalised per-hazard scores
%   riskCat  : categorical {Low, Moderate, High, Critical}

    nrm = @(x) (x - min(x)) ./ (max(x) - min(x) + eps);

    Sc.ship       = nrm(d.ais.shipDensity + ...
                        0.5*d.ais.anchoringEvents + ...
                        0.5*d.ais.trawlingEvents);
    Sc.current    = nrm(d.ocean.currentSpeed + 2*d.ocean.currentShear);
    Sc.seismic    = nrm(d.seismic.pga .* (d.seismic.magnitude/6) .* ...
                        (1./(1+d.seismic.depthKm/10)));
    Sc.bathymetry = nrm(0.6*d.bathy.slopeDeg/10 + 0.4*d.bathy.canyonProx);
    Sc.meteo      = nrm(0.6*d.meteo.stormIndex + 0.4*d.meteo.waveHeightM/5);
    Sc.cableAge   = nrm(0.7*d.cable.ageYears/20 + ...
                        0.3*(1 - d.cable.burialDepthM/2));

    W = cfg.weights;
    CTI = W.ship*Sc.ship + W.current*Sc.current + W.seismic*Sc.seismic + ...
          W.bathymetry*Sc.bathymetry + W.meteo*Sc.meteo + ...
          W.cableAge*Sc.cableAge;
    CTI = min(max(CTI,0),1);

    edges = [0 cfg.ctiThresholds 1];
    riskCat = discretize(CTI, edges, ...
        'categorical', {'Low','Moderate','High','Critical'});
end