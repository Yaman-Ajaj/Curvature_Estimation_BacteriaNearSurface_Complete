clear; clc;

% Load data
data = load('Fn25NoGradientSmoothed.mat');
S =  data.S;
% data.trajectories;

nTracks =  length(S.Speeds);
%length(data.trajectories);

% Z-boundary parameters
surfaceZmin = 35.9535;
surfaceZmax = 35.8652;
tolerance = 3.5;


% --- Method selection dialog ---
methodOptions = {
    'Spline-smoothed + circle-fit'
    'Spline-smoothed + least-squares circle'
    'Spline-smoothed + tangent-angle (signed)'
    'Spline-smoothed derivative (signed)'
    % 'local-polynomial'
    % 'Circle-fit (osculating circle)'
    % 'Tangent-angle'
    % 'Least-squares circle'
    % 'High-order central difference'
};

[selection, ok] = listdlg('PromptString', 'Select curvature method:', ...
    'SelectionMode', 'single', ...
    'ListString', methodOptions, ...
    'ListSize', [300, 120]);

if ~ok
    error('No method selected. Aborting.');
end

% --- Hardcoded parameters for methods that need them ---
% splineP = 0.01;
lsWindowSize = 9;
% cdOrder = 4;
% lpWindow = 11;
% lpOrder = 3;
sigma = 0.2;   % <-- set to your known/estimated noise std
curvatureStep = 7; % only used if curvatureFcn needs it (e.g. circle-fit method)
tolMult = 1;

switch selection
    case 1
        curvatureMethodBase = 'Real_splinesmoothed_circlefit';
        curvatureMethod = sprintf('%s_sig%s_m%s', curvatureMethodBase, ...
        strrep(num2str(sigma), '.', ''), strrep(num2str(tolMult), '.', ''));
        curvatureFcn = @(x,y,z,t) curvature_estimation_splineSmoothed_circlefit([x, y], sigma, curvatureStep, t, tolMult);

    case 2
        curvatureMethodBase = 'Real_splinesmoothed_leastSquaresCircle';
        curvatureMethod = sprintf('%s_sig%s_m%s_w%d', curvatureMethodBase, ...
        strrep(num2str(sigma), '.', ''), strrep(num2str(tolMult), '.', ''), lsWindowSize);
        curvatureFcn = @(x,y,z,t) curvature_estimation_splineSmoothed_leastSquaresCircle([x, y], sigma, lsWindowSize, t, tolMult);

    case 3
        curvatureMethodBase = 'Real_splinesmoothed_tangentAngle';
        curvatureMethod = sprintf('%s_sig%s_m%s', curvatureMethodBase, ...
            strrep(num2str(sigma), '.', ''), strrep(num2str(tolMult), '.', ''));
        curvatureFcn = @(x,y,z,t) curvature_estimation_splineSmoothed([x, y], sigma, curvatureStep, t, tolMult);

    case 4
        curvatureMethod = sprintf('Real_splineDerivative_sig%s_m%s', ...
        strrep(num2str(sigma), '.', ''), strrep(num2str(tolMult), '.', ''));
        curvatureFcn = @(x,y,z,t) curvature_estimation_splineSmoothed_derivative([x, y], sigma, t, tolMult);
    
%     case 5
%          curvatureMethod = sprintf('Noise_localPoly_w%d_o%d', lpWindow, lpOrder);
%          curvatureFcn = @(x,y,z,t) curvature_estimation_localPoly_wrapped([x, y], lpWindow, lpOrder, t);
% 
%     case 6
%         curvatureMethod = 'Noise_circlefit';
%         curvatureFcn = @(x,y,z,t) deal_kidx([x,y], curvatureStep);
% 
%     case 7
%         curvatureMethod = 'Noise_tangentangle';
%         curvatureFcn = @(x,y,z,t) curvatureEstimationTangentAngle([x, y], curvatureStep);
% 
%     case 8
%         curvatureMethodBase = 'Noise_leastSquaresCircle';
%         curvatureMethod = sprintf('%s_w%d', curvatureMethodBase, lsWindowSize);
%         curvatureFcn = @(x,y,z,t) getKIdxFromLSCircle([x,y], lsWindowSize);
% 
%     case 9
%         curvatureMethod = sprintf('Noise_centralDiff_order%d', cdOrder);
%         curvatureFcn = @(x,y,z,t) curvature_estimation_centralDiff([x, y], cdOrder);
end

fprintf('Using method: %s\n', curvatureMethod);

allTrackResults = cell(nTracks, 1);

for k = 1:nTracks

    M =  S.Speeds{k};
    % data.trajectories{k};

    if isempty(M) || size(M,2) < 4
        continue;
    end

    validRows = ~any(isnan(M(:,2:4)), 2);
    M = M(validRows, :);

    if isempty(M)
        continue;
    end

    frame = M(:,1);
    x = M(:,2);
    y = M(:,3);
    z = M(:,4);

    nearSurface = (abs(z - surfaceZmax) <= tolerance) | ...
                  (abs(z + surfaceZmin) <= tolerance);

    % ------------------------------------------------------------
    % Split into contiguous near-surface runs. Curvature is computed
    % independently within each run, so no calculation ever bridges a
    % surface-departure gap (which would otherwise connect two points
    % that are not really adjacent in the continuous near-surface path).
    % ------------------------------------------------------------
    runBoundaries = find(diff([0; nearSurface; 0]) ~= 0);
    runStarts = runBoundaries(1:2:end);
    runEnds = runBoundaries(2:2:end) - 1;
    isRunNearSurface = nearSurface(runStarts);

    trackSections = struct([]);

    for r = 1:numel(runStarts)

        if ~isRunNearSurface(r)
            continue; % only near-surface runs are kept
        end

        idxRun = runStarts(r):runEnds(r);

        xRun = x(idxRun);
        yRun = y(idxRun);
        zRun = z(idxRun);
        frameRun = frame(idxRun);

        [kRun, idxLocal] = curvatureFcn(xRun, yRun, zRun, frameRun);
        if strcmp(curvatureMethod, 'Noise_tangentangle')
             kRun = abs(kRun);
        end

        secResult = struct();
        secResult.sectionIndex = numel(trackSections) + 1;
        secResult.startRow = idxRun(1);
        secResult.endRow = idxRun(end);
        secResult.startFrame = frameRun(1);
        secResult.endFrame = frameRun(end);
        secResult.frame = frameRun(idxLocal);
        secResult.k = kRun;
        secResult.idx = idxLocal; % row indices into xRun/yRun/zRun (local to this run)
        secResult.meanCurvature = mean(kRun(isfinite(kRun)));
        secResult.stdCurvature = std(kRun(isfinite(kRun)));

        trackSections = [trackSections; secResult]; %#ok<AGROW>
    end

    allTrackResults{k} = struct( ...
        'trackIndex', k, ...
        'sections', trackSections);

end

% --- Save results ---
% resultsFile = sprintf('curvatureResults_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
% save(resultsFile, 'allTrackResults', ...
%     'surfaceZmin', 'surfaceZmax', 'tolerance', 'curvatureStep');
% fprintf('Results saved to %s\n', resultsFile);

% --- Save results ---
resultsFile = sprintf('curvatureResults_%s_step%d_%s.mat', ...
    curvatureMethod, curvatureStep, datestr(now, 'yyyymmdd_HHMMSS'));
save(resultsFile, 'allTrackResults', ...
'surfaceZmin', 'surfaceZmax', 'tolerance', 'curvatureStep', 'curvatureMethod');
fprintf('Results saved to %s\n', resultsFile);