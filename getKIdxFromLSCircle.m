function [k, idx] = getKIdxFromLSCircle(traj, windowSize)
    [~, k, ~, idx] = curvature_estimation_leastSquaresCircle(traj, windowSize);
end