function verifyAlignmentAutofocus(recordingID, middleProfile, CPTWL, ...
                                  rowShift, colShift)
%VERIFYALIGNMENTAUTOFOCUS  Verify range alignment and autofocus on one CPI.
%
%   verifyAlignmentAutofocus(recordingID, middleProfile, CPTWL)
%   verifyAlignmentAutofocus(recordingID, middleProfile, CPTWL, rowShift, colShift)
%
%   Forms the ISAR image and image contrast (IC) for a single CPI at three
%   processing stages:
%     1. before alignment (no range alignment or autofocus)
%     2. after modified Haywood range alignment only
%     3. after range alignment and adapted Yuan multiple-scatterer autofocus
%
%   The three ISAR images and the corresponding unaligned/aligned HRR
%   profiles are displayed in the project style, and the IC progression is
%   printed. This demonstrates the effect of each translational
%   motion-compensation stage on image focus.
%
%   recordingID   : recording ID from recordingParameters.m (e.g. 'Y2')
%   middleProfile : selected middle HRR-profile index
%   CPTWL         : coherent processing time-window length (profiles)
%   rowShift      : Doppler-bin shift for the ISAR images (default 0)
%   colShift      : range-bin shift for the ISAR images and HRR profiles (default 0)

    if nargin < 4 || isempty(rowShift), rowShift = 0; end
    if nargin < 5 || isempty(colShift), colShift = 0; end

    dopplerBinsToRemove = 2;

    %% Load the recording
    paths = setupPaths();
    p = recordingParameters(recordingID);
    [HRRProfilesAll, RangeAxis, ProfileRepetitionFreq] = ...
        loadRecording(fullfile(paths.data, p.filename));
    RangeAxis = reshape(RangeAxis, 1, []);

    %% CPI limits (higher-indexed central profile for even CPTWL)
    N = CPTWL;
    startProfile = middleProfile - floor(N/2);
    stopProfile  = startProfile + N - 1;
    if startProfile < 1 || stopProfile > size(HRRProfilesAll, 1)
        error('verifyAlignmentAutofocus:cpiOutOfRange', ...
              'Selected CPI (%d-%d) is outside the recording.', ...
              startProfile, stopProfile);
    end
    HRR_profiles   = HRRProfilesAll(startProfile:stopProfile, :);
    DopplerAxis_Hz = ((0:N-1) - floor(N/2)) * ProfileRepetitionFreq / N;

    %% ---- Three processing stages ----
    % Stage 1: before alignment
    ISAR_before = formImage(HRR_profiles);
    IC_before   = computeIC(ISAR_before, N, dopplerBinsToRemove);

    % Stage 2: after range alignment only
    AlignedProfiles = HaywoodAlignFunction(HRR_profiles);
    ISAR_aligned    = formImage(AlignedProfiles);
    IC_aligned      = computeIC(ISAR_aligned, N, dopplerBinsToRemove);

    % Stage 3: after range alignment and autofocus
    FocusedProfiles = YuanAutofocusFunction(AlignedProfiles);
    ISAR_focused    = formImage(FocusedProfiles);
    IC_focused      = computeIC(ISAR_focused, N, dopplerBinsToRemove);

    %% ---- Verify against the main processing function ----
    [IC_check, ISAR_check, FocusedProfiles_check] = ...
        evaluateWindow(HRR_profiles, dopplerBinsToRemove);

    assert(abs(IC_check - IC_focused) < 1e-10, ...
        'IC differs from evaluateWindow.');

    assert(max(abs(ISAR_check(:) - ISAR_focused(:))) < 1e-10, ...
        'ISAR image differs from evaluateWindow.');

    assert(max(abs(FocusedProfiles_check(:) - FocusedProfiles(:))) < 1e-10, ...
        'Focused profiles differ from evaluateWindow.');

    fprintf('Verification against evaluateWindow passed.\n');
    
    %% ---- Display IC results ----
    fprintf('IC  before = %.4f  ->  aligned = %.4f  ->  focused = %.4f\n', ...
            IC_before, IC_aligned, IC_focused);

    %% ---- ISAR images at each stage ----
    plotISAR(ISAR_before,  rowShift, colShift, RangeAxis, DopplerAxis_Hz, ...
        sprintf('ISAR Before Range Alignment  |  IC %.2f', IC_before));
    plotISAR(ISAR_aligned, rowShift, colShift, RangeAxis, DopplerAxis_Hz, ...
        sprintf('ISAR After Range Alignment  |  IC %.2f', IC_aligned));
    plotISAR(ISAR_focused, rowShift, colShift, RangeAxis, DopplerAxis_Hz, ...
        sprintf('ISAR After Range Alignment and Autofocus  |  IC %.2f', IC_focused));

    %% ---- HRR profiles: unaligned vs aligned ----
    plotHRR(HRR_profiles,    colShift, RangeAxis, N, 'HRR Profiles Before Range Alignment');
    plotHRR(AlignedProfiles, colShift, RangeAxis, N, 'HRR Profiles After Range Alignment');
