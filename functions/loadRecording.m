function [HRRProfilesAll, RangeAxis, ProfileRepetitionFreq] = loadRecording(recordingFile)
%LOADRECORDING  Load one CSIR recording and extract the processing inputs.
%
%   [HRRProfilesAll, RangeAxis, ProfileRepetitionFreq] = loadRecording(recordingFile)
%
%   recordingFile          : full path to a CSIR .mat recording
%   HRRProfilesAll         : profiles x range-bins complex HRR matrix
%   RangeAxis              : down-range axis in metres (row vector)
%   ProfileRepetitionFreq  : HRR-profile repetition frequency (Hz)
%
%   Handles the Pattern_time / pattern_time field-name variation between
%   recordings.

    if ~isfile(recordingFile)
        error('loadRecording:fileNotFound', ...
              ['Recording not found:\n  %s\n' ...
               'Place the CSIR .mat recordings in the data/ folder. ' ...
               'They are not distributed with this repository.'], recordingFile);
    end

    S = load(recordingFile);
    g = S.sb_HRR.G1;

    HRRProfilesAll = g.HRR_NoMC_calib.';
    RangeAxis      = reshape(g.xaxis_downrange_m, 1, []);

    % Field name varies between recordings.
    if isfield(g, 'Pattern_time')
        patternTime = g.Pattern_time;
    elseif isfield(g, 'pattern_time')
        patternTime = g.pattern_time;
    else
        error('loadRecording:noPatternTime', ...
              'No Pattern_time / pattern_time field in %s', recordingFile);
    end
    ProfileRepetitionFreq = 1 / patternTime;
end