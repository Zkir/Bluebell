# planet.pbf-->Country.o5m --> feature.osm --> feature.geojson --> feature.shp

# planet.pbf: osmupdate 
# planet.pbf--> Country.o5m : osmconvert
# Country.o5m --> feature.osm: osmfilter
# feature.o5m --> feature.json: zOsm2GeoJSON
# feature.json --> feature.shp: ogr2ogr 


vpath %.pbf data\in\mapaction\per_country_pbf data\in\planet.osm
vpath %.o5m data\in\mapaction\per_country_pbf data\in\planet.osm
vpath % data\vtargets  

geoextent = tza

#=================================================================================================
# Definitions of operations
#=================================================================================================
# Generate dataset (json+shp) from OSM file
define generate_dataset_from_osm
	status.py target "$@" "started" "$<"
	if not exist "data\out\mapaction\datasets\$(geoextent)\$(1)" md data\out\mapaction\datasets\$(geoextent)\$(1)
	if not exist "data\mid\interim_osm" md "data\mid\interim_osm"
	if not exist "data\out\mapaction\zipped" md "data\out\mapaction\zipped"
        if not exist "data\vtargets" md "data\vtargets"
	tools\osmfilter.exe data\in\mapaction\per_country_pbf\$(geoextent).o5m $(2) -o=data\mid\interim_osm\$@.osm
	zOsm2GeoJSON\zOsm2GeoJSON.py data\mid\interim_osm\$@.osm data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json --action=$(3) $(2)
	ogr2ogr.exe  -lco ENCODING=UTF8 -skipfailures data\out\mapaction\datasets\$(geoextent)\$(1)\$@.shp data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json
        tools\zip_json.bat data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json data\out\mapaction\zipped\$@.json.zip
        tools\zip_shp.bat  data\out\mapaction\datasets\$(geoextent)\$(1)\$@      data\out\mapaction\zipped\$@.shp.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\zipped\$@.json.zip s3://mekillot-backet/datasets/$@.json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\zipped\$@.shp.zip  s3://mekillot-backet/datasets/$@.shp.zip
	tools\update_ckan.bat data\out\mapaction\datasets\$(geoextent)\$(1)\$@.CKAN.json
	status.py target "$@" "completed"
        touch data\vtargets\$(@F)   
	echo $@ completed
endef

# Generate dataset (json+shp) from SHP file, + clipping
define generate_dataset_from_shp
	status.py target "$@" "started" "$<"
	if not exist "data\out\mapaction\datasets\$(geoextent)\$(1)" md data\out\mapaction\datasets\$(geoextent)\$(1)
	ogr2ogr.exe -clipsrc static_data\mapaction_poly_files\$(geoextent).shp -lco ENCODING=UTF8 -skipfailures data\out\mapaction\datasets\$(geoextent)\$(1)\$@.shp $<\$(<F).shp
	ogr2ogr.exe -skipfailures data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json data\out\mapaction\datasets\$(geoextent)\$(1)\$@.shp
	tools\zip_json.bat data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json data\out\mapaction\zipped\$@.json.zip
	tools\zip_shp.bat  data\out\mapaction\datasets\$(geoextent)\$(1)\$@      data\out\mapaction\zipped\$@.shp.zip
	zOsm2GeoJSON\writeCKANjson.py "data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json"
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\zipped\$@.json.zip s3://mekillot-backet/datasets/$@.json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\zipped\$@.shp.zip  s3://mekillot-backet/datasets/$@.shp.zip
	tools\update_ckan.bat data\out\mapaction\datasets\$(geoextent)\$(1)\$@.CKAN.json
	status.py target "$@" "completed" 
        touch data\vtargets\$(@F)
endef

