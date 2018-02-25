;*********************************************************************
;filename:      draw_12p3X1_year_vari.ncl
;input_data:    Month_ave_year_varience-6h.nc 
;Draw the contour map of monthly variance of 27 years 
;And there are three cases,1AMIP-CTRL,2TP-NUDG,3 is the difference between the above two
;the third case will do the significance testing, the dot mean the difference is significance
;The data(3variables,3cases,12month,3levs) are all save in one file
;                                                     by Ql Ren
;                                                    2018/01/08
;*********************************************************************************
begin
;the path of the file
path    = "/users/yangsong3/renql/project/TP_NUDG"
filename = path + "/nudgtest/mdata/" + (/"CTRL","NUDG24h","NUDG6h"/) + "Month_ave_year_variance.nc"
fig_name   = path + "/nudgtest/fig/12p3X1_year_vari"
fig_title  = "Variance of 27 years in "
    case   = (/"AMIP_CTRL","(CTRL-NUDG24h)/CTRL%","(CTRL-NUDG6h)/CTRL%"/)
    ;case   = (/"AMIP_CTRL","CTRL-NUDG24h","CTRL-NUDG6h"/)
fig_out    ="pdf";"x11"
unit       = ""
ncase = 3 
draw_var = (/"U","V","T"/)  ;this is the variable used to draw, can used as center string
var_name = (/"vari"/) ;this is the var_name in data file
months   = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)

;area: east Asia
lats = -20
latn = 60
lonl = 20
lonr = 220
lev  = (/850,500,200/)  ;can used as right string
siglvl = 0.05
;nv = 0 
;nl = 2

;set the area of the box
maxlon = 105
minlon = 70
maxlat = 40
minlat = 25
lonx = (/ minlon, maxlon, maxlon, minlon, minlon /)
latx = (/ minlat, minlat, maxlat, maxlat, minlat /)

;define the thickness and height of the title,tick and label
   tick_font      = 0.02
   subtitle_font  = 0.02
   title_font     = 0.03
   tick_thick     = 5.0
   subtitle_thick = 5.0  ;not have this attribute
   title_thick    = 5.0
   mp_thick       = 5.0

;the number of the panel plot
    plot     = new((/3/),graphic)
    plot2    = new((/2/),graphic)
    line     = new((/3/),graphic)

f = addfile(filename(0),"r")
nmonth = dimsizes(months)
nlat   = getfilevardimsizes(f,"lat")
nlon   = getfilevardimsizes(f,"lon")
var  = new((/ncase,nmonth,nlat,nlon/),float)
prob = new((/ncase-1,nmonth,nlat,nlon/),float)

do nv = 0,2,1
do nl = 0,2,1
;================================================================
;read data
;====================================================================
do nf = 0 ,ncase-1, 1
    f = addfile(filename(nf),"r")
    var(nf,:,:,:)  = f->$var_name$(nv,:,nl,:,:) ;get an array (ncase,nmonth,nlat,nlon)
end do

var_temp = where(var(0,:,:,:).eq.0,var@_FillValue,var(0,:,:,:))
do nf = 0 ,ncase-2,1
prob(nf,:,:,:) = ftest(var(0,:,:,:),27,var(nf+1,:,:,:),27,0)
var(nf+1,:,:,:)= (var(0,:,:,:) - var(nf+1,:,:,:))/var_temp*100 ;get the difference between CTRL and NUDG
end do
prob = mask(prob,prob.lt.siglvl,True)
copy_VarMeta(var(0,0,:,:),prob(0,0,:,:))
printVarSummary(var)
printVarSummary(prob)

;==============================================================
;draw figure in twelve months (one month is a fgure)
;==================================================================
    wks = gsn_open_wks(fig_out,fig_name+lev(nl)+draw_var(nv))
    ;gsn_define_colormap(wks,"GMT_polar") 
    ;blue and red, has 20 colors, 2-11 is bule, 12-21 is red
    gsn_define_colormap(wks,"matlab_jet") 
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
    res@tmXBLabelFontHeightF     = tick_font
    ; res@tmXBLabelFontAspectF   = 1.6
    res@tmXBLabelFontThicknessF  = tick_thick
    res@tmYLLabelFontHeightF     = tick_font
    ; res@tmYLLabelFontAspectF   = 1.3
    res@tmYLLabelFontThicknessF  = tick_thick
    
    ;  res@tmXBMajorOutwardLengthF = -0.
    ;  res@tmYLMajorOutwardLengthF = -0.
    ;  res@tmYRMajorOutwardLengthF = -0.
      
    ;  res@tmXBMinorOutwardLengthF = -0.
    ;  res@tmYLMinorOutwardLengthF = -0.
    ;  res@tmYRMinorOutwardLengthF = -0.
;res_lin = res
res_sig = res
;---------set the attribute of the contour-----------------
    res@cnFillOn         = True
    res@cnLinesOn        = False
    res@cnLineLabelsOn   = False  ; True
   
    ;res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
    ;res@cnLevels             = (/-5,-4.5,-4,-3.5,-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5/)
    ;res@cnLevels             = ispan(0,60,10)
    ;res@cnFillColors         = (/-1,20,47,57,94,127,152/)
    ;res@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
    ;res@cnMinLevelValF        = 1          ; set min contour level
    ;res@cnMaxLevelValF        = 13 ;32        ; set max contour level
    ;res@cnLevelSpacingF       = 1        ; set contour interval

    res@gsnSpreadColors      = True              ; turn of the full color map
    res@gsnSpreadColorStart  = 2                ; start at color 17
    res@gsnSpreadColorEnd    = 65                ; end at color 200
    
    res@lbLabelBarOn         = False   ; the label bar
    res@lbOrientation        = "vertical"
    res@lbLabelFontHeightF   = tick_font              ; make labels smaller
    res@lbLabelStride        = 1

