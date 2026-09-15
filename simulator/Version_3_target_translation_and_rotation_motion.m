
% Version 3 - include target translation motion 

clearvars;
close all;
clc;

C = 3e8;                                            % Speed of light
F0 = 9.5e9;                                         % Starting frequency
DeltaF = 4e6;                                       % Frequency step size
N = 256;                                            % Number of pulses/stepped-frequencies in one burst
M = 50; %32;                                        % Number of Bursts collected (burst = HRR profile)
PRF = 25600; %16e3;                                 % Pulse Repetition Frequency - individual pulses are transmitted at 25,600 pulses/s.
SNR_dB = 40;                                        % Assume signal power = 1
CentreFrequencyVector = (0:1:(N-1))*DeltaF + F0;
R0 = 10.106e3;                                      % Distance to centre of target in m 
Pn = 10^(-(SNR_dB-10*log10(N))/10);                 % Simulated Noise Power (estimate)

Fc = mean(CentreFrequencyVector);                   % Calculate centre frequency of the entire stepped-frequency burst, Fc 
lamda = C/(Fc);                                     % Wavelength to convert Doppler information into cross-range distance. 
Range_Resolution = C/(2*N*DeltaF);
Unambiguous_range = C/(2*DeltaF);

PRI = 1/PRF; % individual pulses are separated by 100 microseconds.
BurstRepetitionFrequency = PRF/N; % Radar produces 100 HRR profiles per second (burst = profile)
BurstRepetitionInterval = 1/BurstRepetitionFrequency; % One HRR profile(burst) is produced every 10 ms

% Time of every burst (slow-time axis --> At what time was this particular HRR profile collected)
TimePerBurstVector = (0:1:(M-1))*BurstRepetitionInterval; % Slow-time axis for the M HRR profiles

disp(' ');
disp(['Range resolution = ' num2str(round(Range_Resolution, 3)) ' m']);
disp(['Unambiguous Range = ' num2str(round(Unambiguous_range,0)) ' m']);
disp(' ');

TgtVelocity_ms = 0; % No translational motion

%% ===== VESSEL SELECTION FLAG =====
% flag = 1 -> Yacht (Umoya)   |   flag = 2 -> Patrol boat (Namacurra)   |   flag = 3 -> RIB
flag = 3;

switch flag
    case 1   % ---------- Yacht (Umoya), side view ----------
        VesselName             = 'Yacht (Umoya)';
        RotRate_deg_s          = 1.7;
        InitialOrientation_deg = 180;
        Scatterer_xy_local = [ ...
            % Hull
            -6.25 0; -5.25 0; -4.25 0; -3.25 0; -2.25 0; -1.25 0; 0.00 0; ...
             1.25 0;  2.25 0;  3.25 0;  4.25 0;  5.25 0;  6.25 0; ...
            % Mast (at x = 3.25, 1 m spacing up to 19 m)
             3.25 1;  3.25 2;  3.25 3;  3.25 4;  3.25 5;  3.25 6;  3.25 7; ...
             3.25 8;  3.25 9;  3.25 10; 3.25 11; 3.25 12; 3.25 13; 3.25 14; ...
             3.25 15; 3.25 16; 3.25 17; 3.25 18; 3.25 19 ];
        % Scatterer_xy_local(:,2) = -Scatterer_xy_local(:,2);

    case 2   % ---------- Patrol boat (Namacurra), side view ----------
        VesselName             = 'Patrol boat (Namacurra)';
        RotRate_deg_s          = 3.4;
        InitialOrientation_deg = 180;
        Scatterer_xy_local = [ ...
            % Main hull
            -4.75 0.0; -3.75 0.0; -2.75 0.0; -1.75 0.0; -0.75 0.0; 0.00 0.0; ...
             0.70 0.0;  1.75 0.0;  2.75 0.0;  3.75 0.0;  4.75 0.0; ...
            % Cabin / upper structure
             0.5 1.5; 1.00 1.5; 1.5 1.5; 2.00 1.00; 2.5 1.00; 3.00 1.00; 3.5 0.50; ...
            % Raised mast / radar structure
             0.00 0.5; 0.00 1.0; 0.00 1.5; 0.00 2.0; 0.00 2.5; ...
            % Bow railing
             4.00 0.5; 4.25 0.5; 4.5 0.5; 4.75 0.5; ...
            % Stern-mounted engine
            -4.75 0.25 ];
        Scatterer_xy_local(:,2) = -Scatterer_xy_local(:,2);

    case 3   % ---------- RIB, top view ----------
        VesselName             = 'RIB';
        RotRate_deg_s          = 3.4;
        InitialOrientation_deg = 60;   % -45 degrees start the RIB already rotated, to mimic the measured data
        Scatterer_xy_local = [ ...
            % Port-side tube
            -3.00 0.75; -2.50 0.75; -2.00 0.75; -1.50 0.75; -1.00 0.75; ...
            -0.50 0.75;  0.00 0.75;  0.50 0.75;  1.00 0.75;  1.50 0.75; ...
             2.00 0.75;  2.50 0.75;  3.00 0.75; 3.00 0.00 ...     % Bow
            % Starboard-side tube
             3.00 -0.75; 2.50 -0.75; 2.00 -0.75; 1.50 -0.75; 1.00 -0.75; 0.50 -0.75; ...
             0.00 -0.75; -0.50 -0.75; -1.00 -0.75; -1.50 -0.75; -2.00 -0.75; ...
            -2.50 -0.75; -3.00 -0.75; ...
            % Stern / transom
            -3.00 0.00; ...
            % Outboard engine
            -3.50 0.00 ];

    otherwise
        error('flag must be 1 (Yacht), 2 (Patrol boat), or 3 (RIB).');