# Generate dataset (json+shp) from CSV file, + clipping
define generate_dataset_from_csv
	status.py target "$@" "started" "$<"
	if not exist "data\out\mapaction\datasets\$(geoextent)\$(1)" md data\out\mapaction\datasets\$(geoextent)\$(1)
	ogr2ogr.exe -s_srs EPSG:4326 -t_srs EPSG:3857 -oo X_POSSIBLE_NAMES=lon* -oo Y_POSSIBLE_NAMES=lat* -lco ENCODING=UTF8 -clipsrc static_data\mapaction_poly_files\$(geoextent).shp  -f "ESRI Shapefile" data\out\mapaction\datasets\$(geoextent)\$(1)\$@.shp $<
	ogr2ogr.exe -skipfailures data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json data\out\mapaction\datasets\$(geoextent)\$(1)\$@.shp
	zOsm2GeoJSON\writeCKANjson.py "data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json"
	tools\zip_json.bat data\out\mapaction\datasets\$(geoextent)\$(1)\$@.json data\out\mapaction\zipped\$@.json.zip
	tools\zip_shp.bat  data\out\mapaction\datasets\$(geoextent)\$(1)\$@      data\out\mapaction\zipped\$@.shp.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\zipped\$@.json.zip s3://mekillot-backet/datasets/$@.json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\zipped\$@.shp.zip  s3://mekillot-backet/datasets/$@.shp.zip
	tools\update_ckan.bat data\out\mapaction\datasets\$(geoextent)\$(1)\$@.CKAN.json
	status.py target "$@" "completed" 
        touch data\vtargets\$(@F)
endef


#=================================================================================================
# Crash move folder -- the main target
#=================================================================================================
$(geoextent)_cmf: $(geoextent)_osm_datasets $(geoextent)_non_osm_datasets
	status.py target "$@" "started" "$<"
	zOsm2GeoJSON\completness_test.py "$(geoextent)" "data\out\mapaction\datasets\$(geoextent)"
	if not exist "data\out\mapaction\cmf_zipped" md data\out\mapaction\cmf_zipped
	tools\zip_cmf_json.bat data\out\mapaction\datasets\$(geoextent) data\out\mapaction\cmf_zipped\$@_json.zip	
	tools\zip_cmf_shp.bat  data\out\mapaction\datasets\$(geoextent) data\out\mapaction\cmf_zipped\$@_shp.zip
	zOsm2GeoJSON\writeCKANjson.py "data\out\mapaction\cmf_zipped\$@"
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\cmf_zipped\$@_json.zip s3://mekillot-backet/cmfs/$@_json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp data\out\mapaction\cmf_zipped\$@_shp.zip  s3://mekillot-backet/cmfs/$@_shp.zip	
	tools\update_ckan.bat data\out\mapaction\cmf_zipped\$@.CKAN.json
	touch data\vtargets\$(@F)
	status.py target "$@" "completed" 


#=================================================================================================
# Symbolic target for OSM based datasets
#=================================================================================================
$(geoextent)_osm_datasets: \
            $(geoextent)_tran_rds_ln_s4_osm_pp_mainroads \
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
	echo OSM layers completed OK
	touch data\vtargets\$(@F)


#=================================================================================================
# Symbolic target for Non-osm datasets
#=================================================================================================
$(geoextent)_non_osm_datasets:  $(geoextent)_tran_rds_ln_s0_naturalearth_pp_roads \
                                $(geoextent)_stle_stl_pt_s0_naturalearth_pp_maincities \
                                $(geoextent)_phys_riv_ln_s0_naturalearth_pp_rivers \
                                $(geoextent)_phys_lak_py_s0_naturalearth_pp_waterbodies \
                                $(geoextent)_elev_cst_ln_s0_naturalearth_pp_coastline \
                                $(geoextent)_tran_air_pt_s0_ourairports_pp_airports \
                                $(geoextent)_tran_por_pt_s0_worldports_pp_ports \
                                $(geoextent)_util_pst_pt_s0_gppd_pp_powerplants

	echo Non-osm layers completed OK
	touch data\vtargets\$(@F)
# $(geoextent)_tran_rrd_ln_s0_wfp_pp_railways\

#=================================================================================================
# OSM based datasets
#=================================================================================================

