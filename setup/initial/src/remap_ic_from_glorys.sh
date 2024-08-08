#!/home/nicole.laureanti/miniconda3/envs/obcic/bin/python

"""

    Scrip para remapear as condições de fronteira do SODA para o MOM6
    Inputs: arquivo netcdf
    Desenvolvido por Nicole C. Laureanti
    Baseado em: https://github.com/ESMG/regionalMOM6_notebooks/blob/master/creating_obc_input_files/panArctic_OBC_from_global_MOM6.ipynb
    nlaureanti@gmail.com
    
"""
#=================================================================================================================
#=================================================================================================================
def main():
    global sel_var, dir_out, dz, view_results    
    view_results=False

    if(len(sys.argv)<=1):
	    print(f"Abort. Erro no uso: {sys.argv[0]} <arquivo_hgrid> <global> <var> <fronteira>")
	    print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	    quit()
    else:
	    print('............. Generating IC .............') 
	    print(f' {sys.argv[:]}')   
	    
    use_location=True
    undef=1e20
    dir_out='./'


    global_file=sys.argv[2]
    sel_var=sys.argv[3]
    fronteira=sys.argv[4]
    
    if "ocean_hgrid" in sys.argv[1] :         
        regional_grid=open_grid(sys.argv[1],sel_var) # com ocean_hgrid.nc sem supergrid
        #regional_grid=xr.open_dataset(sys.argv[1],decode_times=False)
        ocean_hgrid=True
        print(f"ocean_hgrid? {ocean_hgrid}")
    else:
        regional_grid=xr.open_dataset(sys.argv[1])
        ocean_hgrid=False
        print(f"ocean_hgrid? {ocean_hgrid}")  
        
    if ocean_hgrid:
#        ds_regionalgrid=xr.Dataset(
#            {
#		    "lat": (["lat"], np.linspace(regional_grid.y.min().values,regional_grid.y.max().values,len(regional_grid.y.values[:,0]))), #for regular grid
#		    "lon": (["lon"], np.linspace(regional_grid.x.min().values,regional_grid.x.max().values,len(regional_grid.x.values[0,:]))),
#                    "lat": (["lat"], regional_grid.y.values[:,0]),
#                    "lon": (["lon"], regional_grid.x.values[0,:]),
#            }
#        )
        ds_regionalgrid=regional_grid[['x', 'y']].rename({'y': 'lat', 'x': 'lon'})
    else: 
        ds_regionalgrid=regional_grid      
        if 'lat' not in ds_regionalgrid.dims or 'lon' not in ds_regionalgrid.dims:
             for (x,y) in [('longitude','latitude'),('xh','yh'),('xt_ocean','yt_ocean'),('nx','ny')]:
                    try:
                        ds_regionalgrid=ds_regionalgrid.rename({x:'lon',y:'lat'})
                        break
                    except:
                        pass

    ds=xr.open_dataset(global_file)
    Vvar={'thetao':'temp','so':'salt','zos':'ssh',
                                                'uo':'u','vo':'v'}
    for VVar in Vvar.keys():
        try:
           ds=ds.rename({VVar:Vvar[VVar]})
        except:
           pass
    if sel_var not in ds.data_vars:
	    print(sel_var, 'not in ds.datavars')
	    print(ds.data_vars)
	    quit()

    if 'lat' not in ds.dims or 'lon' not in ds.dims:
	    for (x,y) in [('longitude','latitude'),('xh','yh'),('xt_ocean','yt_ocean'),('nx','ny')]:
                    try:
                        ds=ds.rename({x:'lon',y:'lat'})
                        break
                    except:
                        pass
    
    # *** 3. Subsetting the domain no need
    #ds_cut = ds.sel(lon=slice(-60, -19), lat=slice(-42,-10),
    #                lon=slice(-60, -20), lat=slice(-42,-10))
    for zstr in ['z_l','zl','z_i','depth','lev','st_ocean']:
         try:
            z=ds[zstr].values
            break
         except:
             pass 
        
    #print("disponível:", ds.indexes.values())
    if len(ds.dims) > 3:
       time, lon, lat, lev = ds.indexes.values()	
    else:
       time,lon,lat = ds.indexes.values()

    print(f" coords input={ds.dims}"  )
    print(f" coords grid ={regional_grid.dims}"  )        
    
    nt=time.shape[0]
    nx=lon.shape[0]
    ny=lat.shape[0]

    try:
        nkmin = ds.prho.isel(time=0).min("lat").min("lon").values
        layer=True
        print(f"nk min= {nkmin}")
        da_layer=xr.DataArray(nkmin,coords=[('lev',lev)])
    except:
        layer=False
        
    try:    
        #if ds is a mom6 file, we have h
        dz=np.tile(ds.dz.data[np.newaxis,np.newaxis,:,np.newaxis],(nx,ny,1,nt))
        ds['h']=xr.DataArray(dz,coords=[('lon',lon),('lat',lat),
                        ('lev',lev),('time',time)])          
    except:
        print(f"not able to open dz in {fronteira}")
        pass
      

    print('..................................START..................................')
    print(f'...............regriding var: {sel_var}')
    print('...........................Interpolation method..........................')
    interpolation_method(ds,ds_regionalgrid,fronteira)
    print('.........................................................................')
    saving_files(use_location,dir_out,undef,fronteira)
    #plot(dir_out,fronteira)
    print('...................................END...................................')
    #regridder.clean_weight_file()    
    
