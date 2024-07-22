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
                xt, yt, st = ds.indexes.values()  
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
        zi=ds['dz']

        dz0=zi-np.roll(zi,shift=1)
        dz0[0]=zi[0]
        dzdepth=True
    except:
        dzdepth=False
        print(ds.keys())
        pass 
    print(f" dzdepth={dzdepth}"*5  )       

    if zstr == 'st_ocean':        
        print('z original>>>>>>>>>>>',z)
        
        if dzdepth:
                zl=xr.where(z>dz0,dz0,zl)
        else:                
                zl=z
        zi=0.5*(np.roll(zl,shift=-1)+zl)
        zi[-1]=-5500.
        ds['z_i']=zi
        print('z modificado>>>>>>>>>>>',zi)
            
        dz=zi-np.roll(zi,shift=1)
        dz[0]=zi[0]
        ds['dz1']=dz[::-1]
        print('dz >>>>>>>>>>>',dz)      

        
    else:

        z0=np.empty((nz,ny,nx))
        for k in range(nz):
                z0[k,:,:]=z[k]
        #z0[-1,:,:]=0.
        if view_results:
                print('z original >>>>>>>>>>>',z0[:,0,0])
                ds['z0']=xr.DataArray(z0,coords=[('lev',st),('lat',yt),('lon',xt)], name='z0')
                ds['z0'].isel(lat=0).plot()
                plt.show()
        

        if dzdepth:
                zl=xr.where(z0>zi,zi,z0) #altura real das camada com campo de profundidade
        else:                
                zl=z
        if view_results:
                ds['zl']=xr.DataArray(zl,coords=[('lev',st),('lat',yt),('lon',xt)], name='zl')
                ds['zl'].isel(lat=0).plot()
                plt.show()                        

        zi0=np.empty((nz,ny,nx))    
        for x in range(nx):    
                for y in range(ny):        
                        zi0[:,y,x]=0.5*(np.roll(zl[:,y,x],shift=-1)+zl[:,y,x])
        
        #zi0[0,:,:]=0.5*(5500.-zl[0,y,x]) #before
        
        
        dzi=np.empty((nt,nz,ny,nx))
        for t in range(nt):
                dzi[t,:,:,:]=zi0
        ds['dz_i']=xr.DataArray(dzi,coords=[('time',time.data),('lev',st),('lat',yt),('lon',xt)])
        
        if view_results:
                print('z modificado >>>>>>>>>>>',ds['dz_i'].isel(time=0,lat=0))        
                ds['dz_i'].isel(time=0,lat=0).plot()
                plt.show()
         
        dz=np.empty((nz,ny,nx))    
        for x in range(nx):    
                for y in range(ny):
                        dz[:,y,x]=np.roll(zl[:,y,x],shift=1)-zl[:,y,x]
                        #dz[:,y,x]=5500-zi[:,y,x]
                        
        #dz[0,:,:]=zi[0,:,:] #before
        #dz[-1,:,:]=zi[-1,:,:] #before
        dadz=np.empty((nt,nz,ny,nx))   
        if dzdepth:
                dz=xr.where(abs(dz)>abs(zi),-1.0*zi,dz)
 
        for t in range(nt):
                dadz[t,:,:,:]=dz
        da_dz=xr.DataArray(dadz ,coords=[('time',time.data),('lev',st),
                        ('lat',yt),('lon',xt)], name='dz') 

        if view_results:
                print('dz >>>>>>>>>>>',da_dz.isel(time=0,lat=0))               
                da_dz.isel(time=0,lat=0).plot()
                plt.show()
#            nczt[:] = var.depth[:, 0, 0]
#            nczw[0] = 0
#            nczw[1:] = var.dz[:, 1, 1].cumsum()
#            ncinterfaces[0] = 0
#            ncinterfaces[1:] = var.dz[:, 0, 0].cumsum()    


    try:
        nkmin = ds.prho.isel(time=0).min("lat").min("lon").values
        layer=True
        print(f"nk min= {nkmin}")
        da_layer=xr.DataArray(nkmin,coords=[('lev',st)])
    except:
        layer=False
        
    da_dz0=np.empty((nt,nz,ny,nx))
    for t in range(nt):
        da_dz0[t,:,:,:]=zi                      
    ds['dz']=xr.DataArray(da_dz0[:,::-1,:,:] ,coords=[('time',time.data),('lev',st),
                        ('lat',yt),('lon',xt)], name='dz')
    ds['dz']=da_dz                        

            
    if layer:   

        ds_=xr.Dataset({'time':time.data,'lev':st,
                                  'lon':xt,'lat':yt,'Interface':da_dz,
                                  'Layer':da_layer})
        ds_['Layer'].attrs={'units' : "kg m-3", 
                       'long_name' : "Layer Target Potential Density"}
    else:        
        ds_=xr.Dataset()
        ds_=xr.Dataset({'time':time.data,'lev':st,'lon':xt,'lat':yt,'dz':da_dz})
        #ds_['dz']=da_dz[:,::-1,:,:]
 
               
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



