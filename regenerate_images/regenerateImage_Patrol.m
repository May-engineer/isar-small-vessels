%% Regenerate and centre only NAMACURA MP436 / Frame 15

clearvars;
close all;
clc;

%% ============================================================
% Load the relevant Namacura recording
% =============================================================

filename ='DAP_2010-10-15_07-06-04_000_NAMACURA_INB_MAXKNOTS_870__P870_T001_G1_sb_HRR_G1_02804.mat ';

S = load(filename);
sb_HRR = S.sb_HRR;

%% Extract radar data

HRRProfilesAll = sb_HRR.G1.HRR_NoMC_calib.';
RangeAxis      = sb_HRR.G1.xaxis_downrange_m;

ProfileRepetitionFreq = 1 / sb_HRR.G1.Pattern_time;

%% ============================================================
% Selected ISAR image settings
% =============================================================

middleProfile        = 958;
CPTWL                = 58;
dopplerBinsToRemove  = 2;

% Calculate the exact CPI limits
startProfile = middleProfile - CPTWL/2;
stopProfile  = startProfile + CPTWL - 1;

fprintf('Start profile: %d\n', startProfile);
fprintf('Stop profile: %d\n', stopProfile);
fprintf('Middle profile: %d\n', middleProfile);

%% Extract only the selected CPI

HRR_profiles = ...
    HRRProfilesAll(startProfile:stopProfile, :);

%% Form the focused ISAR image

[IC_value, ISAR_image] = ...
    evaluateWindow(HRR_profiles, dopplerBinsToRemove);

%% ============================================================
% Apply the manually selected circular shift
% =============================================================

rowShift = 0;
colShift = 25;    % Try a value between 15 and 20 bins

ISAR_centred = circshift( ...
    ISAR_image, [rowShift, colShift]);

%% ============================================================
% Generate plotting axes
% =============================================================

N = CPTWL;

DopplerAxis_Hz = ...
    (-N/2 : N/2-1) * ProfileRepetitionFreq / N;

RangeAxis = reshape( ...
    RangeAxis, 1, []);

%% Convert centred ISAR image to dB

image_dB = 20 * log10(abs(ISAR_centred) + eps);

%% Use the same 35 dB display range as the movie

maximum_dB    = max(image_dB(:));
lowerLimit_dB = maximum_dB - 35;
clims         = [lowerLimit_dB, maximum_dB];

% %% ============================================================
% % Display the centred ISAR image - below creates image like simulator not
% like in movie
% % =============================================================
% 
% fig = figure('Color', 'w');
% 
% imagesc( ...
%     RangeAxis, ...
%     DopplerAxis_Hz, ...
%     image_dB, ...
%     clims);
% 
% xlabel('Range (m)');
% ylabel('Doppler frequency (Hz)');
% 
% title(sprintf( ...
%     ['CPTWL %d | Profiles %d-%d | Middle Profile %d | ' ...
%      'IC %.2f | Range Shift %d Bins'], ...
%     CPTWL, ...
%     startProfile, ...
%     stopProfile, ...
%     middleProfile, ...
%     IC_value, ...
%     colShift));
% 
% colormap('jet');
% colorbar;
% axis xy;
% 
% %% ============================================================
% % Save the newly generated centred image
% % =============================================================
% 
% outputFolder = 'Selected_Namacura_ISAR_Images';
% 
% if ~exist(outputFolder, 'dir')
%     mkdir(outputFolder);
% end
% 
% outputName = ...
%     'NAMACURA_02743_MP436_CPTWL58_Frame15_Centred.png';
% 
% outputPath = fullfile(outputFolder, outputName);
% 
% exportgraphics(fig, outputPath, 'Resolution', 300);
% 
% fprintf('Saved centred ISAR image:\n%s\n', outputPath);

%% ============================================================
% Display using the same dimensions as the movie frame
% =============================================================

fig = figure( ...
    'Color', 'w', ...
    'Units', 'pixels', ...
    'Position', [100, 100, 1074, 648]);

imagesc( ...
    RangeAxis, ...
    DopplerAxis_Hz, ...
    image_dB, ...
    clims);

xlabel('Range (m)');
ylabel('Doppler frequency (Hz)');

% Keep the same title format as the original movie
title(sprintf( ...
    'CPTWL %d | Profiles %d-%d | Middle Profile %d | IC %.2f', ...
    CPTWL, ...
    startProfile, ...
    stopProfile, ...
    middleProfile, ...
    IC_value));

colormap('jet');
colorbar;
axis xy;

drawnow;

%% ============================================================
% Capture and save exactly as the movie-generation script does
% =============================================================

outputFolder = 'Selected_Namacura_ISAR_Images';

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

outputName = ...
    'NAMACURA_02804_MP958_CPTWL58_Frame33_Centred.png';

outputPath = fullfile(outputFolder, outputName);

centredFrame = getframe(fig);
imwrite(centredFrame.cdata, outputPath);

fprintf('Saved centred ISAR image:\n%s\n', outputPath);
