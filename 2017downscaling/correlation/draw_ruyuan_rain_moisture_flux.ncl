;*********************************************************************
;filename:      draw_1p2X2_ruyuan_rain_corr.ncl_
;input_data:    Corr_rain_and_omega.nc
;Draw the distribution of the correlation between Ruyuan daily rainfall and omega
;the sample number of the 1970-2016 winter time series is 8519.
;one panel have four plots which show the conditions in different levels.
;                                            by Ql_Ren
;                                           2018/02/22
;*********************************************************************************
begin
;path       = "/users/yangsong3/renql/project/TP_NUDG"
path       = "/home/ys17-19/renql/project/2017downscaling" 
filename   = path + "/correlation/mdata/" + "corr_summer_rain_and_vertical-shum-cfd.nc"
fig_name   = path + "/correlation/fig/" + "1p_ruyuan_rain_corr_with_divg_flux-cfd-summer";-delay" 
;fig_name   = path + "/correlation/fig/" + "1p_ruyuan_rain_corr_with_flux-summer-delay" 
;fig_title  = "Delay Correlation with Moisture Flux Divg in Summer"
;fig_title  = "Delay Correlation with Moisture Flux in Summer"
fig_title  = "Correlation with Moisture Flux Divg in Summer"
;fig_title  = "Correlation with Moisture Flux in Summer"
fig_out    = "pdf";"x11"
lefttitle  = "moisture flux divg"
;lefttitle  = "moisture flux"
unit       = "g/(s*m*m)"
;unit       = "g/(m*m)"
;var_name   = (/"corr_flux","prob_flux"/)
;var_name   = (/"corr_flux1day","prob_flux1day"/)
var_name   = (/"corr_divg_flux","prob_divg_flux"/)
;var_name   = (/"corr_divg_flux1day","prob_divg_flux1day"/)
nsample    = 8519

;plot area 
lats = 5
latn = 60
lonl = 70
lonr = 150
siglvl  = 0.05
siglvl2 = 0.01

mlat = 25
mlon = 113

;define the dimension of the data
nlev  = 1
plot  = new((/nlev/),graphic)
plot2 = new((/nlev/),graphic)
plot3 = new((/nlev/),graphic)
mark  = new((/nlev/),graphic)

;define the thickness and height of the title,tick and label
   tick_font      = 0.02
   subtitle_font  = 0.02
   title_font     = 0.03
   tick_thick     = 5.0
   subtitle_thick = 5.0  ;not have this attribute
   title_thick    = 5.0
   mp_thick       = 5.0

;================================================================
;read data
;====================================================================
f     = addfile(filename,"r")
corr  = f->$var_name(0)$({lats:latn},{lonl:lonr})
var   = corr*100
copy_VarMeta(corr,var)
prob  = f->$var_name(1)$({lats:latn},{lonl:lonr})
prob1  = mask(prob,prob.lt.siglvl,True)
prob2  = mask(prob,prob.lt.siglvl2,True)
copy_VarMeta(prob,prob1)
copy_VarMeta(prob,prob2)
printVarSummary(var)
printVarSummary(prob)

;==============================================================
;draw figure in twelve months (one month is a fgure)
;==================================================================
    wks = gsn_open_wks(fig_out,fig_name)
    gsn_define_colormap(wks,"GMT_polar") 
    ;blue and red, has 20 colors, 2-11 is bule, 12-21 is red
    
    res                  = True
    res@gsnFrame         = False
    res@gsnDraw          = False
    res@gsnMaximize      = True
    res@gsnAddCyclic     = False
    res@gsnPaperOrientation = "landscape"

;--------------------------------------------------------
;set the attribute of the map
;-------------------------------------------------------------
    res@mpCenterLonF     = 180.
    res@mpMaxLatF        = latn
    res@mpMinLatF        = lats
    res@mpMaxLonF        = lonr
    res@mpMinLonF        = lonl
    res@gsnMajorLatSpacing = 10
    res@gsnMajorLonSpacing = 20
    res@mpFillOn         = False
    ;res@mpLandFillColor = "gray"
    ;res@mpFillDrawOrder = "PreDraw"
    res@mpGeophysicalLineThicknessF = mp_thick
    res@mpGeophysicalLineColor      = "black";"white"

;----------------------------------------------------------------------
;set the form of the coordinate

;----------------------------------------------------------------------
;set the form of the coordinate
;------------------------------------------------------------------------
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

