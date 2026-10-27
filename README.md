# ISAR Imaging of Small Maritime Vessels

**Honours thesis · EEE4022 · Project YAG26-07**  
**Supervisor:** Dr M. Y. Abdul Gaffar

Investigating the feasibility of Inverse Synthetic Aperture Radar (ISAR) imaging for
small maritime vessels using measured radar data.

---

## About

ISAR exploits the relative rotational motion between a radar and a target to form a two-dimensional
image. It is well established for aircraft and large ships, but comparatively little
experimental work exists on the radar phenomenology of *small* vessels — rubber inflatable
boats (RIBs), patrol vessels and yachts.

This project investigates the feasibility and temporal availability of useful ISAR imagery
from measured radar data of small maritime vessels. It examines how the coherent processing
interval (CPI), target motion and achievable cross-range resolution influence image quality,
and assesses the qualitative interpretability of vessel-specific scattering centres and their plausible associations with physical vessel structures.
Measured ISAR images are compared against idealised reference images produced by an adapted
point-scatterer simulator.

The work uses measured high-range-resolution radar datasets from the CSIR and is
implemented in MATLAB.

## Processing pipeline

**Measured-data processing:**  
HRR profiles → modified Haywood range alignment → adapted Yuan autofocus →
Hamming-windowed Range–Doppler image formation → image-contrast evaluation.

**Image selection and assessment:**  
MC-ATWS identification of high-contrast candidate intervals and visual inspection of overlapping-CPI ISAR sequences → qualitative assessment of vessel-specific structure.

**Simulation:**  
Point-scatterer vessel model → prescribed rotation → simulated HRR profiles →
Range–Doppler image formation.

Measured ISAR images were selected using MC-ATWS and through visual inspection of
ISAR movies, and compared against the simulated reference images.

## Repository structure

- **`setupPaths.m`** — configures the MATLAB path and returns the project directories.
  Run once per session before any other script.

- **`functions/`** — shared MATLAB helper functions:
  - `loadRecording.m` — loads one recording and handles the `Pattern_time`/`pattern_time` field-name variation
  - `HaywoodAlignFunction.m` — modified Haywood range alignment (cross-correlation with robust delay fitting)
  - `YuanAutofocusFunction.m` — Yuan multiple-scatterer autofocus
  - `evaluateWindow.m` — forms the ISAR image and image contrast for one candidate CPI
  - `Normalise_limitDynamicRange_ISAR_dB.m` — dB normalisation for display (provided by the supervisor)

- **`config/`** — project configuration:
  - `recordingParameters.m` — filename, vessel class and fixed-duration CPTWL for each recording (by ID)

- **`mcatws/`** — the Maximum Contrast-based Automatic Time-Window Selection (MC-ATWS) pipeline:
  - `run_all.m` — top-level batch script over all 17 recordings
  - `runMCATWS.m` — runs the search and window-length refinement for one recording
  - `searchCPTWL.m` — finds local image-contrast peaks (candidate imaging centres)
  - `refineWLE.m` — refines the window length at each candidate
  - `filterCandidates.m` — removes invalid candidates, deduplicates overlapping intervals and applies a relative IC threshold

- **`imaging/`** — ISAR image and movie generation:
  - `generateISARImage.m` — regenerates a single selected ISAR image (with optional display centring)
  - `generateISARMovie.m` — forms a sequence of ISAR images and saves it as a movie
  - `runISARMovie.m` — driver for generating an ISAR movie of a recording

- **`simulator/`** — a point-scatterer simulator:
  - `simulateISAR.m` — generates idealised reference ISAR imagery for each vessel class

- **`verification/`** — processing-stage verification and diagnostics:
  - `verifyAlignmentAutofocus.m` — compares the ISAR image and IC before alignment, after alignment, and after autofocus
  - `inspectZeroDopplerBand.m` — inspects the zero-Doppler band width used for the IC calculation

- **`data/`** — location for the CSIR recordings (not distributed; see *Data* below).

- **`outputs/`** — generated results, including the retained MC-ATWS summary CSV. Generated images and movies are excluded from Git.

- **`docs/`** — write-ups documenting the implementation and verification of each stage.

## Documentation

- [Processing pipeline](docs/processing_pipeline.md)
- [MC-ATWS](docs/mcatws.md)
- [Point-scatterer simulator](docs/simulator.md)
- [Verification](docs/verification.md)
- [Results reproduction](docs/results_reproduction.md)

## How to run

The recordings are **not** distributed with this repository (see *Data* below). Place the
authorised CSIR `.mat` recordings in the `data/` folder, then run MATLAB from the
repository root and configure the paths once:

```matlab
setupPaths();
```

All scripts locate the data and shared functions through `setupPaths`, so no further path
configuration is needed.

- **MC-ATWS candidate selection (all recordings):**