;----------set the attribute of the contour line map-----------
    res_lin                  = True
    res_lin@gsnDraw          = False
    res_lin@gsnFrame         = False
    res_lin@cnFillOn         = False
    res_lin@cnLinesOn        = True
    res_lin@cnLineLabelsOn   = True
    res_lin@cnInfoLabelOn    = False
    
    res_lin@cnLineThicknessF = 2
    res_lin@gsnContourZeroLineThicknessF = 4.0
    res_lin@gsnContourNegLineDashPattern = 5
    res_lin@gsnContourPosLineDashPattern = 0
    res_lin@cnLineColor      = "black"

    ;res_lin@cnMonoLevelFlag     = False
    ;res_lin@cnLineLabelInterval = 2
    res_lin@cnLineLabelPlacementMode = "Computed"
    res_lin@cnLineLabelDensityF  = 1

    res_lin@gsnCenterString      = ""
    res_lin@gsnRightStringFontHeightF = subtitle_font
    res_lin@gsnLeftStringFontHeightF  = subtitle_font
    res_lin@gsnLeftString    = " "
    res_lin@gsnRightString   = " "
    
    ;res_lin@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
    ;res_lin@cnMinLevelValF        = 1          ; set min contour level
    ;res_lin@cnMaxLevelValF        = 13 ;32        ; set max contour level
    ;res_lin@cnLevelSpacingF       = 20        ; set contour interval

;----------Set res sig-----------
    ;res_sig                  = True
    ;res_sig@gsnDraw          = False
    ;res_sig@gsnFrame         = False
    res_sig@cnFillOn         = True       ; Fill contours
    res_sig@cnLinesOn        = False;True      ; turn off contour lines
    res_sig@cnLineLabelsOn   = False      ; turn off contour line labels
    ;res_sig@cnLineThicknessF = 2
    ;res_sig@cnLineColor     = "black"
    res_sig@cnInfoLabelOn    = False
    ;res_sig@cnMonoFillPattern= True;False
    ;res_sig@cnFillPattern    = 11
    ;res_sig@cnMonoFillScale  = True
    ;res_sig@cnFillScaleF     = 1.
    ;res_sig@cnMonoFillColor  = True
    ;res_sig@cnFillColor      = "darkslategray"
    ;res_sig@cnFillDotSizeF   = 0.1
    res_sig@lbLabelBarOn     = False;True   ; turn off the label bar
    res_sig@cnLevelSelectionMode ="ExplicitLevels"
    res_sig@cnLevels             = (/0.01/)
    ;res_sig@cnFillPattern        = "GMT_gray"
    res_sig@cnFillColors         = (/"grey30","grey50"/) ;
    
    res_sig@gsnCenterString      = ""
    res_sig@gsnRightStringFontHeightF = subtitle_font
    res_sig@gsnLeftStringFontHeightF  = subtitle_font
    res_sig@gsnLeftString    = " "
    res_sig@gsnRightString   = " "

;--------set the attribute of polygon--------------
    lnres                      = True
    lnres@gsLineColor          = "black"
    lnres@gsLineDashPattern    = 0
    lnres@gsLineThicknessF     = 4.0
    ;lnres@gsLineLabelString    = "TP"

;------------------------------------------------------------------
;draw the subgraph and change the left and right titles
;-----------------------------------------------------------------------
   ; res@tiMainString         = fig_title + "in" + months(m)
    ;res@tiMainFontHeightF    = 0.04
   ; res@tiMainFontColor      = "black"
    res@gsnCenterString      = ""
    res@gsnRightStringFontHeightF = subtitle_font
    res@gsnLeftStringFontHeightF  = subtitle_font

    resp  = True    
    resp@gsnMaximize   = True
    resp@gsnPaperOrientation = "portrait"
    resp@gsnPanelLabelBar = True
    resp@pmLabelBarWidthF  = 0.5
    resp@pmLabelBarHeightF = 0.05
    resp@lbLabelFontHeightF = tick_font
    resp@lbLabelFontThicknessF = tick_thick
    resp@txFontHeightF = title_font 
    resp@txFontThicknessF = title_thick

do nm = 0,11,1
    do nc = 0, ncase-1,1
        if(nc.gt.0) then
            res_sig@gsnLeftString   = case(nc)
            res_sig@gsnRightString  = "siglvl: " + siglvl
            plot(nc)     = gsn_csm_contour_map_ce(wks,prob(nc-1,nm,:,:),res_sig)
            plot2(nc-1)  = gsn_csm_contour(wks,var(nc,nm,:,:),res_lin)
            plot2(nc-1)  = ColorNegDashZeroPosContour(plot2(nc-1),"blue","red","red")
            overlay(plot(nc),plot2(nc-1))
        else
            res@gsnLeftString    = case(nc)
            res@gsnRightString   = draw_var(nv) + lev(nl) + "hPa" 
            plot(nc)     = gsn_csm_contour_map_ce(wks,var(nc,nm,:,:),res)
        end if
        line(nc) = gsn_add_polyline( wks, plot(nc), lonx, latx, lnres )
        print(max(var(nc,nm,{lats:latn},{lonl:lonr})))
        print(min(var(nc,nm,{lats:latn},{lonl:lonr})))
    end do 

    resp@txString      = fig_title + months(nm) 
    gsn_panel(wks,plot,(/3,1/),resp)
end do ;for the month 
end do ;for level
end do ;for varables
end
