#!/Volumes/A1/workdir/nicole/envs/xesmf_env_test/bin/python
# code has been adapted from Andrew Ross , Alistair Adcroft, and Matthew Harrison: https://github.com/andrew-c-ross/nwa-shared/blob/main/setup/rivers/write_runoff_glofas.py
import numpy as np
import xarray
import xesmf


def get_coast_mask(mask_file):
    mask = xarray.open_dataset(mask_file)

    # Alistair's method of finding coastal cells
    ocn_mask = mask['mask'].values
    cst_mask = 0 * ocn_mask # All land should be 0
    is_ocean = ocn_mask > 0
    cst_mask[(is_ocean) & (np.roll(ocn_mask, 1, axis=1) == 0)] = 1 # Land to the west
    cst_mask[(is_ocean) & (np.roll(ocn_mask, -1, axis=1) == 0)] = 1 # Land to the east
    cst_mask[(is_ocean) & (np.roll(ocn_mask, 1, axis=0) == 0)] = 1 # Land to the south
    cst_mask[(is_ocean) & (np.roll(ocn_mask, -1, axis=0) == 0)] = 1 # Land to the north

    # Model boundaries are not coasts
    cst_mask[0, :] = 0
    cst_mask[:, 0] = 0
    cst_mask[-1, :] = 0
    cst_mask[:, -1] = 0

    return cst_mask


def write_runoff(glofas, glofas_mask, hgrid, coast_mask, out_file):
    glofas_latb = np.arange(glofas['latitude'][0]+.05, glofas['latitude'][-1]-.051, -.1)
    glofas_lonb = np.arange(glofas['longitude'][0]-.05, glofas['longitude'][-1]+.051, .1)
    
    lon = hgrid.x[1::2, 1::2]
    lonb = hgrid.x[::2, ::2]
    lat = hgrid.y[1::2, 1::2]
    latb = hgrid.y[::2, ::2]
    # From Alistair
    area = (hgrid.area[::2, ::2] + hgrid.area[1::2, 1::2]) + (hgrid.area[1::2, ::2] + hgrid.area[::2, 1::2])
    
    # Convert m3/s to kg/m2/s
    # Borrowed from https://xgcm.readthedocs.io/en/latest/xgcm-examples/05_autogenerate.html
    distance_1deg_equator = 111000.0
    dlon = dlat = 0.1  # GloFAS grid spacing
    #dx = dlon * xarray.ufuncs.cos(xarray.ufuncs.deg2rad(glofas.lat)) * distance_1deg_equator #deprecated
    dx = dlon * np.cos(np.deg2rad(glofas.latitude)) * distance_1deg_equator
    dy = ((glofas.longitude * 0) + 1) * dlat * distance_1deg_equator
    glofas_area = dx * dy
    glofas_kg = glofas * 1000.0 / glofas_area
    
    # Conservatively interpolate runoff onto MOM grid
    glofas_to_mom_con = xesmf.Regridder(
        {'lon': glofas.longitude, 'lat': glofas.latitude, 'lon_b': glofas_lonb, 'lat_b': glofas_latb},
        {'lat': lat, 'lon': lon, 'lat_b': latb, 'lon_b': lonb},
        method='conservative',
        periodic=True,
        reuse_weights=False
    )
    # Interpolate only from GloFAS points that are river end points.
    print(glofas_mask)
    print(glofas_kg.where(glofas_mask > 0).shape)
    glofas_regridded = glofas_to_mom_con(glofas_kg.where(glofas_mask > 0).fillna(0.0))
    
    glofas_regridded = glofas_regridded.rename({'nyp': 'ny', 'nxp': 'nx'}).values

    # Flatten mask and coordinates to 1D
    flat_mask = coast_mask.ravel().astype('bool')
    coast_lon = lon.values.ravel()[flat_mask]
    coast_lat = lat.values.ravel()[flat_mask]
    mom_id = np.arange(np.prod(coast_mask.shape))

    # Use xesmf to find the index of the nearest coastal cell
    # for every grid cell in the MOM domain
    coast_to_mom = xesmf.Regridder(
        {'lat': coast_lat, 'lon': coast_lon},
        {'lat': lat, 'lon': lon},
        method='nearest_s2d',
        locstream_in=True,
        reuse_weights=False
    )
    coast_id = mom_id[flat_mask]
    nearest_coast = coast_to_mom(coast_id).ravel()

    # Raw runoff on MOM grid, reshaped to 2D (time, grid_id)
    raw = glofas_regridded.reshape([glofas_regridded.shape[0], -1])

    # Zero array that will be filled with runoff at coastal cells
    filled = np.zeros_like(raw)

    # Loop over each coastal cell and fill the result array
    # with the sum of runoff for every grid cell that
    # has this coastal cell as its closest coastal cell
    for i in coast_id:
        filled[:, i] = raw[:, nearest_coast == i].sum(axis=1)

    # Reshape back to 3D
    filled_reshape = filled.reshape(glofas_regridded.shape)



    # Convert to xarray
    ds = xarray.Dataset({
        'runoff': (['time', 'y', 'x'], filled_reshape),
        'area': (['y', 'x'], area.data),
        'lat': (['y', 'x'], lat.data),
        'lon': (['y', 'x'], lon.data)
        },
        coords={'time': glofas['time'].data, 'y': np.arange(filled_reshape.shape[1]), 'x': np.arange(filled_reshape.shape[2])}
    )

    # Drop '_FillValue' from all variables when writing out
    all_vars = list(ds.data_vars.keys()) + list(ds.coords.keys())
    encodings = {v: {'_FillValue': None} for v in all_vars}

    # Make sure time has the right units and datatype
    # otherwise it will become an int and MOM will fail. 
    encodings['time'].update({
        'units': 'days since 1950-01-01',
        'dtype': np.float, 
        'calendar': 'gregorian'
    })

    ds['time'].attrs = {'cartesian_axis': 'T'}
    ds['x'].attrs = {'cartesian_axis': 'X'}
    ds['y'].attrs = {'cartesian_axis': 'Y'}
    ds['lat'].attrs = {'units': 'degrees_north'}
    ds['lon'].attrs = {'units': 'degrees_east'}
    ds['runoff'].attrs = {'units': 'kg m-2 s-1'}

    # Write out
    ds.to_netcdf(
        out_file,
        unlimited_dims=['time'],
        format='NETCDF3_64BIT',
        encoding=encodings,
        engine='netcdf4'
    )
    ds.close()



