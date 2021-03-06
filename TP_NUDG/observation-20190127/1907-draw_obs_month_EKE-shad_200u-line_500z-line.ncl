;*********************************************************************
;Draw the shaded map of monthly average EKE in east asia. 
;overlap the contour map of monthly 500 hgt
;then overlap the monthly axis of 200 westerly jet and 20 m/s isotach of 200hPa uwind
;                                                     by Ql Ren
;                                                    2019/07
;*********************************************************************************
begin
draw_var = (/"EKE"        ,"200uwnd","500hgt"/)  ;this is the variable used to draw, can used as center string
unit     = (/"10~S~4~N~ J","m/s"    ,"m"     /)    ;this can be used as right string 
;var_name = (/"season_ave","season_vari"/) ;this is the var_name in data file
;months   = (/"DJF","MAM","JJA","SON"/)
var_name = (/"month_ave","month_vari"/) ;this is the var_name in data file
months   = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)

;the path of the file
path   = "/home/ys17-19/renql/project/TP_NUDG/observation-20190127"
path1  = "/home/ys17-19/data-observation/ERA-interim/"
filename = path + "/mdata/ERA-Interim_Clim_month_ave_" + draw_var 
gtopfile = path1 + "gtopo_1.5x1.5.nc"
;fig_name = path + "/fig/ERA-Interim_" + draw_var(0) + "-line_" + draw_var(1) + "-shad_" + var_name(0)
fig_name = path + "/fig/ERA-Interim_" + draw_var(1) + "-line_" + draw_var(0) + "-shad_" + var_name(0)
fig_title  = "Climate " + draw_var(0) + " (" + unit(0) + ") and " + draw_var(1)
pre_case   = (/"(a","(b","(c","(d","(e","(f","(g","(h","(i","(j","(k","(l"/)
fig_out    ="pdf";"x11"

;area: east Asia
lats = -15 ;20 ;-20
latn = 55  ;55 ;60
lonl = 30  ;30 ;20
lonr = 150 ;150;220

f = addfile(gtopfile,"r")
phis   = short2flt(f->z(0,{lats:latn},{lonl:lonr}))
phis   = phis/9.8   ;convert unit from m2/s2 to gpm
nmonth = dimsizes(months)
nlat   = dimsizes(phis&latitude)
nlon   = dimsizes(phis&longitude)
nvar   = dimsizes(draw_var)
var  = new((/nvar,nmonth,nlat,nlon/),float)

;the number of the panel plot
    plot     = new((/nmonth/),graphic)
    line1    = new((/nmonth/),graphic)
    line2    = new((/nmonth/),graphic)
    gtop     = new((/nmonth/),graphic)
    axis     = new((/nmonth/),graphic)

;define the thickness and height of the title,tick and label
   tick_font      = 0.03
   subtitle_font  = 0.03
   title_font     = 0.03
   tick_thick     = 8.0
   subtitle_thick = 8.0  ;not have this attribute
   title_thick    = 5.0
   mp_thick       = 1.5
   font_index     = 22

;================================================================
;read data
;====================================================================
do nv = 0,nvar-1,1
f = addfile(filename(nv)+".nc","r")
var(nv,:,:,:) = f->$var_name(0)$(:,{lats:latn},{lonl:lonr}) ;get an array (ncase,nmonth,nlat,nlon)

if(nv.eq.0) then 
    var(nv,:,:,:) = var(nv,:,:,:)/10000
end if
if(nv.eq.2) then 
    var(nv,:,:,:) = var(nv,:,:,:)/9.8
end if

end do 
printVarSummary(var)

alon = var&lon
alat = new((/nmonth,nlon/),float)
lat1 = var&lat
do nm = 0, nmonth-1,1
do inln = 0, nlon-1,1
   alat(nm,inln) = maxind(var(1,nm,:,inln))
end do
end do

;==============================================================
;draw figure in twelve months (one month is a fgure)
;==================================================================
    wks = gsn_open_wks(fig_out,fig_name)
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
    res@gsnMajorLatSpacing = 10
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
    res@cnLinesOn        = False
    res@cnLineLabelsOn   = False
    res@cnInfoLabelOn    = False
;    res@cnLineThicknessF = 1.0

    res@cnFillPalette = "precip3_16lev"
    ;blue and yellow and red, has 17 colors,2-18,2 is white
    ;res@cnFillPalette = "GMT_gray" ;has 10 colors 
    res@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
    res@cnMinLevelValF        = 2    ; set min contour level
    res@cnMaxLevelValF        = 50   ; set max contour level
    res@cnLevelSpacingF       = 3  ; set contour interval
    
    res@gsnSpreadColors      = False              ; turn of the full color map
    res@gsnSpreadColorStart  = 9    ;This resource only takes effect if gsnSpreadColors is set to True 
    res@gsnSpreadColorEnd    = 0                ; end at color 200
    
    res@lbLabelBarOn         = True   ; the label bar
    res@lbOrientation        = "Horizontal"
    res@lbLabelFontHeightF   = tick_font              ; make labels smaller
    res@lbLabelFont          = font_index              ; make labels smaller
    res@lbLabelStride        = 1
    res@lbBoxLineThicknessF  = mp_thick-1

    res@pmLabelBarZone               = 0
    res@pmLabelBarOrthogonalPosF     = 0.15
    res@pmLabelBarParallelPosF       = 0.5