;--------------------------------------------------------------------------
;set the attribute of the contour
;--------------------------------------------------------------------------
    res@cnFillOn         = True
    res@cnLinesOn        = False
    res@cnLineLabelsOn   = False  ; True
   
    ;res@cnLevelSelectionMode = "ExplicitLevels"   ; set manual contour levels
    ;res@cnLevels             = (/-5,-4.5,-4,-3.5,-3,-2.5,-2,-1.5,-1,-0.5,0,0.5,1,1.5,2,2.5,3,3.5,4,4.5,5/)
    ;res@cnLevels             = ispan(0,60,10)
    ;res@cnFillColors         = (/-1,20,47,57,94,127,152/)
    res@cnLevelSelectionMode  = "ManualLevels" ; set manual contour levels
    res@cnMinLevelValF        = -45          ; set min contour level
    res@cnMaxLevelValF        = 45        ; set max contour level
    res@cnLevelSpacingF       = 5       ; set contour interval

    res@gsnSpreadColors      = False              ; turn of the full color map
    res@gsnSpreadColorStart  = 11                ; start at color 17
    res@gsnSpreadColorEnd    = 2                ; end at color 200

    res@lbLabelBarOn         = True   ; the label bar
    res@lbOrientation        = "vertical"
    res@lbLabelFontHeightF   = tick_font              ; make labels smaller
    res@lbLabelStride        = 1

;----------Set res sig-----------
    res_sig                  = True
    res_sig@gsnDraw          = False
    res_sig@gsnFrame         = False
    res_sig@cnFillOn         = True       ; Fill contours
    res_sig@cnLinesOn        = False;True      ; turn off contour lines
    res_sig@cnLineLabelsOn   = False      ; turn off contour line labels
    res_sig@cnInfoLabelOn    = False
    ;res_sig@cnLineThicknessF = 2
    ;res_sig@cnLineColor     = "black"
    res_sig@cnMonoFillPattern= True;False
    res_sig@cnFillPattern    = 11
    res_sig@cnMonoFillScale  = True
    res_sig@cnFillScaleF     = 1.
    res_sig@cnMonoFillColor  = True
    res_sig@cnFillColor      = "darkslategray"
    res_sig@cnFillDotSizeF   = 0.1
    res_sig@lbLabelBarOn     = False;True   ; turn off the label bar
    ;res_sig@cnLevelSelectionMode ="ExplicitLevels"
    ;res_sig@cnLevels             = (/0.01/)
    ;res_sig@cnFillPattern        = "GMT_gray"
    ;res_sig@cnFillColors         = (/"grey30","grey50"/) ;
    
    res_sig@gsnCenterString      = ""
    res_sig@gsnRightStringFontHeightF = subtitle_font
    res_sig@gsnLeftStringFontHeightF  = subtitle_font
    res_sig@gsnLeftString    = " "
    res_sig@gsnRightString   = " "

    res_sig2 = res_sig
    res_sig2@cnFillPattern   = 12
    
;--------set the attribute of polygon--------------
    lnres                      = True
    lnres@gsMarkerIndex     = 16          ; polymarker style
    lnres@gsMarkerSizeF     = 5.          ; polymarker size
    lnres@gsMarkerColor     = "green"

;------------------------------------------------------------------
;draw the subgraph and change the left and right titles
   ; res@tiMainFontColor      = "black"
    res@gsnCenterString      = "siglvl: " + siglvl2
    res@gsnRightStringFontHeightF = subtitle_font
    res@gsnLeftStringFontHeightF  = subtitle_font
    res@gsnLeftString    = lefttitle
    res@gsnRightString   = unit 

    resp  = True    
    resp@gsnMaximize   = True
    resp@gsnPaperOrientation = "landscape" ;"portrait"
    ;resp@gsnPanelLabelBar = True
    ;resp@pmLabelBarWidthF  = 0.5
    ;resp@pmLabelBarHeightF = 0.05
    ;resp@lbLabelFontHeightF = tick_font
    ;resp@lbLabelFontThicknessF = tick_thick
    resp@txFontHeightF = title_font 
    resp@txFontThicknessF = title_thick

do nl = 0,nlev-1,1
    plot(nl)   = gsn_csm_contour_map_ce(wks,var(:,:),res)
    ;plot2(nl)  = gsn_csm_contour(wks,prob1(:,:),res_sig)
    plot3(nl)  = gsn_csm_contour(wks,prob2(:,:),res_sig2)
    ;overlay(plot(nl),plot2(nl))
    overlay(plot(nl),plot3(nl))
    mark(nl)   = gsn_add_polymarker( wks, plot(nl), mlon, mlat, lnres )
    print(max(var({lats:latn},{lonl:lonr})))
    print(min(var({lats:latn},{lonl:lonr})))
end do 
    
    resp@txString      = fig_title 
    gsn_panel(wks,plot,(/1,1/),resp)
end

