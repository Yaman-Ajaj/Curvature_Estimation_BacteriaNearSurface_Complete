% ------------------------------------------------------------
% compareCurvatureVariationAcrossResultFiles.m
% Loads multiple analyzeAllTracks results files (e.g. one per
% curvatureStep value tested), reuses each file's already-computed
% meanCurvature/stdCurvature (no recomputation), and compares the
% resulting curvature variation grouped by which file it came from
% — to see which run produces the least noisy (most consistent)
% curvature estimates.
% ------------------------------------------------------------
clear; clc;

% --- List every results file you want to compare ---
resultsFiles = {
    'curvatureResults_tangentangle_RealData_step2_20260915_133445.mat';
    'curvatureResults_circlefit_RealData_step2_20260915_105818.mat';
};

% --- Load each file, pull curvature variation per section, grouped by file ---
allCurvatureVariation = [];
allFileLabels = [];
for f = 1:numel(resultsFiles)
    thisFile = resultsFiles{f};
    if ~isfile(thisFile)
        fprintf('File not found, skipping: %s\n', thisFile);
        continue;
    end
    resultsData = load(thisFile);
    if ~isfield(resultsData, 'allTrackResults')
        fprintf('File missing allTrackResults, skipping: %s\n', thisFile);
        continue;
    end
    allTrackResults = resultsData.allTrackResults;
    if isempty(allTrackResults)
        fprintf('File has no tracks, skipping: %s\n', thisFile);
        continue;
    end

    % --- Flatten every section's stdCurvature/meanCurvature across all tracks ---
    cv = [];
    for t = 1:numel(allTrackResults)
        sections = allTrackResults{t}.sections;
        if isempty(sections)
            continue;
        end
        for s = 1:numel(sections)
            cv(end+1) = sections(s).stdCurvature / sections(s).meanCurvature; %#ok<AGROW>
        end
    end

    if isempty(cv)
        fprintf('File has no sections, skipping: %s\n', thisFile);
        continue;
    end

    allCurvatureVariation = [allCurvatureVariation, cv]; %#ok<AGROW>
    allFileLabels = [allFileLabels, repmat(f, 1, numel(cv))]; %#ok<AGROW>
end

% --- Print summary stats per file ---
uniqueFiles = unique(allFileLabels);
fprintf('%-40s %8s %10s %10s %10s\n', 'resultsFile', 'N', 'Median', 'Mean', 'Std');
for fi = 1:numel(uniqueFiles)
    mask = (allFileLabels == uniqueFiles(fi));
    vals = allCurvatureVariation(mask);
    vals = vals(isfinite(vals));
    fprintf('%-40s %8d %10.3f %10.3f %10.3f\n', ...
        resultsFiles{uniqueFiles(fi)}, numel(vals), median(vals), mean(vals), std(vals));
end

% --- Plot grouped by file ---
figure;
hold on;
colors = lines(numel(uniqueFiles));
for fi = 1:numel(uniqueFiles)
    mask = (allFileLabels == uniqueFiles(fi));
    vals = allCurvatureVariation(mask);
    vals = vals(isfinite(vals));
    xVals = fi * ones(numel(vals),1) + (rand(numel(vals),1)-0.5)*0.3; % jitter for visibility
    scatter(xVals, vals, 20, colors(fi,:), 'filled', 'MarkerFaceAlpha', 0.4);
end
set(gca, 'XTick', 1:numel(uniqueFiles), 'XTickLabel', resultsFiles(uniqueFiles), ...
    'TickLabelInterpreter', 'none');
xlabel('results file');
ylabel('curvature variation (std(k)/mean(k))');
title('Curvature variation, grouped by results file');
grid on;
hold off;