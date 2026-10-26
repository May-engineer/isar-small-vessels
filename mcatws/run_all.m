%% run_all.m - MC-ATWS processing across all 17 recordings
% Runs Maximum-Contrast-based Automatic Time-Window Selection (MC-ATWS)
% on all 17 measured recordings using initial CPTWLs of 32, 64 and 128.
%
% For each recording, the pipeline identifies local IC maxima (MPL),
% refines the window lengths (WLE), and deduplicates and filters the
% candidates. Retained high-contrast candidate ISAR images and their
% parameters are saved under outputs/mcatws/.
%
% Recording filenames are defined in recordingParameters.m.
% Radar data are loaded through the shared loadRecording.m function.

clear; close all; clc;

%% Configure project paths
paths = setupPaths();

% Suppress robustfit iteration-limit warnings during processing.
warning('off', 'stats:statrobustfit:IterationLimit');

%% Recordings to process
recordingIDs = { ...
    'Y1','Y2','Y3','Y4','Y5','Y6', ...
    'P1','P2','P3', ...
    'R1','R2','R3','R4','R5', ...
    'G1','G2','G3'};

%% MC-ATWS processing parameters
dopplerBinsToRemove = 2;     % Central Doppler exclusion for IC
nInitial            = 5;     % WLE step parameter
overlapThreshold    = 0.8;   % Deduplication overlap threshold
relativeICThreshold = 0.75;  % Retain IC >= 75% of recording maximum

%% Output directories
outputDir = fullfile(paths.outputs, 'mcatws');
imgFolder = fullfile(outputDir, 'selected_images');

if ~isfolder(imgFolder)
    mkdir(imgFolder);
end

%% Results table: one row per retained candidate
Results = table('Size', [0 8], ...
    'VariableTypes', { ...
        'string','string','double','double', ...
        'double','double','double','double'}, ...
    'VariableNames', { ...
        'File','Vessel','ProfileRate_Hz','InitialCPTWL', ...
        'RefinedCPTWL','CPI_seconds','MiddleProfile','IC'});

% Record any datasets that fail during processing.
failedRecordings = {};

%% Process each recording
for i = 1:numel(recordingIDs)

    recordingID = recordingIDs{i};

    try
        %% Retrieve recording metadata
        p = recordingParameters(recordingID);

        filename = p.filename;
        vessel = p.vessel;

        % Preserve the vessel labels from the original MC-ATWS results.
        if strcmp(vessel, 'Patrol')
            vessel = 'Patrol Boat';

        elseif strcmp(vessel, 'RIB')
            if startsWith(p.id, 'G')
                vessel = 'RIB2';
            else
                vessel = 'RIB1';
            end
        end

        fprintf('\n########## %s (%s) ##########\n', ...
            filename, vessel);

        %% Load radar data
        recordingFile = fullfile(paths.data, filename);

        [HRRProfilesAll, RangeAxis, ProfileRepetitionFreq] = ...
            loadRecording(recordingFile);

        %% Run MC-ATWS
        candidates = runMCATWS( ...
            HRRProfilesAll, ...
            ProfileRepetitionFreq, ...
            dopplerBinsToRemove, ...
            nInitial, ...
            RangeAxis);

        %% Deduplicate and filter refined candidates
        [kept, stats] = filterCandidates( ...
            candidates, overlapThreshold, relativeICThreshold);

        fprintf('  %d refined -> %d deduplicated -> %d retained\n', ...
            stats.nValid, stats.nDedup, stats.nKept);

        %% Save retained candidate ISAR images
        recTag = erase(filename, '.mat');

        for kk = 1:numel(kept)

            N = kept(kk).refinedCPTWL;

            % Doppler axis supporting both even and odd CPTWLs.
            DopplerAxis_Hz = ...
                ((0:N-1) - floor(N/2)) * ProfileRepetitionFreq / N;

            % Convert the selected ISAR image to dB and normalise so the
            % strongest return is at 0 dB, giving a consistent -35 to 0 dB
            % display range across all recordings and vessel types.
            image_dB = 20*log10(abs(kept(kk).ISAR_image) + eps);
            image_dB = image_dB - max(image_dB(:));   % normalise: peak = 0 dB
            clims = [-35 0];

            %% Display ISAR image
            fig = figure('Visible', 'off');

            imagesc(RangeAxis, DopplerAxis_Hz, image_dB, clims);

            xlabel('Down-Range (m)');
            ylabel('Doppler frequency (Hz)');

            title(sprintf( ...
                '%s | MP %d | CPTWL %d (%.2f s) | IC %.2f', ...
                vessel, ...
                kept(kk).middleProfile, ...
                N, ...
                kept(kk).CPI_seconds, ...
                kept(kk).IC));

            colormap('jet');
            colorbar;
            axis xy;

            %% Save image
            figName = sprintf('%s_MP%d_CPTWL%d.png', ...
                recTag, kept(kk).middleProfile, N);

            saveas(fig, fullfile(imgFolder, figName));
            close(fig);

            %% Record retained candidate parameters
            Results = [Results; { ...
                string(filename), ...
                string(vessel), ...
                ProfileRepetitionFreq, ...
                kept(kk).initialCPTWL, ...
                N, ...
                kept(kk).CPI_seconds, ...
                kept(kk).middleProfile, ...
                kept(kk).IC}];

        end

        fprintf('  Saved %d retained images for this recording.\n', ...
            numel(kept));

    catch ME
        failedRecordings{end+1} = recordingID;

        fprintf(2, '\n  FAILED (%s): %s\n', ...
            recordingID, ME.message);
    end

end

%% Display results
disp(Results);

%% Check whether all recordings were processed successfully
if ~isempty(failedRecordings)

    fprintf(2, '\nMC-ATWS failed for %d recording(s):\n', ...
        numel(failedRecordings));

    fprintf(2, '  %s\n', failedRecordings{:});

    warning('MC-ATWS batch incomplete. Summary CSV not overwritten.');

else

    %% Save complete results summary
    summaryPath = fullfile(outputDir, 'MCATWS_results_summary.csv');

    writetable(Results, summaryPath);

    fprintf('\nSuccessfully processed all %d recordings.\n', ...
        numel(recordingIDs));

    fprintf('Retained %d candidate intervals.\n', ...
        height(Results));

    fprintf('Saved MC-ATWS summary to:\n%s\n', summaryPath);

end
