# Radar Data

This directory is intended for the measured high-range-resolution (HRR)
radar recordings used in this project.

The recordings were provided by the Council for Scientific and Industrial
Research (CSIR) and are used under approval for academic research.

The original `.mat` files are not publicly distributed and are excluded
from this repository through `.gitignore`.

To reproduce the measured-data results, authorised users should place
the recordings in this directory. Filenames are defined in
`config/recordingParameters.m`.

The repository's MATLAB scripts load the recordings using `loadRecording.m`.
