;***************************************************************************
;use the post-processing data to calculate Qd, Qeddy and A
;1. calc climate and transient U V T W
;2. calc transient Qeddy and A, climate Qd 
;3. calc climatology daily Qeddy and A
;4. calc climatology daily forcing induced by Qeddy and Qd,
;   which can influence geopotential tendency
;
;The ncl functions have been used are: 
;   dim_avg_n_Wrap, center_finite_diff_n, conform
;   dim_rmvmean_n_Wrap
;                                            by Ql_Ren
;                                           2019/01/25
;******************************************************************************
begin
path    = "/home/ys17-19/renql"
case_option = 0 ;0 means NUDG experiment; 1 means noTP experiment
option   = 0 ;0 means remove annual cycle, 1 means bandpass filter
geo = True;False ;if true, only can calc 10N 

;parameter for bw_bandpass_filter
ca = 7.0 ;day
cb = 2.5 

if(case_option.eq.0) then
    case    = (/"CTRL","NG24h","NG6h"/)
    filein  = path +(/"/model/AMIP-CTRL/AMIP_C5PM.cam.h1.YEAR.",\
                      "/model/TP-NUDG-24h/AMIP_C5PM_TP_NUDG.cam.h1.YEAR.",\
                      "/model/TP-NUDG-6h/AMIP_C5PM_TP_NUDG.cam.h1.YEAR."/)
    years   = ispan(1979,1980,1)   ;the calculate time
    if(option.eq.0) then
        fileout = path + "/project/TP_NUDG/z_tendency-20191022/mdata/" + (/"CTRL","NUDG24h","NUDG6h"/) + "-Clim_DJF_Qd_Qeddy_A.nc"
    else
        fileout = path + "/project/TP_NUDG/z_tendency-20191022/mdata/" + (/"CTRL","NUDG24h","NUDG6h"/) + "-Clim_DJF_Qd_Qeddy_A_" + cb + "-" + ca + "day.nc"
    end if  
else
    ;remove TP experiment, sample number is ten years 
    case    = (/"TP_CTRL","TP_CR"/) ;TP_CTRL is 0021-0030; TP_CR is 0041-0050
    filein  = path + "/model/" + case + "/pro/" + case + ".cam.h1.YEAR.00" ; + year + ".daily." + var_name + ".nc"
    years   = ispan(21,30,1)   ;the calculate time
    if(option.eq.0) then
        fileout = path + "/project/TP_NUDG/z_tendency-20191022/mdata/" + case + "-Clim_DJF_Qd_Qeddy_A.nc"
    else                                                      
        fileout = path + "/project/TP_NUDG/z_tendency-20191022/mdata/" + case + "-Clim_DJF_Qd_Qeddy_A_" + cb + "-" + ca + "day.nc"
    end if  
end if

var_name = (/"U","V","T","OMEGA","Z3"/)
ncase    = dimsizes(case)
g  = 9.8 ;m/(s*s)
cp = 1004.0 ; J/(K kg)  [ m2/(K s2) ] 
R  = 287.0  ; J/(kg*K) for dry air
a  = 6378388 ;the radius of earth, m
pi = atan(1.0)*4
print(pi)

;area: east Asia
lats =  10 ;-90 ;
latn =  90 ;
lonl =  0  ;
lonr = 360 ;
zlev = (/1000,925,850,700,600,500,400/) ;hPa
lev2 = (/1000,925,850,700,600,500,400,350,300,250,200,150,100/) ;hPa
lev3 = fspan(1000,100,19)
lev = lev2

;==========================================================
;create an array(nvar,ncase,nyear) to store the data
;============================================================
f    = addfile(filein(0)+years(0)+".daily."+var_name(0)+".nc","r")
time = cd_calendar(f->time,0)
vars:= f->$var_name(0)$(0,{lev},{lats:latn},{lonl:lonr})
nlat  = dimsizes(vars&lat)
nlon  = dimsizes(vars&lon)
nyear = dimsizes(years)
nvar  = dimsizes(var_name)
ncase = dimsizes(filein)

iyear = 0
itime = 1
ilev  = 2
ilat  = 3
ilon  = 4
lat  = vars&lat
lon  = vars&lon
lat  = lat*pi/180.0
lon  = lon*pi/180.0
opt    = 0     ;used by center_finite_diff_n, no meanging 
loncyc = True ;used by center_finite_diff_n
cyclic = False ;used by center_finite_diff_n
;means NOT treated as cyclic in differenced coordinates
;the end values will use a one-sided difference scheme for the end points. 

do nf = 0,0,2
if((case_option.eq.1).and.(nf.eq.1))
    years  = ispan(41,50,1)   ;the calculate time
