function candidates = runMCATWS(HRRProfilesAll, ProfileRepetitionFreq, ...
                                dopplerBinsToRemove, nInitial, RangeAxis)
% RUNMCATWS  Full MC-ATWS: for each initial CPTWL, find local IC peaks (MPL)
%   and refine the window length at each peak (WLE). Returns all refined
%   candidate images for the recording.
%
%   HRRProfilesAll        : totalProfiles x n complex HRR profiles
%   ProfileRepetitionFreq : slow-time sample rate (Hz)
%   dopplerBinsToRemove   : Doppler bins each side of zero excluded from IC
%   nInitial              : WLE starting step half-width (e.g. 5)
%   RangeAxis             : range axis (m) (passed through for later display)
%
%   candidates : struct array of refined imaging intervals, each with fields
%                .initialCPTWL .middleProfile .refinedCPTWL .CPI_seconds
%                .IC .startProfile .ISAR_image

    initialCPTWLs = [32, 64, 128];

    candidates = struct('initialCPTWL', {}, 'middleProfile', {}, ...
                        'refinedCPTWL', {}, 'CPI_seconds', {}, ...
                        'IC', {}, 'startProfile', {}, 'ISAR_image', {});

    for c = 1:numel(initialCPTWLs)
        CPTWL = initialCPTWLs(c);

        % MPL: find local IC peaks at this initial CPTWL
        [peaks, ~] = searchCPTWL(HRRProfilesAll, CPTWL, dopplerBinsToRemove);

        % fprintf('\n=== Initial CPTWL %d: %d local peaks found ===\n', CPTWL, numel(peaks));

        % WLE: refine the window length at each peak centre 
        for p = 1:numel(peaks)
            centre = peaks(p).middleProfile;

            [refCPTWL, refIC, refImg, refStart] = ...
                refineWLE(HRRProfilesAll, centre, CPTWL, nInitial, dopplerBinsToRemove);

            % store this refined candidate
            k = numel(candidates) + 1;
            candidates(k).initialCPTWL  = CPTWL;
            candidates(k).middleProfile = centre;
            candidates(k).refinedCPTWL  = refCPTWL;
            candidates(k).CPI_seconds   = refCPTWL / ProfileRepetitionFreq;
            candidates(k).IC            = refIC;
            candidates(k).startProfile  = refStart;
            candidates(k).ISAR_image    = refImg;
            % 
            % fprintf('  Peak MP %4d: CPTWL %d -> %d (%.2f s), IC %.2f -> %.2f\n', ...
            %         centre, CPTWL, refCPTWL, candidates(k).CPI_seconds, ...
            %         peaks(p).IC, refIC);
        end
    end

    % fprintf('\n>>> Total refined candidates for this recording: %d\n', numel(candidates));
end