#roads	
$(geoextent)_tran_rds_ln_s4_osm_pp_roads: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran,--keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary  =unclassified =residential =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link =lining_street =service =track =road",write_lines)

#main roads	
$(geoextent)_tran_rds_ln_s4_osm_pp_mainroads: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran,--keep= --keep-ways="highway=motorway =trunk =primary =secondary =tertiary =motorway_link =trunk_link =primary_link =secondary_link =tertiary_link",write_lines)

#railroads
$(geoextent)_tran_rrd_ln_s4_osm_pp_railways: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep= --keep-ways="railway=rail",write_lines)


#urban rail
$(geoextent)_tran_rrd_ln_s4_osm_pp_subwaytram: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep= --keep-ways="railway=subway =tram",write_lines)


#dam
$(geoextent)_phys_dam_pt_s4_osm_pp_dam: $(geoextent).o5m
	$(call generate_dataset_from_osm,221_phys, --keep="waterway=dam",write_poi)


#education_school
$(geoextent)_educ_edu_pt_s4_osm_pp_school: $(geoextent).o5m
	$(call generate_dataset_from_osm,210_educ,--keep="amenity=school",write_poi)


#education_high
$(geoextent)_educ_uni_pt_s4_osm_pp_university: $(geoextent).o5m
	$(call generate_dataset_from_osm,210_educ,--keep="amenity=college =university",write_poi)


#ferry terminal
$(geoextent)_tran_fte_pt_s4_osm_pp_ferry_terminal: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep="amenity=ferry_terminal",write_poi)

#ferry route
$(geoextent)_tran_fer_ln_s4_osm_pp_ferry_route: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep="route=ferry",write_lines)

#port
$(geoextent)_tran_por_pt_s4_osm_pp_port: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep="( landuse=harbour =port ) or ( industrial=port ) ",write_poi)


#banks
$(geoextent)_cash_bnk_pt_s4_osm_pp_banks: $(geoextent).o5m
	$(call generate_dataset_from_osm,208_cash, --keep="amenity=bank",write_poi)


#atm 
$(geoextent)_cash_atm_pt_s4_osm_pp_atm: $(geoextent).o5m
	$(call generate_dataset_from_osm,208_cash, --keep="amenity=atm or ( amenity=bank and atm=yes )",write_poi)

#health_facilities
$(geoextent)_heal_hea_pt_s4_osm_pp_health_facilities: $(geoextent).o5m 
	$(call generate_dataset_from_osm,215_heal, --keep="amenity=clinic =doctors =health_post =pharmacy =hospital",write_poi)	

#hospitals 
$(geoextent)_heal_hos_pt_s4_osm_pp_hospitals: $(geoextent).o5m 
	$(call generate_dataset_from_osm,215_heal, --keep="amenity=hospital",write_poi)	


#market_place
$(geoextent)_cash_mkt_pt_s4_osm_pp_marketplace: $(geoextent).o5m 
	$(call generate_dataset_from_osm,208_cash, --keep="amenity=marketplace",write_poi)	


#place_of_worship
$(geoextent)_pois_rel_pt_s4_osm_pp_place_of_worship: $(geoextent).o5m
	$(call generate_dataset_from_osm,222_pois, --keep="amenity=place_of_worship",write_poi)


#refugee_site
$(geoextent)_cccm_ref_pt_s4_osm_pp_refugee_site: $(geoextent).o5m
	$(call generate_dataset_from_osm,209_cccm, --keep="amenity=refugee_site",write_poi)


#border_control
$(geoextent)_pois_bor_pt_s4_osm_pp_border_control: $(geoextent).o5m
	$(call generate_dataset_from_osm,222_pois, --keep="barrier=border_control",write_poi)

#Settlements
$(geoextent)_stle_stl_pt_s4_osm_pp_settlements: $(geoextent).o5m
	$(call generate_dataset_from_osm,229_stle, --keep="place=city =borough =town =village =hamlet",write_poi)