if __name__ == '__main__':
    coast = get_coast_mask('/home/nicole/workdir/SWA14/grid/ocean_mask.nc')
    hgrid = xarray.open_dataset('/home/nicole/workdir/SWA14/grid/ocean_hgrid.nc')
    # For NWA: subset GloFAS to a smaller region containing NWA.
    upArea_subset = dict(latitude=slice(5,-55), longitude=slice(-69, -9))
    glofas_subset = dict(latitude=slice(5,-55), longitude=slice(-69, -9))

    # GloFAS upstream area from 
    # https://confluence.ecmwf.int/download/attachments/143039724/upArea.nc?version=3&modificationDate=1648465375523&api=v2
    # The metadata says it is GloFAS version 2.1, but it looks like a good match for 3.1
    uparea = xarray.open_dataarray('/home/nicole/workdir/GloFAS/upArea.nc').sel(**upArea_subset)

    # Find river end points by looking for local maxima in upstream area.
    uparea = uparea.fillna(0).values
    points = np.zeros_like(uparea)
    window = 2  # look with +- this number of grid points
    ni, nj = uparea.shape
    for i in range(window, ni-window):
        for j in range(window, nj-window):
            sub = uparea[i-window:i+window+1, j-window:j+window+1]
            point = uparea[i, j]
            # A river end point has a reasonably large upstream area
            # and is a local maximum
            if point > 1e6 and sub.max() == point:
                points[i, j] = 1
    print(uparea.shape,points.shape)
    for y in range(2017, 2018):
        print(y)
        # GloFAS 3.1 data copied to vftmp from:
        # /archive/e1n/datasets/GloFAS/
        gloFASdir='/Volumes/A1/workdir/nicole/GloFAS/'
        files = [f'{gloFASdir}/Glofas_{y}.nc' for y in [y-1, y, y+1]]
        glofas = (
            xarray.open_mfdataset(files, combine='by_coords')
            .sel(time=slice(f'{y-1}-01-01 00:00:00', f'{y+1}-01-01 00:00:00'), **glofas_subset)
            .dis24
        )
        out_file = f'/home/nicole/workdir/SWA14/INPUT/glofas_runoff_{y}.nc'
        write_runoff(glofas, points, hgrid, coast, out_file)

    print('done!')    