def open_grid(path,var,decode_times=False):
    
    """Return a grid object containing staggered grid locations"""
    grid={}
    grid['ds']=xr.open_dataset(path,decode_times=False)
    grid['ds']=grid['ds'].drop_dims(['ny','nx'])
    grid['ds']=grid['ds'].drop_vars(['tile'])
    try:
        grid['nyp']=grid['ds'].nyp.data[-1]+1
        grid['nxp']=grid['ds'].nxp.data[-1]+1
        nxp=grid['nxp'];nyp=grid['nyp']
        grid['h'] = grid['ds'].isel(nxp=slice(1,nxp+1,2),nyp=slice(1,nyp+1,2))
        #The q grid is not symmetric, but Cu and Cv are
        grid['q'] = grid['ds'].isel(nxp=slice(2,nxp+1,2),nyp=slice(2,nyp+1,2))
        grid['Cu'] = grid['ds'].isel(nxp=slice(0,nxp+1,2),nyp=slice(1,nyp+1,2))
        grid['Cv'] = grid['ds'].isel(nxp=slice(1,nxp+1,2),nyp=slice(0,nyp+1,2))
    except:
        grid['nyp1']=grid['ds'].nyp1.data[-1]+1
        grid['nxp1']=grid['ds'].nxp1.data[-1]+1
        nxp1=grid['nxp1'];nyp1=grid['nyp1']

        grid['h'] = grid['ds'].isel(nxp1=slice(1,nxp1+1,2),nyp1=slice(1,nyp1+1,2))
        #The q grid is not symmetric, but Cu and Cv are
        grid['q'] = grid['ds'].isel(nxp1=slice(2,nxp1+1,2),nyp1=slice(2,nyp1+1,2))
        grid['Cu'] = grid['ds'].isel(nxp1=slice(0,nxp1+1,2),nyp1=slice(1,nyp1+1,2))
        grid['Cv'] = grid['ds'].isel(nxp1=slice(1,nxp1+1,2),nyp1=slice(0,nyp1+1,2))
        
    if var=='u':    
        final_grid= grid['Cu']
    elif var=='v':    
        final_grid= grid['Cv']
    else:
        final_grid= grid['h']         
    return final_grid  
    
    
def mkdir(path):    
    import os
    try:
        os.mkdir(path)
    except OSError as error:
        print(error)
        
