function [peaks, searchData] = searchCPTWL( ...
    HRRProfilesAll, CPTWL, dopplerBinsToRemove)
% SEARCHCPTWL
% Slide one fixed CPTWL across an entire radar recording using 50% overlap,
% evaluate each candidate CPI using Martorella image contrast and return the
% LOCAL PEAKS in the IC-versus-position curve (candidate imaging centres).
%
% INPUTS
%   HRRProfilesAll      : totalProfiles x n complex HRR profile matrix
%   CPTWL               : CPI length in profiles (e.g. 32, 64, 128)
%   dopplerBinsToRemove : Doppler bins on EACH SIDE of zero excluded from IC
%
% OUTPUTS
%   peaks      : struct array, one entry per local IC peak, with fields
%                .middleProfile .startProfile .stopProfile .IC
%   searchData : IC values and middle profiles for ALL windows (for plotting)

    totalProfiles = size(HRRProfilesAll, 1);

    if CPTWL > totalProfiles
        error('CPTWL is longer than the radar recording.');
    end

    %% Slide the window (50% overlap) and score every position
    step = CPTWL / 2;
    startPositions = 1 : step : (totalProfiles - CPTWL + 1);
    numWindows = numel(startPositions);

    IC_values      = zeros(numWindows, 1);
    middleProfiles = zeros(numWindows, 1);

    for w = 1:numWindows
        startProfile = startPositions(w);
        stopProfile  = startProfile + CPTWL - 1;
        HRR_profiles = HRRProfilesAll(startProfile:stopProfile, :);
        IC_values(w) = evaluateWindow(HRR_profiles, dopplerBinsToRemove);
        middleProfiles(w) = startProfile + CPTWL/2;
    end

    %% Find ALL local peaks in the IC-versus-position curve
    [peakIC, peakIdx] = findpeaks(IC_values);

    %% Build the peaks struct (one entry per local maximum)
    peaks = struct('middleProfile', {}, 'startProfile', {}, 'stopProfile', {}, 'IC', {});
    for p = 1:numel(peakIdx)
        idx = peakIdx(p);
        startProfile = startPositions(idx);
        peaks(p).middleProfile = middleProfiles(idx);
        peaks(p).startProfile  = startProfile;
        peaks(p).stopProfile   = startProfile + CPTWL - 1;
        peaks(p).IC            = peakIC(p);
    end

    %% Save the full search curve for diagnostics / plotting
    searchData.middleProfiles = middleProfiles;
    searchData.startPositions = startPositions;
    searchData.IC_values      = IC_values;
    searchData.peakIdx        = peakIdx;      % indices of the detected peaks
    searchData.CPTWL          = CPTWL;
end