#townscities
$(geoextent)_stle_stl_pt_s4_osm_pp_townscities: $(geoextent).o5m
	$(call generate_dataset_from_osm,229_stle, --keep="place=city =town",write_poi)

#Buildings!
$(geoextent)_bldg_bdg_py_s4_osm_pp_buildings: $(geoextent).o5m
	$(call generate_dataset_from_osm,206_bldg, --keep="building= ",write_poly)

#bridges
$(geoextent)_tran_brg_pt_s4_osm_pp_bridges: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep="man_made=bridge",write_poi)

#pipeline
$(geoextent)_util_ppl_ln_s4_osm_pp_pipeline: $(geoextent).o5m
	$(call generate_dataset_from_osm,233_util, --keep="man_made=pipeline",write_lines)

#powerline
$(geoextent)_util_pwl_ln_s4_osm_pp_powerline: $(geoextent).o5m
	$(call generate_dataset_from_osm,233_util, --keep="power=line",write_lines)

#powerstation
$(geoextent)_util_pst_pt_s4_osm_pp_powerstation: $(geoextent).o5m
	$(call generate_dataset_from_osm,233_util, --keep="power=plant",write_poi)

#substation
$(geoextent)_util_pst_pt_s4_osm_pp_substation: $(geoextent).o5m
	$(call generate_dataset_from_osm,233_util, --keep="power=substation",write_poi)

#military areas
$(geoextent)_util_mil_py_s4_osm_pp_militaryinstallation: $(geoextent).o5m 
	$(call generate_dataset_from_osm,233_util, --keep="landuse=military or military= ",write_poly)

#water bodies
$(geoextent)_phys_lak_py_s4_osm_pp_natural_water: $(geoextent).o5m 
	$(call generate_dataset_from_osm,221_phys, --keep="natural=water",write_poly)
	
#rivers as lines 
$(geoextent)_phys_riv_ln_s4_osm_pp_rivers: $(geoextent).o5m 
	$(call generate_dataset_from_osm,221_phys, --keep="waterway=river",write_lines)

#canals, for some reason in tran group
$(geoextent)_tran_can_ln_s4_osm_pp_canals: $(geoextent).o5m 
	$(call generate_dataset_from_osm,232_tran, --keep="waterway=canal",write_lines)


#railway stations
$(geoextent)_tran_rst_pt_s4_osm_pp_railway_station: $(geoextent).o5m 
	$(call generate_dataset_from_osm,232_tran, --keep="railway=station =halt ",write_poi)

#emergency 
$(geoextent)_shel_eaa_pt_s4_osm_pp_emergency: $(geoextent).o5m 
	$(call generate_dataset_from_osm,228_shel, --keep="emergency=assembly_point",write_poi)

#water source 
$(geoextent)_wash_wts_pt_s4_osm_pp_water_source: $(geoextent).o5m 
	$(call generate_dataset_from_osm,234_wash, --keep="amenity=drinking_water or drinking_water=yes ",write_poi)

#toilets
$(geoextent)_wash_toi_pt_s4_osm_pp_toilets: $(geoextent).o5m 
	$(call generate_dataset_from_osm,234_wash, --keep="amenity=toilets",write_poi)

#coast lines 	
$(geoextent)_elev_cst_ln_s4_osm_pp_coastline: $(geoextent).o5m
	$(call generate_dataset_from_osm,211_elev, --keep="natural=coastline",write_lines)

#airports	
$(geoextent)_tran_air_pt_s4_osm_pp_airports: $(geoextent).o5m
	$(call generate_dataset_from_osm,232_tran, --keep="aeroway=aerodrome",write_poi)


#admin boundaries
# should be both lines and polygons

$(geoextent)_admn_ad0_py_s4_osm_pp_adminboundary0: $(geoextent).o5m
	$(call generate_dataset_from_osm,202_admn, --keep= --keep-relations="( boundary=administrative ) and ( admin_level=2 )",write_poly)

