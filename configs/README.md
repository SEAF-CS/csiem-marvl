[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

# csiem-marvl

![image](aed-marvl/docs/MARVL-overview.png)

## Overview
csiem-marvl (the Cockburn Sound Integrated Ecosystem Model - Model Assessment, Reporting and Visualisation Library) is an integrated software package for visualizing the model outputs and observational datasets, and evaluating the model performance. csiem-marvl uses the `aed-marvl` as the core functions for plotting and evaluating model outputs. For the key features and modules of `aed-marvl` the readers are refered to https://github.com/AquaticEcoDynamics/aed-marvl 

## Repository Organisation
- `aed-marvl`: core plotting and model performance evaluating scripts and libraries for MARVL; 
- `config`: site-specific configurations for csiem;
- `gis`: shape files for defining polygons, transect, and sites for plotting;
- `data`: place-holder for storing observed/modelled datasets;
- `scripting`: place-holder for storing other scripts relating to model assessment and reporting;

## Execution Instruction
- Colone the `csiem-marvl` repository onto local computer
- Open Matlab (version 2020 or later versions), go to the local `csiem-marvl` folder and add the paths to tools/libraries by entering
 ```
 addpath(genpath('./'))
 ```
- Go to `config` folder, edit the `MARVL.m` to configure the plots (use the 'MARVL.m' under example folder as templates);
- Under the `config` path, start the plotting by entering
 ```
  run_AEDmarvl('./MARVL.m','matlab')
 ```
   or if you wish to use YAML style configuration
 ```
   run_AEDmarvl('./MARVL.m','yaml')
 ```

## MARVL Configuration
- The MARVL user instruction documentation is available in `aed-marvl` repository (under docs/MARVL user instruction.docx).
 