```matlab
run_all
```

  Processes each recording over initial CPTWLs of 32, 64 and 128 profiles with 50% overlap, refines the
  window length at each candidate, deduplicates overlapping candidates and applies a relative image-contrast threshold, and writes
  `outputs/mcatws/MCATWS_results_summary.csv`.

- **Regenerate a selected ISAR image:**

```matlab
generateISARImage(recordingID, middleProfile, CPTWL, rowShift, colShift, showAlignedHRR)

% e.g.
generateISARImage('Y2', 176, 50, 5, -15)        % with display centring
generateISARImage('G2', 609, 34, 0, 20, true)   % also plot the aligned HRR profiles
```

  `rowShift`/`colShift` are optional display-only circular shifts (Doppler and range bins);
  `showAlignedHRR` optionally plots the aligned HRR profiles. Recording IDs are defined in
  `config/recordingParameters.m`.

- **Generate a simulated reference ISAR image:**

```matlab
simulateISAR(flag)                         % 1 = yacht, 2 = patrol, 3 = RIB

% optionally override rotation rate and initial orientation:
simulateISAR(1, 1.7, 180)                  % Yacht rotated 180 degrees
simulateISAR(3, 3.4, 135)                  % RIB pre-rotated to 135 degrees
```

- **Generate an ISAR movie of a recording:**
  set `recordingID` and `CPTWL` at the top of `imaging/runISARMovie.m` and run it.

- **Verify the alignment and autofocus stages:**

```matlab
verifyAlignmentAutofocus('Y2', 176, 50, 5, -15)
inspectZeroDopplerBand('Y2', 176, 50)
```

## Verification

The principal processing stages were assessed using measured radar data, image-contrast comparisons and qualitative inspection.

- **Range alignment:** Verified using yacht recording Y2 (MP 176, CPTWL 50). IC increased from 7.80 before alignment to 11.31 after modified Haywood range alignment, accompanied by a more compact and better-defined ISAR response.

- **Autofocus:** Verified using the same yacht CPI. Applying adapted Yuan autofocus after range alignment increased IC from 11.31 to 13.10, indicating improved image-intensity concentration, although the visual change was modest.

- **Range–Doppler image formation:** The implementation successfully formed ISAR images from measured HRR profiles and was reviewed by the supervisor.

- **MC-ATWS:** Verified using three retained candidate intervals from yacht recording Y2, representing high, intermediate and lower IC values. Each was compared against two randomly chosen intervals of the same CPTWL that were not selected by MC-ATWS. All three MC-ATWS-selected intervals achieved higher IC than their respective comparison intervals, supporting the intended contrast-based selection behaviour.

- **Point-scatterer simulation:** The simulator generated plausible ISAR scattering responses for idealised vessel models and was reviewed by the supervisor.

- **Implementation consistency:** `verifyAlignmentAutofocus.m` checks the consistency of the range-aligned and autofocused HRR profiles, complex ISAR image and IC against `evaluateWindow.m`, using a numerical tolerance of `1e-10`.

## Tools

MATLAB (signal processing, image formation, simulation, analysis) · LaTeX (report).


## Key references

- V. C. Chen and M. Martorella, *Inverse Synthetic Aperture Radar Imaging: Principles, Algorithms and Applications*. Edison, NJ, USA: SciTech, 2014. doi: 10.1049/SBRA504E.

- B. Haywood and R. J. Evans, "Motion compensation for ISAR imaging," in *Proc. Australian Symp. Signal Process. Appl. (ASSPA '89)*, R. F. Barrett, Ed., Adelaide, Australia, Apr. 17–19, 1989, pp. 113–117.

- A. Zyweck, "Preprocessing issues in high resolution radar target classification," Ph.D. dissertation, Dept. Elect. Electron. Eng., Univ. Adelaide, Adelaide, Australia, 1995.

- C. Yuan and D. Casasent, "Composite filters for inverse synthetic aperture radar classification of small ships," *Opt. Eng.*, vol. 41, no. 1, pp. 94–104, Jan. 2002. doi: 10.1117/1.1425789.

- M. Martorella and F. Berizzi, "Time windowing for highly focused ISAR image reconstruction," *IEEE Trans. Aerosp. Electron. Syst.*, vol. 41, no. 3, pp. 992–1007, Jul. 2005. doi: 10.1109/TAES.2005.1541444.

- M. Y. Abdul Gaffar, W. A. J. Nel, and M. R. Inggs, "Selecting suitable coherent processing time window lengths for ground-based ISAR imaging of cooperative sea vessels," *IEEE Trans. Geosci. Remote Sens.*, vol. 47, no. 9, pp. 3231–3240, Sep. 2009. doi: 10.1109/TGRS.2009.2019729.


## Data

The CSIR datasets are used under approval for this project and are **not** included in
this repository (excluded via `.gitignore`). Place the authorised `.mat` recordings in the
`data/` folder to run the processing scripts.