end if
;==========================================================
;read the data
;============================================================
select_time := ind(time(:,1).eq.12.or.time(:,1).le.2)
ntime = dimsizes(select_time)
lev := lev2
nlev   = dimsizes(lev)
nzlev  = dimsizes(zlev)
u     := new((/nyear,ntime,nlev ,nlat,nlon/),float)
v     := new((/nyear,ntime,nlev ,nlat,nlon/),float)
t     := new((/nyear,ntime,nlev ,nlat,nlon/),float)
w     := new((/nyear,ntime,nlev ,nlat,nlon/),float)
z     := new((/nyear,ntime,nzlev,nlat,nlon/),float)

do nt = 0,nyear-1,1
print("handle with " + case(nf) + " " + years(nt))
nv = 0
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
u(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{lev},{lats:latn},{lonl:lonr})

nv = 1
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
v(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{lev},{lats:latn},{lonl:lonr})

nv = 2
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
t(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{lev},{lats:latn},{lonl:lonr})

nv = 3
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
w(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{lev},{lats:latn},{lonl:lonr})

nv = 4
f      = addfile(filein(nf) + years(nt) + ".daily." + var_name(nv) + ".nc","r")
z(nt,:,:,:,:)  = f->$var_name(nv)$(select_time,{zlev},{lats:latn},{lonl:lonr})
end do
u = linmsg_n(u,-1,ilat)
v = linmsg_n(v,-1,ilat)
t = linmsg_n(t,-1,ilat)
w = linmsg_n(w,-1,ilat)
z = linmsg_n(z,-1,ilat)
printVarSummary(w)

if(geo) then
coslat = conform(z(:,:,0,:,:),cos(lat),ilat-1)
f0     = conform(z(:,:,0,:,:),2*(2*pi/24.0/3600.0)*sin(lat),ilat-1)
z = z*g
lat1 = vars&lat
lat_ind = ind(lat1.le.80.0)
lat2 = lat(lat_ind)
printVarSummary(lat_ind)
do nlv = 0,1,1
    nl = 1 - nlv
    ;z1 = z(:,:,nl+2,:,:) + 2*R*t(:,:,nl+1,:,:)*(lev(nl+2)-lev(nl))*100/lev(nl+1)/100
    z1 = z(:,:,nl+1,lat_ind,:) + R*t(:,:,nl,lat_ind,:)*(lev(nl+1)-lev(nl))*100/lev(nl)/100
    u1 = -center_finite_diff_n(z1,lat2,cyclic,opt,ilat-1)/f0(:,:,lat_ind,:)/a        ;(:,:,nl,lat_ind,:)
    v1 =  center_finite_diff_n(z1,lon ,loncyc,opt,ilon-1)/f0(:,:,lat_ind,:)/a/coslat(:,:,lat_ind,:) ;(:,:,nl,lat_ind,:)
    t1 = -lev(nl)*100*(z(:,:,nl+1,lat_ind,:)-z1)/((lev(nl+1)-lev(nl))*100)/R
    print(max(abs(z(:,:,nl,lat_ind,:)-z1)))
    print(max(abs(u(:,:,nl,lat_ind,:)-u1)))
    print(max(abs(v(:,:,nl,lat_ind,:)-v1)))
    print(max(abs(t(:,:,nl,lat_ind,:)-t1)))
    print(z(1,1,nl,10,10:20)-z1(1,1,10,10:20))
    print(u(1,1,nl,10,10:20)-u1(1,1,10,10:20))
    print(v(1,1,nl,10,10:20)-v1(1,1,10,10:20))
    print(t(1,1,nl,10,10:20)-t1(1,1,10,10:20))
    z(:,:,nl,lat_ind,:) = (/tofloat(z1)/)
    u(:,:,nl,lat_ind,:) = (/tofloat(u1)/)
    v(:,:,nl,lat_ind,:) = (/tofloat(v1)/)
    ;t(:,:,nl,lat_ind,:) = (/tofloat(t1)/)
end do
delete([/coslat,f0,u1,v1,z1,t1,z/])
end if

lev := lev3
nlev = dimsizes(lev)
Qeddy := new((/nyear,ntime,nlev,nlat,nlon/),double)

linlog = 0 ;1 mean linear interpolation; 0 mean log interpolation
p_in   = conform(u    ,lev2,ilev)
p_out  = conform(Qeddy,lev3,ilev)
u := int2p_n(p_in,u,p_out,linlog,ilev)
v := int2p_n(p_in,v,p_out,linlog,ilev)
t := int2p_n(p_in,t,p_out,linlog,ilev)
w := int2p_n(p_in,w,p_out,linlog,ilev)
delete([/p_in,p_out,linlog/])

