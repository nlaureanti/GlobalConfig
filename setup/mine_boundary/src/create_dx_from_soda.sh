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


    if(len(sys.argv)<1):
	    print(f"uso: {sys.argv[0]} <arquivo> <file_out>")
	    print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	    quit()
    else:
	    print(f"uso: {sys.argv}\n",'------\t'*13)

    tctl='01jan1900'
    tnc=np.datetime64('1900-01-01') 
    undef=1e20
    selvar='grade'

    ds = xr.open_dataset(sys.argv[1])
    file_out=sys.argv[2]

 
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
                time, xt, yt, st = ds.indexes.values()  
                lev=False
        except:
                print(f'ERRO! arquivo não tem as mesmas coords do soda, arrumar o script {sys.argv[0]}')
                print("disponível:", ds.indexes.values())
                quit()
    print(f" z_coords={zstr}"*5  )        

    if zstr == 'st_ocean':        
        print('z original>>>>>>>>>>>',z)
        zl=z
        zi=0.5*(np.roll(zl,shift=-1)+zl)
        zi[-1]=5500.
        ds['z_i']=zi
        print('z modificado>>>>>>>>>>>',zi)
            
        dz=zl-np.roll(zl,shift=1)
        dz[0]=zl[0]
        ds['dz']=dz[::-1]
        print('dz >>>>>>>>>>>',dz)
    else:
        print('z original>>>>>>>>>>>',z)
        zl=z[::-1]
        zi=0.5*(np.roll(zl,shift=-1)+zl)
        zi[-1]=5500.
        ds['z_i']=zi
        print('z modificado>>>>>>>>>>>',zi)
            
        #criar dz: valores positivos, da diferença da altura da coluna com relação ao fundo
        dz=np.roll(zl,shift=-1)-zl
        dz[-1] = (  5500-zl[-1]   )
        dz[0] = zl[0] 
        ds['dz']=dz[::-1]
        print('dz >>>>>>>>>>>',dz)                
    
    
#            nczt[:] = var.depth[:, 0, 0]
#            nczw[0] = 0
#            nczw[1:] = var.dz[:, 1, 1].cumsum()
#            ncinterfaces[0] = 0
#            ncinterfaces[1:] = var.dz[:, 0, 0].cumsum()    
    nt=time.shape[0]
    nx=xt.shape[0]
    ny=yt.shape[0]

    try:
        nkmin = ds.prho.isel(time=0).min("lat").min("lon").values
        layer=True
        print(f"nk min= {nkmin}")
        da_layer=xr.DataArray(nkmin,coords=[('lev',st)])
    except:
        layer=False
        
        
    dz=np.tile(ds.dz.data[np.newaxis,:,np.newaxis,np.newaxis],(nt,1,ny,nx))
    da_dz=xr.DataArray(dz,coords=[('time',time),('lev',st),
                        ('lat',yt),('lon',xt)])
    #print('dz final >>>>>>>>>>>',dz)  
    
    if layer:   

        ds_=xr.Dataset({'time':time,'lev':st,
                                  'lon':xt,'lat':yt,'Interface':da_dz,
                                  'Layer':da_layer})
        ds_['Layer'].attrs={'units' : "kg m-3", 
                       'long_name' : "Layer Target Potential Density"}
    else:        
            
            ds_=xr.Dataset({'time':time,'lev':st,'lon':xt,'lat':yt,'dz':da_dz})
 
               
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



