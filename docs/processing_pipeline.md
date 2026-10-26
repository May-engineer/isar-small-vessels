# Measured ISAR processing pipeline

Each selected coherent processing interval (CPI) is a complex matrix of high-range-resolution (HRR) profiles: **rows = slow-time profiles; columns = down-range bins**.

`evaluateWindow.m` applies the common pipeline:

1. **Range alignment:** `HaywoodAlignFunction.m` estimates circular magnitude-correlation delays relative to the first profile, fits a robust linear delay trend without an intercept, and applies fractional shifts using a Fourier phase ramp.
2. **Autofocus:** `YuanAutofocusFunction.m` selects up to 11 stable range bins using the amplitude-variance metric (threshold 0.16, with a fallback) and corrects profile-to-profile phase.
3. **Range–Doppler formation:** an `N`-sample Hamming window is applied along slow time, followed by an `N`-point FFT and `fftshift` along that dimension; no Doppler zero-padding is used.
4. **Image contrast (IC):** contrast is calculated from image intensity after excluding the zero-Doppler row and two bins on either side **from an IC-only copy**. The returned complex ISAR image retains every Doppler row.

Doppler frequency is displayed using `((0:N-1)-floor(N/2))*f_HRR/N`, which supports odd and even CPI lengths. Where requested, `generateISARImage.m` applies circular range/Doppler shifts **after** image formation for presentation only. These shifts do not change the IC result. IC indicates focus, not necessarily recognisable vessel structure.
