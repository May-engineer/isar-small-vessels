function [FocusedProfiles, phaseShift, selectedBins] = YuanAutofocusFunction(AlignedProfiles)
%   YUANAUTOFOCUS  Yuan multiple-scatterer autofocus.
%   FocusedProfiles = YuanAutofocusFunction(AlignedProfiles)
%   AlignedProfiles : N x n complex, range aligned profiles
%   Returns the phase corrected profiles, the estimated phase error vector
%   (N x 1) and the range bins selected as scatterers.

    [N, n] = size(AlignedProfiles);
    B = AlignedProfiles;

    % Step 1: mean and variance of amplitude per range bin (coloumn)
    amp = abs(B);
    m = mean(amp, 1);              % 1 x n
    v = var(amp, 0, 1);            % 1 x n

    % Step 2: selection metric v/(v+m^2), smallest = most stable
    metric = v ./ (v + m.^2);

    % Sort ALL bins by stability (most stable first) regardless of threshold
    [sortedMetric, sortedBins] = sort(metric, 'ascend');

    % Prefer bins meeting Yuan's stability criterion (< 0.16), if none do
    % fall back to the most stable bins available (lowest metric).
    qualifying = find(sortedMetric < 0.16);        % positions within the sorted list
    if isempty(qualifying)
        % No bin meets 0.16 -> use the most stable bins anyway
        numScatterers = min(11, numel(sortedBins));
    else
        numScatterers = min(11, numel(qualifying));
    end

    selectedBins = sortedBins(1:numScatterers);    % most stable N bins

    % Step 3: reference = selected scatterer bins from the first profile
    RefBins = B(1, selectedBins);  % 1 x numScatterers

    % Steps 4-7: phase estimate per profile
    RefBinsRep = repmat(conj(RefBins), N, 1);        % N x numScatterers  % Abdul Gaffar
    products   = B(:, selectedBins) .* RefBinsRep;   % N x numScatterers
    avgVal     = sum(products, 2) / numScatterers;   % N x 1
    phaseShift = angle(avgVal);                      % N x 1

    % Step 8: complex phase correction vector (unit magnitude)
    phaseCorrection = exp(-1j * phaseShift);         % N x 1

    % Step 9: apply correction to every profile
    phaseCorrectionRep = repmat(phaseCorrection, 1, n);   % N x n  % Abdul Gaffar
    FocusedProfiles = B .* phaseCorrectionRep;            % N x n
end