clear; clc;

% --- Specify the two saved results files to compare ---
groundTruthFile = 'groundTruth.mat'; 

% --- Pick the result file via a popup ---
scriptFolder = fileparts(mfilename('fullpath'));
if isempty(scriptFolder)
    scriptFolder = pwd; % fallback when running as a section/selection rather than a saved script
end

[fileName, filePath] = uigetfile(fullfile(scriptFolder, '*.mat'), ...
    'Select the curvature results file to compare');

if isequal(fileName, 0)
    error('No file selected. Aborting.');
end

resultFile = fullfile(filePath, fileName);
fprintf('Comparing against: %s\n', fileName);


% --- Specify which tracks to compare ---
%trackIdsToPlot = [8, 27, 9, 24, 17, 18, 4, 5, 28, 30];
rng(1)
trackIdsToPlot = randperm(40, 10);

smoothWindow = 1; % applied to both methods' k after loading, for a fair comparison

% --- Load both results files ---
groundTruthData = load(groundTruthFile);
allTrackResults = groundTruthData.allTrackResults;

resultsData = load(resultFile);
allTrackResultsAnalyzed = resultsData.allTrackResults;

% --- Plot each requested track: circle-fit vs tangent-angle, both smoothed ---
skippedTracks = [];

for i = 1:numel(trackIdsToPlot)
    trackIdx = trackIdsToPlot(i);

    try
        % --- Concatenate circle-fit k, smoothed, with NaN gaps between sections ---
        circleSections = allTrackResults{trackIdx}.sections;
        if isempty(circleSections)
            error('No near-surface sections for this track (circle-fit results).');
        end

        frameCircleAll = [];
        kCircleAll = [];
        for s = 1:numel(circleSections)
            kSmoothed = smoothCurvature(circleSections(s).k, smoothWindow);
            frameCircleAll = [frameCircleAll; circleSections(s).frame(:); NaN]; %#ok<AGROW>
            kCircleAll = [kCircleAll; kSmoothed(:); NaN]; %#ok<AGROW>
        end
        if ~isempty(frameCircleAll)
            frameCircleAll(end) = []; kCircleAll(end) = [];
        end

        % --- Concatenate tangent-angle k, smoothed, with NaN gaps between sections ---
        tangentSections = allTrackResultsAnalyzed{trackIdx}.sections;
        if isempty(tangentSections)
            error('No near-surface sections for this track (tangent-angle results).');
        end

        frameTangentAll = [];
        kTangentAll = [];
        for s = 1:numel(tangentSections)
            kSmoothed = smoothCurvature(abs(tangentSections(s).k), smoothWindow); % abs() for magnitude comparison
            frameTangentAll = [frameTangentAll; tangentSections(s).frame(:); NaN]; %#ok<AGROW>
            kTangentAll = [kTangentAll; kSmoothed(:); NaN]; %#ok<AGROW>
        end
        if ~isempty(frameTangentAll)
            frameTangentAll(end) = []; kTangentAll(end) = [];
        end

        % --- Plot both on the same axes ---
        figure;
        plot(frameCircleAll, kCircleAll, 'b-', 'LineWidth', 1.2, 'DisplayName', 'Ground Truth');
        hold on;
        plot(frameTangentAll, kTangentAll, 'r-', 'LineWidth', 1.2, 'DisplayName', 'Analyzed Curvature');
        hold off;
        xlabel('frame');
        ylabel('curvature');
        title(sprintf('Track %d: curvature method comparison', trackIdx));
        legend('show');
        grid on;

    catch ME
        skippedTracks(end+1,1) = trackIdx; %#ok<AGROW>
        fprintf('Skipped track %d: %s\n', trackIdx, ME.message);
    end
end

% circleSections = allTrackResultsCircle{8}.sections;
% tangentSections = allTrackResultsTangent{8}.sections;
% 
% kCircleRaw = circleSections(1).k;
% kTangentRaw = abs(tangentSections(1).k);
% 
% fprintf('Circle-fit  k: min=%.4f max=%.4f mean=%.4f std=%.4f\n', min(kCircleRaw), max(kCircleRaw), mean(kCircleRaw), std(kCircleRaw));
% fprintf('Tangent-ang k: min=%.4f max=%.4f mean=%.4f std=%.4f\n', min(kTangentRaw), max(kTangentRaw), mean(kTangentRaw), std(kTangentRaw));
% 
% isequal(kCircleRaw, kTangentRaw)

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