clm_u = dim_avg_n(u,itime)
clm_v = dim_avg_n(v,itime) 
clm_t = dim_avg_n(t,itime) 
clm_w = dim_avg_n(w,itime) 
if(option.eq.1) then
    fca = 1.0/ca
    fcb = 1.0/cb    
    opt = False
    edd_u = bw_bandpass_filter(u,fca,fcb,opt,1)
    edd_v = bw_bandpass_filter(v,fca,fcb,opt,1)
else
    edd_u = u - conform(u, clm_u, (/0,2,3,4/))
    edd_v = v - conform(v, clm_v, (/0,2,3,4/))   
    edd_t = t - conform(t, clm_t, (/0,2,3,4/))   
    edd_w = w - conform(w, clm_w, (/0,2,3,4/))  
end if
printVarSummary(clm_u)
delete([/u,v,t,w/])

;==========================================================
;calc forcing factors: Qeddy, Qd, A, dimension is 5d
;============================================================
coslat4d = conform(clm_u,cos(lat),ilat-1)
tanlat4d = conform(clm_u,tan(lat),ilat-1)
lev4d    = conform(clm_u, lev*100,ilev-1)

sigm0 = (R/cp)*(clm_t/lev4d) - center_finite_diff_n(clm_t,lev*100,cyclic,opt,ilev-1)
Qd    =   (clm_u/a/coslat4d) * center_finite_diff_n(clm_t,lon,loncyc,opt,ilon-1) \
        + (clm_v/a         ) * center_finite_diff_n(clm_t,lat,cyclic,opt,ilat-1) \
        - sigm0 * clm_w 
delete([/clm_u,clm_v,clm_t,clm_w/])
delete([/coslat4d,tanlat4d,lev4d/])

coslat = conform(Qeddy,cos(lat),ilat)
tanlat = conform(Qeddy,tan(lat),ilat)
lev5d  = conform(Qeddy, lev*100,ilev)

Qeddy := - (1.0/a/coslat) * center_finite_diff_n(edd_u*edd_t       ,lon,loncyc,opt,ilon) \
         - (1.0/a/coslat) * center_finite_diff_n(edd_v*edd_t*coslat,lat,cyclic,opt,ilat) \
         + (R/cp)*(edd_w*edd_t)/lev5d - center_finite_diff_n(edd_w*edd_t,lev*100,cyclic,opt,ilev) 
Qeddy := dim_avg_n(Qeddy,itime)
Qd   = Qd - Qeddy
print(Qeddy(0,5,30,30))
print(Qd  (0,5,30,30))

A := -(1.0   /a/a/coslat/coslat)*center_finite_diff_n(center_finite_diff_n(edd_u*edd_v              ,lon    ,loncyc,opt,ilon),lon    ,loncyc,opt,ilon)\
     -(1.0   /a/a/coslat/coslat)*center_finite_diff_n(center_finite_diff_n(edd_v*edd_v*coslat       ,lon    ,loncyc,opt,ilon),lat    ,cyclic,opt,ilat)\
     -(1.0   /a  /coslat       )*center_finite_diff_n(center_finite_diff_n(edd_v*edd_w              ,lon    ,loncyc,opt,ilon),lev*100,cyclic,opt,ilev)\
     -(tanlat/a/a/coslat       )*                     center_finite_diff_n(edd_u*edd_u              ,lon    ,loncyc,opt,ilon)                         \
     +(1.0   /a/a/coslat       )*center_finite_diff_n(center_finite_diff_n(edd_u*edd_u              ,lat    ,cyclic,opt,ilat),lon    ,loncyc,opt,ilon)\
     +(1.0   /a/a/coslat/coslat)*center_finite_diff_n(center_finite_diff_n(edd_u*edd_v*coslat*coslat,lat    ,cyclic,opt,ilat),lat    ,cyclic,opt,ilat)\
     +(tanlat/a/a/coslat/coslat)*                     center_finite_diff_n(edd_u*edd_v*coslat*coslat,lat    ,cyclic,opt,ilat)                         \
     +(1.0   /a                )*center_finite_diff_n(center_finite_diff_n(edd_u*edd_w              ,lat    ,cyclic,opt,ilat),lev*100,cyclic,opt,ilev)\
     -(tanlat/a                )*                     center_finite_diff_n(edd_u*edd_w              ,lev*100,cyclic,opt,ilev)
A := dim_avg_n(A,itime)
print(A(0,5,30,30))
delete([/edd_u,edd_v,edd_t,edd_w/])
delete([/coslat,tanlat/])

sigm0 := dim_avg_n_Wrap(sigm0,0)
Qd    := dim_avg_n_Wrap(Qd,0)
Qeddy := dim_avg_n_Wrap(Qeddy,0)
A     := dim_avg_n_Wrap(A,0)

