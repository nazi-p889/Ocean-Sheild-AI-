function [CTI_pred, CTI_peak] = forecastCTI(CTI, horizon, alpha, beta)
% FORECASTCTI  Recursive 24-h predictive forecast of the Cable Threat Index.
%
%   [CTI_pred, CTI_peak] = forecastCTI(CTI)
%   [CTI_pred, CTI_peak] = forecastCTI(CTI, horizon, alpha, beta)
%
%   CTI      : N×1 current CTI vector
%   horizon  : forecast horizon in hours (default 24)
%   alpha    : persistence coefficient   (default 0.85)
%   beta     : trend coefficient         (default 0.15)
%
%   CTI_pred : N×horizon forecast matrix
%   CTI_peak : N×1  per-segment maximum forecast

    if nargin < 2 || isempty(horizon), horizon = 24;   end
    if nargin < 3 || isempty(alpha),   alpha   = 0.85; end
    if nargin < 4 || isempty(beta),    beta    = 0.15; end

    N = numel(CTI);
    CTI_pred = zeros(N, horizon);
    trend    = gradient(CTI);
    CTI_pred(:,1) = CTI;

    for t = 2:horizon
        CTI_pred(:,t) = alpha*CTI_pred(:,t-1) + beta*trend + 0.02*randn(N,1);
        CTI_pred(:,t) = min(max(CTI_pred(:,t),0),1);
    end
    CTI_peak = max(CTI_pred, [], 2);
end