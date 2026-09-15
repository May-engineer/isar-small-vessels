# ISAR Imaging of Small Maritime Vessels
**Honours thesis · EEE4022 · Project YAG26-07**
Supervisor: Dr M. Y. Abdul Gaffar

Investigating the feasibility of Inverse Synthetic Aperture Radar (ISAR) imaging for
small maritime vessels using measured radar data.

---

## About

ISAR exploits the relative motion between a radar and a target to form a two-dimensional
image. It is well established for aircraft and large ships, but comparatively little
experimental work exists on the radar phenomenology of *small* vessels — rigid inflatable
boats (RIBs), patrol boats and yachts.

This project investigates whether useful, focused ISAR images can be formed from measured
radar data of small vessels, and analyses the dominant scattering centres in those images.
It examines how the coherent processing interval (CPI), achievable cross-range resolution
and target motion affect image quality, and relates the dominant scattering centres back to
the physical structures on each boat. Measured ISAR images are compared against idealised
reference images produced by a point-scatterer simulator.

The work uses anonymous high-range-resolution radar datasets from the CSIR and is
implemented in MATLAB.

## Processing pipeline

Measured-data processing:
HRR profiles → range alignment → autofocus → ISAR image formation → image contrast → automatic time-window selection (MC-ATWS) → scattering-centre analysis

Simulated reference images:
Point-scatterer vessel model → rotation → simulated HRR profiles → simulated ISAR image

Focused measured ISAR images were selected both automatically (via the MC-ATWS
pipeline) and by visual inspection of ISAR movies, and compared against the simulated
reference images.

## Repository structure

- **`functions/`** — shared MATLAB functions used across the project:
  - `HaywoodAlignFunction.m` — range alignment (cross-correlation with robust delay fitting)
  - `YuanAutofocusFunction.m` — Yuan multiple-scatterer autofocus
  - `evaluateWindow.m` — forms an ISAR image for one window and computes its image contrast
  - `Normalise_limitDynamicRange_ISAR_dB.m` — dB normalisation for display
  - `centreISARImage.m` — centres the target in an ISAR image
  - `generateISARMovie.m` — forms a sequence of ISAR images and saves them as a movie
  - `runISARMovie.m` — driver template for generating an ISAR movie of a recording

- **`mcatws/`** — the Maximum-Contrast Automatic Time-Window Selection (MC-ATWS) pipeline,
  which automatically extracts focused ISAR images from a recording:
  - `run_all.m` — top-level batch script over all recordings
  - `runMCATWS.m` — runs the search and window-length refinement for one recording
  - `searchCPTWL.m` — finds local image-contrast peaks (candidate imaging centres)
  - `refineWLE.m` — refines the window length at each candidate (Martorella Step 3)
  - `filterCandidates.m` — deduplicates and quality-filters the refined candidates
  - `zeroDopplerCheck.m` — helper to inspect the zero-Doppler band width
  - `MCATWS_results_summary.csv` — the selected image parameters across all recordings

- **`simulator/`** — a point-scatterer simulator that generates idealised reference ISAR
  images for each vessel class (selectable via a vessel flag).

- **`regenerate_images/`** — scripts to regenerate specific selected ISAR images with a
  manual centring shift, for the measured-versus-simulated comparison.

- **`docs/`** — write-ups documenting the implementation, testing and verification of each
  processing stage, and the measured-versus-simulated image comparison.

## How to run

All scripts require the shared functions to be on the MATLAB path. From the repository root:

```matlab
addpath('functions');
```

Place the CSIR `.mat` recordings in the relevant working folder (the data is **not**
distributed with this repository — see *Data* below).

- **Form ISAR images and automatically select the best-focused ones:**
  run `mcatws/run_all.m`. This processes each recording over CPTWLs of 32, 64 and 128
  profiles, refines the window length at each candidate, deduplicates and quality-filters
  the results, and writes `MCATWS_results_summary.csv`.

- **Generate an ISAR movie of a recording:**
  edit the recording filename and settings at the top of `functions/runISARMovie.m` and
  run it. The script handles the `Pattern_time`/`pattern_time` field-name variation between
  recordings automatically.

- **Generate an idealised simulated ISAR image:**
  set the vessel flag (1 = yacht, 2 = patrol boat, 3 = RIB) in `simulator/`
  and run the simulator script.

## Verification

Each processing stage was implemented and tested before being combined into the full
pipeline:

- The range-alignment method was developed and its robustness to outliers investigated by
  comparing several outlier-handling approaches; the write-up in `docs/` documents this
  investigation and the selection of robust regression.
- The autofocus and image-formation stages were verified on windows with known behaviour,
  and the image-contrast metric was checked against values reported in the literature.
- The MC-ATWS pipeline was tested per stage (window evaluation, peak search, window-length
  refinement, candidate filtering) before combining, and applied across all 17 recordings;
  the resulting selected-image parameters are recorded in
  `mcatws/MCATWS_results_summary.csv`.
- Measured ISAR images were compared against idealised simulated reference images to check
  that the observed signatures are consistent with the expected vessel geometry.

The write-ups in `docs/` provide the detailed evidence of testing and verification for each
stage.

## Tools

MATLAB (signal processing, image formation, simulation, analysis) · LaTeX (report).

## Key references

- V. C. Chen and M. Martorella, *Inverse Synthetic Aperture Radar Imaging: Principles,
  Algorithms and Applications*, SciTech Publishing, 2014.
- M. Martorella and F. Berizzi, "Time windowing for highly focused ISAR image
  reconstruction," *IEEE Transactions on Aerospace and Electronic Systems*, vol. 41,
  no. 3, pp. 992–1007, 2005.

## Data

The CSIR datasets are used under approval for this project and are **not** included in
this repository (excluded via `.gitignore`).