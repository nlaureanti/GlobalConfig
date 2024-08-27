# Create conda env
 
##################################################################
 
 conda create -n transform_vgrid python=3.8.10
 
 conda activate transform_vgrid
 
 pip install os-sys
 
 conda install -c conda-forge xarray dask netCDF4 bottleneck
 
 conda install -c conda-forge xgcm numba
 
##################################################################
 
 conda create -n transform_vgrid python=3.6.15
 
 conda activate transform_vgrid
 
 conda install -c conda-forge xarray dask netCDF4 bottleneck
 
 conda install -c conda-forge xgcm numba  
 
 pip install os-sys