def interpolation_method(ds_cut,ds_ccs,fronteira):     

    global drowned_var_east, drowned_var_north, drowned_var_south, var_north, var_south, var_east, var_ic_ccs, alldrowned_var

    # *** 4. Regridding to Open Boundaries
    if fronteira in ['north']:
        north = xr.Dataset()
        north['lon'] = ds_ccs['x'].isel(nyp=-1)
        north['lat'] = ds_ccs['y'].isel(nyp=-1)
        regrid_north = xesmf.Regridder(ds_cut.rename({'lon': 'lon', 'lat': 'lat'}), 
            north, 'bilinear', #reuse_weights=True,
            locstream_out=True, periodic=False, filename='regrid_north.nc')            
    elif fronteira in ['south']:
        # southern boundary
        south = xr.Dataset()
        south['lon'] = ds_ccs['x'].isel(nyp=0)
        south['lat'] = ds_ccs['y'].isel(nyp=0)
            
        regrid_south = xesmf.Regridder(ds_cut.rename({'lon': 'lon', 'lat': 'lat'}), 
            south, 'bilinear', #reuse_weights=True, 
            locstream_out=True, periodic=False, filename='regrid_south.nc')            
    elif fronteira in ['east']:        
        # eastern boundary
        east = xr.Dataset()
        east['lon'] = ds_ccs['x'].isel(nxp=-1)
        east['lat'] = ds_ccs['y'].isel(nxp=-1)
        
        regrid_east = xesmf.Regridder(ds_cut.rename({'lon': 'lon', 'lat': 'lat'}), 
            east, 'bilinear', #reuse_weights=True,
            locstream_out=True, periodic=False, filename='regrid_east.nc') 
    elif fronteira in ['initial']:
        # *** 3. Subsetting the domain no need
        if len(ds_cut.dims) > 3:
             ds_cut = ds_cut.rename({'depth': 'lev'}).isel(time=0)        
        else:
             ds_cut = ds_cut.isel(time=0)
        if view_results:
                print(ds_cut)
        if sel_var in ['u','v','uo','vo']:
             reuse_weights=False
        else:
             reuse_weights=True
        regrid_domain = xesmf.Regridder(ds_cut, 
                                ds_ccs,
                                'bilinear', periodic=False, reuse_weights=reuse_weights, 
                                filename='regrid_domain.nc')
    if view_results:  
        ds_cut[sel_var].isel(lev=0).plot()
        plt.show()                             
                                 
    # Remapping the variable ontonorthern boundary  using the appropriate xESMF regridder:
    if sel_var in ['SSH','ssh','zos']:
        drowned_var = flood_kara(ds_cut[sel_var], xdim='lon', ydim='lat', tdim='time')
        #drowned_var=ds_cut[sel_var]

    else:    
        drowned_var = flood_kara(ds_cut[sel_var], xdim='lon', ydim='lat', zdim='lev')
  
    
    if fronteira in ['initial']:              
        #alldrowned_var = drowned_var.ffill(dim='lev').bfill(dim='lev')
        var_ic_ccs = regrid_domain(drowned_var)        
        alldrowned_var= var_ic_ccs.drop(['lon','lat']).rename({'nxp': 'lon', 'nyp': 'lat'})
        
        if view_results:       
                var_ic_ccs.isel(time=0,lev=0).plot()
                plt.show()
                print(alldrowned_var)
                alldrowned_var.isel(time=0,lev=0).plot()
                plt.show()                
		
   
    print('ok') 

#========================================================================
def write_obc(da, dadz, varname, fname='obc_teste.nc', fill_value=1e20):
    #not used
    print(f'writing {varname} to {fname}')
    ds_=da.assign_coords({'lat':da['lat'].data,'lon':da['lon']}).to_dataset(name=varname)
    if dadz is not None:
        ds_['dz_'+varname]=dadz
    if view_results:
        print(ds_)
    for v in ds_:
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['dtype']=np.float32
    for v in ds_.coords:
        ds_[v]=xr.DataArray(ds_[v].data, dims=[v], coords= {v:(v,ds_[v].data)})
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['dtype']=np.float32
    if varname in ['uo','u']:
        xstr,ystr='lonq','lath'
    elif varname in ['vo','v']:
        xstr,ystr='lonh','latq'
    else:
        xstr,ystr='lonh','lath'
    ds_=ds_.rename({'lon':xstr,'lat':ystr})
    ds_[xstr].attrs={'standard_name':"longitude",
                        'long_name' : "geographic_longitude",
                        'axis' : "X",
                        'cartesian_axis' : "X",
                        'units' : "degrees_east"}
    ds_[ystr].attrs={'standard_name' : "latitude",
                            'long_name' : "geographic_latitude",
                            'axis' : "Y",
                            'cartesian_axis' : "Y",
                            'units' : "degrees_north"}                           
               
    if 'ssh' not in varname:
        ds_.lev.attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                       'positive' : "down", 'units' : "m", 'long_name' : "Layer pseudo-depth -z*"}

    ds_.to_netcdf( fname,unlimited_dims=('time')  )
    print(f'>{fname} saved')        
