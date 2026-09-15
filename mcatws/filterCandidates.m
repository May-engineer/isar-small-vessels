function [kept, stats] = filterCandidates(candidates, overlapThreshold, relativeICThreshold)
% FILTERCANDIDATES  Stage 4: remove invalid candidates, deduplicate overlapping
%   imaging intervals then apply a RELATIVE image contrast quality filter.
%
%   candidates          : struct array from runMCATWS (all refined candidates)
%   overlapThreshold    : overlap ratio above which two candidates are treated
%                         as the same imaging interval (e.g. 0.8). CONFIGURABLE.
%   relativeICThreshold : keep candidates whose IC >= this fraction of the best
%                         IC in the recording (e.g. 0.75). CONFIGURABLE.
%                         Pass 0 to disable the quality filter (dedup only).
%
%   kept  : deduplicated + quality filtered candidates, sorted chronologically
%   stats : struct with inspection numbers

    if nargin < 2, overlapThreshold    = 0.8;  end
    if nargin < 3, relativeICThreshold = 0.75; end

    nRaw = numel(candidates);

    %% Step 1 - remove invalid candidates
    valid = true(1, nRaw);
    for i = 1:nRaw
        c = candidates(i);
        if isempty(c.ISAR_image) || ~isfinite(c.IC) || ...
           isnan(c.startProfile) || c.refinedCPTWL < 2
            valid(i) = false;
        end
    end
    candidates = candidates(valid);
    nValid = numel(candidates);

    %% Step 2 - deduplicate by refined time interval overlap 
    % Multiple initial CPTWLs and nearby MPL peaks can produce refined candidates
    % that represent essentially the same portion of the recording. To avoid
    % retaining redundant images, candidates are first sorted from highest to
    % lowest IC so that the strongest candidate is given priority.
    [~, order] = sort([candidates.IC], 'descend');    % highest IC first
    candidates = candidates(order);

    % Initially assume that every candidate will be retained.
    keepMask = true(1, numel(candidates));

    for i = 1:numel(candidates)
        
        % Skip candidate i if it has already been identified as a duplicate of
        % an earlier, higher-IC candidate.
        if ~keepMask(i), continue; end

        % Determine the refined profile interval occupied by candidate A.
        sA = candidates(i).startProfile;
        eA = candidates(i).startProfile + candidates(i).refinedCPTWL - 1;
        LA = candidates(i).refinedCPTWL;

         % Compare candidate A with every lower-IC candidate that follows it.
        for j = (i+1):numel(candidates)

            % Skip candidate j if it has already been removed.
            if ~keepMask(j), continue; end

            % Determine the refined profile interval occupied by candidate B.
            sB = candidates(j).startProfile;
            eB = candidates(j).startProfile + candidates(j).refinedCPTWL - 1;
            LB = candidates(j).refinedCPTWL;

            % Calculate the number of profiles shared by the two intervals.
            % If the intervals do not overlap, nOverlap is zero.
            nOverlap = max(0, min(eA, eB) - max(sA, sB) + 1);

            % Express the overlap relative to the shorter candidate interval.
            % For example rOverlap = 1 means that the shorter interval lies
            % completely within the longer interval.
            rOverlap = nOverlap / min(LA, LB);

            % If the required fraction of the shorter interval overlaps with
            % the higher IC candidate, treat candidate B as redundant. Since
            % candidates were sorted by decreasing IC, candidate A is retained.
            if rOverlap >= overlapThreshold
                keepMask(j) = false;
            end
        end
    end

    % Retain only the non-redundant candidates.
    dedup = candidates(keepMask);
    nDedup = numel(dedup);

    %% Step 5 - RELATIVE quality filter (fraction of the recording's best IC)
    if relativeICThreshold > 0 && ~isempty(dedup)

        % Find the highest IC among the deduplicated candidates. This provides
        % the reference value against which all remaining candidates are assessed.
        bestIC   = max([dedup.IC]);

         % Retain candidates whose IC is at least the specified fraction of the
         % best IC. For example, a threshold of 0.75 retains candidates with an
         % IC greater than or equal to 75% of the best IC in this recording.
        qualMask = [dedup.IC] >= relativeICThreshold * bestIC;

        % Remove candidates that do not satisfy the relative IC criterion.
        dedup    = dedup(qualMask);
    end

    % Record the number of candidates remaining after quality filtering.
    nKept = numel(dedup);

    %% Step 6 - sort the retained candidates chronologically
    [~, chronOrder] = sort([dedup.middleProfile], 'ascend');
    kept = dedup(chronOrder);

    %% Inspection stats
    icValues = [kept.IC];
    stats.nRaw     = nRaw;
    stats.nValid   = nValid;
    stats.nDedup   = nDedup;
    stats.nKept    = nKept;
    stats.bestIC   = max(icValues);
    stats.worstIC  = min(icValues);
    stats.medianIC = median(icValues);

    % fprintf('\n--- Stage 4: candidate filtering ---\n');
    % fprintf('  Raw candidates:        %d\n', nRaw);
    % fprintf('  After invalid removal: %d\n', nValid);
    % fprintf('  After deduplication:   %d  (overlap threshold %.2f)\n', nDedup, overlapThreshold);
    % fprintf('  After quality filter:  %d  (IC >= %.2f x best)\n', nKept, relativeICThreshold);
    % fprintf('  Retained IC range:     %.2f to %.2f (median %.2f)\n', ...
    %         stats.worstIC, stats.bestIC, stats.medianIC);
    % fprintf('  Retained (chronological):\n');
    % for i = 1:nKept
    %     fprintf('    MP %4d | CPTWL %d | IC %.2f\n', ...
    %             kept(i).middleProfile, kept(i).refinedCPTWL, kept(i).IC);
    % end
end