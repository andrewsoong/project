;*********************************************************************
;filename:      draw_1p2x3_qtran_int.ncl
;input_data:    CTRL-JJA_ano_850hpa_qu.nc 
;                                                     by Ql Ren
;                                                    2018/01/18
;*********************************************************************************
begin
draw_var = (/"Total","Steady","Transient"/) 
var_name_u = (/"qu","ste_qu","edd_qu"/)
var_name_v = (/"qv","ste_qv","edd_qv"/)
unit     = "kg/(s*m)" ;"K"   ;this can be used as right string 
div_option = True

months = (/"MJ","JA"/)
;months = (/"JF","MA","MJ","JA"/)
;months  = (/"May","Jun","Jul","Aug"/)
nmonth = dimsizes(months)
month_s = 5
month_e = 8

;the path of the file
path     = "/home/ys17-19/renql/project/TP_NUDG"
filename = path + "/energy-20180417/mdata/" + (/"CTRL","NUDG6h"/) + "-Clim_qtran_int_rmvannual.nc" ;,"NUDG24h"
gtopfile = path + "/analysis/mdata/" + "gtopo30_0.9x1.25.nc"
fig_name = path + "/energy-20180417/fig/1p2x3_qtran_int_rmvannual"
    case   = (/" CTRL"," NG6h-CTRL"/) ;," NG24h-CTRL"
pre_case   = (/"(a","(b","(c","(d","(e","(f","(g","(h","(i","(j","(k","(l","(m","(n","(o","(p"/)
fig_out    ="pdf";"x11"
;fig_out    ="eps";"x11"

;area: east Asia
lats = (/10 ,-15/) ;-20
latn = (/55 ,55 /) ;60
lonl = (/90 ,30 /) ;20
lonr = (/150,150/) ;220
siglvl = 0.05
ntime  = 27
na = 0

f = addfile(gtopfile,"r")
phis   = f->PHIS({lats(na):latn(na)},{lonl(na):lonr(na)})
phis   = phis/9.8   ;convert unit from m2/s2 to gpm
ncase  = dimsizes(case)
nvar   = dimsizes(draw_var)
nlat   = dimsizes(phis&lat)
nlon   = dimsizes(phis&lon)

f      = addfile(filename(0),"r")
time   = cd_calendar(f->time,0)
select_time = ind(time(:,1).ge.month_s.and.time(:,1).le.month_e)
ntime = dimsizes(select_time)
u  = new((/ncase,nvar,ntime,nlat,nlon/),float)
v  = new((/ncase,nvar,ntime,nlat,nlon/),float)
var_u  = new((/ncase,nvar,nmonth,nlat,nlon/),float)
var_v  = new((/ncase,nvar,nmonth,nlat,nlon/),float)

;the number of the panel plot
    plot     = new((/ncase*nmonth/),graphic)
    plotvc   = new((/ncase*nmonth/),graphic)
    line     = new((/ncase*nmonth/),graphic)
    gtop     = new((/ncase*nmonth/),graphic)

;set the area of the box
maxlon = 105
minlon = 70
maxlat = 40
minlat = 25
lonx = (/ minlon, maxlon, maxlon, minlon, minlon /)
latx = (/ minlat, minlat, maxlat, maxlat, minlat /)

;================================================================
;read data
;====================================================================
do nf = 0 ,ncase-1, 1
f = addfile(filename(nf),"r")
do nv = 0,nvar-1,1
    print("read " + case(nf) + " " + var_name_u(nv))
    print("read " + case(nf) + " " + var_name_v(nv))
    u(nf,nv,:,:,:)  = f->$var_name_u(nv)$(select_time,{lats(na):latn(na)},{lonl(na):lonr(na)}) ;get an array (ncase,nmonth,nlat,nlon)
    v(nf,nv,:,:,:)  = f->$var_name_v(nv)$(select_time,{lats(na):latn(na)},{lonl(na):lonr(na)}) ;get an array (ncase,nmonth,nlat,nlon)
end do
end do

time1  = cd_calendar(f->time(select_time),0)
do nm = 0, nmonth-1, 1
mons = 2*nm + month_s
mone = 2*nm + month_s + 1
select_time1 := ind(time1(:,1).ge.mons.and.time1(:,1).le.mone)
var_u(:,:,nm,:,:) = dim_avg_n_Wrap(u(:,:,select_time1,:,:),2)
var_v(:,:,nm,:,:) = dim_avg_n_Wrap(v(:,:,select_time1,:,:),2)
end do

do nc = 1, ncase-1, 1
    var_u(nc,:,:,:,:) =  var_u(nc,:,:,:,:) - var_u(0,:,:,:,:) 
    var_v(nc,:,:,:,:) =  var_v(nc,:,:,:,:) - var_v(0,:,:,:,:) 
