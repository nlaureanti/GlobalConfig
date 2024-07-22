#!/home/nicole/miniconda3/bin/python






def main():
        print("Filling obc")
        
        if(len(sys.argv)<1):
	        print(f"uso: {sys.argv[0]} <arquivo> <file_out>*")
	        print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	        quit()
        else:
	        print(f"uso: {sys.argv}\n",'-----\t'*13)
        
        #=============================================================================  
        #Geral defs
        ds = xr.open_dataset(sys.argv[1])
        try:
                file_out=sys.argv[2]
        except:
                file_out=os.path.join(os.path.dirname(sys.argv[1]),
                                os.path.basename(sys.argv[1].replace('.nc','fill.nc')))

        uv=False   
        # Escrevendo as dimensões
        #=============================================================================
        ds_fill = xr.Dataset()
        for v in ds.keys():
                print('*~ filling z ', v)
                for coordz in ["lev","lev_2","z_l","st_ocean"]:
                        try:
                                ds_fill[v] = ds[v].ffill(coordz).bfill(coordz)
                        except: 
                                pass      
                if len(ds_fill.dims) == 0:
                    print(f"coordz not found in {ds.dims}")
                
                    
        if 'v' in  [i.split('_')[0] for i in list(ds.keys())] :           
                print('v '*20)
                v=list(ds.keys())[1]
                suffix=list(ds.keys())[1].split('_')[1]+'_'+list(ds.keys())[1].split('_')[2]
                nvar='dvdx_'+suffix
                nvar2='dz_dvdx_'+suffix
                try:
                        dvdx = (ds[v][:,:,:,-1] - ds[v][:,:,:,-2]) / ds.lon[-1]
                except:        
                        dvdx = (ds[v][:,:,-1,:] - ds[v][:,:,-2,:]) / ds.lat[-1]
                ds_fill[nvar] = dvdx
                ds_fill[nvar2] = ds['dz_v_'+suffix]
                uv=True
                
                
        if 'u' in  [i.split('_')[0] for i in list(ds.keys())] :           
                v=list(ds.keys())[1]
                suffix=list(ds.keys())[1].split('_')[1]+'_'+list(ds.keys())[1].split('_')[2]
                nvar='dudy_'+suffix
                nvar2='dz_dudy_'+suffix
                print(ds[v].dims)
                try:
                        dudy = (ds[v][:,:,:,-1] - ds[v][:,:,:,-2]) / ds.lat[-1]
                except:
                        dudy = (ds[v][:,:,-1,:] - ds[v][:,:,-2,:]) / ds.lon[-1]                        
                ds_fill[nvar] = dudy 
                ds_fill[nvar2] = ds['dz_u_'+suffix]
                uv=True
    
        for v in ds_fill.keys():
                print('*~', v)
                for coordz in ["lev","lev_2","z_l","st_ocean"]:
                        try:
                                ds_fill[v] = ds_fill[v].ffill(coordz).bfill(coordz)
                        except: 
                                pass      
                if len(ds_fill.dims) == 0:
                    print(f"coordz not found in {ds.dims}")                
        write_obc(ds_fill,ds.dims,file_out)
        print("ok")        

#=============================================================================
def write_obc(ds_, varname, fname='obc_teste.nc', fill_value=1e20):
    print(f'writing {varname} in {fname}')


    print(ds_)
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
               
    for coordz in ["lev","lev_2","z_l","st_ocean"]:
        try:
                ds_[coordz].attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                       'positive' : "down", 'units' : "milibar", 'long_name' : "Level"}
        except: 
                pass
        


    #ds_.time.attrs={"calendar":"365_day"}
    ds_.to_netcdf( fname,unlimited_dims=('time')  )
    print(f'>{fname} saved')
    
#=============================================================================    
# Visualização dos arquivos
def plota_obc(da_inicial, da_obc, loc='', levels=None):
    
    
    print(f"shapes: {da_inicial.shape} , {da_obc.shape}")

    g = xr.plot.contourf(da_inicial,figsize=(10,4),cmap='jet',
                                            yincrease=False,
                                            levels=levels)
    plt.suptitle(f'Global {loc}\n', y=1.05, fontsize=16)
    g.axes.set_title(f'Global {loc}\n mean = {da_inicial.mean(skipna=True).data:.4f} $^\circ$ C')


    g = xr.plot.contourf(da_obc,cmap='jet',figsize=(10,4),
                                            yincrease=False,
                                            levels=levels )
    plt.suptitle(f'OBC {loc}\n', y=1.05, fontsize=16)
    g.axes.set_title(f'OBC {loc} \n mean = {da_obc.mean(skipna=True).data:.4f} $^\circ$ C')
    


if __name__ == "__main__":
    import xarray as xr
    import matplotlib.pyplot as plt
    import cartopy.crs as ccrs
    import numpy as np
    import sys
    
    main()               
                                                                                                               

#=============================================================================   
