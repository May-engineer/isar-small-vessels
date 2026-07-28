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
boats (RIBs), patrol boats, fishing vessels and yachts.

This project investigates whether useful, focused ISAR images can be formed from measured
radar data of small vessels, and analyses the dominant scattering centres in those images.
It examines how the coherent processing interval (CPI), Doppler bandwidth, signal-to-noise
ratio and target motion affect image quality, and relates the dominant scattering centres
back to the physical structures on each boat.

The work uses anonymous high-range-resolution radar datasets from the CSIR and is
implemented in MATLAB.

## Processing pipeline

```
HRR profiles → range alignment → autofocus (translational motion compensation) → image formation → quality metrics → scattering-centre analysis
```

## Tools

MATLAB (signal processing, image formation, analysis) · LaTeX (report).

## Key references

- V. C. Chen and M. Martorella, *Inverse Synthetic Aperture Radar Imaging: Principles,
  Algorithms and Applications*, SciTech Publishing, 2014.
- M. A. Richards, J. A. Scheer, W. A. Holm (eds.), *Principles of Modern Radar: Basic
  Principles*.

## Data

The CSIR datasets are used under approval for this project and are **not** included in
this repository.
