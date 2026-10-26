# MC-ATWS candidate selection

Run `mcatws/run_all.m` from the repository root after `setupPaths.m` and placement of authorised radar recordings in `data/`.

The Maximum-Contrast-based Automatic Time-Window Selection (MC-ATWS) implementation uses:

1. **MPL search:** `searchCPTWL.m` scans even initial lengths of **32, 64 and 128 profiles**, with 50% overlap, and retains local maxima in the IC-versus-position curve.
2. **WLE refinement:** `refineWLE.m` changes window length around a fixed selected middle profile, starting with a half-step of **5 profiles**, to seek greater IC.
3. **Candidate filtering:** `filterCandidates.m` removes invalid results, deduplicates intervals with overlap at least **0.8** relative to the shorter interval, and retains candidates with IC at least **75%** of the recording's best deduplicated candidate.

The initial overlap scan uses **even** CPTWLs; refined lengths therefore also remain even. Image contrast is a focus metric, not a qualitative judgement of vessel-image usefulness.

`run_all.m` writes the candidate summary to `outputs/mcatws/MCATWS_results_summary.csv`; generated candidate PNGs are excluded from Git. The verified baseline contains **105 candidates** across the 17 recordings.