end do
if(div_option) then 
var = -uv2dv_cfd ( var_u, var_v, var_u&lat, var_v&lon, 2)*100000
else
var = sqrt(var_u^2 + var_v^2)
end if
copy_VarMeta(var_u,var)

printVarSummary(var_u)
printVarSummary(var)

;==============================================================
;draw figure in twelve months (one month is a fgure)
;==================================================================
;define the thickness and height of the title,tick and label
   tick_font      = 0.03
   subtitle_font  = 0.03
   title_font     = 0.03
   vcref_font     = 0.02
   tick_thick     = 5.0
   subtitle_thick = 5.0  ;not have this attribute
   title_thick    = 5.0
   mp_thick       = 3.0
   vc_thick       = 3.0
   font_index     = 22

wks = gsn_open_wks(fig_out,fig_name)
    ;gsn_define_colormap(wks,"GMT_polar") 
    ;blue and red, has 20 colors, 2-11 is bule, 12-21 is red
    ;gsn_define_colormap(wks,"matlab_jet") 
    ;has 64 colors blue green yellow,red

    res                  = True
    res@gsnFrame         = False
    res@gsnDraw          = False
;    res@gsnMaximize      = True
    res@gsnAddCyclic     = False
    res@gsnPaperOrientation = "portrait"
    ;res@vpHeightF        = 0.25
    ;res@vpWidthF         = 0.8

;-------set the attribute of the map-------------------
    res@mpCenterLonF     = 180.
    res@mpMaxLatF        = latn(na)
    res@mpMinLatF        = lats(na)
    res@mpMaxLonF        = lonr(na)
    res@mpMinLonF        = lonl(na)
    res@gsnMajorLatSpacing = 15
    res@gsnMinorLatSpacing = 15
    res@gsnMajorLonSpacing = 20
    res@mpFillOn         = False
    ;res@mpLandFillColor = "gray"
    ;res@mpFillDrawOrder = "PreDraw"
    res@mpGeophysicalLineThicknessF = mp_thick
    res@mpGeophysicalLineColor      = "black";"white"

;--------set the form of the coordinate-----------------
    ;res@tmXBLabelsOn         = False              ; do not draw bottom labels
    ;res@tmXBOn               = False              ; no bottom tickmarks
    ;res@tmYLLabelsOn         = False              ; no right labels
    ;res@tmYLOn               = False              ; no right tickmarks
    ;res@tmXTLabelsOn         = False              ; do not draw bottom labels
    ;res@tmXTOn               = False              ; no bottom tickmarks
    ;res@tmYLLabelsOn         = False              ; no right labels
    ;res@tmYLOn               = False              ; no right tickmarks
    
    res@tmBorderThicknessF  = mp_thick
    res@tmXBLabelFont   = font_index
    res@tmYLLabelFont   = font_index
    res@tmXBLabelFontHeightF     = tick_font
    ; res@tmXBLabelFontAspectF   = 1.6
    res@tmXBLabelFontThicknessF  = tick_thick
    res@tmYLLabelFontHeightF     = tick_font
    ; res@tmYLLabelFontAspectF   = 1.3
    res@tmYLLabelFontThicknessF  = tick_thick
    
    res@tmXBMajorThicknessF     = mp_thick
    res@tmYLMajorThicknessF     = mp_thick
    ;  res@tmXBMajorOutwardLengthF = -0.
    ;  res@tmYLMajorOutwardLengthF = -0.
    ;  res@tmYRMajorOutwardLengthF = -0.
      
    res@tmXBMinorThicknessF     = mp_thick
    res@tmYLMinorThicknessF     = mp_thick
    ;  res@tmXBMinorOutwardLengthF = -0.
    ;  res@tmYLMinorOutwardLengthF = -0.
    ;  res@tmYRMinorOutwardLengthF = -0.

    res@gsnCenterString      = ""
    res@gsnLeftString      = ""
    res@gsnRightString      = ""
    res@gsnStringFont         = font_index
    res@gsnStringFontHeightF  = subtitle_font
    
