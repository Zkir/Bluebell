# planet.pbf-->Country.o5m --> feature.osm --> feature.geojson --> feature.shp

# planet.pbf: osmupdate 
# planet.pbf--> Country.o5m : osmconvert
# Country.o5m --> feature.osm: osmfilter
# feature.o5m --> feature.json: zOsm2GeoJSON
# feature.json --> feature.shp: ogr2ogr 

geoextent = blr

define generate_file
	status.py target "$@" "started" "$<"
	tools\osmfilter.exe 01_countries\$< $(2) -o=02_Interim_osm\$@.osm
	if not exist "90_Output\$(geoextent)\$(1)" md 90_Output\$(geoextent)\$(1)
	zOsm2GeoJSON\zOsm2GeoJSON.py 02_Interim_osm\$@.osm 90_Output\$(geoextent)\$(1)\$@.json --action=$(3) $(2)
	c:\OSGeo4W\bin\ogr2ogr.exe  -lco ENCODING=UTF8 -skipfailures 90_Output\$(geoextent)\$(1)\$@.shp 90_Output\$(geoextent)\$(1)\$@.json
        tools\zip_json.bat 90_Output\$(geoextent)\$(1)\$@.json 91_Output_zipped\$@.json.zip
        tools\zip_shp.bat  90_Output\$(geoextent)\$(1)\$@      91_Output_zipped\$@.shp.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.json.zip s3://mekillot-backet/datasets/$@.json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.shp.zip  s3://mekillot-backet/datasets/$@.shp.zip
	tools\update_ckan.bat 90_Output\$(geoextent)\$(1)\$@.CKAN.json
	status.py target "$@" "completed" 
	echo $@ completed
endef




$(geoextent)_cmf: $(geoextent)_country_datasets
	status.py target "$@" "started" "$<"
	tools\zip_cmf_json.bat 90_Output\$(geoextent) 92_Output_cmf_zipped\$@_json.zip	
	tools\zip_cmf_shp.bat  90_Output\$(geoextent) 92_Output_cmf_zipped\$@_shp.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 92_Output_cmf_zipped\$@_json.zip s3://mekillot-backet/cmfs/$@_json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 92_Output_cmf_zipped\$@_shp.zip  s3://mekillot-backet/cmfs/$@_shp.zip	
	tools\update_ckan.bat 92_Output_cmf_zipped\$@.CKAN.json
	status.py target "$@" "completed" 

$(geoextent)_country_datasets: $(geoextent)_tran_rds_ln_s4_osm_pp_mainroads \
            $(geoextent)_tran_rds_ln_s4_osm_pp_roads \
            $(geoextent)_tran_rrd_ln_s4_osm_pp_railways \
            $(geoextent)_tran_rrd_ln_s4_osm_pp_subwaytram \
            $(geoextent)_phys_dam_pt_s4_osm_pp_dam \
            $(geoextent)_educ_edu_pt_s4_osm_pp_school \
            $(geoextent)_educ_uni_pt_s4_osm_pp_university\
            $(geoextent)_tran_fte_pt_s4_osm_pp_ferry_terminal \
            $(geoextent)_tran_fer_ln_s4_osm_pp_ferry_route \
            $(geoextent)_tran_por_pt_s4_osm_pp_port \
            $(geoextent)_cash_bnk_pt_s4_osm_pp_banks \
            $(geoextent)_cash_atm_pt_s4_osm_pp_atm \
            $(geoextent)_heal_hea_pt_s4_osm_pp_health_facilities \
            $(geoextent)_heal_hos_pt_s4_osm_pp_hospitals \
            $(geoextent)_cash_mkt_pt_s4_osm_pp_marketplace \
            $(geoextent)_pois_rel_pt_s4_osm_pp_place_of_worship \
            $(geoextent)_cccm_ref_pt_s4_osm_pp_refugee_site \
            $(geoextent)_pois_bor_pt_s4_osm_pp_border_control \
            $(geoextent)_stle_stl_pt_s4_osm_pp_settlements \
            $(geoextent)_stle_stl_pt_s4_osm_pp_townscities \
            $(geoextent)_tran_brg_pt_s4_osm_pp_bridges \
            $(geoextent)_util_ppl_ln_s4_osm_pp_pipeline \
            $(geoextent)_util_pwl_ln_s4_osm_pp_powerline \
            $(geoextent)_util_pst_pt_s4_osm_pp_powerstation \
            $(geoextent)_util_pst_pt_s4_osm_pp_substation \
            $(geoextent)_util_mil_py_s4_osm_pp_militaryinstallation \
            $(geoextent)_phys_lak_py_s4_osm_pp_natural_water \
            $(geoextent)_phys_riv_ln_s4_osm_pp_rivers \
            $(geoextent)_tran_can_ln_s4_osm_pp_canals \
            $(geoextent)_tran_rst_pt_s4_osm_pp_railway_station \
            $(geoextent)_shel_eaa_pt_s4_osm_pp_emergency \
            $(geoextent)_wash_wts_pt_s4_osm_pp_water_source \
            $(geoextent)_wash_toi_pt_s4_osm_pp_toilets\
            $(geoextent)_elev_cst_ln_s4_osm_pp_coastline \
            $(geoextent)_tran_air_pt_s4_osm_pp_airports \
            $(geoextent)_admn_ad0_py_s4_osm_pp_adminboundary0 \
            $(geoextent)_admn_ad1_py_s4_osm_pp_adminboundary1 \
            $(geoextent)_admn_ad2_py_s4_osm_pp_adminboundary2 \
            $(geoextent)_admn_ad3_py_s4_osm_pp_adminboundary3 \

