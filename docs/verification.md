# Processing verification and diagnostics

`verification/verifyAlignmentAutofocus.m` compares three stages for the **same CPI**: before range alignment, after modified Haywood range alignment, and after alignment plus adapted Yuan autofocus. It displays the three Range–Doppler images, before/after aligned HRR profiles, and their IC values.

Example using the original yacht verification interval:

```matlab
setupPaths();
verifyAlignmentAutofocus('Y2', 176, 50, 5, -15);
```

The first shift is in Doppler bins (ISAR display only); the second is in range bins (ISAR and HRR displays). If enabled in the final verification script, numerical assertions compare the focused profiles, complex image and IC with `evaluateWindow.m`. Such assertions establish **implementation agreement**, not independent proof of algorithm correctness.

The optional `zeroDopplerCheck.m` diagnostic plots mean image magnitude versus Doppler bin around zero Doppler. It helps inspect the central response but does not establish a universally optimal number of excluded IC bins.