end

NumScatterers = size(Scatterer_xy_local,1);

% Rotate the scatterers to the initial orientation for the plot,
% so the figure shows the actual starting geometry (e.g. RIB at -45 deg).
InitialRotationMatrix = [ cosd(InitialOrientation_deg) -sind(InitialOrientation_deg); ...
                          sind(InitialOrientation_deg)  cosd(InitialOrientation_deg) ];
Scatterer_xy_initial = (InitialRotationMatrix * Scatterer_xy_local.').';

figure;
plot(Scatterer_xy_initial(:,1), Scatterer_xy_initial(:,2), 'o');
grid on; axis equal;
xlabel('x (m)'); ylabel('y (m)');
title([VesselName ' Point-Scatterer Model (initial orientation)']);

% Preallocate arrays
RotationAngleDeg = zeros(1,M); % array for rotation angle at each burst
Scatterer_xy_local_rotated = zeros(NumScatterers,2); % array for rotated coordinates of every scatterer
Scatterer_xy_global = zeros(NumScatterers,2); % array for actual coordinates after placing the target 10.106 km away
RxN = complex(zeros(M,N)); % array for received complex signal for all M bursts and N frequency steps (size 50 x 256)


for BurstCounter = 1:M

    burstTime = TimePerBurstVector(BurstCounter); % Time corresponding to the current burst
    
    RotationAngleDeg(BurstCounter) = InitialOrientation_deg + RotRate_deg_s*burstTime; % Calculates the current target angle, scatterer geometry is slightly different for every HRR profile.
    
     for ScattererCounter = 1:NumScatterers
         % Rotate every point scatterer one at a time by the current target rotation angle, for every burst
         
         SingleScatterer_xy_local_Original = Scatterer_xy_local(ScattererCounter, :).';
         RotationMatrix = [ cosd(RotationAngleDeg(BurstCounter)) -sind(RotationAngleDeg(BurstCounter)); sind(RotationAngleDeg(BurstCounter)) cosd(RotationAngleDeg(BurstCounter))];
         SingleScatterer_xy_local_rotated = RotationMatrix*SingleScatterer_xy_local_Original; % calculates the scatterer's new (x,y) coordinates after rotation
         Scatterer_xy_local_rotated(ScattererCounter, :) = SingleScatterer_xy_local_rotated'; % stores those rotated coordinates back into the matrix containing all scatterers.
     end
    
    Scatterer_xy_global(:,1) = Scatterer_xy_local_rotated(:,1) + R0 + TgtVelocity_ms*burstTime; % Takes the rotated local boat geometry and places it back into the real radar scene.
    Scatterer_xy_global(:,2) = Scatterer_xy_local_rotated(:,2);
    
    Rk = sqrt(Scatterer_xy_global(:,1).^2 + Scatterer_xy_global(:,2).^2);   % Slant range from the radar to each scatterer (chnages slightly from burst to burst because scatterers move from rotation)
    Rx = complex(zeros(1,N));
    
    for i = 1:  NumScatterers % For each scatterer, calculate the complex echo at all 256 transmitted frequencies and sum them into the total received signal for this burst.
        Rx = Rx + exp(-1i*4*pi*CentreFrequencyVector*Rk(i)/C);
    end
    
    a = randn(1,N); % Adding noise
    b = randn(1,N);
    
    PnVector = sqrt(Pn)*(a+1i*b)*1/sqrt(2);  
    RxN(BurstCounter, :) = Rx + PnVector;    % Receive Signal plus noise
    
end

HRR_Profile = (ifft(RxN,[], 2)); % Creates the HRR profile for every burst
RangeAxis = (0:1:(N-1))*C/(2*N*DeltaF); % coloumns are range bins. (gone from 50 bursts x 256 freqs to 50 HRR profiles x 256 range bins)

% Obtain cross-range axis
 CrossRangeRes_m = lamda/(2*deg2rad(RotRate_deg_s)*M*(1/PRF*N));             % cross-range resolution in meters 
 % Verical axis goes from Doppler bin number to Cross-range(m)
 CrossRangeAxis_m = (-M/2:1:(M/2-1))*CrossRangeRes_m; % Cross-range resolution tells you how close two scatterers can be sideways on the target and still appear separately in the ISAR image.

% Plot HRR profiles
figure;
HRR_Profile_dB = Normalise_limitDynamicRange_ISAR_dB(HRR_Profile,40);
imagesc(RangeAxis, 1:M, HRR_Profile_dB);
xlabel('Down-Range (m)'); % Fast-time: range bins within a profile % Each column is one range bin tracked over all 50 bursts. 
ylabel('Profile Number'); % Slow-time: profiles
title('HRR Profiles');
%colormap('jet');
colorbar;


% Plot ISAR image
WindowMatrix = repmat(hamming(M),1, N);
ISAR_linear = fftshift(fft(HRR_Profile.*WindowMatrix, [], 1),1); % Appoly fft across 50 profiles (slow-time axis) to convert slow-time into Doppler Frequency
ISAR_dB = Normalise_limitDynamicRange_ISAR_dB(ISAR_linear,40); % Converts ISAR image to a normalised 40 dB display range
FrequencyAxis_Hz = (-M/2:1:(M/2-1))*BurstRepetitionFrequency/M;

% Display ISAR image in two different ways
% First - range-doppler image
figure;
imagesc(RangeAxis, FrequencyAxis_Hz, ISAR_dB);
xlabel('Down-Range (m)');
ylabel('Doppler frequency (Hz)');
title('ISAR image');
colorbar;
colormap('jet');
axis xy;

% Second - down vs cross-range
figure;
imagesc(RangeAxis, CrossRangeAxis_m,ISAR_dB);             % Abdul Gaffar
xlabel('Down-Range (m)');
ylabel('Cross-range (m)');
title("Down-Range vs Cross-Range");
colormap('jet');
colorbar;
axis xy;

%x = 1;              % Debugging statement

% Declare all functions 

function Normalise_limitDynamicRange_ISAR_dB = Normalise_limitDynamicRange_ISAR_dB(ISAR_image_complex_linear, dynamic_range)

      ISAR_image_complex_linear = abs(ISAR_image_complex_linear)./max(max(abs(ISAR_image_complex_linear)));
      ISAR_image_dB = 20*log10(abs(ISAR_image_complex_linear));
      max_value_inplot = max(max(ISAR_image_dB));
      indx = find(ISAR_image_dB < (max_value_inplot-dynamic_range));
      ISAR_image_dB(indx) = (max_value_inplot-dynamic_range);
      ISAR_image_dB =  ISAR_image_dB - max_value_inplot;
      
      Normalise_limitDynamicRange_ISAR_dB = ISAR_image_dB;

end
