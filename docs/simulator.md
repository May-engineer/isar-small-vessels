# Idealised point-scatterer simulator

`simulator/simulateISAR.m` generates reference imagery for three simplified vessel models: **1 = yacht**, **2 = patrol vessel**, **3 = RIB**. The two-dimensional models contain 32, 29 and 29 equal-amplitude scatterers, respectively.

The simulator uses 256 stepped-frequency samples per burst, a 4 MHz step from 9.5 GHz, 50 bursts, and a pulse repetition frequency of 25.6 kHz. This produces **100 HRR profiles/s** and a **0.5 s CPI**. Prescribed rotation is 1.7°/s for the yacht and 3.4°/s for the patrol vessel and RIB; default initial orientation is 0°. Translation is set to zero, and complex Gaussian noise uses a nominal 40 dB SNR setting.

The program coherently sums scatterer echoes, takes an IFFT across frequency to form HRR profiles, and applies a Hamming-windowed slow-time FFT and Doppler centring. It displays the point-scatterer model, HRR profiles, Range–Doppler image, and idealised range–cross-range image. **Measured-recording range alignment and autofocus are not applied to simulated HRR profiles.**

Examples:

```matlab
simulateISAR(1)            % Yacht, default settings
simulateISAR(2)            % Patrol vessel
simulateISAR(3, 3.4, 135)  % RIB with 135-degree initial orientation
```

These images are idealised structural references, not predictions of measured scattering signatures.