;----------Set res line-----------
    res_line                  = True
    res_line@gsnDraw          = False
    res_line@gsnFrame         = False
    res_line@gsnAddCyclic     = False
    res_line@cnFillOn         = False       ; Fill contours
    res_line@cnLinesOn        = True      ; turn off contour lines
    res_line@cnLineLabelsOn   = False      ; turn off contour line labels
    res_line@cnInfoLabelOn    = False
    res_line@cnLineThicknessF = 2.5
    res_line@cnMonoLineColor  = True ;False
    res_line@cnLineColor      = "black"
    res_line@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
    res_line@cnLevels         = (/20/)
    res_line@lbLabelBarOn     = False   ; the label bar
    res_line@gsnCenterString  = ""
    res_line@gsnLeftString    = " "
    res_line@gsnRightString   = " "

;--------set the attribute of gtop--------------
    res_gtop                  = True
    res_gtop@gsnDraw          = False
    res_gtop@gsnFrame         = False
    res_gtop@cnFillOn         = False
    res_gtop@cnLinesOn        = True      ; turn off contour lines
    res_gtop@cnLineLabelsOn   = False      ; turn off contour line labels
    res_gtop@cnInfoLabelOn    = False
    res_gtop@cnLineThicknessF = mp_thick
    res_gtop@cnLineColor      = "black"
    res_gtop@cnLevelSelectionMode  = "ExplicitLevels" ; set manual contour levels
    res_gtop@cnLevels         = (/1500/)
    res_gtop@gsnCenterString      = ""
    res_gtop@gsnLeftString    = " "
    res_gtop@gsnRightString   = " "

;--------set the attribute of polygon to draw axis--------------
    lnres                      = True
    lnres@gsLineColor          = "black"
    lnres@gsLineDashPattern    = 1
    lnres@gsLineThicknessF     = 3.5

;----------Set res line for hgt-----------
    res_hgt                  = True
    res_hgt@gsnDraw          = False
    res_hgt@gsnFrame         = False
    res_hgt@gsnAddCyclic     = False
    res_hgt@cnFillOn         = False       ; Fill contours
    res_hgt@cnLinesOn        = True      ; turn off contour lines
    res_hgt@cnLineLabelsOn   = False      ; turn off contour line labels
    res_hgt@cnInfoLabelOn    = False
    res_hgt@cnLineThicknessF = 2
    res_hgt@cnMonoLineColor  = True ;False
    res_hgt@cnLineColor      = "dimgray"
    res_hgt@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
    res_hgt@cnMinLevelValF        = 5500  ;4          ; set min contour level
    res_hgt@cnMaxLevelValF        = 5860 ;60 ;32        ; set max contour level
    res_hgt@cnLevelSpacingF       = 30 ;        ; set contour interval
    res_hgt@gsnCenterString      = ""
    res_hgt@gsnLeftString    = " "
    res_hgt@gsnRightString   = " "

;------------------------------------------------------------------
;draw the subgraph and change the left and right titles
;-----------------------------------------------------------------------
    res@gsnCenterString      = ""
    res@gsnStringFont        = font_index
    res@gsnStringFontHeightF = subtitle_font

    resp  = True    
    resp@gsnMaximize   = True
    resp@gsnPaperOrientation = "portrait"
    ;resp@gsnPanelLabelBar = True
    ;resp@pmLabelBarWidthF  = 0.5
    ;resp@pmLabelBarHeightF = 0.05
    ;resp@lbLabelFontHeightF = tick_font
    ;resp@lbLabelFontThicknessF = tick_thick
    resp@txFontHeightF = title_font 
    resp@txFontThicknessF = title_thick

do nm = 0,nmonth-1,1
    res@gsnLeftString   = "Obs"
    res@gsnRightString  = months(nm) + " " + draw_var(0) + " (" + unit(0) + ")"
    plot(nm) = gsn_csm_contour_map_ce(wks,var(0,nm,:,:),res)
    gtop(nm) = gsn_csm_contour(wks,phis,res_gtop)
    line1(nm) = gsn_csm_contour(wks,var(1,nm,:,:),res_line)
    line2(nm) = gsn_csm_contour(wks,var(2,nm,:,:),res_hgt)
    overlay(plot(nm),gtop(nm))
    overlay(plot(nm),line2(nm))
    overlay(plot(nm),line1(nm))
    axis(nm) = gsn_add_polyline( wks, plot(nm), alon, alat(nm,:), lnres )
    print(max(var(0,nm,{lats:latn},{lonl:lonr})))
    print(min(var(0,nm,{lats:latn},{lonl:lonr})))
    print(max(var(2,nm,{lats:latn},{lonl:lonr})))
    print(min(var(2,nm,{lats:latn},{lonl:lonr})))
end do 

;    resp@txString      = fig_title
    gsn_panel(wks,plot,(/1,4/),resp)
end

