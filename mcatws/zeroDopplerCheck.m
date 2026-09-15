%% Inspect the zero-Doppler band width for one winning window
clear; close all; clc;

% --- pick the recording and its winning window (from your results table) ---
filename      = 'DAP_2010-10-15_09-57-43_002_GID17282__P460_T001_G1_sb_HRR_G1_02415.mat';
CPTWL         = 128;      % winning CPTWL for this recording
middleProfile = 513;     % winning middle profile for this recording

% --- load and extract that window ---
load(filename);
HRRProfilesAll = sb_HRR.G1.HRR_NoMC_calib.';

startProfile = middleProfile - CPTWL/2;
stopProfile  = startProfile + CPTWL - 1;
HRR_profiles = HRRProfilesAll(startProfile:stopProfile, :);

% --- form the ISAR image for this window (align -> autofocus -> image) ---
[~, ISAR_image] = evaluateWindow(HRR_profiles, 0);   % 0 = don't remove bins, we want the FULL image

% --- Doppler profile: how wide is the zero-Doppler band? ---
DopplerProfile  = mean(abs(ISAR_image), 2);   % avg magnitude across range, per Doppler bin
N               = size(ISAR_image, 1);
DopplerBinIndex = (-N/2 : N/2-1);             % bin index, 0 = zero Doppler

figure;
plot(DopplerBinIndex, 20*log10(DopplerProfile), 'o-');
xlabel('Doppler bin (0 = zero Doppler)');
ylabel('Mean magnitude (dB)');
title('Doppler profile - width of the zero-Doppler band');
xlim([-15 15]); grid on;