Qeddy@long_name = "Climatology daily transient eddy heating"
Qeddy@units     = "K/s" 
Qd@long_name = "Climatology daily diabatic heating"
Qd@units     = "K/s" 
A@long_name = "Climatology daily diabatic heating"
A@units     = "s^-2" 

;==========================================================
;calc Qd foring and Qeddy forcing, dimension is 4d 
;============================================================
lev3d = conform(A, lev*100,ilev-2)
sigm1 = sigm0*R/lev3d
sigm1_m = conform(lev3d, wgt_areaave(sigm1,1.0,1.0,0), (/ilev-2/));cos(lat) 
;f0    = conform(A, 2*(2*pi/24.0/3600.0)*sin(lat), ilat-2)
f0    = conform(A, 2*(2*pi/24.0/3600.0)*sin(45.0*pi/180.0), ilat-2)

;do ilat = 0, nlat-1
;if (abs(lat(ilat)*180.0/pi ).lt. 10. ) then
;f0(:,:,ilat,:)= A@_FillValue
;end if
;end do

f_Qd     = -f0*R*center_finite_diff_n((Qd   /sigm1_m/lev3d),lev*100,cyclic,opt,ilev-2)
f_Qeddy  = -f0*R*center_finite_diff_n((Qeddy/sigm1_m/lev3d),lev*100,cyclic,opt,ilev-2)
delete(lev3d)
delete(f0)
delete(sigm1_m)

f_Qeddy@long_name = "Climatology daily transient eddy heating"
f_Qeddy@units     = "s^-2" 
f_Qd@long_name    = "Climatology daily diabatic heatinig"
f_Qd@units        = "s^-2" 
sigm1@long_name = "One kind of static stability measured by potential temperature"
sigm1@units     = "J/(Pa^2*Kg)" 
print(f_Qeddy(5,30,30))
print(f_Qd   (5,30,30))
print(lat(0:9))

;========================================================================
;save the data
;=======================================================================
system("rm -f " + fileout(nf))
setfileoption("nc","Format","LargeFile") 
ncdf = addfile(fileout(nf),"c")
setfileoption(ncdf,"definemode",True)

;set all field attribute
fileatt =  True
fileatt@creation_date = systemfunc("date")
fileatt@discription   = "1-8 monthly three forcing factors, Qd, Qeddy, A"
fileattdef(ncdf,fileatt)  

;define all coordinate
dimNames = (/"lev","lat","lon"/);
dimSizes = (/nlev ,nlat ,nlon/) ;
dimUnlim = (/False,False,False/);
filedimdef(ncdf, dimNames, dimSizes, dimUnlim)

;define var_names, type(string) and dims_names(string)
filevardef(ncdf,"lev" ,typeof(vars&level),(/"lev"/))
filevardef(ncdf,"lat" ,typeof(vars&lat),getvardims(vars&lat))
filevardef(ncdf,"lon" ,typeof(vars&lon),getvardims(vars&lon))
filevardef(ncdf,"sigm1",typeof(sigm1),(/"lev","lat","lon"/))
filevardef(ncdf,"Qeddy",typeof(Qeddy),(/"lev","lat","lon"/))
filevardef(ncdf,"Qd"   ,typeof(Qd),(/"lev","lat","lon"/))
filevardef(ncdf,"A"    ,typeof(A),(/"lev","lat","lon"/))
filevardef(ncdf,"f_Qd",typeof(f_Qd),(/"lev","lat","lon"/))
filevardef(ncdf,"f_Qeddy",typeof(f_Qeddy),(/"lev","lat","lon"/))


;define var attribute
filevarattdef(ncdf,"lev",vars&level)
filevarattdef(ncdf,"lat",vars&lat)
filevarattdef(ncdf,"lon",vars&lon)
filevarattdef(ncdf,"sigm1",sigm1)
filevarattdef(ncdf,"Qeddy",Qeddy)
filevarattdef(ncdf,"Qd"   ,Qd)
filevarattdef(ncdf,"A"    ,A)
filevarattdef(ncdf,"f_Qeddy",f_Qeddy)
filevarattdef(ncdf,"f_Qd"   ,f_Qd)

ncdf->lev  = (/toint(lev)/)
ncdf->lat  = (/vars&lat/)
ncdf->lon  = (/vars&lon/)
ncdf->sigm1 = (/sigm1/)
ncdf->Qeddy = (/Qeddy/)
ncdf->Qd    = (/Qd/)
ncdf->A     = (/A/)
ncdf->f_Qeddy = (/f_Qeddy/)
ncdf->f_Qd    = (/f_Qd/)
end do
end