#========================================================================
def saving_files(use_location,dir_out,fill_value,fronteira):
        print(f"Salvando as condições de fronteira em campo interpolado: {fronteira}")
#################################################################################
#                               LOCATIONS 

        import numpy as np

        params=[]
        if fronteira in ['north']:    
                params.append({'suffix':'_segment_001',
                            'dim0':2,'tr_in':drowned_var_north,
                            'tr_out':'{1}/obc_{0}_north.nc'.format(sel_var,dir_out)})
        elif fronteira in ['east']:                        
                params.append({'suffix':'_segment_003',
                           'dim0':3,'tr_in':drowned_var_east,
                           'tr_out':'{1}/obc_{0}_east.nc'.format(sel_var,dir_out)})
        elif fronteira in ['south']:                       
                params.append({'suffix':'_segment_002',
                            'dim0':2,'tr_in':drowned_var_south,
                            'tr_out':'{1}/obc_{0}_south.nc'.format(sel_var,dir_out)})
        elif fronteira in ['initial']:                       
                params.append({'suffix':'',
                            'dim0':2,'tr_in':alldrowned_var,
                            'tr_out':'{1}/ic_{0}.nc'.format(sel_var,dir_out)})
                          
        for pr in params:
            if view_results:
                print(pr)
            print(f" coords output={pr['tr_in'].dims}"  )
            #print(f"{pr['tr_in'].lat} {pr['tr_in'].locations}")                    

            # exporting coords         
            try:
                time=pr['tr_in'].time
                lev=pr['tr_in'].lev
                lat=pr['tr_in'].lat
                lon=pr['tr_in'].lon            
            except:
                try:
                        time=pr['tr_in'].time
                        lev=pr['tr_in'].z
                        lat=pr['tr_in'].lat
                        lon=pr['tr_in'].lon 
                except:         
                        if len(pr['tr_in'].dims) > 2:
                            print(f'ERRO! arquivo não tem as mesmas coords do soda, arrumar o script {sys.argv[0]}')
                            print("disponível:", pr['tr_in'].indexes.values())
                            quit()
                        else:
                            lat=pr['tr_in'].lat
                            lon=pr['tr_in'].lon
                            time=pr['tr_in'].time
  
            try: 
               zl=lev.data
            except:
               pass
            print(time.shape)
            nt=time.shape[0]
            nx=lon.shape[0]
            ny=lat.shape[0]             
            
            #ds_ = pr['tr_in'].to_dataset(name=sel_var+pr['suffix'])

            if  'east' in pr['tr_out']:
                   ds_=xr.Dataset(data_vars={
#                                'dz_'+sel_var+pr['suffix']:da_dz,
                   sel_var+pr['suffix']:(["time","lev","lat","lon"] , pr['tr_in'])},
                             coords=dict(time=(['time'],time),
                                      lev=(['lev'],lev),
                                      lon=(['lon'],lon),lat=(['lat'],[lat[0]])))
            elif 'ic' in pr['tr_out'] and len(pr['tr_in'].dims) >2:
                   ds_=xr.Dataset(data_vars={
                   sel_var+pr['suffix']:(["time","lev","lat","lon"] , pr['tr_in'].data)},
                             coords=dict(time=(['time'],time.data),
                                      lev=(['lev'],lev.data),
                                      lon=(['lon'],lon.data),
                                      lat=(['lat'],lat.data))) 
            elif 'ic' in pr['tr_out'] : #for ssh
                   ds_=xr.Dataset(data_vars={
                   sel_var+pr['suffix']:(["time","lat","lon"] , pr['tr_in'].data)},
                             coords=dict(time=(['time'],time.data),
                                      lon=(['lon'],lon.data),
                                      lat=(['lat'],lat.data)))		    
            else:
                   ds_=xr.Dataset(data_vars={
#                                'dz_'+sel_var+pr['suffix']:da_dz,
                   sel_var+pr['suffix']:(["time","lev","lat","lon"] , pr['tr_in'])},
                             coords=dict(time=(['time'],time),
                                      lev=(['lev'],lev),
                                      lon=(['lon'],[lon[0]]),
                                      lat=(['lat'],lat)))  
                                      
            if view_results:
                 ds_[sel_var+pr['suffix']].isel(time=0,lev=0).plot()
                 plt.show()
            #for v in ds_:
            #    if sel_var in ['SSH','ssh']:            
            #        ds_[v] = ds_[v].expand_dims({'dim_0':pr['dim0']-1},2)
            #    else:
            #        ds_[v] = ds_[v].expand_dims({'dim_0':pr['dim0']},2)
            if 'ic' not in pr['tr_out'] :
                # create dx from SODA                           
                zi=0.5*(np.roll(zl,shift=1)+zl)
                zi[0]=5500.
                if view_results:
                   print('z modificado>>>>>>>>>>>',zi)
                ds_['z_i']=zi
            
                dz=zi-np.roll(zi,shift=-1)
                dz[-1]=zi[0] 
                if view_results:
                   print('dz >>>>>>>>>>>',dz)
                ds_['dz']=dz  

                try:
                    nkmin = ds.prho.isel(time=0).min("lat").min("lon").values
                    print(f"nk min= {nkmin}")
                    da_layer=xr.DataArray(nkmin,coords=[('lev',st)])
                    Layer=True
                except:
                    Layer=False
                    print(f"WARNING prho not found Layer = {Layer}")
            
                dz=np.tile(ds_.dz.data[np.newaxis,:,np.newaxis,np.newaxis],(nt,1,ny,nx))
                da_dz=xr.DataArray(dz,coords=[('time',time.data),('lev',lev.data),
                        ('lat',lat.data),('lon',lon.data)])
                        
                ds_['dz_'+sel_var+pr['suffix']] = da_dz
                if Layer:   
                    ds_['Layer']=xr.Dataset({'time':time,'lev':lev,
                                  'lon':lon,'lat':lat,'Interface':da_dz,
                                  'Layer':da_layer})
                    ds_['Layer'].attrs={'units' : "kg m-3", 
                        'long_name' : "Layer Target Potential Density"}
            #Managing attributes
            ds_.time.encoding['calendar']="gregorian"
            for v in ds_:
               ds_[v].encoding['_FillValue']=fill_value
               ds_[v].encoding['dtype']=np.float32
            for v in ds_.coords:
               ds_[v].encoding['_FillValue']=fill_value
               ds_[v].encoding['dtype']=np.float32

            ds_.lon.attrs={'standard_name':"longitude",
                        'long_name' : "geographic_longitude",
                        'axis' : "X",
                        'cartesian_axis' : "X",
                        'units' : "degrees_east"}
            ds_.lat.attrs={'standard_name' : "latitude",
                            'long_name' : "geographic_latitude",
                            'axis' : "Y",
                            'cartesian_axis' : "Y",
                            'units' : "degrees_north"}                           
               
            if sel_var not in ['SSH','ssh']:
                ds_.lev.attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                        'positive' : "down", 'units' : "meters", 'long_name' : "Depth at cell center"}
                        
                        
                        
            #=============================================================================
            ds_fill = xr.Dataset()
            for v in ds_.keys():
                print('*~ filling xy ', v)
                for coordx,coordy in [("lon","lat"),("x","y"),
                                  ("longitude","latitude")]:
                        try:
                                ds_fill[v] = ds_[v].ffill(coordx).bfill(coordx).ffill(coordy).bfill(coordy)
                        except: 
                                pass      
                if len(ds_fill.dims) == 0:
                    print(f"coord not found in {ds.dims}")
            for v in ds_.keys():
                print('*~', v)
                for coordz in ["lev","lev_2","z_l","st_ocean"]:
                        try:
                                ds_fill[v] = ds_[v].ffill(coordz).bfill(coordz)
                        except: 
                                pass      
                if len(ds_fill.dims) == 0:
                    print(f"coordz not found in {ds.dims}") 
