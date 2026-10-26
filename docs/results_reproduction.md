# Reproducing outputs

## Prerequisites

MATLAB with the toolboxes needed by the processing functions (including `robustfit` and `findpeaks`). Place authorised CSIR `.mat` recordings in the local `data/` directory. **Radar recordings are not distributed with this repository.** Run MATLAB from the repository root and initialise paths:

```matlab
setupPaths();
```

## Commands

```matlab
run_all                         % MC-ATWS candidate search and summary CSV
generateISARImage('Y2',1089,84,0,0,true)  % Example selected CPI; also plot aligned HRR
generateISARImage('G2',609,34,0,20,true) % Example RIB CPI with display centring
runISARMovie                    % Movie settings configured inside the runner
simulateISAR(1)                 % Example idealised yacht simulation
verifyAlignmentAutofocus('Y2',176,50,5,-15)
```

The image-generation examples above are **test intervals**, not a verified list of exact submitted thesis-figure settings. Use the recording ID, middle profile, CPTWL and display shifts associated with the specific figure being reproduced.

## Outputs

- `outputs/mcatws/MCATWS_results_summary.csv`: retained MC-ATWS candidate table.
- `outputs/mcatws/selected_images/`: generated candidate PNGs.
- `outputs/isar_images/`: centred selected images and optional aligned HRR plots.
- `outputs/movies/`: generated movie files.

Generated images/videos and restricted input recordings remain local. Re-running the established MC-ATWS workflow previously reproduced **105 retained candidates**; outputs can vary if the underlying processing code or datasets are changed.
