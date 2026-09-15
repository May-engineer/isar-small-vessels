function [IC_value, ISAR_image, FocusedProfiles] = evaluateWindow(HRR_profiles, dopplerBinsToRemove)
% EVALUATEWINDOW  Align, autofocus, form and score one candidate CPI window.
%
%   HRR_profiles        : N x n complex HRR profiles
%                         (rows = profiles / slow time, coloumns = range bins)
%
%   dopplerBinsToRemove : number of Doppler bins on EACH SIDE of zero Doppler
%                         to EXCLUDE from the IC calculation (removed, not zeroed).
%                         Example: 1 -> removes 3 bins total
%                                  2 -> removes 5 bins total
%
%   IC_value            : Martorella image contrast (computed on the ISAR image
%                         with the central low spread Doppler bins removed)
%   ISAR_image          : full complex ISAR image (zero Doppler bins RETAINED,
%                         for display)
%   FocusedProfiles     : range aligned and autofocused HRR profiles

    [N, n] = size(HRR_profiles);

    %% Range alignment (robustfit-based Haywood)
    AlignedProfiles = HaywoodAlignFunction(HRR_profiles);

    %% Yuan multiple scatterer autofocus
    FocusedProfiles = YuanAutofocusFunction(AlignedProfiles);

    %% Form ISAR image (FFT down slow time)
    window       = hamming(N);               % N x 1
    WindowMatrix = repmat(window, 1, n);     % N x n  (explicit dims, per Abdul Gaffar)

    ISAR_image = fftshift( fft(FocusedProfiles .* WindowMatrix, [], 1), 1 );

    %% Exclude the low spread zero-Doppler region from the IC calculation only
    IC_image  = ISAR_image;                  % copy, keep ISAR_image full for display
    centreBin = floor(N/2) + 1;              % zero-Doppler row after fftshift

    lo = max(1, centreBin - dopplerBinsToRemove);
    hi = min(N, centreBin + dopplerBinsToRemove);

    IC_image(lo:hi, :) = [];                  % REMOVE those Doppler rows entirely

    %% Martorella image contrast (on the bin removed image)
    I = abs(IC_image(:)).^2;                  % image intensity (power)
    meanIntensity = mean(I);
    IC_value = sqrt(mean((I - meanIntensity).^2)) / meanIntensity;

end