[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

# aed-marvl : scripts for visualisation and assessment of AED model output 

## Overview
MARVL is an integrated software package for visualizing the model outputs and observational datasets, and evaluating the model performance.  It is also able to carry out high-level system assessment such and environmental response functions and nutrient budgeting analysis, though certain pre-processing steps are required to prepare the data for the high-level system assessment. One of the key challenges for water quality modelling is to assess the model performance against field observations that typically include plenty of biogeochemical variables, exist at multiple sites, and are provided by multiple agencies in different formats. To handle this challenge, the AED research group has developed a series of data processing framework to store the data in a uniform format that is compatible to the AED outputs. At the same time, the group has developed a series of model assessment methods and scripts that were specifically designed to be compatible with the AED data repository and model outputs. The repository is a collection of AED inhouse scripts that have been developed during previous research projects, and has been refined with uniform and easier user interfaces. At the moment, the AED-MARVL was designed with the following features:
- Multiple visualizing options such as time-series, transect view, curtain view, site profiling;
- Standard and advanced performance evaluating methods;
- One configuration file for all options;
- Uniform outlook (e.g. font style and size, figure resolution) of the figures and animations;
- Option to use YAML style of configurations that can be shared with other plotting software such as R and python;

Following visualizing functions are available in MARVL: 
- Time series (with options to show observational data and perform model skill assessment);
- Transect (with options to show observational data on the same transect);
- Transect stacked area for comparing water quality compositions;
- Transect exceedance for comparing water quality levels against guidelines;
- Site profiling of selected water quality variables;
- Sheet plotting and animations;
- Curtain plotting and animations;

High-level systematic assessment of water quality response of to environmental factors and nutrient budgeting analysis have been developed using many of the basic functions of MARVL. However, these high level assessments require several pre-processing steps to prepare data for the assessment, and the configurations and pre-processing varied in different case studies. Therefore, there is still no straightforward script for these high level assessments. We have included the workflow in this document and examples scripts/outputs of the high-level assessments in the MARVL repository. Users of MARVL can follow the workflow and modify the scripts to produce the assessment outcomes of their studies.

The plotting functions have been tested within several case studies, including Coorong Lagoon, Cockburn Sound, and Lake Erie, and examples are included in the current repository. However, MARVL is still under development and please provide feedback for us to improve the user experience, as well as functionality.

## Repository Organisation
- `docs`: place holder for documenting MARVL science and user instructions;
- `sources`: matlab plotting scripts and libraries for MARVL;
- `examples`: site-specific configurations and recommended place for plotting results, to be updated;

## Execution Instruction
- Colone the `aed-marvl` repository onto local computer
- Open Matlab (version 2020 or later versions), go to the local `aed-marvl` folder and  add the paths to tools/libraries by entering
 ```
 addpath(genpath('./'))
 ```
- Go to `aed-marvl/{your project}/` folder, edit the `MARVL.m` to configure the plots (use the 'MARVL.m' under example folder as templates);
- Under the `aed-marvl/{your project}/` path, start the plotting by entering
 ```
  run_AEDmarvl('./MARVL.m','matlab')
 ```
   or if you wish to use YAML style configuration
 ```
   run_AEDmarvl('./MARVL.m','yaml')
 ```

## MARVL Configuration
- The MARVL user instruction documentation is available in docs folder, or please refer to the [wiki](https://github.com/AquaticEcoDynamics/aed-marvl/wiki) pages for examples.
 
