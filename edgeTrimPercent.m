function pct = edgeTrimPercent(nPoints, nMin, nMax, pctMin, pctMax)
% Linearly interpolate trim percentage based on track length,
% clamped to [pctMin, pctMax].
if nargin < 3, nMin = 50;  end
if nargin < 4, nMax = 200; end
if nargin < 5, pctMin = 7; end
if nargin < 6, pctMax = 17; end

frac = (nPoints - nMin) / (nMax - nMin);
frac = min(max(frac, 0), 1);   % clamp to [0,1]
pct = pctMin + frac * (pctMax - pctMin);
end