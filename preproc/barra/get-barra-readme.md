# Get Barra
<b>Tools to download BARRA atmospheric data and process for usage with TUFLOW FV</b><br>
Maintainers: A.Waterhouse and M.Smith <br>

## Getting Started
### Installation
This package can be installed using pip. We recommend using a virtual environment to manage this package's dependencies. <br><br>

If you are using <b>`pip`</b> to manage your python package installation, please use:<br>
`pip install git+https://gitlab.com/tuflow-user-group/tuflow-fv/data-pre-processing/get_barra.git` 
<br><br>
If you are using <b>`conda` (or `mamba)`</b> to manage your python packages, please first install the dependencies of this package using the following command: <br>
`conda install xarray dask cftime toolz tqdm netcdf4 pydap siphon bottleneck scipy`<br>
Note: This command has been tested with `conda-forge` as the default channel (i.e., `conda install -c conda-forge ...`).<br>
Finally, install this package using `pip install --no-dependencies git+https://gitlab.com/tuflow-user-group/tuflow-fv/data-pre-processing/get_barra.git`

### Usage
This package uses a command line interface to access the download and preprocess methods. <br>
Simply open up a terminal, activate a python environment with this package installed, and use the following commands:

<b>Example - downloading BARRA data for Northern Queensland</b>
1. Call `GetBarra` in the terminal to see the program setup. (Note: your python environment with this package installed should already be activated).<br>
   This cmd will show the two sub-program options, which are:
   A) Download raw BARRA Files
   B) Merge the raw BARRA Files
2. To download data, first check the arguments by calling program A, and typing `-h` for help, e.g., <br>
   `GetBarra A -h`
3. Call the program with your options, e.g., a month worth of data covering parts of North Queensland: <br>
   `GetBarra A "2010-01-01 00:00" "2010-02-01 00:00" 151 156 -30 -22.5 --path nrth_qsld/raw`
4. Once that is finished, we can merge the datafiles into a single netcdf so that it can be used with TUFLOW-FV <br>
   Call `GetBarra B -h` to see the options for merging data
5. Now submit our merge job: <br>`GetBarra B --in_path nrth_qsld/raw --out_path nrth_qsld`

If you wish to use the underlying python functions, simply import the package `from get_barra import barra_tools`
