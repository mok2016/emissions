;IDL
;-----------------------------------------------------------------------------
;
;
;   combine_all_sources_SO2_low_1960-2020.pro
;
;
;   This program reads emissions files for SO2 from the following
;   anthropogenic MACCity emissions sectors:
;
;    * Agricultural production, 
;    * Agricultural waste burning, 
;    * Residential and commercial combustion, 
;    * Maritime transport, 
;    * Waste treatment and disposal, 
;    * Solvent production and use, 
;    * Land transport,
;    * 50% of industrial processes and combustion.
;
;   It combines all the data into one netCDF file using one joint emissions
;   mass flux for the emitted specie.
;
;   The time coordinates are the mid-month point according to the respective
;   calendar that is used.
;
;
;-----------------------------------------------------------------------------


;------ set file paths and variable names -------------------------------------


; raw data input files:

; all files have the same dimensions in lons, lats and times, 
; however the grid coordinates need reordering in some of the input files


ukca_gws     = '/group_workspaces/jasmin2/ukca/vol1/mkoehler/'
maccity_dir  = 'emissions/ACCMIP-MACCity_anthrop_1960-2020/sectors/SO2/'

file1  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_agricultural_production_1960-2020_88516.nc'
file2  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_agricultural_waste_burning_1960-2020_87213.nc'
file3  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_residential_and_commercial_combustion_1960-2020_87003.nc'
file4  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_maritime_transport_1960-2020_88759.nc'
file5  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_waste_treatment_and_disposal_1960-2020_86596.nc'
file6  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_solvent_production_and_use_1960-2020_85907.nc'
file7  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_land_transport_1960-2020_61604.nc'
file8  = ukca_gws + maccity_dir + 'MACCity_anthro_SO2_industrial_processes_and_combustion_1960-2020_86699.nc'


; output file:

;ofn          = ukca_gws+'emissions/combined_1960-2020/combined_sources_SO2_low_1960-2020_360d.nc'
ofn          = ukca_gws+'emissions/combined_1960-2020/combined_sources_SO2_low_1960-2020_greg.nc'
gregorian    = 1  ; set to 1 for Gregorian or 0 for 360-day calendar


; parameters to calculate monthly and annual total emissions:

surf_file    =  ukca_gws+'data/surf_half_by_half_2.nc'  ; surface area
startyear    =  1960
numyears     =  61  ; 1960-2020
numdays      = [31,28,31,30,31,30,31,31,30,31,30,31]  ; no leap day
leapdays     = [31,29,31,30,31,30,31,31,30,31,30,31]  ; include leap day
secs_per_day =  86400.d


;------------------------------------------------------------------------------


;---- open emissions files:

print
print,'reading anthropogenic sector emission fluxes:'

print,'File1: Agricultural production'
ncid = ncdf_open(file1,/nowrite)
timeid = ncdf_varid(ncid,'date')
ncdf_varget,ncid,timeid,times
lonid = ncdf_varid(ncid,'lon')
ncdf_varget,ncid,lonid,lons
latid = ncdf_varid(ncid,'lat')
ncdf_varget,ncid,latid,lats
varid  = ncdf_varid(ncid,'MACCity')
ncdf_attget,ncid,varid,'units',varunits
ncdf_varget,ncid,varid,file1_flux
ncdf_close,ncid

