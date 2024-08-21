#!/home/nicole.laureanti/miniconda3/envs/obcic/bin/python

"""
    Vertical interpolation
    Contributition of Nicole C. Laureanti, 2023
    Earth System Modeling Group, Rutgers University, NJ/USA
    Brazilian National Institute for Space Research, SP/Brazil
    nlaureanti@gmail.com
    
    Source: https://xgcm.readthedocs.io/en/latest/transform.html
    
    Installing requirements:
    #python=3.6.15
    conda install -c conda-forge xarray dask netCDF4 bottleneck
    conda install -c conda-forge xgcm
    conta install -c conda-forge numpy sys
   
"""    
def main(ds, dsCtrl2, preffix='ds_', zcoord_in='z_l', zcoord_to='depth'):

#           ### TRANSFORM Z-COORD ###
            dsCtrl2['z_to'] = abs(zcoord_to)
            try:
                gridz = Grid(dsCtrl2, coords={'Z': {'center':zcoord_in}}, periodic=False)
            except:
                gridz = Grid(dsCtrl2, coords={'Z': {'center':'depth'}}, periodic = False)
            newds = xr.Dataset()
            for var in dsCtrl2.variables:
                if var not in dsCtrl2.dims and dsCtrl2[var].ndim > 3 and var not in ['time_bnds']:
                    #print(var)
                    newds[var] = gridz.transform(dsCtrl2[var], 'Z', dsCtrl2.z_to,
                    mask_edges=False,
                        method='linear')
                elif var not in dsCtrl2.dims and var not in ['time_bnds']:
                    newds[var]=dsCtrl2[var]
            print(newds.dims)

            for x,y in [('xh','yh'),('longitude','latitude'),
                            ('nx','ny'),('lon','lat'),('lonq','lath'),('lonh','latq')]:
               if x in newds.dims and y in newds.dims:
                  break
                 
            newds=newds.transpose('time','z_to',y,x).rename({'z_to':'depth',x:'lon',y:'lat'})#.bfill('lat',2).ffill('lat',2).ffill('lon')
            fill_value=1e20
            for v in newds:
               newds[v].encoding['_FillValue']=fill_value
               newds[v].encoding['missing_value']=fill_value
               newds[v].encoding['dtype']=np.float32
            newds.to_netcdf(f'{preffix}_zl.nc')
            print(f'> out : {preffix}_zl.nc')

            quit()

def vgrid_to_interfaces(vgrid, max_depth=6500.0):
    if isinstance(vgrid, xr.DataArray):
        vgrid = vgrid.data
    zi = np.concatenate([[0], np.cumsum(vgrid)])
    zi[-1] = np.array(max_depth)
    return zi


def vgrid_to_layers(vgrid, max_depth=6500.0):
    if isinstance(vgrid, xr.DataArray):
        vgrid = vgrid.data
    ints = vgrid_to_interfaces(vgrid, max_depth=max_depth)
    z = (ints + np.roll(ints, shift=1)) / 2
    layers = z[1:]
    return layers
            

if __name__ == "__main__":
        import xarray as xr
        import sys
        from xgcm import Grid
        import numpy as np

        import warnings   
        warnings.filterwarnings("ignore")

        print(sys.argv[:])
        if (len(sys.argv[:]) <= 2):
                print(f'Vertical interpolation\n Run: {sys.argv} + <nc file with z coord> <ncfile2>')

                quit()
        else:
            ncfile=sys.argv[1]
            ncfile2=sys.argv[2]
            ds_fromZ=xr.open_mfdataset(f'{ncfile}')
            ds_toTransform=xr.open_mfdataset(f'{ncfile2}')

        zcoord_to=sys.argv[3]
        if zcoord_to not in ds_fromZ.dims and zcoord_to not in ds_fromZ.data_vars:
              print(ds_fromZ.data_vars)
              print('zcoord_to:');zcoord_to=input()

        z=vgrid_to_layers(ds_fromZ[zcoord_to].values, max_depth=sys.argv[4])

        main(ds_fromZ,ds_toTransform,preffix=ncfile2.replace('.nc',''),
                zcoord_in='z_l', zcoord_to=z)
