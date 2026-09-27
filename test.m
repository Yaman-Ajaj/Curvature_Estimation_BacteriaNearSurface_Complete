% M = S.Speeds{677};
% validRows = ~any(isnan(M(:,2:4)), 2);
% M = M(validRows,:);
% x = M(:,2); y = M(:,3); z = M(:,4);
% pd = pointMetricsXY(x, y, z, curvatureStep);
% fprintf('k: min=%.4f max=%.4f median=%.4f mean=%.4f\n', min(pd.k), max(pd.k), median(pd.k), mean(pd.k));
% fprintf('current curvatureThreshold = %.4f\n', curvatureThreshold);
% 
% labels = {allRows.shapeLabel};
% tabulate(labels)
% 
% [cv, kUsed] = curvatureVariationByTrack(5667, S, curvatureStep, 2269, 2291);
% disp(kUsed');
% mean(kUsed)
% std(kUsed)
% 
% M = trajectories{3}; % use whichever track/index this test track actually is
% x = M(:,2); y = M(:,3);
% traj = [x, y];
% step = 2; % match whatever curvatureStep/step you used for both saved runs
% 
% [rCircle, kCircle, ccCircle, idxCircle] = curvature_estimation_traj2d(traj, step);
% [kTangent, idxTangent] = curvatureEstimationTangentAngle(traj, step);
% 
% fprintf('idx match: %d\n', isequal(idxCircle, idxTangent));
% fprintf('length kCircle=%d, length kTangent=%d\n', numel(kCircle), numel(kTangent));
% 
% % Compare the first 10 points directly, side by side
% disp(table(idxCircle(1:10), kCircle(1:10), abs(kTangent(1:10)), ...
%     'VariableNames', {'idx','k_circle','k_tangent_abs'}))
% 
% Direct, bypass-everything diagnostic: compare curvature_estimation_traj2d
% and curvature_estimation_tangentAngle on the SAME raw trajectory data,
% same step, no main loop, no saved files, no smoothing involved.
% 
% data = load('Fn25NoGradientSmoothed.mat'); % or your synthetic file
% S = data.S;
% 
% trackIdx = 8; % pick a track you know is near-surface and jittered/noisy
% M = S.Speeds{trackIdx};
% validRows = ~any(isnan(M(:,2:4)), 2);
% M = M(validRows, :);
% x = M(:,2); y = M(:,3);
% traj = [x, y];
% 
% step = 2;
% 
% [rCircle, kCircle, ccCircle, idxCircle] = curvature_estimation_traj2d(traj, step);
% [kTangent, idxTangent] = curvatureEstimationTangentAngle(traj, step);
% 
% fprintf('idx match: %d\n', isequal(idxCircle, idxTangent));
% fprintf('length kCircle=%d, length kTangent=%d\n', numel(kCircle), numel(kTangent));
% 
% fprintf('Circle-fit  k: min=%.4f max=%.4f mean=%.4f std=%.4f\n', min(kCircle), max(kCircle), mean(kCircle), std(kCircle));
% fprintf('Tangent-ang k: min=%.4f max=%.4f mean=%.4f std=%.4f\n', min(abs(kTangent)), max(abs(kTangent)), mean(abs(kTangent)), std(abs(kTangent)));
% 
% disp(table(idxCircle(1:10), kCircle(1:10), abs(kTangent(1:10)), ...
%     'VariableNames', {'idx','k_circle','k_tangent_abs'}))
% 
% % Direct element-wise difference, to see how close they really are pointwise
% diffVals = kCircle - abs(kTangent);
% fprintf('Pointwise diff: mean=%.6f, max abs diff=%.6f\n', mean(diffVals), max(abs(diffVals)));
% 
% D = load('Fake_synthetic_trajectories_Noise.mat');
% kTrue = getTrueCurvature('Fake_synthetic_trajectories_Clean.mat');
% 
% trajNoisy = cellfun(@(M) M(:,2:3), D.trajectories, 'UniformOutput', false);
% 
% pBest = sweep_splineP(trajNoisy, kTrue, 1);
% 
% try
%     pBest = sweep_splineP(trajNoisy, kTrue, 1);
% catch ME
%     disp(ME.message)
%     disp(ME.stack(1))
% end
% 

% 
% sigma = 0.2;  % known from your generator
% [multBest, multGrid, rmse, bias] = sweep_tolMult(trajNoisy, kTrue, 1, sigma, [], tFrames);
% 
% D = load('Fake_synthetic_trajectories_Noise.mat');
% 
% nPoints = cellfun(@(M) size(M,1), D.trajectories);
% types = D.trajectoryType;
% 
% T = table(types, nPoints, 'VariableNames', {'Type','nPoints'});
% disp(T)
% 
% fprintf('\n--- Summary by type ---\n');
% uniqueTypes = unique(types);
% for i = 1:numel(uniqueTypes)
%     mask = strcmp(types, uniqueTypes{i});
%     fprintf('%-12s: n = %2d tracks, points = %d to %d (mean %.1f), total = %d\n', ...
%         uniqueTypes{i}, sum(mask), min(nPoints(mask)), max(nPoints(mask)), ...
%         mean(nPoints(mask)), sum(nPoints(mask)));
% end
% 
% fprintf('\nTotal points across all tracks: %d\n', sum(nPoints));
% 
% trackIdsToCheck = [677, 582, 579, 577, 761, 744, 705]; % add other track indices you know contain visible circles
% kAll = [];
% 
% for ti = trackIdsToCheck
%     M = S.Speeds{ti};
%     validRows = ~any(isnan(M(:,2:4)), 2);
%     M = M(validRows,:);
%     x = M(:,2); y = M(:,3); z = M(:,4);
%     pd = pointMetricsXY(x, y, z, curvatureStep);
%     kAll = [kAll; pd.k];
% end
% 
% prctile(kAll, [5 10 25 50 75 90])
% 
% allPCR = [allRows.pathChordRatio];
% allDC = [allRows.directionConsistency];
% allRE = [allRows.radialError];
% allTurns = [allRows.turns];
% 
% fprintf('pathChordRatio: min=%.3f p25=%.3f median=%.3f p75=%.3f max=%.3f\n', ...
%     min(allPCR), prctile(allPCR,25), median(allPCR), prctile(allPCR,75), max(allPCR));
% fprintf('directionConsistency: min=%.3f p25=%.3f median=%.3f p75=%.3f max=%.3f\n', ...
%     min(allDC), prctile(allDC,25), median(allDC), prctile(allDC,75), max(allDC));
% fprintf('radialError: min=%.3f p25=%.3f median=%.3f p75=%.3f max=%.3f\n', ...
%     min(allRE), prctile(allRE,25), median(allRE), prctile(allRE,75), max(allRE));
% fprintf('turns: min=%.3f p25=%.3f median=%.3f p75=%.3f max=%.3f\n', ...
%     min(allTurns), prctile(allTurns,25), median(allTurns), prctile(allTurns,75), max(allTurns));
% 
% fprintf('\nHow many sections exceed loopChordRatioMin=3.0: %d / %d\n', ...
%     sum(allPCR >= 3.0), numel(allPCR));
% fprintf('How many sections exceed highDirConsistency=0.85: %d / %d\n', ...
%     sum(allDC >= 0.85), numel(allDC));
% fprintf('How many sections satisfy BOTH: %d / %d\n', ...
%     sum(allPCR >= 3.0 & allDC >= 0.85), numel(allPCR));
% nNaNsections = sum(isnan(allPCR));
% fprintf('%d / %d sections have NaN pathChordRatio\n', nNaNsections, numel(allPCR));
% 
% sectionLengths = [allRows.nPoints];
% nanMask = isnan([allRows.pathChordRatio]);
% 
% fprintf('NaN sections: min length=%d, max length=%d, median length=%.1f\n', ...
%     min(sectionLengths(nanMask)), max(sectionLengths(nanMask)), median(sectionLengths(nanMask)));
% fprintf('Non-NaN sections: min length=%d\n', min(sectionLengths(~nanMask)));

% clear; clc; close all
% D = load('Fake_synthetic_trajectories_Noise.mat');
% kTrue = getTrueCurvature('Fake_synthetic_trajectories_Clean.mat');
% trajNoisy = cellfun(@(M) M(:,2:3), D.trajectories, 'UniformOutput', false);
% 
% isClosed = ismember(D.trajectoryType, {'Circular','Elliptical'});
% for k = find(isClosed)'
%     trajNoisy{k}(end,:) = [];
%     kTrue{k}(end)       = [];
% end
% 
% pBest = sweep_splineP(trajNoisy, kTrue, 1);
% 
% tFrames = cellfun(@(M) M(:,1), D.trajectories, 'UniformOutput', false);
% for k = find(isClosed)'
%     tFrames{k}(end) = [];
% end
% 
% sigma = 0.2;
% [tolBest, stepBest, RMSE] = sweep_splineCirclefit_2D(trajNoisy, kTrue, sigma, tFrames);
% 
% [wBest, oBest, RMSE, windowSizes, polyOrders] = sweep_localPoly(trajNoisy, kTrue, tFrames);

% [pBest, pGrid, rmse, bias] = sweep_splineP(trajNoisy, kTrue, 1, [], tFrames);
% kTrue = getTrueCurvature('Fake_synthetic_trajectories_Clean.mat');
% D = load('Fake_synthetic_trajectories_Clean.mat');
% mask = strcmp(D.trajectoryType, 'SpatiallyVarying');
% idxSV = find(mask);
% 
% for k = idxSV'
%     fprintf('Track %d: kTrue range [%.3f, %.3f], max |kTrue| = %.3f\n', ...
%         k, min(kTrue{k}), max(kTrue{k}), max(abs(kTrue{k})));
% end
% 
% mask = strcmp(D.trajectoryType, 'SpatiallyVarying');
% trajSV   = trajNoisy(mask);
% kTrueSV  = kTrue(mask);
% tFramesSV = tFrames(mask);
% 
% sigma = 0.2;
% 
% % 1. Spline-derivative
% methodFcn = @(traj,t,tolMult) curvature_estimation_splineSmoothed_derivative(traj, sigma, t, tolMult);
% sweep_tolMult(trajSV, kTrueSV, methodFcn, tFramesSV, [], true);   % true = signed comparison
% 
% % 2. Spline + circle-fit
% methodFcn = @(traj,t,tolMult,step) curvature_estimation_splineSmoothed_circlefit(traj, sigma, step, t, tolMult);
% sweep_splineCirclefit_2D(trajSV, kTrueSV, tFramesSV, methodFcn, [], [], false);  % unsigned, circle-fit has no sign
% 
% % 3. Spline + least-squares circle
% methodFcn = @(traj,t,tolMult,step) curvature_estimation_splineSmoothed_leastSquaresCircle(traj, sigma, step, t, tolMult);
% sweep_splineCirclefit_2D(trajSV, kTrueSV, tFramesSV, methodFcn, [], [], false);
% 
% % 4. Local polynomial
% methodFcn = @(traj,t,w,o) curvature_estimation_localPoly(traj, w, o, t);
% sweep_localPoly(trajSV, kTrueSV, tFramesSV, methodFcn, [], [], true);   % true = signed, local-poly is signed

D = load('Fake_synthetic_trajectories_Clean.mat');
mask = strcmp(D.trajectoryType, 'FastVarying');
for k = find(mask)'
    fprintf('Track %d: kTrue range [%.3f, %.3f], nCycles=%d\n', ...
        k, min(D.trajectoryKappaTrue{k}), max(D.trajectoryKappaTrue{k}), D.trajectoryFV.nCycles(k));
end