print,'File2: Agricultural waste burning'
ncid = ncdf_open(file2,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file2_flux
ncdf_close,ncid

print,'File3: Residential and commercial combustion'
ncid = ncdf_open(file3,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file3_flux
ncdf_close,ncid

print,'File4: Maritime transport (ships)'
ncid = ncdf_open(file4,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file4_flux
ncdf_close,ncid

print,'File5: Waste treatment and disposal'
ncid = ncdf_open(file5,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file5_flux
ncdf_close,ncid

print,'File6: Solvent production and use'
ncid = ncdf_open(file6,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file6_flux
ncdf_close,ncid

print,'File7: Land transportation (road)'
ncid = ncdf_open(file7,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file7_flux
ncdf_close,ncid

print,'File8: Industrial processes and combustion'
ncid = ncdf_open(file8,/nowrite)
varid  = ncdf_varid(ncid,'MACCity')
ncdf_varget,ncid,varid,file8_flux
ncdf_close,ncid

print,'done.'
print

;---- add fluxes to combined field

print,'combining all fluxes'

allflux = dblarr(n_elements(lons),n_elements(lats),n_elements(times))

allflux = file1_flux + file2_flux + file3_flux + file4_flux + file5_flux $
        + file6_flux + file7_flux + (0.5 * file8_flux)

;File1: agriculture
;File2: agric waste
;File3: residential
;File4: ships
;File5: waste
;File6: solvents
;File7: transport
;File8: industry * 0.5

file1_flux=0b
file2_flux=0b
file3_flux=0b
file4_flux=0b
file5_flux=0b
file6_flux=0b
file7_flux=0b
file8_flux=0b

print


;---- postprocessing of field

; the latitudes in the anthropogenic MACCity emissions are N-->S
; swap latitudes to S --> N

print,'re-ordering anthrop emissions field to ascending latitudes...'

tmpfield = dblarr(n_elements(lons),n_elements(lats),n_elements(times))
tmplats  = fltarr(n_elements(lats))

for t=0,n_elements(times)-1 do begin
for k=0,n_elements(lats)-1 do begin
   k_bar = (n_elements(lats)-1)-k   ; k counting up from 0, k_bar counting down from 359
   tmpfield[*,k_bar,t] = allflux[*,k,t]
endfor
endfor

allflux = tmpfield

for k=0,n_elements(lats)-1 do begin   ; do the same for lats as reverse function not available
   k_bar = (n_elements(lats)-1)-k
   tmplats[k_bar] = lats[k]
endfor

lats = tmplats

print,'re-ordering completed.'
tmpfield = 0b   ; to reduce memory requirements
tmplats  = 0b

print

; cycle longitudes from -180-->180 to 0-->360

print,'cycling anthropogenic emissions fluxes longitudes to 0 --> 360...'

tmpfield = dblarr(n_elements(lons),n_elements(lats),n_elements(times))
tmplons  = fltarr(n_elements(lons))

for i = 0,(n_elements(lons)/2)-1 do $
   tmpfield[i,*,*] = allflux[i+(n_elements(lons)/2),*,*]

for i = (n_elements(lons)/2),n_elements(lons)-1 do $
   tmpfield[i,*,*] = allflux[i-(n_elements(lons)/2),*,*]

allflux = tmpfield

;   generate new longitudes array

for i=0,n_elements(lons)-1 do $
   tmplons[i] = 0.25 + (i*(lons[1]-lons[0]))

lons = tmplons

print,'cycling completed.'
tmpfield = 0b
tmplons  = 0b

print


;---- scale emissions for 360-day calendar

if (gregorian ne 1) then begin

  print,'scaling gregorian emission fluxes to a 360-day calendar...'
  time = 0

  for year=0,numyears-1 do begin

     leap = ( (fix((startyear+year) mod 4) eq 0 and fix((startyear+year) mod 100) ne 0) $
               or (fix((startyear+year) mod 400) eq 0) )

     for mth=0,n_elements(numdays)-1 do begin

       time = time+1
       if (leap eq 1) then month_length=leapdays[mth] else month_length=numdays[mth]
       allflux[*,*,time-1] = allflux[*,*,time-1] * ( double(month_length)/double(30) )

     endfor

  endfor

  print,'scaling completed.'
  print

endif


;---- calculate emissions totals for years

; get surface area

ncid = ncdf_open(surf_file,/nowrite)
varid  = ncdf_varid(ncid,'surf')
ncdf_varget,ncid,varid,surf
ncdf_close,ncid

print,'opening csv files to write out total emissions...'

openw, unit1, ukca_gws+'emissions/combined_1960-2020/SO2_low_monthly_combined.csv', /get_lun
openw, unit2, ukca_gws+'emissions/combined_1960-2020/SO2_low_annual_combined.csv', /get_lun

outfield = fltarr(n_elements(lons),n_elements(lats),n_elements(numdays))

time = 0

for year=0,numyears-1 do begin

  syear = strcompress(string(startyear+year),/remove_all)
  leap = ( (fix((startyear+year) mod 4) eq 0 and fix((startyear+year) mod 100) ne 0) $
            or (fix((startyear+year) mod 400) eq 0) )

  totalyear = 0.d

  for mth=0,n_elements(numdays)-1 do begin

    if ( (gregorian eq 1) and (leap eq 1) ) then month_length=leapdays[mth]
    if ( (gregorian eq 1) and (leap ne 1) ) then month_length=numdays[mth]
    if (  gregorian ne 1) then month_length=30

    time = time+1
    outfield[*,*,mth] = allflux[*,*,time-1]
    totalmonth = total(outfield[*,*,mth]*surf[*,*]*month_length*secs_per_day,/double)
    totalyear = totalyear + totalmonth

    printf, unit1, syear+'-'+strcompress(string(mth+1),/remove_all)+' , ', totalmonth

  endfor

  printf, unit2, syear, totalyear

endfor

free_lun, unit1
free_lun, unit2
print,'csv files closed.'
print


;---- write out new combined emissions file for multiple years

timeunits='days since 1960-01-01 00:00:00'

if (gregorian eq 1) then begin

   outtimes = [ 15.5, 45.5, 75.5, 106, 136.5, 167, 197.5, 228.5, 259, 289.5, 320, $
    350.5, 381.5, 411, 440.5, 471, 501.5, 532, 562.5, 593.5, 624, 654.5, 685, $
    715.5, 746.5, 776, 805.5, 836, 866.5, 897, 927.5, 958.5, 989, 1019.5, $
    1050, 1080.5, 1111.5, 1141, 1170.5, 1201, 1231.5, 1262, 1292.5, 1323.5, $
    1354, 1384.5, 1415, 1445.5, 1476.5, 1506.5, 1536.5, 1567, 1597.5, 1628, $
    1658.5, 1689.5, 1720, 1750.5, 1781, 1811.5, 1842.5, 1872, 1901.5, 1932, $
    1962.5, 1993, 2023.5, 2054.5, 2085, 2115.5, 2146, 2176.5, 2207.5, 2237, $
    2266.5, 2297, 2327.5, 2358, 2388.5, 2419.5, 2450, 2480.5, 2511, 2541.5, $
    2572.5, 2602, 2631.5, 2662, 2692.5, 2723, 2753.5, 2784.5, 2815, 2845.5, $
    2876, 2906.5, 2937.5, 2967.5, 2997.5, 3028, 3058.5, 3089, 3119.5, 3150.5, $
    3181, 3211.5, 3242, 3272.5, 3303.5, 3333, 3362.5, 3393, 3423.5, 3454, $
    3484.5, 3515.5, 3546, 3576.5, 3607, 3637.5, 3668.5, 3698, 3727.5, 3758, $
    3788.5, 3819, 3849.5, 3880.5, 3911, 3941.5, 3972, 4002.5, 4033.5, 4063, $
    4092.5, 4123, 4153.5, 4184, 4214.5, 4245.5, 4276, 4306.5, 4337, 4367.5, $
    4398.5, 4428.5, 4458.5, 4489, 4519.5, 4550, 4580.5, 4611.5, 4642, 4672.5, $
    4703, 4733.5, 4764.5, 4794, 4823.5, 4854, 4884.5, 4915, 4945.5, 4976.5, $
    5007, 5037.5, 5068, 5098.5, 5129.5, 5159, 5188.5, 5219, 5249.5, 5280, $
    5310.5, 5341.5, 5372, 5402.5, 5433, 5463.5, 5494.5, 5524, 5553.5, 5584, $
    5614.5, 5645, 5675.5, 5706.5, 5737, 5767.5, 5798, 5828.5, 5859.5, 5889.5, $
    5919.5, 5950, 5980.5, 6011, 6041.5, 6072.5, 6103, 6133.5, 6164, 6194.5, $
    6225.5, 6255, 6284.5, 6315, 6345.5, 6376, 6406.5, 6437.5, 6468, 6498.5, $
    6529, 6559.5, 6590.5, 6620, 6649.5, 6680, 6710.5, 6741, 6771.5, 6802.5, $
    6833, 6863.5, 6894, 6924.5, 6955.5, 6985, 7014.5, 7045, 7075.5, 7106, $
    7136.5, 7167.5, 7198, 7228.5, 7259, 7289.5, 7320.5, 7350.5, 7380.5, 7411, $
    7441.5, 7472, 7502.5, 7533.5, 7564, 7594.5, 7625, 7655.5, 7686.5, 7716, $
    7745.5, 7776, 7806.5, 7837, 7867.5, 7898.5, 7929, 7959.5, 7990, 8020.5, $
    8051.5, 8081, 8110.5, 8141, 8171.5, 8202, 8232.5, 8263.5, 8294, 8324.5, $
    8355, 8385.5, 8416.5, 8446, 8475.5, 8506, 8536.5, 8567, 8597.5, 8628.5, $
    8659, 8689.5, 8720, 8750.5, 8781.5, 8811.5, 8841.5, 8872, 8902.5, 8933, $
    8963.5, 8994.5, 9025, 9055.5, 9086, 9116.5, 9147.5, 9177, 9206.5, 9237, $
    9267.5, 9298, 9328.5, 9359.5, 9390, 9420.5, 9451, 9481.5, 9512.5, 9542, $
    9571.5, 9602, 9632.5, 9663, 9693.5, 9724.5, 9755, 9785.5, 9816, 9846.5, $
    9877.5, 9907, 9936.5, 9967, 9997.5, 10028, 10058.5, 10089.5, 10120, $
    10150.5, 10181, 10211.5, 10242.5, 10272.5, 10302.5, 10333, 10363.5, $
    10394, 10424.5, 10455.5, 10486, 10516.5, 10547, 10577.5, 10608.5, 10638, $
    10667.5, 10698, 10728.5, 10759, 10789.5, 10820.5, 10851, 10881.5, 10912, $
    10942.5, 10973.5, 11003, 11032.5, 11063, 11093.5, 11124, 11154.5, $
    11185.5, 11216, 11246.5, 11277, 11307.5, 11338.5, 11368, 11397.5, 11428, $
    11458.5, 11489, 11519.5, 11550.5, 11581, 11611.5, 11642, 11672.5, $
    11703.5, 11733.5, 11763.5, 11794, 11824.5, 11855, 11885.5, 11916.5, $
    11947, 11977.5, 12008, 12038.5, 12069.5, 12099, 12128.5, 12159, 12189.5, $
    12220, 12250.5, 12281.5, 12312, 12342.5, 12373, 12403.5, 12434.5, 12464, $
    12493.5, 12524, 12554.5, 12585, 12615.5, 12646.5, 12677, 12707.5, 12738, $
    12768.5, 12799.5, 12829, 12858.5, 12889, 12919.5, 12950, 12980.5, $
    13011.5, 13042, 13072.5, 13103, 13133.5, 13164.5, 13194.5, 13224.5, $
    13255, 13285.5, 13316, 13346.5, 13377.5, 13408, 13438.5, 13469, 13499.5, $
    13530.5, 13560, 13589.5, 13620, 13650.5, 13681, 13711.5, 13742.5, 13773, $
    13803.5, 13834, 13864.5, 13895.5, 13925, 13954.5, 13985, 14015.5, 14046, $
    14076.5, 14107.5, 14138, 14168.5, 14199, 14229.5, 14260.5, 14290, $
    14319.5, 14350, 14380.5, 14411, 14441.5, 14472.5, 14503, 14533.5, 14564, $
    14594.5, 14625.5, 14655.5, 14685.5, 14716, 14746.5, 14777, 14807.5, $
    14838.5, 14869, 14899.5, 14930, 14960.5, 14991.5, 15021, 15050.5, 15081, $
    15111.5, 15142, 15172.5, 15203.5, 15234, 15264.5, 15295, 15325.5, $
    15356.5, 15386, 15415.5, 15446, 15476.5, 15507, 15537.5, 15568.5, 15599, $
    15629.5, 15660, 15690.5, 15721.5, 15751, 15780.5, 15811, 15841.5, 15872, $
    15902.5, 15933.5, 15964, 15994.5, 16025, 16055.5, 16086.5, 16116.5, $
    16146.5, 16177, 16207.5, 16238, 16268.5, 16299.5, 16330, 16360.5, 16391, $
    16421.5, 16452.5, 16482, 16511.5, 16542, 16572.5, 16603, 16633.5, $
    16664.5, 16695, 16725.5, 16756, 16786.5, 16817.5, 16847, 16876.5, 16907, $
    16937.5, 16968, 16998.5, 17029.5, 17060, 17090.5, 17121, 17151.5, $
    17182.5, 17212, 17241.5, 17272, 17302.5, 17333, 17363.5, 17394.5, 17425, $
    17455.5, 17486, 17516.5, 17547.5, 17577.5, 17607.5, 17638, 17668.5, $
    17699, 17729.5, 17760.5, 17791, 17821.5, 17852, 17882.5, 17913.5, 17943, $
    17972.5, 18003, 18033.5, 18064, 18094.5, 18125.5, 18156, 18186.5, 18217, $
    18247.5, 18278.5, 18308, 18337.5, 18368, 18398.5, 18429, 18459.5, $
    18490.5, 18521, 18551.5, 18582, 18612.5, 18643.5, 18673, 18702.5, 18733, $
    18763.5, 18794, 18824.5, 18855.5, 18886, 18916.5, 18947, 18977.5, $
    19008.5, 19038.5, 19068.5, 19099, 19129.5, 19160, 19190.5, 19221.5, $
    19252, 19282.5, 19313, 19343.5, 19374.5, 19404, 19433.5, 19464, 19494.5, $
    19525, 19555.5, 19586.5, 19617, 19647.5, 19678, 19708.5, 19739.5, 19769, $
    19798.5, 19829, 19859.5, 19890, 19920.5, 19951.5, 19982, 20012.5, 20043, $
    20073.5, 20104.5, 20134, 20163.5, 20194, 20224.5, 20255, 20285.5, $
    20316.5, 20347, 20377.5, 20408, 20438.5, 20469.5, 20499.5, 20529.5, $
    20560, 20590.5, 20621, 20651.5, 20682.5, 20713, 20743.5, 20774, 20804.5, $
    20835.5, 20865, 20894.5, 20925, 20955.5, 20986, 21016.5, 21047.5, 21078, $
    21108.5, 21139, 21169.5, 21200.5, 21230, 21259.5, 21290, 21320.5, 21351, $
    21381.5, 21412.5, 21443, 21473.5, 21504, 21534.5, 21565.5, 21595, $
    21624.5, 21655, 21685.5, 21716, 21746.5, 21777.5, 21808, 21838.5, 21869, $
    21899.5, 21930.5, 21960.5, 21990.5, 22021, 22051.5, 22082, 22112.5, $
    22143.5, 22174, 22204.5, 22235, 22265.5 ]

endif else begin

  outtimes = (findgen(n_elements(times))*30.)+15.

endelse

print,'creating netcdf file: ',ofn
ncid=ncdf_create(ofn,/clobber)

timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
londim_id=ncdf_dimdef(ncid,'lon',n_elements(lons))
latdim_id=ncdf_dimdef(ncid,'lat',n_elements(lats))

timevar_id=ncdf_vardef(ncid,'time',timedim_id,/float)
ncdf_attput,ncid,timevar_id,'units',timeunits
if (gregorian eq 1) then ncdf_attput,ncid,timevar_id,'calendar','gregorian' $
 else ncdf_attput,ncid,timevar_id,'calendar','360_day'
lonvar_id=ncdf_vardef(ncid,'lon',londim_id,/float)
ncdf_attput,ncid,lonvar_id,'name','longitude'
ncdf_attput,ncid,lonvar_id,'units','degrees_east'
latvar_id=ncdf_vardef(ncid,'lat',latdim_id,/float)
ncdf_attput,ncid,latvar_id,'name','latitude'
ncdf_attput,ncid,latvar_id,'units','degrees_north'

fieldvar_id=ncdf_vardef(ncid,'emiss_flux',[londim_id,latdim_id,timedim_id],/double)
ncdf_attput,ncid,fieldvar_id,'units','kg m-2 s-1'
ncdf_attput,ncid,fieldvar_id,'long_name','Surface SO2 emissions'
ncdf_attput,ncid,fieldvar_id,'molecular_weight',64.07,/float
ncdf_attput,ncid,fieldvar_id,'molecular_weight_units','g mol-1'

ncdf_attput,ncid,/global,'history','combine_all_sources_SO2_low_1960-2020.pro'
ncdf_attput,ncid,/global,'file_creation_date',systime(/utc)+' UTC'
ncdf_attput,ncid,/global,'description','Time-varying monthly surface emissions of sulfur dioxide from 1960 to 2020.'
ncdf_attput,ncid,/global,'source','MACCity provides anthropogenic emissions from 1960 to 2020. The emissions flux in this file comprises lumped SO2 emissions from the following anthropogenic sectors: (1) Agricultural production, (2) agricultural waste burning, (3) residential and commercial combustion, (4) maritime transport, (5) waste treatment and disposal, (6) solvent production and use, (7) land transport, and (8) 50% of industrial processes and combustion.'
ncdf_attput,ncid,/global,'grid','regular 0.5x0.5 degree latitude-longitude grid'
ncdf_attput,ncid,/global,'earth_ellipse','Earth spheric model'
ncdf_attput,ncid,/global,'earth_radius',6371229.d
ncdf_attput,ncid,/global,'global_total_emissions_2000','37.474 Tg SO2 per year'

ncdf_control,ncid,/endef

ncdf_varput,ncid,timevar_id,outtimes
ncdf_varput,ncid,lonvar_id,lons
ncdf_varput,ncid,latvar_id,lats
ncdf_varput,ncid,fieldvar_id,allflux

ncdf_close,ncid

print,'netCDF file closed.'


END