end


% ======================================================================
function ISAR = formImage(profiles)
%FORMIMAGE  Hamming-windowed slow-time FFT with Doppler centring (as evaluateWindow).
    [N, n] = size(profiles);
    WindowMatrix = repmat(hamming(N), 1, n);
    ISAR = fftshift(fft(profiles .* WindowMatrix, [], 1), 1);
end

% ======================================================================
function IC = computeIC(ISAR_image, N, dopplerBinsToRemove)
%COMPUTEIC  Martorella image contrast with central Doppler rows removed (as evaluateWindow).
    IC_image  = ISAR_image;
    centreBin = floor(N/2) + 1;
    lo = max(1, centreBin - dopplerBinsToRemove);
    hi = min(N, centreBin + dopplerBinsToRemove);
    IC_image(lo:hi, :) = [];
    I = abs(IC_image(:)).^2;
    IC = sqrt(mean((I - mean(I)).^2)) / mean(I);
end

% ======================================================================
function plotISAR(ISAR_image, rowShift, colShift, RangeAxis, DopplerAxis_Hz, titleStr)
%PLOTISAR  Display an ISAR image in the project style.
    fontSize = 25;
    ISAR_display = circshift(ISAR_image, [rowShift, colShift]);
    image_dB = 20*log10(abs(ISAR_display) + eps);
    image_dB = image_dB - max(image_dB(:));

    figure('Color','w','Units','pixels','Position',[100 100 1074 648]);
    imagesc(RangeAxis, DopplerAxis_Hz, image_dB, [-35 0]);
    xlabel('Down-Range (m)', 'FontSize',fontSize, 'FontWeight','bold');
    ylabel('Doppler frequency (Hz)', 'FontSize',fontSize, 'FontWeight','bold');
    title(titleStr, 'FontSize',fontSize, 'FontWeight','bold');
    ax = gca; ax.FontSize = fontSize; ax.LineWidth = 1;
    colormap('jet');
    cb = colorbar; cb.FontSize = fontSize; cb.Ticks = -35:5:0;
    axis xy;
    xticks(ceil(min(RangeAxis)/2)*2 : 2 : floor(max(RangeAxis)/2)*2);
    ylim([-80 80]); yticks(-80:20:80);
    drawnow;
end

% ======================================================================
function plotHRR(profiles, colShift, RangeAxis, CPTWL, titleStr)
%PLOTHRR  Display HRR profiles in the project style (range shift only).
    fontSize = 25;
    profiles_display = circshift(profiles, [0, colShift]);
    HRR_dB = 20*log10(abs(profiles_display) + eps);
    HRR_dB = HRR_dB - max(HRR_dB(:));

    figure('Color','w','Units','pixels','Position',[100 100 1074 648]);
    imagesc(RangeAxis, 1:CPTWL, HRR_dB, [-35 0]);
    xlabel('Down-Range (m)', 'FontSize',fontSize, 'FontWeight','bold');
    ylabel('Profile Number', 'FontSize',fontSize, 'FontWeight','bold');
    title(titleStr, 'FontSize',fontSize, 'FontWeight','bold');
    colormap('jet');
    cb = colorbar; cb.FontSize = fontSize; cb.Ticks = -35:5:0;
    axis xy;
    xticks(ceil(min(RangeAxis)/2)*2 : 2 : floor(max(RangeAxis)/2)*2);
    yticks(0:10:CPTWL);
    ax = gca; ax.FontSize = fontSize; ax.LineWidth = 1;
    drawnow;
end