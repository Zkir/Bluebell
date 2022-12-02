geoextent = tza

define generate_dataset_from_shp
	status.py target "$@" "started" "$<"
	if not exist "90_Output\$(geoextent)\$(1)" md 90_Output\$(geoextent)\$(1)
	c:\OSGeo4W\bin\ogr2ogr.exe -clipsrc poly\$(geoextent).shp -lco ENCODING=UTF8 -skipfailures 90_Output\$(geoextent)\$(1)\$@.shp $<\$(<F).shp
	c:\OSGeo4W\bin\ogr2ogr.exe -skipfailures 90_Output\$(geoextent)\$(1)\$@.json 90_Output\$(geoextent)\$(1)\$@.shp
	tools\zip_json.bat 90_Output\$(geoextent)\$(1)\$@.json 91_Output_zipped\$@.json.zip
	tools\zip_shp.bat  90_Output\$(geoextent)\$(1)\$@      91_Output_zipped\$@.shp.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.json.zip s3://mekillot-backet/datasets/$@.json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.shp.zip  s3://mekillot-backet/datasets/$@.shp.zip
	tools\update_ckan.bat 90_Output\$(geoextent)\$(1)\$@.CKAN.json
	status.py target "$@" "completed" 
endef


#	c:\OSGeo4W\bin\ogr2ogr.exe -s_srs EPSG:4326 -t_srs EPSG:3857 -oo X_POSSIBLE_NAMES=longitude_deg -oo Y_POSSIBLE_NAMES=latitude_deg -lco ENCODING=UTF8 -clipsrc poly\$(geoextent).shp  -f "ESRI Shapefile" 90_Output\$(geoextent)\$(1)\$@.shp $<

define generate_dataset_from_csv
	status.py target "$@" "started" "$<"
	if not exist "90_Output\$(geoextent)\$(1)" md 90_Output\$(geoextent)\$(1)
	c:\OSGeo4W\bin\ogr2ogr.exe -s_srs EPSG:4326 -t_srs EPSG:3857 -oo X_POSSIBLE_NAMES=lon* -oo Y_POSSIBLE_NAMES=lat* -lco ENCODING=UTF8 -clipsrc poly\$(geoextent).shp  -f "ESRI Shapefile" 90_Output\$(geoextent)\$(1)\$@.shp $<
	c:\OSGeo4W\bin\ogr2ogr.exe -skipfailures 90_Output\$(geoextent)\$(1)\$@.json 90_Output\$(geoextent)\$(1)\$@.shp
	tools\zip_json.bat 90_Output\$(geoextent)\$(1)\$@.json 91_Output_zipped\$@.json.zip
	tools\zip_shp.bat  90_Output\$(geoextent)\$(1)\$@      91_Output_zipped\$@.shp.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.json.zip s3://mekillot-backet/datasets/$@.json.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.shp.zip  s3://mekillot-backet/datasets/$@.shp.zip
	tools\update_ckan.bat 90_Output\$(geoextent)\$(1)\$@.CKAN.json
	status.py target "$@" "completed" 
endef

all:  tza_tran_rds_ln_s0_naturalearth_pp_roads \
      tza_stle_stl_pt_s0_naturalearth_pp_maincities \
      tza_phys_riv_ln_s0_naturalearth_pp_rivers \
      tza_phys_lak_py_s0_naturalearth_pp_waterbodies \
      tza_elev_cst_ln_s0_naturalearth_pp_coastline \
      tza_tran_air_pt_s0_ourairports_pp \
      tza_tran_por_pt_s0_worldports_pp \
      tza_tran_rrd_ln_s0_wfp_pp_railways\
      tza_util_pst_pt_s0_gppd_pp_powerplants

#=================================================================================================
# Natural Earth
#=================================================================================================
#from ESRI SHAPE FILE
tza_tran_rds_ln_s0_naturalearth_pp_roads: 12_Downloads/natural_earth/ne_10m_roads
	$(call generate_dataset_from_shp,232_tran)

tza_stle_stl_pt_s0_naturalearth_pp_maincities: 12_Downloads/natural_earth/ne_10m_populated_places
	$(call generate_dataset_from_shp,229_stle)

tza_phys_riv_ln_s0_naturalearth_pp_rivers: 12_Downloads/natural_earth/ne_10m_rivers_lake_centerlines
	$(call generate_dataset_from_shp,221_phys)

tza_phys_lak_py_s0_naturalearth_pp_waterbodies: 12_Downloads/natural_earth/ne_10m_lakes
	$(call generate_dataset_from_shp,221_phys)

tza_elev_cst_ln_s0_naturalearth_pp_coastline:  12_Downloads/natural_earth/ne_10m_coastline
	$(call generate_dataset_from_shp,211_elev)

12_Downloads/natural_earth/ne_10m_lakes:  11_Downloads_zip/ne_10m_lakes.zip
	unzip "$<" "$@"

12_Downloads/natural_earth/ne_10m_rivers_lake_centerlines : 11_Downloads_zip/ne_10m_rivers_lake_centerlines.zip
	unzip "$<" "$@"

12_Downloads/natural_earth/ne_10m_coastline : 11_Downloads_zip/ne_10m_coastline.zip 
	unzip "$<" "$@"

12_Downloads/natural_earth/ne_10m_roads: 11_Downloads_zip/ne_10m_roads.zip
	unzip "$<" "$@"

12_Downloads/natural_earth/ne_10m_populated_places : 11_Downloads_zip/ne_10m_populated_places.zip
	unzip "$<" "$@"

#=================================================================================================
# Our Airports
#=================================================================================================
#from CSV file
tza_tran_air_pt_s0_ourairports_pp: 12_Downloads/ourairports/airports.csv
	$(call generate_dataset_from_csv,232_tran)

#=================================================================================================
# World Ports
#=================================================================================================
#from CSV file
tza_tran_por_pt_s0_worldports_pp: 12_Downloads/worldports/UpdatedPub150.csv
	$(call generate_dataset_from_csv,232_tran)

#=================================================================================================
# WFP Railroads
#=================================================================================================
#from ESRI SHAPE FILE
tza_tran_rrd_ln_s0_wfp_pp_railways: 12_Downloads/WFP/wld_trs_railways_wfp
	$(call generate_dataset_from_shp,232_tran)

12_Downloads/WFP/wld_trs_railways_wfp : 11_Downloads_zip/wld_trs_railways_wfp.zip
	unzip "$<" "$@"

#=================================================================================================
# Global Power Plant Database
#=================================================================================================
#from CSV file
tza_util_pst_pt_s0_gppd_pp_powerplants: 12_Downloads/gppd/global_power_plant_database.csv
	$(call generate_dataset_from_csv,233_util)

12_Downloads/gppd/global_power_plant_database.csv: 11_Downloads_zip/global_power_plant_database_v_1_3.zip
	unzip "$<" "$(@D)"