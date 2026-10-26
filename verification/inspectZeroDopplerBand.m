function inspectZeroDopplerBand(recordingID, middleProfile, CPTWL)
%INSPECTZERODOPPLERBAND  Inspect the zero-Doppler band width for one window.
%
%   inspectZeroDopplerBand(recordingID, middleProfile, CPTWL)
%
%   Forms the full ISAR image for the selected window (no Doppler bins
%   removed) and plots the range-averaged Doppler-magnitude profile, used
%   to choose how many central Doppler bins to exclude from the image-
%   contrast calculation (dopplerBinsToRemove).

    paths = setupPaths();
    p = recordingParameters(recordingID);
    [HRRProfilesAll, ~, ~] = loadRecording(fullfile(paths.data, p.filename));

    N = CPTWL;
    startProfile = middleProfile - floor(N/2);
    stopProfile  = startProfile + N - 1;
    HRR_profiles = HRRProfilesAll(startProfile:stopProfile, :);

    % Full image (0 = keep all Doppler bins).
    [~, ISAR_image] = evaluateWindow(HRR_profiles, 0);

    DopplerProfile  = mean(abs(ISAR_image), 2);           % per Doppler bin
    DopplerBinIndex = (0:N-1) - floor(N/2);               % 0 = zero Doppler

    figure('Color','w');
    plot(DopplerBinIndex, 20*log10(DopplerProfile), 'o-');
    xlabel('Doppler bin (0 = zero Doppler)');
    ylabel('Mean magnitude (dB)');
    title('Doppler profile - width of the zero-Doppler band');
    xlim([-15 15]); grid on;
end