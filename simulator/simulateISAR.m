function simulateISAR(flag, rotRate_deg_s, initialOrientation_deg)
%SIMULATEISAR  Generate an idealised point-scatterer ISAR image for a vessel.
%
%   simulateISAR(flag)
%   simulateISAR(flag, rotRate_deg_s, initialOrientation_deg)
%
%   flag : 1 = Yacht (Umoya), 2 = Patrol boat (Namacurra), 3 = RIB
%
%   rotRate_deg_s           : (optional) rotation rate in deg/s.
%                             Defaults: yacht 1.7, patrol 3.4, RIB 3.4.
%                             Pass [] to use the default.
%   initialOrientation_deg  : (optional) initial orientation in deg.
%                             Default 0. Use 180 for an inbound yacht, or
%                             135 to pre-rotate the RIB to match the measured
%                             data. Pass [] to use the default.
%
%   Produces four figures, each in its own window:
%     1. point-scatterer model at the initial orientation
%     2. simulated HRR profiles
%     3. simulated Range-Doppler ISAR image
%     4. simulated down-range vs cross-range image
%
%   No centring shift is applied. Requires Normalise_limitDynamicRange_ISAR_dB
%   on the MATLAB path (run setupPaths first).

    %% ---- Radar / waveform parameters (fixed) ----
    C      = 3e8;        % speed of light (m/s)
    F0     = 9.5e9;      % start frequency (Hz)
    DeltaF = 4e6;        % frequency step (Hz)
    N      = 256;        % frequency steps per burst
    M      = 50;         % number of bursts (HRR profiles)
    PRF    = 25600;      % pulse repetition frequency (Hz)
    SNR_dB = 40;         % signal-to-noise ratio (dB)
    R0     = 10.106e3;   % range to target centre of rotation (m)

    CentreFrequencyVector = (0:N-1)*DeltaF + F0;
    Fc     = mean(CentreFrequencyVector);
    lamda  = C / Fc;
    Pn     = 10^(-(SNR_dB - 10*log10(N))/10);

    BurstRepetitionFrequency = PRF / N;                 % HRR-profile rate (Hz)
    BurstRepetitionInterval  = 1 / BurstRepetitionFrequency;
    TimePerBurstVector       = (0:M-1) * BurstRepetitionInterval;

    TgtVelocity_ms = 0;                                 % no translational motion

    %% ---- Vessel model and defaults ----
    [VesselName, Scatterer_xy_local, defaultRot, viewLabel] = vesselModel(flag);

    % Optional overrides for rotation rate / initial orientation.
    if nargin < 2 || isempty(rotRate_deg_s)
        rotRate_deg_s = defaultRot;
    end
    if nargin < 3 || isempty(initialOrientation_deg)
        initialOrientation_deg = 0;
    end

    NumScatterers = size(Scatterer_xy_local, 1);

    %% ---- Figure 1: point-scatterer model at initial orientation ----
    R_init = rotationMatrix(initialOrientation_deg);
    Scatterer_xy_initial = (R_init * Scatterer_xy_local.').';

    figure;
    plot(Scatterer_xy_initial(:,1), Scatterer_xy_initial(:,2), 'o');
    grid on; axis equal;
    xlabel('x (m)'); ylabel('y (m)');
    title([VesselName ' Point-Scatterer Model (initial orientation)']);

    %% ---- Simulate the received signal over all bursts ----
    RxN = complex(zeros(M, N));
    for b = 1:M
        burstTime = TimePerBurstVector(b);
        angleDeg  = initialOrientation_deg + rotRate_deg_s * burstTime;
        R_b       = rotationMatrix(angleDeg);

        xy_rot = (R_b * Scatterer_xy_local.').';
        xg = xy_rot(:,1) + R0 + TgtVelocity_ms * burstTime;
        yg = xy_rot(:,2);
        Rk = sqrt(xg.^2 + yg.^2);

        Rx = sum(exp(-1i*4*pi*CentreFrequencyVector .* Rk / C), 1);

        noise = sqrt(Pn) * (randn(1,N) + 1i*randn(1,N)) / sqrt(2);
        RxN(b,:) = Rx + noise;
    end

    %% ---- Form HRR profiles and axes ----
    HRR_Profile = ifft(RxN, [], 2);                     % M x N (profiles x range bins)
    RangeAxis   = (0:N-1) * C / (2*N*DeltaF);

    CrossRangeRes_m  = lamda / (2*deg2rad(rotRate_deg_s)*M*(N/PRF));
    CrossRangeAxis_m = (-M/2 : M/2-1) * CrossRangeRes_m;

    %% ---- Figure 2: simulated HRR profiles ----
    HRR_dB = Normalise_limitDynamicRange_ISAR_dB(HRR_Profile, 35);
    figure;
    imagesc(RangeAxis, 1:M, HRR_dB);
    xlabel('Down-Range (m)');
    ylabel('Profile Number');
    title(['Simulated HRR Profiles - ' VesselName]);
    colormap('jet'); colorbar; axis xy;

    %% ---- Form the simulated ISAR image ----
    WindowMatrix = repmat(hamming(M), 1, N);
    ISAR_linear  = fftshift(fft(HRR_Profile .* WindowMatrix, [], 1), 1);
    ISAR_dB      = Normalise_limitDynamicRange_ISAR_dB(ISAR_linear, 35);

    % Doppler axis (general form, both even and odd M).
    DopplerAxis_Hz = ((0:M-1) - floor(M/2)) * BurstRepetitionFrequency / M;

    %% ---- Figure 3: simulated Range-Doppler ISAR image ----
    figure;
    imagesc(RangeAxis, DopplerAxis_Hz, ISAR_dB);
    xlabel('Down-Range (m)');
    ylabel('Doppler frequency (Hz)');
    title({sprintf('Simulated %s %s ISAR Image', viewLabel, VesselName), ...
           sprintf('(Rotation rate = %.1f deg/s, Initial orientation = %.0f deg)', ...
                   rotRate_deg_s, initialOrientation_deg)});
    colormap('jet'); colorbar; axis xy;

    %% ---- Figure 4: down-range vs cross-range ----
    figure;
    imagesc(RangeAxis, CrossRangeAxis_m, ISAR_dB);
    xlabel('Down-Range (m)');
    ylabel('Cross-Range (m)');
    title(sprintf('Simulated %s %s - Down-Range vs Cross-Range', viewLabel, VesselName));
    colormap('jet'); colorbar; axis xy;
end


% ======================================================================
function R = rotationMatrix(angleDeg)
%ROTATIONMATRIX  2-D rotation matrix for a given angle in degrees.
    R = [ cosd(angleDeg) -sind(angleDeg); ...
          sind(angleDeg)  cosd(angleDeg) ];
end


% ======================================================================
function [name, xy, defaultRot, viewLabel] = vesselModel(flag)
%VESSELMODEL  Point-scatterer geometry, default rotation rate and view per vessel.
%
%   flag : 1 = Yacht, 2 = Patrol boat, 3 = RIB
%
%   name       : vessel name for figure titles
%   xy         : local (x,y) scatterer coordinates in metres
%   defaultRot : default rotation rate in deg/s
%   viewLabel  : 'Side-view' or 'Top-view'

    switch flag
        case 1   % Yacht (Umoya), side view
            name = 'Yacht (Umoya)';
            defaultRot = 1.7;
            viewLabel  = 'Side-view';
            xy = [ ...
                % Hull
                -6.25 0; -5.25 0; -4.25 0; -3.25 0; -2.25 0; -1.25 0; 0.00 0; ...
                 1.25 0;  2.25 0;  3.25 0;  4.25 0;  5.25 0;  6.25 0; ...
                % Mast (at x = 3.25, 1 m spacing up to 19 m)
                 3.25 1;  3.25 2;  3.25 3;  3.25 4;  3.25 5;  3.25 6;  3.25 7; ...
                 3.25 8;  3.25 9;  3.25 10; 3.25 11; 3.25 12; 3.25 13; 3.25 14; ...
                 3.25 15; 3.25 16; 3.25 17; 3.25 18; 3.25 19 ];

        case 2   % Patrol boat (Namacurra), side view
            name = 'Patrol boat (Namacurra)';
            defaultRot = 3.4;
            viewLabel  = 'Side-view';
            xy = [ ...
                % Main hull
                -4.75 0.0; -3.75 0.0; -2.75 0.0; -1.75 0.0; -0.75 0.0; 0.00 0.0; ...
                 0.75 0.0;  1.75 0.0;  2.75 0.0;  3.75 0.0;  4.75 0.0; ...
                % Cabin / upper structure
                 0.5 1.5; 1.00 1.5; 1.5 1.5; 2.00 1.00; 2.5 1.00; 3.00 1.00; 3.5 0.50; ...
                % Raised mast / radar structure
                 0.00 0.5; 0.00 1.0; 0.00 1.5; 0.00 2.0; 0.00 2.5; 0.00 3; ...
                % Bow railing
                 4.00 0.5; 4.25 0.5; 4.5 0.5; 4.75 0.5; ...
                % Stern-mounted engine
                -4.75 0.25 ];

        case 3   % RIB, top view
            name = 'RIB';
            defaultRot = 3.4;
            viewLabel  = 'Top-view';
            xy = [ ...
                % Port-side tube
                -3.00 0.75; -2.50 0.75; -2.00 0.75; -1.50 0.75; -1.00 0.75; ...
                -0.50 0.75;  0.00 0.75;  0.50 0.75;  1.00 0.75;  1.50 0.75; ...
                 2.00 0.75;  2.50 0.75;  3.00 0.75; 3.00 0.00; ...   % bow
                % Starboard-side tube
                 3.00 -0.75; 2.50 -0.75; 2.00 -0.75; 1.50 -0.75; 1.00 -0.75; 0.50 -0.75; ...
                 0.00 -0.75; -0.50 -0.75; -1.00 -0.75; -1.50 -0.75; -2.00 -0.75; ...
                -2.50 -0.75; -3.00 -0.75; ...
                % Stern / transom
                -3.00 0.00; ...
                % Outboard engine
                -3.50 0.00 ];

        otherwise
            error('simulateISAR:badFlag', ...
                  'flag must be 1 (Yacht), 2 (Patrol), or 3 (RIB).');
    end
end