#            ds_.time.attrs={"units":'days since 1900-01-01 00:00:00',"calendar":"365_day"}

            #ds_fill.to_netcdf(pr['tr_out'])
            if 'ic' in pr['tr_out'] : 
                 write_obc(pr['tr_in'], None, sel_var, pr['tr_out'], 1e20)
            print('>{0} saved'.format(pr['tr_out']))
            #writing nc out	    
            #write_obc(pr['tr_in'], da_dz, sel_var, pr['tr_out'], 1e20)
#========================================================================
def plot(dir_out,fronteira):
    componentes={}
    componentes['north']= { 'dx' : slice(300,340) , 'dy' : -20 , 'suffix' : '_segment_001', 'dt' : 0,
                                      'dybc': -1 }
    componentes['south']= { 'dx' : slice(300,340) , 'dy' : -40 , 'suffix' : '_segment_002', 'dt' : 0,
                                      'dybc': 0 }
    componentes['east'] = { 'dx' :  340, 'dy' : slice(-40,-20) , 'suffix' : '_segment_003', 'dt' : 0,
                                      'dxbc' : -1 }
    componentes['initial'] = { 'dx' : slice(300,340), 'dy' : slice(-40,-20) , 'suffix' : '', 'dt' : 0,
                                      'dxbc' : -1 }                                      

    suffix=componentes[fronteira]['suffix']
    ds=xr.open_dataset(f'{dir_out}/obc_{sel_var}_{fronteira}.nc',decode_times=False)
    ds[sel_var+suffix].isel(time=0).plot(yincrease=False)


    ds.close()
    plt.title(f'{fronteira} Boundary')
    plt.savefig(f'{dir_out}/obc_{sel_var}_{fronteira}_fig.png')
    plt.close()

