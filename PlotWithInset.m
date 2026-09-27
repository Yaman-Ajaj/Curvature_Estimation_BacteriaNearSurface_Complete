clear; clc;

% --- Specify the results file and raw trajectory data ---
% --- Specify the results file and raw trajectory data ---
scriptFolder = fileparts(mfilename('fullpath'));
if isempty(scriptFolder), scriptFolder = pwd; end

[resultsFileName, resultsPath] = uigetfile(fullfile(scriptFolder, '*.mat'), ...
    'Select curvature results file');
if isequal(resultsFileName, 0)
    error('No results file selected. Aborting.');
end
resultsFile = fullfile(resultsPath, resultsFileName);

% [rawFileName, rawPath] = uigetfile(fullfile(scriptFolder, '*.mat'), ...
%     'Select raw trajectory data file');
% if isequal(rawFileName, 0)
%     error('No raw data file selected. Aborting.');
% end

rawDataFile = 'Fn25NoGradientSmoothed.mat';

% --- Specify which tracks to plot ---

trackIdsToPlot = [3461
1981
4057
4859
6803
4752
5846
1787
8472];
% rng(3)
% nTracksAvailable = numel(S.Speeds);
% trackIdsToPlot = randperm(nTracksAvailable, 10);

smoothWindow = 1; % applied to k after loading
method = 'sgolay';

% --- Load results and raw trajectory data ---
resultsData = load(resultsFile);
allTrackResults = resultsData.allTrackResults;

rawData = load(rawDataFile);
S = rawData.S;

% --- Plot each requested track: smoothed curvature, with a trajectory inset ---
skippedTracks = [];

for i = 1:numel(trackIdsToPlot)
    trackIdx = trackIdsToPlot(i);

    try
        % --- Concatenate k, smoothed, with NaN gaps between sections ---
        sections = allTrackResults{trackIdx}.sections;
        if isempty(sections)
            error('No near-surface sections for this track.');
        end

        frameAll = [];
        kAll = [];
        for s = 1:numel(sections)
            kSmoothed = smoothCurvature(sections(s).k, smoothWindow, method);
            frameAll = [frameAll; sections(s).frame(:); NaN]; %#ok<AGROW>
            kAll = [kAll; kSmoothed(:); NaN]; %#ok<AGROW>
        end
        if ~isempty(frameAll)
            frameAll(end) = []; kAll(end) = [];
        end

         % --- Pull the raw trajectory for the inset ---
        M = S.Speeds{trackIdx};
        validRows = ~any(isnan(M(:,2:4)), 2);
        M = M(validRows, :);
        xTraj = M(:,2);
        yTraj = M(:,3);
        frameTraj = M(:,1);

        % --- Main curvature plot ---
        figure;
        mainAx = axes;
        plot(mainAx, frameAll, kAll, 'b-', 'LineWidth', 1.2);
       
        maxAbsK = max(abs(kAll), [], 'omitnan');
        yBound = max(0.3, maxAbsK);
        ylim(mainAx, [-yBound, yBound]);

        xlabel(mainAx, 'frame');
        ylabel(mainAx, 'curvature');
        title(mainAx, sprintf('Track %d: smoothed curvature (window=%d)', trackIdx, smoothWindow));
        grid(mainAx, 'on');

        % --- Trajectory inset, showing ONLY the near-surface sections
        % that curvature was actually computed on, colored by frame
        % (time) so you can see the direction/progression of motion.
        % Color scale is fixed to the FULL track's frame range, so
        % absolute time position is comparable across sections, not
        % just progression within each section individually. ---
        insetAx = axes('Position', [0.68 0.68 0.2 0.2]);
        hold(insetAx, 'on');
        for s = 1:numel(sections)
            idxSec = sections(s).startRow : sections(s).endRow;
            scatter(insetAx, xTraj(idxSec), yTraj(idxSec), 8, frameTraj(idxSec), 'filled');
        end
        hold(insetAx, 'off');
        axis(insetAx, 'equal');
        set(insetAx, 'XTick', [], 'YTick', [], 'Box', 'on');
        colormap(insetAx, 'parula');
        clim(insetAx, [min(frameTraj), max(frameTraj)]);

    catch ME
        skippedTracks(end+1,1) = trackIdx; %#ok<AGROW>
        fprintf('Skipped track %d: %s\n', trackIdx, ME.message);
    end
end