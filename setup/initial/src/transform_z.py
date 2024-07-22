#!/home/nicole.laureanti/miniconda3/envs/obcic/bin/python

"""
    Vertical interpolation
    Contributition of Nicole C. Laureanti, 2023
    Earth System Modeling Group, Rutgers University, NJ/USA
    Brazilian National Institute for Space Research, SP/Brazil
    nlaureanti@gmail.com
    
    Source: https://xgcm.readthedocs.io/en/latest/transform.html
    
    Installing requirements:
    conda install -c conda-forge xarray dask netCDF4 bottleneck
    conda install -c conda-forge xgcm
   
"""    
def main(ds, dsCtrl2, preffix='ds_', zcoord_in='z_l', zcoord_to='depth'):

#           ### TRANSFORM Z-COORD ###
            dsCtrl2['z_to'] = ds[zcoord_to].values
            print(dsCtrl2.dims)
            try:
                gridz = Grid(dsCtrl2, coords={'Z': {'center':zcoord_in}}, periodic=False)
            except:
                gridz = Grid(dsCtrl2, coords={'Z': {'center':'depth'}}, periodic = False)
            newds = xr.Dataset()
            for var in dsCtrl2.variables:
                if var not in dsCtrl2.dims and dsCtrl2[var].ndim > 3 and var not in ['time_bnds']:
                    print(var)
                    newds[var] = gridz.transform(dsCtrl2[var], 'Z', dsCtrl2.z_to,
                    mask_edges=False,
                        method='linear')
                elif var not in dsCtrl2.dims and var not in ['time_bnds']:
                    newds[var]=dsCtrl2[var]
            print(newds.dims)
            for x,y in [('xh','yh'),('longitude','latitude'),
                            ('nx','ny'),('lon','lat')]:
               if x in ds.dims and y in ds.dims:
                  break

            try:        
                newds=newds.transpose('time','z_to',y,x).rename({'z_to':'depth',x:'lon',y:'lat'})
            except:
                newds=newds.rename({'z_to':'depth'})
                pass

            newds.to_netcdf(f'{preffix}_zl.nc')
            print(f'> out : {preffix}_zl.nc')

            quit()

if __name__ == "__main__":
        import xarray as xr
        import sys
        from xgcm import Grid

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
        if zcoord_to not in ds_fromZ.dims:
              print(ds_fromZ.data_vars)
              print('zcoord_to:');zcoord_to=input()

        main(ds_fromZ,ds_toTransform,preffix=ncfile2.replace('.nc',''),
                zcoord_in='z_l', zcoord_to=zcoord_to)
