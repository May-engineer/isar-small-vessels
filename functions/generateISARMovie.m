function generateISARMovie(HRRProfilesAll, ProfileRepetitionFreq, ...
                           CPTWL, RangeAxis, dopplerBinsToRemove, ...
                           fps, outputFilename)
% GENERATEISARMOVIE
% Forms a sequence of focused ISAR images from one radar recording using a
% fixed CPTWL and 50% overlap then saves the sequence as an MP4.
%
% HRRProfilesAll        : totalProfiles x n complex HRR profiles
% ProfileRepetitionFreq : HRR profile repetition frequency (Hz)
% CPTWL                 : coherent processing time window length in profiles
% RangeAxis             : range axis in metres
% dopplerBinsToRemove   : Doppler bins each side of zero excluded from the IC
% fps                   : movie playback frame rate
% outputFilename        : output MP4 filename

    totalProfiles = size(HRRProfilesAll, 1);
    n = size(HRRProfilesAll, 2);

    if CPTWL > totalProfiles
        error('CPTWL is longer than the radar recording.');
    end

    step = CPTWL / 2;                                 % 50% overlap
    startPositions = 1 : step : (totalProfiles - CPTWL + 1);
    numFrames = numel(startPositions);

    N = CPTWL;
    DopplerAxis_Hz = (-N/2 : N/2-1) * ProfileRepetitionFreq / N;

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
            % Report and skip a window that cannot be processed so the movie
            % continues but the failure is not hidden.
            fprintf('  Window %d-%d failed: %s\n', startProfile, stopProfile, ME.message);
            ISAR_image = ones(CPTWL, n) * eps;        % blank frame
            IC_value   = 0;
        end

        %% Convert to dB (+ eps avoids log10(0) = -Inf)
        image_dB = 20 * log10(abs(ISAR_image) + eps);

        %% Display dynamic range (35 dB below peak)
        maximum_dB    = max(image_dB(:));
        lowerLimit_dB = maximum_dB - 35;
        clims = [lowerLimit_dB, maximum_dB];

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