#======================================================================== 
def flood_kara_xr(dataarray, spval=1e+15):
    """Apply flood_kara on a xarray.dataarray

    Arguments:
        dataarray {xarray.DataArray} -- input 2d data array

    Keyword Arguments:
        spval {float} -- missing value (default: {1e+15})

    Returns:
        numpy.ndarray -- field after extrapolation
    """

    masked_array = dataarray.squeeze().to_masked_array()
    out = flood_kara_ma(masked_array, spval=spval)
    return out
#========================================================================    
def flood_kara_ma(masked_array, spval=1e+15):
    """Apply flood_kara on a numpy masked array

    Arguments:
        masked_array {np.ma.masked_array} -- array to extrapolate

    Keyword Arguments:
        spval {float} -- missing value (default: {1e+15})

    Returns:
        out -- field after extrapolation
    """

    field = masked_array.data

    if np.isnan(field).all():
        # all the values are NaN, can't do anything
        out = field.copy()
    else:
        # proceed with extrapolation
        field[np.isnan(field)] = spval
        mask = np.ones(field.shape)
        mask[masked_array.mask] = 0
        out = flood_kara_raw(field, mask)
    return out
#========================================================================        
def flood_kara_raw(field, mask, nmax=1000):
    """Extrapolate land values onto land using the kara method
    (https://doi.org/10.1175/JPO2984.1)

    Arguments:
        field {np.ndarray} -- field to extrapolate
        mask {np.ndarray} -- land/sea binary mask (0/1)

    Keyword Arguments:
        nmax {int} -- max number of iteration (default: {1000})

    Returns:
        drowned -- field after extrapolation
    """

    ny, nx = field.shape
    nxy = nx * ny
    # create fields with halos
    ztmp = np.zeros((ny+2, nx+2))
    zmask = np.zeros((ny+2, nx+2))
    # init the values
    ztmp[1:-1, 1:-1] = field.copy()
    zmask[1:-1, 1:-1] = mask.copy()

    ztmp_new = ztmp.copy()
    zmask_new = zmask.copy()
    #
    nt = 0
    while (zmask[1:-1, 1:-1].sum() < nxy) and (nt < nmax):
        for jj in np.arange(1, ny+1):
            for ji in np.arange(1, nx+1):

                # compute once those indexes
                jjm1 = jj-1
                jjp1 = jj+1
                jim1 = ji-1
                jip1 = ji+1

                if (zmask[jj, ji] == 0):
                    c6 = 1 * zmask[jjm1, jim1]
                    c7 = 2 * zmask[jjm1, ji]
                    c8 = 1 * zmask[jjm1, jip1]

                    c4 = 2 * zmask[jj, jim1]
                    c5 = 2 * zmask[jj, jip1]

                    c1 = 1 * zmask[jjp1, jim1]
                    c2 = 2 * zmask[jjp1, ji]
                    c3 = 1 * zmask[jjp1, jip1]

                    ctot = c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8

                    if (ctot >= 3):
                        # compute the new value for this point
                        zval = (c6 * ztmp[jjm1, jim1] +
                                c7 * ztmp[jjm1, ji] +
                                c8 * ztmp[jjm1, jip1] +
                                c4 * ztmp[jj, jim1] +
                                c5 * ztmp[jj, jip1] +
                                c1 * ztmp[jjp1, jim1] +
                                c2 * ztmp[jjp1, ji] +
                                c3 * ztmp[jjp1, jip1]) / ctot

                        # update value in field array
                        ztmp_new[jj, ji] = zval
                        # set the mask to sea
                        zmask_new[jj, ji] = 1
        nt += 1
        ztmp = ztmp_new.copy()
        zmask = zmask_new.copy()

        if nt == nmax:
            raise ValueError('number of iterations exceeded maximum, '
                             'try increasing nmax')

    drowned = ztmp[1:-1, 1:-1]

    return drowned    
