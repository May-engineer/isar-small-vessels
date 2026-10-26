%% runISARMovie.m - Generate ISAR movies for a selected recording
% Forms a sequence of focused ISAR images across one recording (fixed CPTWL,
% 50% overlap) and saves them as slow and/or fast MP4 movies.
%
% To use: set recordingID and CPTWL below, then run. Recording filenames are
% defined in recordingParameters.m and loaded via loadRecording.m.

clear; clc;

%% Configure project paths
paths = setupPaths();

%% Settings
recordingID = 'Y2';     % recording to process (see recordingParameters.m)
CPTWL       = 50;      % coherent processing window length in profiles
dopplerBinsToRemove = 2;
slowFPS     = 2;        % slow-movie frame rate
fastFPS     = 6;        % fast-movie frame rate

%% Retrieve recording metadata and load the radar data
p = recordingParameters(recordingID);
[HRRProfilesAll, RangeAxis, ProfileRepetitionFreq] = ...
    loadRecording(fullfile(paths.data, p.filename));

%% Output location and movie names
movieDir = fullfile(paths.outputs, 'movies', lower(p.vessel));
if ~isfolder(movieDir)
    mkdir(movieDir);
end
slowName = fullfile(movieDir, sprintf('%s_CPTWL%d_slow.mp4', p.id, CPTWL));
fastName = fullfile(movieDir, sprintf('%s_CPTWL%d_fast.mp4', p.id, CPTWL));

%% Slow movie
generateISARMovie(HRRProfilesAll, ProfileRepetitionFreq, CPTWL, ...
                  RangeAxis, dopplerBinsToRemove, slowFPS, slowName);

%% Fast movie (uncomment to also generate)
% generateISARMovie(HRRProfilesAll, ProfileRepetitionFreq, CPTWL, ...
%                   RangeAxis, dopplerBinsToRemove, fastFPS, fastName);