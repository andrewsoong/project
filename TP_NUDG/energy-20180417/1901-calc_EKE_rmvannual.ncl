;***************************************************************************
;use the post-processing data to calculate climatology daily transient eddies
;1. remove annual cycle;  2. calc transient eddies kinetic energy (EkE)
;3. calc climatology daily EKE
;The ncl functions have been used are: dpres_plevel_Wrap,dim_sum_n_Wrap,dim_avg_n_Wrap
;dim_rmvmean_n_Wrap
;                                            by Ql_Ren
;                                           2019/01/25
;******************************************************************************
begin
path    = "/home/ys17-19/renql"
case_option = 0 ;0 means NUDG experiment; 1 means noTP experiment
option   = 0 ;0 means remove annual cycle, 1 means bandpass filter

;parameter for bw_bandpass_filter
ca = 7.0 ;day
cb = 2.5 

if(case_option.eq.0) then
    case    = (/"CTRL","NG24h","NG6h"/)
    filein  = path +(/"/model/AMIP-CTRL/AMIP_C5PM.cam.h1.YEAR.",\
                      "/model/TP-NUDG-24h/AMIP_C5PM_TP_NUDG.cam.h1.YEAR.",\
                      "/model/TP-NUDG-6h/AMIP_C5PM_TP_NUDG.cam.h1.YEAR."/)
    years   = ispan(1979,2005,1)   ;the calculate time
    if(option.eq.0) then
        fileout = path + "/project/TP_NUDG/analysis/mdata/" + (/"CTRL","NUDG24h","NUDG6h"/) + "-Clim_month_ave_EKE.nc"
    else
        fileout = path + "/project/TP_NUDG/analysis/mdata/" + (/"CTRL","NUDG24h","NUDG6h"/) + "-Clim_month_ave_EKE-" + cb + "-" + ca + "day.nc"
    end if  
else
    ;remove TP experiment, sample number is ten years 
    case    = (/"TP_CTRL","TP_CR"/) ;TP_CTRL is 0021-0030; TP_CR is 0041-0050
    filein  = path + "/model/" + case + "/pro/" + case + ".cam.h1.YEAR.00" ; + year + ".daily." + var_name + ".nc"
    years   = ispan(21,30,1)   ;the calculate time
    if(option.eq.0) then
        fileout = path + "/project/TP_NUDG/analysis/mdata/" + case + "-Clim_month_ave_EKE.nc"
        ;fileout = path + "/project/TP_NUDG/analysis/mdata/" + case + "-Clim_month_ave_uv.nc"
    else
        fileout = path + "/project/TP_NUDG/analysis/mdata/" + case + "-Clim_month_ave_EKE-" + cb + "-" + ca + "day.nc"
    end if  
end if

var_name= (/"U","V"/)
ncase   = dimsizes(case)
g  = 9.8 ;m/(s*s)

;area: east Asia
lats = -90 ;-20
latn =  90 ;60
lonl =  0  ;20
lonr = 360 ;220
lev  = (/1000,925,850,700,600,500,400,300,200/)

;==========================================================
;create an array(nvar,ncase,nyear) to store the data
;============================================================
f    = addfile(filein(0)+years(0)+".daily."+var_name(0)+".nc","r")
vars:= f->$var_name(0)$(:,{lev},{lats:latn},{lonl:lonr})
time = cd_calendar(f->time,0)
select_time = ind(time(:,1).ge.1.and.time(:,1).le.12)
ntime = dimsizes(select_time)
nlat  = dimsizes(vars&lat)
nlon  = dimsizes(vars&lon)
nlev  = dimsizes(lev)
nyear = dimsizes(years)
nvar  = dimsizes(var_name)
ncase = dimsizes(filein)
u     = new((/nyear,ntime,nlev,nlat,nlon/),float)
v     = new((/nyear,ntime,nlev,nlat,nlon/),float)
var_month  = new((/nyear,12 ,nlev,nlat,nlon/),float)
var_season = new((/nyear,4  ,nlev,nlat,nlon/),float)
month_ave  = new((/      12 ,nlev,nlat,nlon/),float)
month_vari = new((/      12 ,nlev,nlat,nlon/),float) ;be used to exam the significance of the mean difference between the two groups
season_ave = new((/       4 ,nlev,nlat,nlon/),float)
season_vari= new((/       4 ,nlev,nlat,nlon/),float)

do nf = 2,2,1 
if((case_option.eq.1).and.(nf.eq.1))
    years   = ispan(41,50,1)   ;the calculate time
end if
;==========================================================
;read the data
;============================================================
do nt = 0,nyear-1,1
nv = 0
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
u(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{lev},{lats:latn},{lonl:lonr})

nv = 1
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
v(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{lev},{lats:latn},{lonl:lonr})
end do
printVarSummary(u)

if(option.eq.1) then
    fca = 1.0/ca
    fcb = 1.0/cb    
    opt = False
    filt_u = bw_bandpass_filter(u,fca,fcb,opt,1)
    filt_v = bw_bandpass_filter(v,fca,fcb,opt,1)
    var   = (filt_v*filt_v + filt_u*filt_u)/2.0   ;get (nyear,ntime,nlat,nlon)
    print(filt_u(10,180,2,150,10:20))
    delete(filt_u)
    delete(filt_v)  