;---------set the attribute of the contour-----------------
    res@cnFillOn         = True
    res@cnLinesOn        = False ;True
    res@cnLineLabelsOn   = False
    res@cnInfoLabelOn    = False
   
    ;res@cnLevelSelectionMode = "AutomaticLevels"   ; set manual contour levels
    ;res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
    ;res@cnLevels             = (/-5,-4.5,-4,-3.5,-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5/)
    ;res@cnLevels             = ispan(0,60,10)
    ;res@cnFillColors         = (/-1,20,47,57,94,127,152/)
    ;res@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
    ;res@cnMinLevelValF        = 1          ; set min contour level
    ;res@cnMaxLevelValF        = 13 ;32        ; set max contour level
    ;res@cnLevelSpacingF       = 1        ; set contour interval

    res@gsnSpreadColors      = False  ;True              ; turn of the full color map
    res@gsnSpreadColorStart  = 11                ; start at color 17
    res@gsnSpreadColorEnd    = 2                ; end at color 200
    
    res@lbLabelBarOn         = True ;False   ; the label bar
    res@lbOrientation        = "Horizontal"
    res@lbLabelFontHeightF   = tick_font              ; make labels smaller
    res@lbLabelFont          = font_index              ; make labels smaller
    res@lbLabelStride        = 1
    res@lbBoxLineThicknessF  = mp_thick-2
    res@pmLabelBarOrthogonalPosF = 0.15
    res@pmLabelBarParallelPosF   = 0.5
    res@pmLabelBarWidthF  = 0.7
    res@pmLabelBarHeightF = 0.08

;----------set the attribute of the vector-------------------
    resvc                  = True
    resvc@gsnDraw          = False
    resvc@gsnFrame         = False
    resvc@vcGlyphStyle               = "LineArrow"  ;"CurlyVector"
    resvc@vcVectorDrawOrder          = "PostDraw"
    resvc@vcLineArrowThicknessF      = vc_thick
    resvc@vcMinDistanceF             = 0.028
    resvc@vcLineArrowHeadMinSizeF    = 0.015
    resvc@vcLineArrowHeadMaxSizeF    = 0.015
    ;resvc@vcRefMagnitudeF            = 30.0             ; define vector ref mag
    resvc@vcRefLengthF               = 0.05           ; define length of vec ref
    resvc@vcRefAnnoOn                = False
    resvc@vcRefAnnoZone              = 0     ;set the positional origin in the center of the plot
    ;resvc@vcRefAnnoSide              = "Bottom"          
    ;resvc@vcRefAnnoJust              = "TopRight"
    resvc@vcRefAnnoOrthogonalPosF    = -0.78           ; move ref vector along Y-axis
    resvc@vcRefAnnoParallelPosF      = 0.25            ; move ref vector along X-axis
    resvc@vcRefAnnoPerimOn           = False         ;close the border
    resvc@vcRefAnnoFont              = font_index
    resvc@vcRefAnnoFontHeightF       = vcref_font
    resvc@vcRefAnnoString1On         = False
    resvc@vcRefAnnoString2On         = True
    ;resvc@vcRefAnnoString2           = "30m/s"

    resvc@gsnCenterString      = ""
    resvc@gsnLeftString    = " "
    resvc@gsnRightString   = " "

;--------set the attribute of polygon--------------
    lnres                      = True
    lnres@gsLineColor          = "black"
    lnres@gsLineDashPattern    = 0
    lnres@gsLineThicknessF     = 4.0
    ;lnres@gsLineLabelString    = "TP"

;--------set the attribute of gtop--------------
    res_gtop                  = True
    res_gtop@gsnDraw          = False
    res_gtop@gsnFrame         = False
    res_gtop@cnFillOn         = False
    res_gtop@cnLinesOn        = True      ; turn off contour lines
    res_gtop@cnLineLabelsOn   = False      ; turn off contour line labels
    res_gtop@cnInfoLabelOn    = False
    res_gtop@cnLineThicknessF = 4.0
    res_gtop@cnLineColor      = "black"
    res_gtop@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
    res_gtop@cnLevels         = (/1500/)
    res_gtop@gsnCenterString      = ""
    res_gtop@gsnLeftString    = " "
    res_gtop@gsnRightString   = " "

;------------------------------------------------------------------
;draw the subgraph and change the left and right titles
;-----------------------------------------------------------------------

    resp  = True    
    resp@gsnMaximize   = True
    resp@gsnPaperOrientation = "landscape"  ;"portrait"
    resp@gsnPanelLabelBar = False 
    resp@pmLabelBarWidthF  = 0.8
    resp@pmLabelBarHeightF = 0.05
    resp@lbLabelFont        = font_index              ; make labels smaller
    resp@lbLabelFontHeightF = 0.015
    resp@lbLabelFontThicknessF = tick_thick
    resp@txFontHeightF = title_font 
    resp@txFontThicknessF = title_thick

    vcref  = (/(/200,200,20/),(/50,50,20/),(/50,50,20/)/)  ;the level of 850hpa    ctrl,nudg,diff

    ;minlvl = (/(/15 ,45 , 0/),(/-80,-16,-16/),(/-80,-16,-16/)/) ;used for East Asian Shaded ration
    ;maxlvl = (/(/615,120,30/),(/ 80, 16, 16/),(/ 80, 16, 16/)/)
    ;spacig = (/(/40 ,5  , 2/),(/ 10, 2 , 2 /),(/ 10, 2 , 2 /)/)
