;*********************************************************************
;filename:      draw_1p2x2_preci_qdivg_sh_lh_ave_map-2c.ncl
;input_data:    CTRL-Clim_month_ave_*.nc 
;
;1 read JJA data from four files season_ave(2,:,:) and season_vari(2,:,:)
;2 do the significance test
;3 define the levels then draw the plot 
;                                                     by Ql Ren
;                                                    2018/03/28
;*********************************************************************************
begin
draw_var = (/"preci","TMQ","SHFLX","LHFLX"/)  ;this is the variable used to draw, can used as center string
unit     = (/"mm/day","kg/m~S~2~N~","W/m~S~2~N~","W/m~S~2~N~"/)    ;this can be used as right string 
var_name = (/"season_ave","season_vari"/) ;this is the var_name in data file
;var_name = (/"month_ave","month_vari"/) ;this is the var_name in data file
;months   = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
months   = (/"DJF","MAM","JJA","SON"/)
nm = 2

;the path of the file
path     = "/users/yangsong3/renql/project/TP_NUDG"
;path     = "/home/ys17-19/renql/project/TP_NUDG"
filename = path + "/analysis/mdata/" + (/"CTRL","NUDG6h"/) + "-Clim_month_ave_" ;+ draw_var(nv) + ".nc"
gtopfile = path + "/analysis/mdata/" + "gtopo30_0.9x1.25.nc"
fig_name = path + "/phy_panel-20180328/fig/1p2x2_preci_TMQ_sh_lh_ave_shad" + months(nm) + var_name(0) 
case     = (/"CTRL","NG6h"/)
pre_case   = (/"(a)","(b)","(c)","(d)"/)
fig_out    = "pdf";"x11"

;area: east Asia
lats = -15 ;-20
latn = 55  ;60
lonl = 30  ;20
lonr = 150 ;220
siglvl = 0.05

f = addfile(gtopfile,"r")
phis   = f->PHIS({lats:latn},{lonl:lonr})
phis   = phis/9.8   ;convert unit from m2/s2 to gpm
ncase  = dimsizes(case)
nmonth = dimsizes(months)
nvar   = dimsizes(draw_var)
nlat   = dimsizes(phis&lat)
nlon   = dimsizes(phis&lon)
var  = new((/ncase  ,nvar,nlat,nlon/),float)
vari = new((/ncase  ,nvar,nlat,nlon/),float)
prob = new((/        nvar,nlat,nlon/),float)

;the number of the panel plot
    plot     = new((/nvar/),graphic)
    line     = new((/nvar/),graphic)
    gtop     = new((/nvar/),graphic)
    plot2    = new((/nvar/),graphic)
    plot3    = new((/nvar/),graphic)

;set the area of the box
maxlon = 105
minlon = 70
maxlat = 40
minlat = 25
lonx = (/ minlon, maxlon, maxlon, minlon, minlon /)
latx = (/ minlat, minlat, maxlat, maxlat, minlat /)

;define the thickness and height of the title,tick and label
   tick_font      = 0.03
   subtitle_font  = 0.03
   title_font     = 0.03
   tick_thick     = 8.0
   subtitle_thick = 8.0  ;not have this attribute
   title_thick    = 5.0
   mp_thick       = 4.0
   font_index     = 22

;================================================================
;read data
;====================================================================
do nf = 0 ,ncase-1, 1
do nv = 0 ,nvar-1,1
    f = addfile(filename(nf)+draw_var(nv)+".nc","r")
    var(nf,nv,:,:)  = f->$var_name(0)$(nm,:,:) ;get an array (ncase,nmonth,nlat,nlon)
    vari(nf,nv,:,:)  = f->$var_name(1)$(nm,:,:) ;get an array (ncase,nmonth,nlat,nlon)
end do
end do

nf = 0 
prob = ttest(var(0,:,:,:),vari(0,:,:,:),27,var(nf+1,:,:,:),vari(nf+1,:,:,:),27,True,False)
var(nf+1,:,:,:)= var(nf+1,:,:,:) - var(0,:,:,:) ;get the difference between CTRL and NUDG

var(1,:,:,:) = mask(var(1,:,:,:),prob.lt.siglvl,True)
var_p = var(1,:,:,:)
var_n = var(1,:,:,:)
var_p = mask(var(1,:,:,:),var(1,:,:,:).le.0,False)
var_n = mask(var(1,:,:,:),var(1,:,:,:).lt.0,True)
printVarSummary(var)
printVarSummary(prob)

;==============================================================
;draw figure in twelve months (one month is a fgure)
;==================================================================
    wks = gsn_open_wks(fig_out,fig_name)
    gsn_define_colormap(wks,"precip3_16lev") 
    ;blue and yellow and red, has 17 colors,2-18,2 is white
    ;gsn_define_colormap(wks,"BlueDarkRed18")
    ;blue and red, has 18 colors,2-10 is blue
    ;gsn_define_colormap(wks,"GMT_polar") 
    ;blue and red, has 20 colors, 2-11 is bule, 12-21 is red
    ;gsn_define_colormap(wks,"matlab_jet") 
    ;has 64 colors blue green yellow,red

    res                  = True
    res@gsnFrame         = False
    res@gsnDraw          = False
    res@gsnMaximize      = True
    res@gsnAddCyclic     = False
    res@gsnPaperOrientation = "portrait"
    ;res@vpHeightF        = 0.25
    ;res@vpWidthF         = 0.8

