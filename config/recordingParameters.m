function p = recordingParameters(id)
%RECORDINGPARAMETERS  Per-recording settings for the 17 measured datasets.
%
%   p = recordingParameters(id)
%
%   Returns a struct with the filename, vessel class and the fixed-duration
%   CPTWL for the recording identified by 'id' (e.g. 'Y1', 'P2', 'G3').
%   The HRR-profile repetition frequency is read from the data at load time
%   (see loadRecording), not stored here.

    switch upper(id)
        % ---- Umoya yacht ----
        case 'Y1'
            p.filename = 'DAP_2010-10-06_18-00-05_002_Umoya_P872_55212_outbound.mat';
            p.vessel   = 'Yacht';   p.CPTWL = 36;
        case 'Y2'
            p.filename = 'DAP_2010-10-06_18-01-54_002_Umoya_P873_50446_outbound.mat';
            p.vessel   = 'Yacht';   p.CPTWL = 50;
        case 'Y3'
            p.filename = 'DAP_2010-10-06_18-14-21_002_Umoya_P872_55336_inbound.mat';
            p.vessel   = 'Yacht';   p.CPTWL = 36;
        case 'Y4'
            p.filename = 'DAP_2010-10-09_06-50-40_008_Umoya_P873_02570_outbound.mat';
            p.vessel   = 'Yacht';   p.CPTWL = 50;
        case 'Y5'
            p.filename = 'DAP_2010-10-09_06-55-26_010_Umoya_P874_03468_outbound.mat';
            p.vessel   = 'Yacht';   p.CPTWL = 62;
        case 'Y6'
            p.filename = 'DAP_2010-10-09_06-58-05_012_Umoya_P874_03085_inbound.mat';
            p.vessel   = 'Yacht';   p.CPTWL = 62;

        % ---- Namacurra patrol vessel ----
        case 'P1'
            p.filename = 'DAP_2010-10-15_07-01-33_000_NAMACURA_OUT_12KNOTS_870__P870_T001_G1_sb_HRR_G1_02743.mat';
            p.vessel   = 'Patrol';  p.CPTWL = 58;
        case 'P2'
            p.filename = 'DAP_2010-10-15_07-03-22_000_NAMACURA_OUT_6KNOTS_870__P870_T001_G1_sb_HRR_G1_01956.mat';
            p.vessel   = 'Patrol';  p.CPTWL = 58;
        case 'P3'
            p.filename = 'DAP_2010-10-15_07-06-04_000_NAMACURA_INB_MAXKNOTS_870__P870_T001_G1_sb_HRR_G1_02804.mat';
            p.vessel   = 'Patrol';  p.CPTWL = 58;

        % ---- RIB1 ----
        case 'R1'
            p.filename = 'DAP_2010-10-14_14-31-33_014_RIB_OUT_SPEEDMEDIUM_18KNOTS_462__P462_T001_G1_sb_HRR_G1_01502.mat';
            p.vessel   = 'RIB';     p.CPTWL = 200;
        case 'R2'
            p.filename = 'DAP_2010-10-14_14-52-31_024_RIB_OUT_SPEEDHIGH_FULL_462__P462_T001_G1_sb_HRR_G1_28154.mat';
            p.vessel   = 'RIB';     p.CPTWL = 200;
        case 'R3'
            p.filename = 'DAP_2010-10-14_14-56-49_025_RIB_CRISS-CROSS45_SPEEDHIGH_FULL_462__P462_T001_G1_sb_HRR_G1_44939.mat';
            p.vessel   = 'RIB';     p.CPTWL = 200;
        case 'R4'
            p.filename = 'DAP_2010-10-14_14-57-33_026_RIB_CRISS-CROSS45_SPEEDHIGH_FULL_462__P462_T001_G1_sb_HRR_G1_01266.mat';
            p.vessel   = 'RIB';     p.CPTWL = 200;
        case 'R5'
            p.filename = 'DAP_2010-10-14_15-10-00_029_RIB_CRISS-CROSS_SPEEDMEDIUM_18KNOTS_462__P462_T001_G1_sb_HRR_G1_01342.mat';
            p.vessel   = 'RIB';     p.CPTWL = 200;

        % ---- RIB2 (GID) ----
        case 'G1'
            p.filename = 'DAP_2010-10-14_11-37-03_001_GID13829__P455_T001_G1_sb_HRR_G1_02429.mat';
            p.vessel   = 'RIB';     p.CPTWL = 88;
        case 'G2'
            p.filename = 'DAP_2010-10-14_11-39-33_001_GID13926__P455_T001_G1_sb_HRR_G1_01097.mat';
            p.vessel   = 'RIB';     p.CPTWL = 88;
        case 'G3'
            p.filename = 'DAP_2010-10-15_09-57-43_002_GID17282__P460_T001_G1_sb_HRR_G1_02415.mat';
            p.vessel   = 'RIB';     p.CPTWL = 114;

        otherwise
            error('recordingParameters:unknownID', ...
                  'Unknown recording ID: %s', id);
    end

    p.id = upper(id);
end