#========================================================================    
def flood_kara(data, xdim='lon', ydim='lat', zdim='z', tdim='time',
               spval=1e+15):
    """Apply extrapolation onto land from Kara algo.

    Arguments:
        data {xarray.DataArray} -- input data

    Keyword Arguments:
        xdim {str} -- name of x dimension (default: {'lon'})
        ydim {str} -- name of y dimension (default: {'lat'})
        zdim {str} -- name of z dimension (default: {'z'})
        tdim {str} -- name of time dimension (default: {'time'})
        spval {float} -- missing value (default: {1e+15})

    Returns:
        xarray.DataArray -- result of the extrapolation
    """
    # check for input data shape
    if tdim not in data.dims:
        data = data.expand_dims(dim=tdim)
    if zdim not in data.dims:
        data = data.expand_dims(dim=zdim)

    nrec = len(data[tdim])
    nlev = len(data[zdim])
    ny = len(data[ydim])
    nx = len(data[xdim])
    shape = (nrec, nlev, ny, nx)
    chunks = (1, 1, ny, nx)

    def compute_chunk(zlev, trec):
        data_slice = data.isel({tdim: trec, zdim: zlev})
        return flood_kara_xr(data_slice, spval=spval)[None, None]

    name = str(data.name) + '-' + tokenize(data.name, shape)
    dsk = {(name, rec, lev, 0, 0,): (compute_chunk, lev, rec)
           for lev in range(nlev)
           for rec in range(nrec)}

    out = dsa.Array(dsk, name, chunks,
                    dtype=data.dtype, shape=shape)

    xout = xr.DataArray(data=out, name=str(data.name),
                        coords={tdim: data[tdim],
                                zdim: data[zdim],
                                ydim: data[ydim],
                                xdim: data[xdim]},
                        dims=(tdim, zdim, ydim, xdim))

    # rechunk the result
    xout = xout.chunk({tdim: 1, zdim: nlev, ydim: ny, xdim: nx})

    return xout

if __name__ == "__main__":
    import xarray as xr
    import sys, os
    import matplotlib.pyplot as plt
    import numpy as np
    import xesmf
    from dask.base import tokenize
    import dask.array as dsa
    import warnings
    main()