#            $(geoextent)_bldg_bdg_py_s4_osm_pp_buildings

	status.py target "$@" "started" "$<"		
	echo All layers completed OK
	status.py target "$@" "completed"


#roads	
$(geoextent)_tran_rds_ln_s4_osm_pp_roads: $(geoextent).o5m
	$(call generate_file,232_tran,--keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary  =unclassified =residential =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link =lining_street =service =track =road",write_lines)

#main roads	
$(geoextent)_tran_rds_ln_s4_osm_pp_mainroads: $(geoextent).o5m
	$(call generate_file,232_tran,--keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link",write_lines)

#railroads
$(geoextent)_tran_rrd_ln_s4_osm_pp_railways: $(geoextent).o5m
	$(call generate_file,232_tran, --keep= --keep-ways="railway=rail",write_lines)


#urban rail
$(geoextent)_tran_rrd_ln_s4_osm_pp_subwaytram: $(geoextent).o5m
	$(call generate_file,232_tran, --keep= --keep-ways="railway=subway =tram",write_lines)


#dam
$(geoextent)_phys_dam_pt_s4_osm_pp_dam: $(geoextent).o5m
	$(call generate_file,221_phys, --keep="waterway=dam",write_poi)


#education_school
$(geoextent)_educ_edu_pt_s4_osm_pp_school: $(geoextent).o5m
	$(call generate_file,210_educ,--keep="amenity=school",write_poi)


#education_high
$(geoextent)_educ_uni_pt_s4_osm_pp_university: $(geoextent).o5m
	$(call generate_file,210_educ,--keep="amenity=college =university",write_poi)


#ferry terminal
$(geoextent)_tran_fte_pt_s4_osm_pp_ferry_terminal: $(geoextent).o5m
	$(call generate_file,232_tran, --keep="amenity=ferry_terminal",write_poi)

#ferry route
$(geoextent)_tran_fer_ln_s4_osm_pp_ferry_route: $(geoextent).o5m
	$(call generate_file,232_tran, --keep="route=ferry",write_lines)

#port
$(geoextent)_tran_por_pt_s4_osm_pp_port: $(geoextent).o5m
	$(call generate_file,232_tran, --keep="( landuse=harbour =port ) or ( industrial=port ) ",write_poi)


#banks
$(geoextent)_cash_bnk_pt_s4_osm_pp_banks: $(geoextent).o5m
	$(call generate_file,208_cash, --keep="amenity=bank",write_poi)


#atm 
$(geoextent)_cash_atm_pt_s4_osm_pp_atm: $(geoextent).o5m
	$(call generate_file,208_cash, --keep="amenity=atm or ( amenity=bank and atm=yes )",write_poi)

#health_facilities
$(geoextent)_heal_hea_pt_s4_osm_pp_health_facilities: $(geoextent).o5m 
	$(call generate_file,215_heal, --keep="amenity=clinic =doctors =health_post =pharmacy =hospital",write_poi)	

#hospitals 
$(geoextent)_heal_hos_pt_s4_osm_pp_hospitals: $(geoextent).o5m 
	$(call generate_file,215_heal, --keep="amenity=hospital",write_poi)	


#market_place
$(geoextent)_cash_mkt_pt_s4_osm_pp_marketplace: $(geoextent).o5m 
	$(call generate_file,208_cash, --keep="amenity=marketplace",write_poi)	


#place_of_worship
$(geoextent)_pois_rel_pt_s4_osm_pp_place_of_worship: $(geoextent).o5m
	$(call generate_file,222_pois, --keep="amenity=place_of_worship",write_poi)


#refugee_site
$(geoextent)_cccm_ref_pt_s4_osm_pp_refugee_site: $(geoextent).o5m
	$(call generate_file,209_cccm, --keep="amenity=refugee_site",write_poi)


#border_control
$(geoextent)_pois_bor_pt_s4_osm_pp_border_control: $(geoextent).o5m
	$(call generate_file,222_pois, --keep="barrier=border_control",write_poi)

#Settlements
$(geoextent)_stle_stl_pt_s4_osm_pp_settlements: $(geoextent).o5m
	$(call generate_file,229_stle, --keep="place=city =borough =town =village =hamlet",write_poi)

#townscities
$(geoextent)_stle_stl_pt_s4_osm_pp_townscities: $(geoextent).o5m
	$(call generate_file,229_stle, --keep="place=city =town",write_poi)

#Buildings!
$(geoextent)_bldg_bdg_py_s4_osm_pp_buildings: $(geoextent).o5m
	$(call generate_file,206_bldg, --keep="building= ",write_poly)

#bridges
$(geoextent)_tran_brg_pt_s4_osm_pp_bridges: $(geoextent).o5m
	$(call generate_file,232_tran, --keep="man_made=bridge",write_poi)

#pipeline
$(geoextent)_util_ppl_ln_s4_osm_pp_pipeline: $(geoextent).o5m
	$(call generate_file,233_util, --keep="man_made=pipeline",write_lines)

#powerline
$(geoextent)_util_pwl_ln_s4_osm_pp_powerline: $(geoextent).o5m
	$(call generate_file,233_util, --keep="power=line",write_lines)

#powerstation
$(geoextent)_util_pst_pt_s4_osm_pp_powerstation: $(geoextent).o5m
	$(call generate_file,233_util, --keep="power=plant",write_poi)

#substation
$(geoextent)_util_pst_pt_s4_osm_pp_substation: $(geoextent).o5m
	$(call generate_file,233_util, --keep="power=substation",write_poi)

#military areas
$(geoextent)_util_mil_py_s4_osm_pp_militaryinstallation: $(geoextent).o5m 
	$(call generate_file,233_util, --keep="landuse=military or military= ",write_poly)

#water bodies
$(geoextent)_phys_lak_py_s4_osm_pp_natural_water: $(geoextent).o5m 
	$(call generate_file,221_phys, --keep="natural=water",write_poly)
	
#rivers as lines 
$(geoextent)_phys_riv_ln_s4_osm_pp_rivers: $(geoextent).o5m 
	$(call generate_file,221_phys, --keep="waterway=river",write_lines)

#canals, for some reason in tran group
$(geoextent)_tran_can_ln_s4_osm_pp_canals: $(geoextent).o5m 
	$(call generate_file,232_tran, --keep="waterway=canal",write_lines)


#railway stations
$(geoextent)_tran_rst_pt_s4_osm_pp_railway_station: $(geoextent).o5m 
	$(call generate_file,232_tran, --keep="railway=station =halt ",write_poi)

#emergency 
$(geoextent)_shel_eaa_pt_s4_osm_pp_emergency: $(geoextent).o5m 
	$(call generate_file,228_shel, --keep="emergency=assembly_point",write_poi)

#water source 
$(geoextent)_wash_wts_pt_s4_osm_pp_water_source: $(geoextent).o5m 
	$(call generate_file,234_wash, --keep="amenity=drinking_water or drinking_water=yes ",write_poi)

#toilets
$(geoextent)_wash_toi_pt_s4_osm_pp_toilets: $(geoextent).o5m 
	$(call generate_file,234_wash, --keep="amenity=toilets",write_poi)

#admin boundaries
# should be both lines and polygons

$(geoextent)_admn_ad0_py_s4_osm_pp_adminboundary0: $(geoextent).o5m
	$(call generate_file,202_admn, --keep="( boundary=administrative ) and ( admin_level=2 )",write_poly)

$(geoextent)_admn_ad1_py_s4_osm_pp_adminboundary1: $(geoextent).o5m
	$(call generate_file,202_admn, --keep="boundary=administrative and admin_level=4",write_poly)

$(geoextent)_admn_ad2_py_s4_osm_pp_adminboundary2: $(geoextent).o5m
	$(call generate_file,202_admn, --keep="boundary=administrative and admin_level=6",write_poly)

$(geoextent)_admn_ad3_py_s4_osm_pp_adminboundary3: $(geoextent).o5m
	$(call generate_file,202_admn, --keep="( boundary=administrative ) and ( admin_level=7 or admin_level=8 or admin_level=9 or admin_level=10 )",write_poly)

#coast lines 	
$(geoextent)_elev_cst_ln_s4_osm_pp_coastline: $(geoextent).o5m
	$(call generate_file,211_elev, --keep="natural=coastline",write_lines)

#airports	
$(geoextent)_tran_air_pt_s4_osm_pp_airports: $(geoextent).o5m
	$(call generate_file,232_tran, --keep="aeroway=aerodrome",write_poi)
#==================Country ==================================================================

$(geoextent).o5m:
	status.py target "$@" "started" "$<"
	echo assume that $@ exist
	status.py target "$@" "completed" 


$(geoextent)1.o5m:
	
ifneq ("$(wildcard 01_countries\$(geoextent).o5m)","")
	del 01_countries\$(geoextent)_old.o5m
	ren 01_countries\$(geoextent).o5m $(geoextent)_old.o5m
	osmupdate64 01_countries\$(geoextent)_old.o5m 01_countries\$(geoextent).o5m -B=poly\$(geoextent).poly -v
else
	osmconvert 00_Planet\planet-latest.osm.pbf --complete-ways --complete-multipolygons -B=poly\$(geoextent).poly -o=01_countries\$(geoextent).o5m
endif
	echo $@  completed

