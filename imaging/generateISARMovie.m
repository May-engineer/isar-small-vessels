function generateISARMovie(HRRProfilesAll, ProfileRepetitionFreq, ...
                           CPTWL, RangeAxis, dopplerBinsToRemove, ...
                           fps, outputFilename)
%GENERATEISARMOVIE  Form a sequence of ISAR images and save as an MP4.
%
%   generateISARMovie(HRRProfilesAll, ProfileRepetitionFreq, CPTWL, ...
%                     RangeAxis, dopplerBinsToRemove, fps, outputFilename)
%
%   Steps a fixed CPTWL window through the recording with 50% overlap,
%   forms a focused ISAR image at each position (via evaluateWindow),
%   and writes the sequence as an MP4 movie.
%
%   HRRProfilesAll        : totalProfiles x n complex HRR profiles
%   ProfileRepetitionFreq : HRR-profile repetition frequency (Hz)
%   CPTWL                 : window length in profiles
%   RangeAxis             : down-range axis in metres
%   dopplerBinsToRemove   : Doppler bins each side of zero excluded from IC
%   fps                   : movie playback frame rate
%   outputFilename        : output MP4 path

    totalProfiles = size(HRRProfilesAll, 1);
    n = size(HRRProfilesAll, 2);

    if CPTWL > totalProfiles
        error('generateISARMovie:windowTooLong', ...
              'CPTWL (%d) is longer than the recording (%d profiles).', ...
              CPTWL, totalProfiles);
    end

    step           = CPTWL / 2;                       % 50% overlap
    startPositions = 1 : step : (totalProfiles - CPTWL + 1);
    numFrames      = numel(startPositions);

    % Doppler axis supporting both even and odd CPTWLs.
    DopplerAxis_Hz = ((0:CPTWL-1) - floor(CPTWL/2)) * ProfileRepetitionFreq / CPTWL;

    RangeAxis = reshape(RangeAxis, 1, n);             % row vector for plotting

    videoObj = VideoWriter(outputFilename, 'MPEG-4');
    videoObj.FrameRate = fps;
    open(videoObj);

    fig = figure('Visible', 'off');

    for w = 1:numFrames
        %% Extract current CPI
        startProfile  = startPositions(w);
        stopProfile   = startProfile + CPTWL - 1;
        middleProfile = startProfile + CPTWL/2;
        HRR_profiles  = HRRProfilesAll(startProfile:stopProfile, :);

        %% Form focused ISAR image (same IC definition as the MC-ATWS search)
        try
            [IC_value, ISAR_image] = evaluateWindow(HRR_profiles, dopplerBinsToRemove);
        catch ME
            % Record a window that cannot be processed as a blank frame so the
            % movie continues without hiding the failure.
            fprintf('  Window %d-%d failed: %s\n', startProfile, stopProfile, ME.message);
            ISAR_image = ones(CPTWL, n) * eps;
            IC_value   = 0;
        end

        %% Convert to dB and normalise so the peak is at 0 dB (-35 to 0 range)
        image_dB = 20 * log10(abs(ISAR_image) + eps);
        image_dB = image_dB - max(image_dB(:));
        clims    = [-35 0];

        %% Plot this frame
        clf(fig);
        imagesc(RangeAxis, DopplerAxis_Hz, image_dB, clims);
        xlabel('Range (m)');
        ylabel('Doppler frequency (Hz)');
        title(sprintf('CPTWL %d | Profiles %d-%d | Middle Profile %.0f | IC %.2f', ...
              CPTWL, startProfile, stopProfile, middleProfile, IC_value));
        colormap('jet');
        colorbar;
        axis xy;
        drawnow;

        %% Capture and write the frame
        writeVideo(videoObj, getframe(fig));
    end

    close(videoObj);
    close(fig);
    fprintf('Saved movie: %s\n', outputFilename);
end