#!/home/nicole/miniconda3/bin/python

"""

    Scrip para converter arquivos netcdf para binário/ctl.
    Específico para condições de contorno: saídas MOM6global->regional
    Inputs: arquivo netcdf
    Desenvolvido por Nicole C. Laureanti
    nlaureanti@gmail.com
    
"""
#=================================================================================================================
#=================================================================================================================
def main():
    import xarray as xr
    import sys

    if(len(sys.argv)<2):
	    print(f"uso: {sys.argv[0]} <selvar> <arquivo> <file_preffix> <tinitial>")
	    print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	    selvar=input('Nome da variável: \n')
	    arquivo=input('Nome do netcdf: \n')
	    file_preffix = input('Nome do arquivo binário: \n')
	    tinitial = input('Tempo inicial: \n')
    else:
	    print(f"uso: {sys.argv}\n",'------\t'*13)
	    selvar=sys.argv[1];arquivo=sys.argv[2]
	    file_preffix=sys.argv[3];tinitial=sys.argv[4]
	    

    undef = 1e20
    ds = xr.open_dataset(arquivo)
    if selvar == '*':
        try:
                listavar=list(ds.variables).remove(list(ds.dims))
        except:
                listavar=list(ds.variables)
        print(f'Variáveis disponíveis: {listavar}')
        #Escrevendo o binário
        for selvar in listavar:  
                converte = analise_dim(selvar, ds)
                if converte:
                    print(f'convertendo: {selvar}')
                    campos = ds[selvar]
                    campos.where(-1e+34,undef)
                    print( campos.shape,campos.dims)
                    vardt=campos.dims[0]
                    lendt=campos.shape[0]
                    #caso bem mais simples: variável 4D (t,x,y,z)
                    nc2bin(campos, file_preffix, tinitial, selvar)    #escrevendo o binário
                else:
                    listavar.remove(selvar)
    else:
        #caso bem mais simples: variável 4D (t,x,y,z)
        analise_dim(selvar, ds)
        nc_in = ds[selvar]
        nc2bin(nc_in, file_preffix, tinitial, selvar)    #escrevendo o binário + ctl      
    try:
        print(f"bin size = {nc_in.shape[0]*nc_in.shape[1]*nc_in.shape[2]*nc_in.shape[3]*4}")
    except:
        print(f"bin size = {nc_in.shape[0]*nc_in.shape[1]*nc_in.shape[2]*4}")
    try:
        plota(ds[selvar],file_preffix) #plot the last record
    except:
        quit()

def create_ctl(ctlout,nomebin,undef,nx,dx,ny,dy,nz,dz,nt,dt,t0,vname):
    print(f"\n Criando ctl {ctlout}\n",'------\t'*10) 
    with open(ctlout,'w', encoding = 'utf-8') as f:
        f.write("""dset ^{0} \ntitle ^Criado automaticamente  \n\
*options sequential\nundef {1} 
xdef {2} linear {3} 1
ydef {4} levels {5} 
zdef {6} levels {7}
tdef {8} linear {10} {9}
vars 1 
{11}  {6} 99 t,z,y,x  Variavel
endvars""".format(nomebin,undef,nx,str(dx).replace('[','').replace(']',''),\
                  ny,str(dy).replace('[','').replace(']',''),\
                    nz,str(dz).replace('[','').replace(']',''),nt,dt,t0,
                    vname))
    f.close()
def create_ctl_2d(ctlout,nomebin,undef,nx,dx,ny,dy,nz,dz,nt,dt,t0,vname):
    print(f"\n Criando ctl {ctlout}\n",'------\t'*10) 
    with open(ctlout,'w', encoding = 'utf-8') as f:
        f.write("""dset ^{0} \ntitle ^Criado automaticamente  \n\
*options sequential\nundef {1} 
xdef {2} levels {3} 
ydef {4} levels {5} 
zdef {6} levels {7}
tdef {8} linear {10} {9}
vars 1 
{11}  {6} 99 t,z,y,x  Variavel
endvars""".format(nomebin,undef,nx,str(dx).replace('[','').replace(']',''),\
                  ny,str(dy).replace('[','').replace(']',''),\
                    nz,str(dz).replace('[','').replace(']',''),nt,dt,t0,
                    vname))
    f.close()


def analise_dim(selvar,ds):
    # Análise das dimensões
    if ds[selvar].dims == ():
        converte=False
    else:
        converte=True
        print('dims--------------\n : \n{0}'\
                  .format(ds[selvar].dims))
        print('shapes------------\n : \n{0}'\
                  .format(ds[selvar].shape))
        print('coords-----------\n : \n{0}'\
                  .format(ds[selvar].coords))
    return converte


def nc2bin(campos, nomes, tinitial, selvar):
        # Conversão de netcdf para binário
        print("\n Conversão de netcdf para binário",'------\t'*10) 
        from scipy.io import FortranFile
        import numpy as np
        import xarray as xr
        np.set_printoptions(suppress=True) #prevent numpy exponential 
                                   #notation on print, default False

        print( nomes,' ->bin')
        print( campos.shape,campos.dims)
        vardt=campos.dims[0]
        lendt=campos.shape[0]


        f = FortranFile(nomes+'.bin', 'w')
        for t in range(0,lendt):
            for zsel in range(len(campos.isel(Time=t).data)):
                try:
#                    print(f'shape at t= {t} zl={zsel} {campos.isel(Time=t,zl=zsel).shape}')
                    matrix=np.array( campos.isel(Time=t,zl=zsel).data, dtype=np.float32).reshape(campos.isel(Time=t,zl=zsel).shape)
                    timerec=campos.isel(Time=t).Time.data
                except:
                    matrix=np.array( campos.isel(Time=t).values, dtype=np.float32).reshape(campos.isel(Time=t).shape)
                    timerec=campos.isel(Time=t).Time.data
                f.write_record(  matrix   )      
        f.close()
        print(f'last: {timerec}')

        if len(campos.shape) == 4:
            create_ctl(nomes+'.ctl',nomes+'.bin',1e20,\
                     campos.shape[3],f"{np.array2string(campos[campos.dims[3]].data[0], precision=4, max_line_width=60)}",\
                  campos.shape[2],f"{np.array2string(campos[campos.dims[2]].data, precision=4, max_line_width=60)}",\
                  campos.shape[1],f"{np.array2string(campos[campos.dims[1]].data, precision=4, max_line_width=60)}",\
                  campos.shape[0],'1dy',tinitial, selvar)                        
        else:
            create_ctl_2d(nomes+'.ctl',nomes+'.bin',1e20,\
                  campos.shape[2],f"{np.array2string(campos[campos.dims[2]].data, precision=4, max_line_width=60)}",\
                  campos.shape[1],f"{np.array2string(campos[campos.dims[1]].data, precision=4, max_line_width=60)}",\
                    1, f" 1 1",\
                  campos.shape[0],'1dy',tinitial, selvar) 
            print('create_ctl_2d')

def plota(da,title):
    # Plotagem simples
    print(f"Plot simples {title}.png\n",'------\t'*10) 
    print( da.shape,da.dims)
    import matplotlib.pyplot as plt
    import xarray as xr
    vmin=0;vmax=27
    fig, axis = plt.subplots(1, figsize=(14,7))    
    xr.plot.contourf(da[-1,-1,:,:],
                         ax=axis,cmap='jet')
#    axis.set_title(title)
    plt.savefig(f'{title}.png',facecolor='white', edgecolor='none')
#    plt.show()    

if __name__ == "__main__":
    main()