$(geoextent)_admn_ad1_py_s4_osm_pp_adminboundary1: $(geoextent).o5m
	$(call generate_dataset_from_osm,202_admn, --keep= --keep-relations="boundary=administrative and admin_level=4",write_poly)

$(geoextent)_admn_ad2_py_s4_osm_pp_adminboundary2: $(geoextent).o5m
	$(call generate_dataset_from_osm,202_admn, --keep= --keep-relations="boundary=administrative and admin_level=5",write_poly)

$(geoextent)_admn_ad3_py_s4_osm_pp_adminboundary3: $(geoextent).o5m
	$(call generate_dataset_from_osm,202_admn, --keep= --keep-relations="( boundary=administrative ) and ( admin_level=6 or admin_level=7 or admin_level=8 or admin_level=9 or admin_level=10 )",write_poly)


#=================================================================================================
# Extraction of geoextent, update of planet
#=================================================================================================


$(geoextent).o5m: planet-latest.osm.pbf | data\in\mapaction\per_country_pbf
	osmium extract -s smart -p static_data\mapaction_poly_files\$(geoextent).poly data\in\planet.osm\planet-latest.osm.pbf -o data\in\mapaction\per_country_pbf\$(geoextent).pbf --overwrite
	osmconvert data\in\mapaction\per_country_pbf\$(geoextent).pbf -o=data\in\mapaction\per_country_pbf\$(geoextent).o5m


planet-latest.osm.pbf:
	if exist "data\in\planet.osm" del /q "data\in\planet.osm" 
	aria2c "https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf.torrent" --seed-time=0 --dir="data\in\planet.osm"
	ren "data\in\planet.osm\planet-*.osm.pbf" $@
	del /q "data\in\planet.osm\planet-*.osm.pbf.torrent"
	touch "data\in\planet.osm/$(@F)"

data\in\mapaction\per_country_pbf:
	md data\in\mapaction\per_country_pbf

#=================================================================================================
#=================================================================================================
#                  Non-osm datasets, from global data
#=================================================================================================
#=================================================================================================

#=================================================================================================
# Natural Earth
#=================================================================================================
#from ESRI SHAPE FILE
$(geoextent)_tran_rds_ln_s0_naturalearth_pp_roads: data\in\mapaction\natural_earth\ne_10m_roads
	$(call generate_dataset_from_shp,232_tran)

$(geoextent)_stle_stl_pt_s0_naturalearth_pp_maincities: data\in\mapaction\natural_earth\ne_10m_populated_places
	$(call generate_dataset_from_shp,229_stle)

$(geoextent)_phys_riv_ln_s0_naturalearth_pp_rivers: data\in\mapaction\natural_earth\ne_10m_rivers_lake_centerlines
	$(call generate_dataset_from_shp,221_phys)

$(geoextent)_phys_lak_py_s0_naturalearth_pp_waterbodies: data\in\mapaction\natural_earth\ne_10m_lakes
	$(call generate_dataset_from_shp,221_phys)

$(geoextent)_elev_cst_ln_s0_naturalearth_pp_coastline:  data\in\mapaction\natural_earth\ne_10m_coastline
	$(call generate_dataset_from_shp,211_elev)

data\in\mapaction\natural_earth\ne_10m_lakes:  data\in\mapaction\zipped\ne_10m_lakes.zip
	unzip "$<" "$@"

data\in\mapaction\natural_earth\ne_10m_rivers_lake_centerlines : data\in\mapaction\zipped\ne_10m_rivers_lake_centerlines.zip
	unzip "$<" "$@"

data\in\mapaction\natural_earth\ne_10m_coastline : data\in\mapaction\zipped\ne_10m_coastline.zip 
	unzip "$<" "$@"

data\in\mapaction\natural_earth\ne_10m_roads: data\in\mapaction\zipped\ne_10m_roads.zip
	unzip "$<" "$@"