else
    edd_u = u - conform(u,dim_avg_n(u,0),(/1,2,3,4/))
    edd_v = v - conform(v,dim_avg_n(v,0),(/1,2,3,4/))   
    var   = (edd_v*edd_v + edd_u*edd_u)/2.0   ;ps-200hPa integral get (nyear,ntime,nlat,nlon)
end if
EKE   = dim_avg_n(var,0) 
EKE_vari = dim_variance_n(var,0) 

EKE@long_name = "Integrated transient eddies kinetic energy"
EKE@units     = "J" 

time = cd_calendar(f->time,0)
do nm = 0,11,1
    select_time := ind(time(:,1).eq.nm+1)
    var_month(:,nm,:,:,:) = dim_avg_n_Wrap(var(:,select_time,:,:,:),1) ;get (nyear,nmonth,nlat,nlon)
end do

;----------calculate the season average-----------------------
mdays    = (/31,28,31,30,31,30,31,31,30,31,30,31/)
do ns = 0,3,1
    nm = ns*3 ;nm = 0,3,6,9
    if(nm.eq.0) then
    var_season(:,ns,:,:,:) = ( var_month(:,11  ,:,:,:)*mdays(11)   + \
                               var_month(:,nm  ,:,:,:)*mdays(nm)   + \
                               var_month(:,nm+1,:,:,:)*mdays(nm+1))/(mdays(11) + mdays(nm)+ mdays(nm+1))
    else
    var_season(:,ns,:,:,:) = ( var_month(:,nm-1,:,:,:)*mdays(nm-1) + \
                               var_month(:,nm  ,:,:,:)*mdays(nm)   + \
                               var_month(:,nm+1,:,:,:)*mdays(nm+1))/(mdays(nm-1) + mdays(nm)+ mdays(nm+1))
    end if
end do
month_ave  = dim_avg_n_Wrap(var_month,0) ;get (nmonth,nlat,nlon)
month_vari = dim_variance_n_Wrap(var_month,0) ;get (nmonth,nlat,nlon)
season_ave  = dim_avg_n_Wrap(var_season,0) ;get (nseason,nlat,nlon)
season_vari = dim_variance_n_Wrap(var_season,0) ;get (nseason,nlat,nlon)
printVarSummary(month_ave)
printVarSummary(season_ave)
print(month_ave(6,2,10,10:20))

;========================================================================
;save the data
;=======================================================================
system("rm -f " + fileout(nf))
ncdf = addfile(fileout(nf),"c")
setfileoption(ncdf,"definemode",True)

;set all field attribute
fileatt =  True
fileatt@creation_date = systemfunc("date")
fileatt@discription   = "rmvannual cycle"
fileattdef(ncdf,fileatt)  

;define all coordinate`
dimNames = (/"month","season","time","lev","lat","lon"/);
dimSizes = (/  12   ,  4     ,ntime ,nlev ,nlat ,nlon/) ;
dimUnlim = (/False  ,False   ,False ,False,False,False/);
filedimdef(ncdf, dimNames, dimSizes, dimUnlim)

;define var_names, type(string) and dims_names(string)
filevardef(ncdf,"month" ,"integer",(/"month" /))
filevardef(ncdf,"season","integer",(/"season"/))
filevardef(ncdf,"time",typeof(u&time),getvardims(u&time))
filevardef(ncdf,"lev" ,typeof(u&level),(/"lev"/))
filevardef(ncdf,"lat" ,typeof(u&lat),getvardims(u&lat))
filevardef(ncdf,"lon" ,typeof(u&lon),getvardims(u&lon))
filevardef(ncdf,"EKE",typeof(EKE),(/"time","lev","lat","lon"/))
filevardef(ncdf,"EKE_vari",typeof(EKE_vari),(/"time","lev","lat","lon"/))
filevardef(ncdf,"month_ave"  ,typeof(month_ave)  ,(/"month" ,"lev","lat","lon"/))
filevardef(ncdf,"season_ave" ,typeof(season_ave) ,(/"season","lev","lat","lon"/))
filevardef(ncdf,"month_vari" ,typeof(month_vari) ,(/"month" ,"lev","lat","lon"/))
filevardef(ncdf,"season_vari",typeof(season_vari),(/"season","lev","lat","lon"/))

;define var attribute
filevarattdef(ncdf,"time",u&time)
filevarattdef(ncdf,"lev",u&level)
filevarattdef(ncdf,"lat",u&lat)
filevarattdef(ncdf,"lon",u&lon)
filevarattdef(ncdf,"EKE",EKE)
filevarattdef(ncdf,"month_ave",EKE)
filevarattdef(ncdf,"season_ave",EKE)
filevarattdef(ncdf,"month_vari",EKE)
filevarattdef(ncdf,"season_vari",EKE)

ncdf->month  = ispan(1,12,1)
ncdf->season = (/1212,345,678,91011/)
ncdf->time = (/u&time/)
ncdf->lev  = (/lev/)
ncdf->lat  = (/u&lat/)
ncdf->lon  = (/u&lon/)
ncdf->EKE  = (/EKE/)
ncdf->EKE_vari  = (/EKE_vari/)
ncdf->month_ave   = (/month_ave/)
ncdf->season_ave  = (/season_ave/)
ncdf->month_vari  = (/month_vari/)
ncdf->season_vari = (/season_vari/)
end do
end

