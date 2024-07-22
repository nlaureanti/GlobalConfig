
import matplotlib.pyplot as plt
import xarray as xr
import cartopy.crs as ccrs #opcional

soda=xr.open_dataset("~/Documentos/INPE/dados_tese/SODA/soda3.15.2_5dy_ocean_reg_2002.nc")
#da_soda=soda.temp.isel(st_ocean=0).sel(xt_ocean=slice(300,340),yt_ocean=slice(-40,-20))



soda=xr.open_dataset("SODA_remap.exp_AScoast002.nc")
reg=xr.open_dataset("~/Documentos/INPE/mom/exps_mom6/exp_AScoast002/workdir/20020107.ocean_daily_z_ts.nc")





da_soda=soda.temp.isel(st_ocean=0).sel(xh=slice(-60,-20),yh=slice(-40,-20))
da_reg=reg.temp.isel(z_l=0)

dif = da_soda.isel(time=0)-da_reg.isel(Time=0)

da_soda.isel(time=0).plot()
plt.title("SODA")
#plt.show()
plt.cla()

da_reg.isel(Time=0).plot()
plt.title("Regional")
#plt.show()
plt.cla()

dif.plot()
#plt.show()

proj=ccrs.PlateCarree() #opcional
tt=1
for t in range(0,len(da_reg.Time),5):
        fig = plt.figure() #figsize=(14, 12) #opcional
        ax = plt.axes(projection=proj) #opcional
        
        dif = da_soda.isel(time=tt)-da_reg.isel(Time=t)
        a=dif.plot(add_colorbar=False)
        
        print(f"data_soda: {da_soda.time.values[tt]}")
        print(f"data_reg: {da_reg.Time.values[t]}")
        
        plt.colorbar(a,ax=ax,shrink=.60,orientation="horizontal", pad=0.15) #opcional
        ax.coastlines() #opcional
        gl = ax.gridlines(crs=proj,color="black", linestyle="dotted",draw_labels=True)   #opcional  
        
        plt.title(f"Diferença SODA-Regional dia {da_reg.Time.values[t]}")
        plt.savefig(f"dif_SODA_reg_{t}.png")
        plt.clf()
        tt=tt+1

print(dif)
