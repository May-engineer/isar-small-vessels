function [AlignedProfiles, rawDelays, NonIntegerDelays, stats] = HaywoodAlignFunction(HRR_profiles)
%   HAYWOODALIGNFUNCTION  Haywood range alignment of complex HRR profiles.
%   [AlignedProfiles, rawDelays, NonIntegerDelays, stats] = HaywoodAlignFunction(HRR_profiles)
%   HRR_profiles : N x n complex matrix (rows = profiles, cols = range bins)
%   Returns the range-aligned complex profiles, the raw delay estimates, the
%   non-integer fitted delays and the robustfit stats (weights etc.).
%
%   Delay trend is estimated with robustfit (bisquare, no intercept) so it is
%   robust to outliers from scatterer switching and is constrained through the
%   origin (reference profile = index 0 = zero delay). Non-integer shifts are
%   applied via a frequency-domain phase ramp, the -1j sign matches this
%   pipeline's delay convention (verified by checking alignment).

    [N, n] = size(HRR_profiles);

    % Reference = first profile
    reference = HRR_profiles(1, :);

    % Vectorised cross-correlation (magnitudes), all profiles at once
    refFFT  = repmat(fft(abs(reference), [], 2), N, 1);   % N x n (replicated reference)  % Abdul Gaffar
    dataFFT = fft(abs(HRR_profiles), [], 2);              % N x n
    C       = ifft(refFFT .* conj(dataFFT), [], 2);       % N x n
    [~, peakIdx] = max(abs(C), [], 2);                    % N x 1

    % Convert circular peak index to signed lag
    rawDelays = peakIdx - 1;
    rawDelays(rawDelays > n/2) = rawDelays(rawDelays > n/2) - n;
    rawDelays = rawDelays.';                               % 1 x N

    % Robust trend fit: bisquare, no intercept -> line forced through the origin
    % (reference profile = index 0 = zero delay). Robust to outliers from
    % scatterer switching, with no window/threshold tuning.
    profileIndex = (0:(N-1)).';                            % index 0 = reference  % Abdul Gaffar
    [b, stats]   = robustfit(profileIndex, rawDelays(:), 'bisquare', [], 'off');
    NonIntegerDelays = (b(1)*profileIndex).';              % fitted delays (row vector)  % Abdul Gaffar

    % Apply non-integer shifts via frequency-domain phase ramp
    AlignedProfiles = zeros(size(HRR_profiles), 'like', HRR_profiles);
    freqIndex = 0:(n-1);                                   % frequency index (matches plain fft/ifft)
    for l = 1:N
        shift = NonIntegerDelays(l);
        ShiftVector = exp(-1j*2*pi*freqIndex*shift/n);     % -1j: verified profiles align
        AlignedProfiles(l, :) = ifft( fft(HRR_profiles(l, :)) .* ShiftVector );
    end
end