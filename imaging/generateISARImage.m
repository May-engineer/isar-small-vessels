
function result = generateISARImage(recordingID, middleProfile, CPTWL, ...
                                    rowShift, colShift, showAlignedHRR)
%GENERATEISARIMAGE Regenerate, centre and save a measured ISAR image.
%
%   generateISARImage(recordingID, middleProfile, CPTWL)
%   generateISARImage(recordingID, middleProfile, CPTWL, ...
%                     rowShift, colShift, showAlignedHRR)
%
%   recordingID    : recording ID from recordingParameters.m
%                    (e.g. 'Y2', 'P2', 'R1', 'G2')
%   middleProfile  : selected middle HRR-profile index
%   CPTWL          : coherent processing time-window length (profiles)
%   rowShift       : Doppler-bin circular shift (default 0)
%   colShift       : range-bin circular shift (default 0)
%   showAlignedHRR : plot and save aligned HRR profiles (default false)
%
%   For even CPTWLs, middleProfile is the higher-indexed of the
%   two central profiles. For odd CPTWLs, it is the central profile.
%
%   Processing is performed by evaluateWindow.m:
%     1. Modified Haywood range alignment
%     2. Adapted Yuan multiple-scatterer autofocus
%     3. Hamming-windowed slow-time FFT and Doppler centring
%     4. Martorella image contrast (IC)
%
%   The full complex ISAR image is retained. Central Doppler rows
%   are excluded only from the IC calculation inside evaluateWindow.
%
%   Circular shifts are applied after image formation for display
%   only. They do not affect image formation or the calculated IC.
%
%   Output images are saved under outputs/isar_images/.

    %% ============================================================
    % Optional inputs and processing settings
    % =============================================================

    if nargin < 4 || isempty(rowShift)
        rowShift = 0;
    end

    if nargin < 5 || isempty(colShift)
        colShift = 0;
    end

    if nargin < 6 || isempty(showAlignedHRR)
        showAlignedHRR = false;
    end

    dopplerBinsToRemove = 2;
    clims = [-35 0];

    %% ============================================================
    % Load the selected recording
    % =============================================================

    paths = setupPaths();
    p = recordingParameters(recordingID);

    recordingPath = fullfile(paths.data, p.filename);

    [HRRProfilesAll, RangeAxis, ProfileRepetitionFreq] = ...
        loadRecording(recordingPath);

    RangeAxis = reshape(RangeAxis, 1, []);

    %% ============================================================
    % Determine the exact CPI limits
    % =============================================================

    if ~isnumeric(CPTWL) || ~isscalar(CPTWL) || ...
            ~isfinite(CPTWL) || CPTWL ~= floor(CPTWL) || CPTWL < 1
        error('CPTWL must be a positive integer.');
    end

    if ~isnumeric(middleProfile) || ~isscalar(middleProfile) || ...
            ~isfinite(middleProfile) || ...
            middleProfile ~= floor(middleProfile)
        error('middleProfile must be an integer.');
    end

    if ~isnumeric(rowShift) || ~isscalar(rowShift) || ...
            ~isfinite(rowShift) || rowShift ~= floor(rowShift) || ...
            ~isnumeric(colShift) || ~isscalar(colShift) || ...
            ~isfinite(colShift) || colShift ~= floor(colShift)
        error('rowShift and colShift must be integer bin offsets.');
    end

    totalProfiles = size(HRRProfilesAll, 1);

    % For even CPTWLs, middleProfile is the higher-indexed
    % central profile. For odd CPTWLs, it is the central profile.
    startProfile = middleProfile - floor(CPTWL/2);
    stopProfile  = startProfile + CPTWL - 1;

    if startProfile < 1 || stopProfile > totalProfiles
        error(['Selected CPI (%d-%d) is outside the ' ...
               'recording (1-%d).'], ...
               startProfile, stopProfile, totalProfiles);
    end

    CPI_seconds = CPTWL / ProfileRepetitionFreq;

    fprintf('\nRecording: %s\n', recordingID);
    fprintf('Vessel: %s\n', p.vessel);
    fprintf('Start profile: %d\n', startProfile);
    fprintf('Stop profile: %d\n', stopProfile);
    fprintf('Middle profile: %d\n', middleProfile);
    fprintf('CPTWL: %d profiles\n', CPTWL);
    fprintf('CPI: %.4f s\n', CPI_seconds);

    %% ============================================================
    % Extract the selected CPI
    % =============================================================

    HRR_profiles = ...
        HRRProfilesAll(startProfile:stopProfile, :);

    %% ============================================================
    % Range alignment, autofocus and Range-Doppler image formation
    % =============================================================

    % evaluateWindow performs the established processing chain.
    % It retains the full complex ISAR image for display and
    % excludes central Doppler rows only when calculating IC.
    %
    % The Hamming-windowed slow-time FFT is implemented inside
    % evaluateWindow, matching the Range-Doppler appendix.

    [IC_value, ISAR_image, FocusedProfiles] = ...
        evaluateWindow(HRR_profiles, dopplerBinsToRemove);

    fprintf('Image contrast: %.4f\n', IC_value);

    %% ============================================================
    % Apply display-only circular shifts
    % =============================================================

    % Rows correspond to Doppler bins; columns to range bins.
    % These shifts are applied only after image formation.
    %
    % The unshifted ISAR_image and its calculated IC are unchanged.

    ISAR_display = circshift( ...
        ISAR_image, [rowShift, colShift]);

    %% ============================================================
    % Generate range and Doppler axes
    % =============================================================

    N = CPTWL;

    % General Doppler axis for both odd and even CPTWLs.
    % Matches the MATLAB implementation quoted in the appendix.
    DopplerAxis_Hz = ...
        ((0:N-1) - floor(N/2)) * ProfileRepetitionFreq / N;

    %% ============================================================
    % Convert the displayed ISAR image to decibels
    % =============================================================

    image_dB = 20 * log10(abs(ISAR_display) + eps);

    % Normalise the strongest response to 0 dB.
    image_dB = image_dB - max(image_dB(:));

    % Display dynamic range is limited using clims = [-35 0].

    %% ============================================================
    % Vessel-specific display settings
    % =============================================================

    switch lower(p.vessel)

        case 'yacht'
            yLimits  = [-30 30];
            yTicks   = -30:10:30;
            fontSize = 25;

        case {'patrol', 'patrol boat', 'patrol vessel'}
            yLimits  = [-50 50];
            yTicks   = -50:10:50;
            fontSize = 25;

        case 'rib'
            % Select display limits from the HRR-profile rate.
            % Higher-rate RIB recordings use a wider Doppler axis.
            if ProfileRepetitionFreq > 300
                yLimits  = [-150 150];
                yTicks   = -150:50:150;
                fontSize = 20;
            else
                yLimits  = [-80 80];
                yTicks   = -80:20:80;
                fontSize = 25;
            end

        otherwise
            error('Unknown vessel type: %s', p.vessel);
    end

    %% ============================================================
    % Figure 1: centred Range-Doppler ISAR image
    % =============================================================

    figISAR = figure( ...
        'Color', 'w', ...
        'Units', 'pixels', ...
        'Position', [100, 100, 1074, 648]);

    imagesc( ...
        RangeAxis, ...
        DopplerAxis_Hz, ...
        image_dB, ...
        clims);

    xlabel('Down-Range (m)', ...
        'FontSize', fontSize, ...
        'FontWeight', 'bold');

    ylabel('Doppler frequency (Hz)', ...
        'FontSize', fontSize, ...
        'FontWeight', 'bold');

    ax = gca;
    ax.FontSize = fontSize;
    ax.LineWidth = 1;

    title({ ...
        'ISAR Image', ...
        sprintf('CPTWL %d | Profiles %d-%d | Middle Profile %d | IC %.2f', ...
        CPTWL, startProfile, stopProfile, middleProfile, IC_value)}, ...
        'FontSize', fontSize, ...
        'FontWeight', 'bold');

    colormap('jet');

    cb = colorbar;
    cb.FontSize = fontSize;

    axis xy;

    % Range-axis ticks every 2 m.
    xticks(ceil(min(RangeAxis)/2)*2 : 2 : ...
           floor(max(RangeAxis)/2)*2);

    % Vessel-specific Doppler display limits.
    ylim(yLimits);
    yticks(yTicks);

    drawnow;

    %% ============================================================
    % Save the centred ISAR image
    % =============================================================

    outputFolder = fullfile(paths.outputs, 'isar_images');

    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    % Filename reflects the actual processing and display settings.
    outputBase = sprintf('%s_MP%d_CPTWL%d_row%+d_col%+d', ...
        upper(char(recordingID)), middleProfile, CPTWL, ...
        rowShift, colShift);

    outputPath = fullfile( ...
        outputFolder, [outputBase '_ISAR.png']);

    % Capture the figure in the same manner as generateISARMovie.
    imageFrame = getframe(figISAR);
    imwrite(imageFrame.cdata, outputPath);

    fprintf('\nSaved centred ISAR image:\n%s\n', outputPath);

    %% ============================================================
    % Figure 2: corresponding aligned HRR profiles (optional)
    % =============================================================

    outputPathHRR = '';

    if showAlignedHRR

        % Align the same CPI used for ISAR image formation.
        % These profiles are range aligned, before autofocus.
        AlignedProfiles = HaywoodAlignFunction(HRR_profiles);

        % Apply the same RANGE-bin shift as the ISAR display.
        % Do not apply rowShift because HRR rows represent
        % slow time rather than Doppler frequency.
        AlignedProfiles_display = circshift( ...
            AlignedProfiles, [0, colShift]);

        % Convert to dB and normalise the maximum to 0 dB.
        AlignedHRR_dB = ...
            20 * log10(abs(AlignedProfiles_display) + eps);

        AlignedHRR_dB = ...
            AlignedHRR_dB - max(AlignedHRR_dB(:));

        figHRR = figure( ...
            'Color', 'w', ...
            'Units', 'pixels', ...
            'Position', [100, 100, 1074, 648]);

        imagesc( ...
            RangeAxis, ...
            1:CPTWL, ...
            AlignedHRR_dB, ...
            clims);

        xlabel('Down-Range (m)', ...
            'FontSize', fontSize, ...
            'FontWeight', 'bold');

        ylabel('Profile Number', ...
            'FontSize', fontSize, ...
            'FontWeight', 'bold');

        title('Aligned HRR Profiles', ...
            'FontSize', fontSize, ...
            'FontWeight', 'bold');

        colormap('jet');

        cbHRR = colorbar;
        cbHRR.FontSize = fontSize;

        axis xy;

        xticks(ceil(min(RangeAxis)/2)*2 : 2 : ...
               floor(max(RangeAxis)/2)*2);

        axHRR = gca;
        axHRR.FontSize = fontSize;
        axHRR.LineWidth = 1;

        drawnow;

        %% Save aligned HRR-profile image

        outputPathHRR = fullfile( ...
            outputFolder, [outputBase '_AlignedHRR.png']);

        imageFrameHRR = getframe(figHRR);
        imwrite(imageFrameHRR.cdata, outputPathHRR);

        fprintf('Saved aligned HRR profiles:\n%s\n', ...
            outputPathHRR);
    end

    %% ============================================================
    % Return processing results
    % =============================================================

    result.recordingID = recordingID;
    result.vessel = p.vessel;

    result.middleProfile = middleProfile;
    result.startProfile = startProfile;
    result.stopProfile = stopProfile;
    result.CPTWL = CPTWL;
    result.CPI_seconds = CPI_seconds;

    result.IC_value = IC_value;

    % Full complex ISAR image before display-only shifts.
    result.ISAR_image = ISAR_image;

    % Range-aligned and autofocus-corrected profiles.
    result.FocusedProfiles = FocusedProfiles;

    % Display adjustments and axes.
    result.rowShift = rowShift;
    result.colShift = colShift;
    result.ISAR_display = ISAR_display;

    result.RangeAxis = RangeAxis;
    result.DopplerAxis_Hz = DopplerAxis_Hz;

    % Saved output paths.
    result.outputPath = outputPath;
    result.outputPathHRR = outputPathHRR;

end