if(div_option) then 
    res@cnFillPalette = "BlueDarkRed18"
    res@cnFillColors  = (/0,1,2,3,4,5,6,7,10,11,12,13,14,15,16,17/) ; If the color indexes are derived from cnFillPalette the first color comes from element 0
    maxlvl = (/(/ 7, 7, 7/),(/ 7, 7, 7/),(/ 7, 7, 7/)/) ;used for East Asian moist transiation
    minlvl = (/(/-7,-7,-7/),(/-7,-7,-7/),(/-7,-7,-7/)/) ;used for CTRL-NUDG
    spacig = (/(/ 1, 1, 1/),(/ 1, 1, 1/),(/ 1, 1, 1/)/)
else
    res@cnFillPalette = "precip3_16lev"
    if(na.eq.1) then
    minlvl = (/(/15 ,15 , 0/),(/ 0, 0, 0/),(/ 0, 0, 0/)/) ;used for East Asian moist transiation
    maxlvl = (/(/615,615,75/),(/45,45,45/),(/45,45,45/)/)
    spacig = (/(/40 ,40 , 5/),(/ 3, 3, 3/),(/ 3, 3, 3/)/)
    else
    minlvl = (/(/30 ,30 , 0/),(/20,20,0 /),(/20,20,0 /)/) ;used for East Asian moist transiation
    maxlvl = (/(/180,180,45/),(/95,95,30/),(/95,95,30/)/)
    spacig = (/(/10 ,10 , 3/),(/ 5, 5,2 /),(/ 5, 5,2 /)/)
    end if
end if

do nv = 0 ,nvar-1,1
do nc = 0, ncase-1,1
do nm = 0, nmonth-1,1
;if(nc.eq.0) then
;    res@cnFillPalette = "precip3_16lev"
;    ;blue and yellow and red, has 17 colors,2-18,2 is white
;else
;    res@cnFillPalette = "BlueDarkRed18"
;    ;blue and red, has 18 colors,2-10 is blue
;end if 
        ;np = nvar*nc + nv
        np = nmonth*nc + nm
        ;if(np.eq.0.or.np.eq.4.or.np.eq.8) then 
        ;    res@tmYLLabelsOn         = True              ; no right labels
        ;    res@tmYLOn               = True              ; no right tickmarks
        ;else
        ;    res@tmYLLabelsOn         = False              ; no right labels
        ;    res@tmYLOn               = False              ; no right tickmarks
        ;end if
        res@gsnLeftString   = pre_case(np) + ")" + case(nc) + " " + months(nm) ;+ " " + draw_var(nv)
        res@gsnRightString  = draw_var(nv)
        res@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
        res@cnLevelSpacingF      := spacig(nc,nv)        ; set contour interval
        res@cnMaxLevelValF       := maxlvl(nc,nv) ;32    ; set max contour level
        res@cnMinLevelValF       := minlvl(nc,nv)       ; set min contour level
        resvc@vcRefMagnitudeF   = vcref(nc,nv)                ; define vector ref mag
        resvc@vcRefAnnoString2  = vcref(nc,nv) + " " + unit
        plot(np)   = gsn_csm_contour_map_ce(wks,var(nc,nv,nm,:,:),res) 
        plotvc(np) = gsn_csm_vector(wks,var_u(nc,nv,nm,:,:),var_v(nc,nv,nm,:,:),resvc)
        gtop(np)   = gsn_csm_contour(wks,phis,res_gtop)
        overlay(plot(np),plotvc(np))
        overlay(plot(np),gtop(np))
        line(np) = gsn_add_polyline( wks, plot(np), lonx, latx, lnres )
        print(max(var_u(nc,nv,nm,{lats(na):latn(na)},{lonl(na):lonr(na)})))
        print(min(var_u(nc,nv,nm,{lats(na):latn(na)},{lonl(na):lonr(na)})))
    end do 
end do 
    ;res1 = True
    ;res2 = True
    ;res1@gsnMaximize = True
    ;attach1 = gsn_attach_plots(plot(0),plot(1:3),res1,res2)
    ;attach2 = gsn_attach_plots(plot(4),plot(5:7),res1,res2)
    ;gsn_panel(wks,plot(0:7:4),(/ncase,1/),resp)
    ;gsn_panel(wks,plot,(/ncase,nvar/),resp)
    gsn_panel(wks,plot,(/ncase,nmonth/),resp)
end do
end 