data\in\mapaction\natural_earth\ne_10m_populated_places : data\in\mapaction\zipped\ne_10m_populated_places.zip
	unzip "$<" "$@"

data\in\mapaction\zipped\ne_10m_rivers_lake_centerlines.zip: |data\in\mapaction\zipped
	curl "https://naciscdn.org/naturalearth/10m/physical/ne_10m_rivers_lake_centerlines.zip" -o "$@"

data\in\mapaction\zipped\ne_10m_coastline.zip : |data\in\mapaction\zipped
	curl "https://naciscdn.org/naturalearth/10m/physical/ne_10m_coastline.zip" -o "$@"

data\in\mapaction\zipped\ne_10m_roads.zip: |data\in\mapaction\zipped
	curl "https://naciscdn.org/naturalearth/10m/cultural/ne_10m_roads.zip" -o "$@"

data\in\mapaction\zipped\ne_10m_populated_places.zip: |data\in\mapaction\zipped
	curl "https://naciscdn.org/naturalearth/10m/cultural/ne_10m_populated_places.zip" -o "$@"

data\in\mapaction\zipped\ne_10m_lakes.zip: |data\in\mapaction\zipped
	curl "https://naciscdn.org/naturalearth/10m/physical/ne_10m_lakes.zip" -o "$@"
#=================================================================================================
# Our Airports
#=================================================================================================
#from CSV file
$(geoextent)_tran_air_pt_s0_ourairports_pp_airports: data\in\mapaction/ourairports/airports.csv
	$(call generate_dataset_from_csv,232_tran)

data\in\mapaction/ourairports/airports.csv:
	if not exist "data\in\mapaction/ourairports" md "data\in\mapaction/ourairports/"
	curl "https://davidmegginson.github.io/ourairports-data/airports.csv" -o "$@"

#=================================================================================================
# World Ports
#=================================================================================================
#from CSV file
$(geoextent)_tran_por_pt_s0_worldports_pp_ports: data\in\mapaction/worldports/UpdatedPub150.csv
	$(call generate_dataset_from_csv,232_tran)

data\in\mapaction/worldports/UpdatedPub150.csv: 
	if not exist "data\in\mapaction/worldports" md "data\in\mapaction/worldports/"
	curl "https://msi.nga.mil/api/publications/download?type=view&key=16920959/SFH00000/UpdatedPub150.csv" -o "$@"

#=================================================================================================
# WFP Railroads
#=================================================================================================
#from ESRI SHAPE FILE
$(geoextent)_tran_rrd_ln_s0_wfp_pp_railways: data\in\mapaction/WFP/wld_trs_railways_wfp
	$(call generate_dataset_from_shp,232_tran)

data\in\mapaction/WFP/wld_trs_railways_wfp : data\in\mapaction\zipped\wld_trs_railways_wfp.zip
	unzip "$<" "$@"

data\in\mapaction\zipped\wld_trs_railways_wfp.zip: |data\in\mapaction\zipped
	curl "https://geonode.wfp.org/geoserver/wfs?format_options=charset%3AUTF-8&typename=geonode%3Awld_trs_railways_wfp&outputFormat=SHAPE-ZIP&version=1.0.0&service=WFS&request=GetFeature" -o "$@"

#=================================================================================================
# Global Power Plant Database
#=================================================================================================
#from CSV file
$(geoextent)_util_pst_pt_s0_gppd_pp_powerplants: data\in\mapaction\gppd\global_power_plant_database.csv
	$(call generate_dataset_from_csv,233_util)

data\in\mapaction\gppd\global_power_plant_database.csv: data\in\mapaction\zipped\global_power_plant_database_v_1_3.zip
	unzip "$<" "$(@D)"

data\in\mapaction\zipped\global_power_plant_database_v_1_3.zip: |data\in\mapaction\zipped
	curl "https://wri-dataportal-prod.s3.amazonaws.com/manual/global_power_plant_database_v_1_3.zip" --remote-time -o "$@"

data\in\mapaction\zipped:
	md $@