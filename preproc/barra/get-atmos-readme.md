# Get Atmos

**Tools to download and process atmospheric data for usage with TUFLOW FV**\
Maintainers: A.Waterhouse and M.Smith

This tool currently supports downloading atmospheric data from [ECMWF's ERA5](https://www.ecmwf.int/en/forecasts/dataset/ecmwf-reanalysis-v5), [NCAR's CFSR and (CFSv2)](https://rda.ucar.edu/datasets/ds093.1/) as well as the Australian [Bureau of Meteorology's BARRA Reanalysis](http://www.bom.gov.au/research/projects/reanalysis).

By default, this tool will download data from ERA5, which is a global atmospheric reanalysis dataset (i.e., `--source ERA5`). CFSR/CFSv2 can be downloaded using the optional argument (`--source CFSR`), or BARRA data can be downloaded by providing the optional argument (e.g., `--source BARRA_<X>`, with <X> one of R, AD, PH, SY, TA). NOTE: **BARRA** has a more restrictive license that should be reviewed by users of this tool.

**Please ensure that your usage of data downloaded using this python library abides with the license requirements for the selected source.**

## Getting Started

### Installation

This package can be installed using pip. We recommend using a virtual environment to manage this package's dependencies.

If you are using **`pip`** to manage your python package installation, please use:\
`pip install git+https://gitlab.com/tuflow-user-group/tuflow-fv/data-pre-processing/get-atmos.git`

If you are using **`conda` (or `mamba)`** to manage your python packages, please first install the dependencies of this package using the following command:\
`conda install xarray dask cftime toolz tqdm netcdf4 pydap siphon bottleneck scipy`\
Note: This command has been tested with `conda-forge` as the default channel (i.e., `conda install -c conda-forge ...`).\
Finally, install this package using\
`pip install --no-dependencies git+https://gitlab.com/tuflow-user-group/tuflow-fv/data-pre-processing/get-atmos.git`

### Usage

This package uses a command line interface to access the download and preprocess methods.\
Open up a terminal, activate a python environment with this package installed, and then you can access the command line tools (see example below). 

**IMPORTANT - You must setup a CDSAPI key to download ERA5, which is the default! [See instructions here](https://cds.climate.copernicus.eu/api-how-to)**\
You can alternatively download CFSR/CFSv2 or BARRA data without any additional setup (noting that you should check the license conditions if using BARRA).


### Example - downloading ERA5 data for Northern Queensland

1. Call `GetAtmos` in the terminal to see the program setup. (Note: your python environment with this package installed should already be activated). \
   This cmd will show the two sub-program options, which are: \
   A) Download raw data files \
   B) Merge the raw data files

2. To download data, first check the arguments by calling program A, and typing `-h` for help, e.g.,\
   `GetAtmos A -h`

3. Call the program with your options, e.g., a month worth of data covering parts of North Queensland:\
   `GetAtmos A "2012-01-01 00:00" "2012-02-01 00:00" 151 156 -30 -22.5 --path nrth_qsld/raw`

4. Once that is finished, we can merge the datafiles into a single netcdf so that it can be used with TUFLOW FV\
   Call `GetAtmos B -h` to see the options for merging data

5. Now submit our merge job:\
   `GetAtmos B --in_path nrth_qsld/raw --out_path nrth_qsld`

Notes:
- To change the data source, add in `--source CFSR/BARRA_<x>/ERA5' to BOTH programs (A and B)
- ERA5 will always download in monthly blocks, however the merged product can be cut down to exact dates using the `--time_start` and `--time_end` optional arguments. 
- GetAtmos B will by default generate an FVC file to use with TUFLOW FV. 
- Reprojection can be handled by supplying the `-rp / --reproject <EPSG_CODE>` optional argument. For example `-rp 7856` will reproject the merged netcdf to GDA2020 MGA56 coordinates, and this will be reflected inside the FVC file. 
- Conversion to local time can be handled by providing the optional argument `-tz <hours>`. You can provide a label as well if you wish to add this to the metadata (e.g., `-ltz AEST` and `-tz 10`). 


If you wish to use the underlying python functions, simply import the package `from get_atmos import DownloadAtmos, MergeAtmos`


### BARRA Download Instructions
BARRA Reanalysis data can optionally be downloaded using this tool. Please refer to here for more information:
[Bureau of Meteorology's BARRA Reanalysis](http://www.bom.gov.au/research/projects/reanalysis).

To download BARRA data, please follow all the general steps as above for CFSR, except that you will need to add an extra argument `--source BARRA_R` to both step A and B. 
The BARRA subdomains can also be downloaded, by replacing `BARRA_R` with the appropriate named sub-domain, e.g., `BARRA_PH`. Refer to the following list, extracted from the Barra website above:

- BARRA_R (12km resolution over Australia, New-Zealand and the maritime continent) for the period 1990-01-01 to 2019-02-28
- BARRA_AD (1.5km resolution over SA) for the period 1990-01-01 to 2019-02-28
- BARRA_PH (1.5km resolution over South-West WA) for the period 1990-01-01 to 2019-02-28
- BARRA_SY (1.5km resolution over Eastern NSW) for the period 1990-01-01 to 2019-02-28
- BARRA_TA (1.5km resolution over Tasmania) for the period 1990-01-01 to 2019-02-28

