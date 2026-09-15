function [bestCPTWL, bestIC, bestImage, bestStart] = refineWLE( ...
    HRRProfilesAll, middleProfile, initialCPTWL, nInitial, dopplerBinsToRemove)
% REFINEWLE  Window Length Estimator (Step 3 of MC-ATWS).
%   At a fixed central time (middleProfile), refine the CPTWL to maximise image
%   contrast following the textbook grow/shrink search with a decreasing step.
%
%   HRRProfilesAll      : totalProfiles x n complex HRR profiles
%   middleProfile       : fixed central profile of the window (the optimal centre)
%   initialCPTWL        : starting window length in profiles (e.g. 32/64/128)
%   nInitial            : starting step half-width (e.g. 5), step = 2n, n decreases to 0
%   dopplerBinsToRemove : Doppler bins each side of zero excluded from IC
%
%   Returns the refined CPTWL, its IC, its ISAR image and its start profile.

    totalProfiles = size(HRRProfilesAll, 1);

    % helper: evaluate a window of a given length at the fixed centre
    function [IC, img, startP, ok] = evalAtLength(CPTWL)
        startP = middleProfile - floor(CPTWL/2);
        stopP  = startP + CPTWL - 1;
        if CPTWL < 2 || startP < 1 || stopP > totalProfiles
            IC = -Inf; img = []; ok = false;   % window doesn't fit -> invalid
            return;
        end
        [IC, img] = evaluateWindow(HRRProfilesAll(startP:stopP, :), dopplerBinsToRemove);
        ok = true;
    end

    % start from the initial CPTWL 
    [currentIC, currentImg, currentStart, ok] = evalAtLength(initialCPTWL);
    currentCPTWL = initialCPTWL;
    if ~ok
        % initial window itself invalid (shouldn't happen) - return as is
        bestCPTWL = initialCPTWL; bestIC = -Inf; bestImage = []; bestStart = NaN;
        return;
    end

    bestCPTWL = currentCPTWL; bestIC = currentIC;
    bestImage = currentImg;   bestStart = currentStart;

    % try each direction: grow first then shrink if growing never helped 
    for direction = [+1, -1]        % +1 = grow, -1 = shrink
        n = nInitial;
        flag = false;               % did this direction ever improve IC?

        % reset to the best so far as the starting point for this direction
        currentCPTWL = bestCPTWL;
        currentIC    = bestIC;

        while n >= 1
            % change window length by 2n (n each side), direction sets grow/shrink
            trialCPTWL = currentCPTWL + direction * 2 * n;
            [trialIC, trialImg, trialStart, ok] = evalAtLength(trialCPTWL);


            if ok && trialIC >= currentIC
                % improvement: accept, keep same n, keep going this direction
                currentCPTWL = trialCPTWL;
                currentIC    = trialIC;
                flag = true;
                if trialIC > bestIC
                    bestCPTWL = trialCPTWL; bestIC = trialIC;
                    bestImage = trialImg;   bestStart = trialStart;
                end
            else
                % no improvement (or invalid): shrink the step
                n = n - 1;
            end
        end

        % textbook: if growing improved at some point, stop (don't try shrinking)
        if direction == +1 && flag
            break;
        end
    end
end