;-------set the attribute of the map-------------------
    res@mpCenterLonF     = 180.
    res@mpMaxLatF        = latn
    res@mpMinLatF        = lats
    res@mpMaxLonF        = lonr
    res@mpMinLonF        = lonl
    res@gsnMajorLatSpacing = 15
    res@gsnMinorLatSpacing = 15
    res@gsnMajorLonSpacing = 30
    res@mpFillOn         = False
    ;res@mpLandFillColor = "gray"
    ;res@mpFillDrawOrder = "PreDraw"
    res@mpGeophysicalLineThicknessF = mp_thick
    res@mpGeophysicalLineColor      = "black";"white"

;--------set the form of the coordinate-----------------
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

;---------set the attribute of the contour-----------------
    res@cnFillOn         = True
    res@cnLinesOn        = False ;True
    res@cnLineLabelsOn   = False
    res@cnInfoLabelOn    = False
    ;res@cnLineThicknessF = 0
    ;res@gsnContourZeroLineThicknessF = 4.0
    ;res@cnLineColor      = "blue"
   
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
    
    res@lbLabelBarOn         = True   ; the label bar
    res@lbOrientation        = "Horizontal"
    res@lbLabelFontHeightF   = tick_font              ; make labels smaller
    res@lbLabelFont          = font_index              ; make labels smaller
    res@lbLabelStride        = 1
    res@lbBoxLineThicknessF  = mp_thick-1

    res@pmLabelBarZone               = 0
    res@pmLabelBarOrthogonalPosF     = 0.15
    res@pmLabelBarParallelPosF       = 0.5

;----------Set res sig-----------
    res_sig                  = True
    res_sig@gsnDraw          = False
    res_sig@gsnFrame         = False
    res_sig@cnFillOn         = False;True       ; Fill contours
    res_sig@cnLinesOn        = True      ; turn off contour lines
    res_sig@cnLineLabelsOn   = True;False      ; turn off contour line labels
    res_sig@cnInfoLabelOn    = False
    res_sig@cnLineThicknessF = mp_thick 
    res_sig@cnLineColor      = "black"
    res_sig@cnLineDashPattern= 0
    res_sig@cnLevelSelectionMode  = "Manuallevels"
    res_sig@cnMinLevelValF        = 0          ; set min contour level
    res_sig@cnMaxLevelValF        = 500 ;32        ; set max contour level
    res_sig@cnLevelSpacingF       = 10        ; set contour interval

    ;res_sig@cnMonoFillPattern= True;False
    ;res_sig@cnFillPattern    = 11
    ;res_sig@cnMonoFillScale  = True
    ;res_sig@cnFillScaleF     = 0.7
    ;res_sig@cnMonoFillColor  = True
    ;res_sig@cnFillColor      = "darkslategray"
    ;res_sig@lbLabelBarOn     = False;True   ; turn off the label bar
    
    res_sig@gsnCenterString      = ""
    res_sig@gsnLeftString    = " "
    res_sig@gsnRightString   = " "

    res_sign    = res_sig
    res_sign@cnLineDashPattern = 2

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
   ; res@tiMainString         = fig_title + "in" + months(m)
    ;res@tiMainFontHeightF    = 0.04
   ; res@tiMainFontColor      = "black"
    res@gsnCenterString      = ""
    res@gsnStringFont         = font_index
    res@gsnStringFontHeightF  = subtitle_font

    resp  = True    
    resp@gsnMaximize   = True
    resp@gsnPaperOrientation = "landscape"
    ;resp@gsnPanelLabelBar = True
    ;resp@pmLabelBarWidthF  = 0.5
    ;resp@pmLabelBarHeightF = 0.05
    ;resp@lbLabelFontHeightF = tick_font
    ;resp@lbLabelFontThicknessF = tick_thick
    ;resp@txFontHeightF = title_font 
    ;resp@txFontThicknessF = title_thick

    minlvl = (/(/ 1 ,5 ,0 ,  0 /),(/-4.0,-4.0, -24, -24/)/)
    maxlvl = (/(/ 16,50,75, 225/),(/ 4.0, 4.0,  24,  24/)/)
    spacig = (/(/ 1 ,3 , 5,  15/),(/ 0.5, 0.5,  3 ,  3 /)/)

do nv = 0, nvar-1,1
    nc = 0
    res@gsnLeftString   = pre_case(nv) + draw_var(nv)
    res@gsnRightString  = "(" + unit(nv) + ")"  
    res@cnLevelSelectionMode  = "manuallevels" ; set manual contour levels
    res@cnLevelSpacingF       := spacig(nc,nv)        ; set contour interval
    res@cnMaxLevelValF        := maxlvl(nc,nv) ;32    ; set max contour level
    res@cnMinLevelValF        := minlvl(nc,nv)       ; set min contour level
    plot(nv)   = gsn_csm_contour_map_ce(wks,var(nc,nv,:,:),res)
    res_sig@cnLevelSpacingF := spacig(1,nv)
    res_sign@cnLevelSpacingF := spacig(1,nv)
    plot2(nv)  = gsn_csm_contour(wks,var_p(nv,:,:),res_sig)
    plot3(nv)  = gsn_csm_contour(wks,var_n(nv,:,:),res_sign)
    overlay(plot(nv),plot2(nv))
    overlay(plot(nv),plot3(nv))
    gtop(nv) = gsn_csm_contour(wks,phis,res_gtop)
    overlay(plot(nv),gtop(nv))
    line(nv) = gsn_add_polyline( wks, plot(nv), lonx, latx, lnres )
    print(max(var(nc,nv,{lats:latn},{lonl:lonr})))
    print(min(var(nc,nv,{lats:latn},{lonl:lonr})))
end do 
gsn_panel(wks,plot,(/2,2/),resp)
end

