# planet.pbf-->Country.o5m --> feature.osm --> feature.geojson --> feature.shp

# planet.pbf: osmupdate 
# planet.pbf--> Country.o5m : osmconvert
# Country.o5m --> feature.osm: osmfilter
# feature.o5m --> feature.json: zOsm2GeoJSON
# feature.json --> feature.shp: ogr2ogr 

define generate_file
	echo $< $@ 
	tools\osmfilter.exe 01_countries\$< $(2) -o=02_Interim_osm\$@.osm
	if not exist "99_Output\$(1)" md 99_Output\$(1)
	zOsm2GeoJSON\zOsm2GeoJSON.py 02_Interim_osm\$@.osm 99_Output\$(1)\$@.json --action=$(3) $(2)
	c:\OSGeo4W\bin\ogr2ogr.exe -skipfailures 99_output\$(1)\$@.shp 99_output\$(1)\$@.json	
	echo $@
endef


full_build: tza_tran_rds_ln_s4_osm_pp_roads \
            tza_tran_rds_ln_s4_osm_pp_mainroads \
            tza_tran_rrd_ln_s4_osm_pp_railways \
            tza_tran_rrd_ln_s4_osm_pp_subwaytram \
            tza_phys_dam_pt_s4_osm_pp_dam \
            tza_educ_edu_pt_s4_osm_pp_school \
            tza_educ_uni_pt_s4_osm_pp_university\
            tza_tran_fte_pt_s4_osm_pp_ferry_terminal \
            tza_tran_fer_ln_s4_osm_pp_ferry_route \
            tza_tran_por_pt_s4_osm_pp_port \
            tza_cash_bnk_pt_s4_osm_pp_banks \
            tza_cash_atm_pt_s4_osm_pp_atm \
            tza_heal_hea_pt_s4_osm_pp_health_facilities \
            tza_heal_hos_pt_s4_osm_pp_hospitals \
            tza_cash_mkt_pt_s4_osm_pp_marketplace \
            tza_pois_rel_pt_s4_osm_pp_place_of_worship \
            tza_cccm_ref_pt_s4_osm_pp_refugee_site \
            tza_pois_bor_pt_s4_osm_pp_border_control \
            tza_stle_stl_pt_s4_osm_pp_settlements \
            tza_stle_stl_pt_s4_osm_pp_townscities \
            tza_tran_brg_pt_s4_osm_pp_bridges \
            tza_util_ppl_ln_s4_osm_pp_pipeline \
            tza_util_pwl_ln_s4_osm_pp_powerline \
            tza_util_pst_pt_s4_osm_pp_powerstation \
            tza_util_pst_pt_s4_osm_pp_substation \
            tza_util_mil_py_s4_osm_pp_militaryinstallation \
            tza_phys_lak_py_s4_osm_pp_natural_water \
			tza_phys_riv_ln_s4_osm_pp_rivers \
            tza_tran_can_ln_s4_osm_pp_canals \
            tza_tran_rst_pt_s4_osm_pp_railway_station \
            tza_shel_eaa_s4_osm_pp_emergency \
            tza_wash_wts_s4_osm_pp_water_source \
            tza_wash_toi_pt_s4_osm_pp_toilets\
			tza_elev_cst_ln_s4_osm_pp_coastline \
			tza_tran_air_pt_s4_osm_pp_airports \
            tza_admn_ad0_py_s4_osm_pp_adminboundary0 \
            tza_admn_ad1_py_s4_osm_pp_adminboundary1 \
            tza_admn_ad2_py_s4_osm_pp_adminboundary2 \
            tza_admn_ad3_py_s4_osm_pp_adminboundary3 \
            tza_bldg_bdg_py_s4_osm_pp_buildings
			
	echo All targets completed OK

#reg_elev_cst_ln_s0_osm_pp_coastline.shp

#roads	
tza_tran_rds_ln_s4_osm_pp_roads: tanzania-latest.o5m
	$(call generate_file,232_tran,--keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary  =unclassified =residential =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link =lining_street =service =track =road",write_lines)

#main roads	
tza_tran_rds_ln_s4_osm_pp_mainroads: tanzania-latest.o5m
	$(call generate_file,232_tran,--keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link",write_lines)

#railroads
tza_tran_rrd_ln_s4_osm_pp_railways: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep= --keep-ways="railway=rail",write_lines)


#urban rail
tza_tran_rrd_ln_s4_osm_pp_subwaytram: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep= --keep-ways="railway=subway =tram",write_lines)


#dam
tza_phys_dam_pt_s4_osm_pp_dam: tanzania-latest.o5m
	$(call generate_file,221_phys, --keep="waterway=dam",write_poi)


#education_school
tza_educ_edu_pt_s4_osm_pp_school: tanzania-latest.o5m
	$(call generate_file,210_educ,--keep="amenity=school",write_poi)


#education_high
tza_educ_uni_pt_s4_osm_pp_university: tanzania-latest.o5m
	$(call generate_file,210_educ,--keep="amenity=college =university",write_poi)


#ferry terminal
tza_tran_fte_pt_s4_osm_pp_ferry_terminal: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep="amenity=ferry_terminal",write_poi)

#ferry route
tza_tran_fer_ln_s4_osm_pp_ferry_route: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep="route=ferry",write_lines)

#port
tza_tran_por_pt_s4_osm_pp_port: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep="( landuse=harbour =port ) or ( industrial=port ) ",write_poi)


#banks
tza_cash_bnk_pt_s4_osm_pp_banks: tanzania-latest.o5m
	$(call generate_file,208_cash, --keep="amenity=bank",write_poi)


#atm 
tza_cash_atm_pt_s4_osm_pp_atm: tanzania-latest.o5m
	$(call generate_file,208_cash, --keep="amenity=atm or ( amenity=bank and atm=yes )",write_poi)

