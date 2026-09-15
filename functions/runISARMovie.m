%% Generate slow and fast ISAR movies
% To use: edit the four settings below for the recording you want, then run.
%   filename  - the CSIR .mat recording
%   vessel    - label used in the output movie name
%   recTag    - short tag for the movie filename (avoids long Windows paths)
%   CPTWL     - coherent processing window length in profiles
% The script handles the Pattern_time / pattern_time field-name variation
% automatically. Requires generateISARMovie.m and the pipeline functions on the path.
clear;
clc;

%% Load recording
filename = 'DAP_2010-10-14_15-10-00_029_RIB_CRISS-CROSS_SPEEDMEDIUM_18KNOTS_462__P462_T001_G1_sb_HRR_G1_01342.mat';
vessel   = 'RIB1';                      % vessel label for the movie name

% Use a shorter tag for the movie filename to avoid Windows path-length issues
recTag = 'Criss-Cross_01342';
slowName = sprintf('%s_%s_slow.mp4', vessel, recTag);
fastName = sprintf('%s_%s_fast.mp4', vessel, recTag);

S = load(filename);
sb_HRR = S.sb_HRR;

%% Extract radar data
HRRProfilesAll = sb_HRR.G1.HRR_NoMC_calib.';
RangeAxis      = sb_HRR.G1.xaxis_downrange_m;
% Handle the Pattern_time / pattern_time capitalisation that varies between files
if isfield(sb_HRR.G1, 'Pattern_time')
    patternTime = sb_HRR.G1.Pattern_time;
elseif isfield(sb_HRR.G1, 'pattern_time')
    patternTime = sb_HRR.G1.pattern_time;
else
    error('No Pattern_time / pattern_time field found.');
end
ProfileRepetitionFreq = 1 / patternTime;

%% Processing settings
CPTWL               = 200;
dopplerBinsToRemove = 2;

%% Slow movie
generateISARMovie( ...
    HRRProfilesAll, ...
    ProfileRepetitionFreq, ...
    CPTWL, ...
    RangeAxis, ...
    dopplerBinsToRemove, ...
    2, ...
    slowName);              % <-- use the auto-generated name

% %% Fast movie
% generateISARMovie( ...
%     HRRProfilesAll, ...
%     ProfileRepetitionFreq, ...
%     CPTWL, ...
%     RangeAxis, ...
%     dopplerBinsToRemove, ...
%     6, ...
%     fastName);              % <-- use the auto-generated name