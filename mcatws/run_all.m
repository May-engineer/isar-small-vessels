%% run_all.m - full MC-ATWS pipeline across all recordings
% Top-level batch script. For each recording of each vessel it runs the MC-ATWS
% processor (MPL peak detection + WLE length refinement over CPTWLs 32/64/128),
% deduplicates and quality-filters the refined candidates then saves each
% distinct good ISAR image and records it in a summary table.
clear; close all; clc;
warning('off', 'stats:statrobustfit:IterationLimit');

%% List of every recording, grouped by vessel class
files = {
'DAP_2010-10-06_18-00-05_002_Umoya_P872_55212_outbound.mat',  'Yacht'
'DAP_2010-10-06_18-01-54_002_Umoya_P873_50446_outbound.mat',  'Yacht'
'DAP_2010-10-06_18-14-21_002_Umoya_P872_55336_inbound.mat',   'Yacht'
'DAP_2010-10-09_06-50-40_008_Umoya_P873_02570_outbound.mat',  'Yacht'
'DAP_2010-10-09_06-55-26_010_Umoya_P874_03468_outbound.mat',  'Yacht'
'DAP_2010-10-09_06-58-05_012_Umoya_P874_03085_inbound.mat',   'Yacht'
'DAP_2010-10-15_07-01-33_000_NAMACURA_OUT_12KNOTS_870__P870_T001_G1_sb_HRR_G1_02743.mat',   'Patrol Boat'
'DAP_2010-10-15_07-03-22_000_NAMACURA_OUT_6KNOTS_870__P870_T001_G1_sb_HRR_G1_01956.mat',    'Patrol Boat'
'DAP_2010-10-15_07-06-04_000_NAMACURA_INB_MAXKNOTS_870__P870_T001_G1_sb_HRR_G1_02804.mat',  'Patrol Boat'
'DAP_2010-10-14_14-31-33_014_RIB_OUT_SPEEDMEDIUM_18KNOTS_462__P462_T001_G1_sb_HRR_G1_01502.mat',  'RIB1'
'DAP_2010-10-14_14-52-31_024_RIB_OUT_SPEEDHIGH_FULL_462__P462_T001_G1_sb_HRR_G1_28154.mat',       'RIB1'
'DAP_2010-10-14_14-56-49_025_RIB_CRISS-CROSS45_SPEEDHIGH_FULL_462__P462_T001_G1_sb_HRR_G1_44939.mat', 'RIB1'
'DAP_2010-10-14_14-57-33_026_RIB_CRISS-CROSS45_SPEEDHIGH_FULL_462__P462_T001_G1_sb_HRR_G1_01266.mat',  'RIB1'
'DAP_2010-10-14_15-10-00_029_RIB_CRISS-CROSS_SPEEDMEDIUM_18KNOTS_462__P462_T001_G1_sb_HRR_G1_01342.mat', 'RIB1'
'DAP_2010-10-14_11-37-03_001_GID13829__P455_T001_G1_sb_HRR_G1_02429.mat', 'RIB2'
'DAP_2010-10-14_11-39-33_001_GID13926__P455_T001_G1_sb_HRR_G1_01097.mat', 'RIB2'
'DAP_2010-10-15_09-57-43_002_GID17282__P460_T001_G1_sb_HRR_G1_02415.mat', 'RIB2'
};

%% Processing parameters
dopplerBinsToRemove = 2;    % Doppler bins each side of zero excluded from IC
nInitial            = 5;    % WLE step parameter
overlapThreshold    = 0.8;  % dedup overlap ratio
relativeICThreshold = 0.75; % keep images with IC >= this x recording's best IC

%% Create a subfolder to hold the saved ISAR images
imgFolder = 'MCATWS_images';
if ~exist(imgFolder, 'dir')
    mkdir(imgFolder);
end

%% Results table: one row PER KEPT IMAGE (not per recording)
Results = table('Size', [0 8], ...
    'VariableTypes', {'string','string','double','double','double','double','double','double'}, ...
    'VariableNames', {'File','Vessel','ProfileRate_Hz','InitialCPTWL','RefinedCPTWL', ...
                      'CPI_seconds','MiddleProfile','IC'});
%% Process each recording in turn
for i = 1:size(files,1)
    filename = files{i,1};
    vessel   = files{i,2};
    fprintf('\n########## %s (%s) ##########\n', filename, vessel);

    try
        %% Load the recording and extract the needed fields
        S = load(filename);
        sb_HRR = S.sb_HRR;

        HRRProfilesAll = sb_HRR.G1.HRR_NoMC_calib.';
        RangeAxis      = sb_HRR.G1.xaxis_downrange_m;
        % Pattern_time field is 'Pattern_time' in some files, 'pattern_time' in others
        if isfield(sb_HRR.G1, 'Pattern_time')
            patternTime = sb_HRR.G1.Pattern_time;
        elseif isfield(sb_HRR.G1, 'pattern_time')
            patternTime = sb_HRR.G1.pattern_time;
        else
            error('No Pattern_time / pattern_time field found.');
        end
        ProfileRepetitionFreq = 1 / patternTime;

        %% MC-ATWS: refined candidates, then deduplicate + quality filter
        candidates = runMCATWS(HRRProfilesAll, ProfileRepetitionFreq, ...
                               dopplerBinsToRemove, nInitial, RangeAxis);
        [kept, stats] = filterCandidates(candidates, overlapThreshold, relativeICThreshold);

        fprintf('  %d refined -> %d deduplicated -> %d retained\n', ...
        stats.nValid, stats.nDedup, stats.nKept);

        %% Save an image for each kept (distinct, good) imaging interval
        recTag = erase(filename, '.mat');
        for kk = 1:numel(kept)
            N = kept(kk).refinedCPTWL;
            DopplerAxis_Hz = (-N/2 : N/2-1) * ProfileRepetitionFreq / N;

            % Centre the target in the image before display
            ISAR_centred = centreISARImage(kept(kk).ISAR_image, 15);

            image_dB = 20*log10(abs(kept(kk).ISAR_image) + eps);
            ref = max(image_dB(:));
            clims = [ref-35, ref];

            fig = figure('Visible', 'off');
            imagesc(RangeAxis, DopplerAxis_Hz, image_dB, clims);
            xlabel('Range (m)'); ylabel('Doppler frequency (Hz)');
            title(sprintf('%s | MP %d | CPTWL %d (%.2f s) | IC %.2f', ...
                  vessel, kept(kk).middleProfile, N, ...
                  kept(kk).CPI_seconds, kept(kk).IC));
            colormap('jet'); colorbar; axis xy;

            figName = sprintf('%s_MP%d_CPTWL%d.png', recTag, kept(kk).middleProfile, N);
            saveas(fig, fullfile(imgFolder, figName));
            close(fig);

            %% Add a row for this image
            Results = [Results; {string(filename), string(vessel), ProfileRepetitionFreq, ...
                       kept(kk).initialCPTWL, N, kept(kk).CPI_seconds, ...
                       kept(kk).middleProfile, kept(kk).IC}];
        end

        fprintf('  Saved %d distinct good images for this recording.\n', numel(kept));

    catch ME
        fprintf('  SKIPPED (%s): %s\n', filename, ME.message);
    end
end

%% Display and save the summary of all kept images across all recordings
disp(Results);
writetable(Results, 'MCATWS_results_summary.csv');
fprintf('\nSaved summary to %s\n', 'MCATWS_results_summary.csv');