#health_facilities
tza_heal_hea_pt_s4_osm_pp_health_facilities: tanzania-latest.o5m 
	$(call generate_file,215_heal, --keep="amenity=clinic =doctors =health_post =pharmacy =hospital",write_poi)	

#hospitals 
tza_heal_hos_pt_s4_osm_pp_hospitals: tanzania-latest.o5m 
	$(call generate_file,215_heal, --keep="amenity=hospital",write_poi)	


#market_place
tza_cash_mkt_pt_s4_osm_pp_marketplace: tanzania-latest.o5m 
	$(call generate_file,208_cash, --keep="amenity=marketplace",write_poi)	


#place_of_worship
tza_pois_rel_pt_s4_osm_pp_place_of_worship: tanzania-latest.o5m
	$(call generate_file,222_pois, --keep="amenity=place_of_worship",write_poi)


#refugee_site
tza_cccm_ref_pt_s4_osm_pp_refugee_site: tanzania-latest.o5m
	$(call generate_file,209_cccm, --keep="amenity=refugee_site",write_poi)


#border_control
tza_pois_bor_pt_s4_osm_pp_border_control: tanzania-latest.o5m
	$(call generate_file,222_pois, --keep="barrier=border_control",write_poi)

#Settlements
tza_stle_stl_pt_s4_osm_pp_settlements: tanzania-latest.o5m
	$(call generate_file,229_stle, --keep="place=city =borough =town =village =hamlet",write_poi)

#townscities
tza_stle_stl_pt_s4_osm_pp_townscities: tanzania-latest.o5m
	$(call generate_file,229_stle, --keep="place=city =town",write_poi)

#Buildings!
tza_bldg_bdg_py_s4_osm_pp_buildings: tanzania-latest.o5m
	$(call generate_file,206_bldg, --keep="building= ",write_poly)

#bridges
tza_tran_brg_pt_s4_osm_pp_bridges: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep="man_made=bridge",write_poi)

#pipeline
tza_util_ppl_ln_s4_osm_pp_pipeline: tanzania-latest.o5m
	$(call generate_file,233_util, --keep="man_made=pipeline",write_lines)

#powerline
tza_util_pwl_ln_s4_osm_pp_powerline: tanzania-latest.o5m
	$(call generate_file,233_util, --keep="power=line",write_lines)

#powerstation
tza_util_pst_pt_s4_osm_pp_powerstation: tanzania-latest.o5m
	$(call generate_file,233_util, --keep="power=plant",write_poi)

#substation
tza_util_pst_pt_s4_osm_pp_substation: tanzania-latest.o5m
	$(call generate_file,233_util, --keep="power=substation",write_poi)

#military areas
tza_util_mil_py_s4_osm_pp_militaryinstallation: tanzania-latest.o5m 
	$(call generate_file,233_util, --keep="landuse=military or military= ",write_poly)

#water bodies
tza_phys_lak_py_s4_osm_pp_natural_water: tanzania-latest.o5m 
	$(call generate_file,221_phys, --keep="natural=water",write_poly)
	
#rivers as lines 
tza_phys_riv_ln_s4_osm_pp_rivers: tanzania-latest.o5m 
	$(call generate_file,221_phys, --keep="waterway=river",write_lines)

#canals, for some reason in tran group
tza_tran_can_ln_s4_osm_pp_canals: tanzania-latest.o5m 
	$(call generate_file,232_tran, --keep="waterway=canal",write_lines)


#railway stations
tza_tran_rst_pt_s4_osm_pp_railway_station: tanzania-latest.o5m 
	$(call generate_file,232_tran, --keep="railway=station =halt ",write_poi)

#emergency 
tza_shel_eaa_s4_osm_pp_emergency: tanzania-latest.o5m 
	$(call generate_file,228_shel, --keep="emergency=assembly_point",write_poi)

#water source 
tza_wash_wts_s4_osm_pp_water_source: tanzania-latest.o5m 
	$(call generate_file,234_wash, --keep="amenity=drinking_water or drinking_water=yes ",write_poi)

#toilets
tza_wash_toi_pt_s4_osm_pp_toilets: tanzania-latest.o5m 
	$(call generate_file,234_wash, --keep="amenity=toilets",write_poi)

#admin boundaries
# should be both lines and polygons

tza_admn_ad0_py_s4_osm_pp_adminboundary0: tanzania-latest.o5m
	$(call generate_file,202_admn, --keep="( boundary=administrative ) and ( admin_level=2 )",write_poly)

tza_admn_ad1_py_s4_osm_pp_adminboundary1: tanzania-latest.o5m
	$(call generate_file,202_admn, --keep="boundary=administrative and admin_level=4",write_poly)

tza_admn_ad2_py_s4_osm_pp_adminboundary2: tanzania-latest.o5m
	$(call generate_file,202_admn, --keep="boundary=administrative and admin_level=6",write_poly)

tza_admn_ad3_py_s4_osm_pp_adminboundary3: tanzania-latest.o5m
	$(call generate_file,202_admn, --keep="( boundary=administrative ) and ( admin_level=7 or admin_level=8 or admin_level=9 or admin_level=10 )",write_poly)

#coast lines 	
tza_elev_cst_ln_s4_osm_pp_coastline: tanzania-latest.o5m
	$(call generate_file,211_elev, --keep="natural=coastline",write_lines)

#airports	
tza_tran_air_pt_s4_osm_pp_airports: tanzania-latest.o5m
	$(call generate_file,232_tran, --keep="aeroway=aerodrome",write_poi)
#==================Country ==================================================================

tanzania-latest.o5m:
	echo just assume that the county file is present
  
