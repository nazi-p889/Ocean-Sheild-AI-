function localContrib = computeXAI(Sc, weights)
% COMPUTEXAI  Explainable-AI feature attribution using a linear surrogate
% of the CTI fusion model.
%
%   localContrib = computeXAI(Sc, weights)
%
%   Sc      : struct with fields ship,current,seismic,bathymetry,meteo,cableAge
%   weights : struct of the same fields holding CTI weights
%
%   localContrib : N×6 normalised per-segment feature contributions
%                  (columns ordered: ship,current,seismic,bathy,meteo,age)

    features = [Sc.ship Sc.current Sc.seismic Sc.bathymetry Sc.meteo Sc.cableAge];
    W = [weights.ship weights.current weights.seismic ...
         weights.bathymetry weights.meteo weights.cableAge];

    contrib = features .* W;
    localContrib = contrib ./ (sum(contrib,2) + eps);
end