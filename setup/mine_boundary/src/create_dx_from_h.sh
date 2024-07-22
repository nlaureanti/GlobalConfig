#!/home/nicole/miniconda3/bin/python



"""

    Scrip para criar a dimensão dx, utilizada nas OBC do MOM6
    Inputs: arquivo netcdf
    Desenvolvido por Nicole C. Laureanti
    Baseado em: https://github.com/ESMG/regionalMOM6_notebooks/blob/master/creating_obc_input_files/panArctic_OBC_from_global_MOM6.ipynb
    nlaureanti@gmail.com
    
"""
#=================================================================================================================
#=================================================================================================================
def main():
    import sys, os
    import matplotlib.pyplot as plt
    import numpy as np
    
    view_results=False

    if(len(sys.argv)<1):
	    print(f"uso: {sys.argv[0]} <arquivo> <file_out>")
	    print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	    quit()
    else:
	    print(f"uso: {sys.argv}\n",'------\t'*13)

    undef=1e20
    selvar='grade'

    ds = xr.open_dataset(sys.argv[1])
    ds_time=xr.open_dataset(sys.argv[2])
    file_out=sys.argv[3]

    time=ds_time.time
    nt=time.shape[0]
    
    if 'z_l' in ds.dims:
        z=ds.z_l
        zstr='z_l'
    elif 'zl' in ds.dims:
        z=ds.zl
        zstr='zl'
    elif 'st_ocean' in ds.dims: 
        z=ds.st_ocean
        zstr='st_ocean'
    else:
        z=ds.lev
        zstr='lev'
    print('------\t'*13)

        
    try:
        #time, xt, yt, xu, yu, st, sw = ds.indexes.values() #para arquivos originais SODA
        time, xt, yt, st, sw = ds.indexes.values()     #para arquivos originais recortados SODA
        lev=True
    except:
        try:
                t, xt, yt, st = ds.indexes.values()  
                lev=False
        except:
                print(f'ERRO! arquivo não tem as mesmas coords do soda, arrumar o script {sys.argv[0]}')
                print("disponível:", ds.indexes.values())
                quit()
    print(f" z_coords={zstr}"*5  )   
    
    
    nx=xt.shape[0]
    ny=yt.shape[0]
    nz=st.shape[0]
    
    try:
        zi=ds['dz'].data
        dzdepth=True
        nk=ds_time.lev.data
    except:
        dzdepth=False
        print(ds.keys())
        pass 
    print(f" dzdepth={dzdepth}"*5  )       

    
    da_dz0=np.empty((nt,nz,ny,nx))
    for t in range(nt):
        da_dz0[t,:,:,:]=zi                  
    da_dz=xr.DataArray(da_dz0[:,::-1,:,:] ,coords=[('time',time.data),('lev',nk),
                        ('lat',yt),('lon',xt)], name='dz')                         

            
    ds_=xr.Dataset({'time':time.data,'lev':nk,'lon':xt,'lat':yt,'dz':da_dz})
 
               
    for v in ds_:
        ds_[v].encoding['_FillValue']=1.e20
        ds_[v].encoding['dtype']=np.float32
    for v in ds_.coords:
        ds_[v].encoding['_FillValue']=1.e20
        ds_[v].encoding['dtype']=np.float64       
    print(f"> {file_out}")
    ds_['lev'].attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                        'positive' : "down", 'units' : "millibar", 
                        'long_name' : "Level"}
    ds_.to_netcdf(file_out,unlimited_dims=('time'))
    
if __name__ == "__main__":
    import xarray as xr
    main()



