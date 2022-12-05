geoextent = tza
#=================================================================================================
# Definitions
#=================================================================================================
define generate_dataset_from_country_tif
	status.py target "$@" "started" "$<"
	if not exist "90_Output\$(geoextent)\$(1)" md 90_Output\$(geoextent)\$(1)
	copy "$<" "90_Output\$(geoextent)\$(1)\$@.tif" 
	zOsm2GeoJSON\writeCKANjson.py "90_Output\$(geoextent)\$(1)\$@.tif"
	zip_json.bat 90_Output\$(geoextent)\$(1)\$@.tif 91_Output_zipped\$@.tif.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.tif.zip s3://mekillot-backet/datasets/$@.tif.zip

	status.py target "$@" "completed" 
endef
#tools\update_ckan.bat 90_Output\$(geoextent)\$(1)\$@.CKAN.json

define generate_dataset_from_country_csv
	status.py target "$@" "started" "$<"
	if not exist "90_Output\$(geoextent)\$(1)" md 90_Output\$(geoextent)\$(1)
	copy "$<" "90_Output\$(geoextent)\$(1)\$@.csv" 
	zOsm2GeoJSON\writeCKANjson.py "90_Output\$(geoextent)\$(1)\$@.csv"
	zip_json.bat 90_Output\$(geoextent)\$(1)\$@.csv 91_Output_zipped\$@.csv.zip
	aws --endpoint-url=https://storage.yandexcloud.net s3 cp 91_Output_zipped\$@.csv.zip s3://mekillot-backet/datasets/$@.csv.zip

	status.py target "$@" "completed" 
endef

#=================================================================================================
# Abstract final target
#=================================================================================================
all:  tza_popu_pop_ras_s1_worldpop_pp_PopDensity_2020UNad \
      tza_popu_pop_tab_ad0_unfpa_pp_2020 \
      tza_popu_pop_tab_ad1_unfpa_pp_2020 \
      tza_popu_pop_tab_ad2_unfpa_pp_2020 

	zOsm2GeoJSON\completness_test.py "$(geoextent)"

#=================================================================================================
# Population
#=================================================================================================

# Rasters
tza_popu_pop_ras_s1_worldpop_pp_PopDensity_2020UNad: 12_Downloads\worldpop\tza_pd_2020_1km_UNadj.tif 12_Downloads\worldpop\tza_ppp_2020_UNadj_constrained.tif
	$(call generate_dataset_from_country_tif,223_popu)

12_Downloads\worldpop\tza_pd_2020_1km_UNadj.tif: 
	if not exist "12_Downloads/worldpop" md "12_Downloads/worldpop"
	curl "https://data.worldpop.org/GIS/Population_Density/Global_2000_2020_1km_UNadj/2020/TZA/tza_pd_2020_1km_UNadj.tif" -o "$@"

12_Downloads\worldpop\tza_ppp_2020_UNadj_constrained.tif: 
	if not exist "12_Downloads/worldpop" md "12_Downloads/worldpop"
	curl "https://data.worldpop.org/GIS/Population/Global_2000_2020_Constrained/2020/maxar_v1/TZA/tza_ppp_2020_UNadj_constrained.tif" -o "$@"

# Tables

tza_popu_pop_tab_ad0_unfpa_pp_2020: 12_Downloads\unfpa\tza_admpop_adm0_2000_v2.csv 
	$(call generate_dataset_from_country_csv,223_popu)

tza_popu_pop_tab_ad1_unfpa_pp_2020: 12_Downloads\unfpa\tza_admpop_adm1_2000_v2.csv 
	$(call generate_dataset_from_country_csv,223_popu)

tza_popu_pop_tab_ad2_unfpa_pp_2020: 12_Downloads\unfpa\tza_admpop_adm2_2000_v2.csv 
	$(call generate_dataset_from_country_csv,223_popu)

12_Downloads\unfpa\tza_admpop_adm0_2000_v2.csv: 
	if not exist "12_Downloads/unfpa" md "12_Downloads/unfpa"
	curl "https://data.humdata.org/dataset/fcd33248-774d-4be2-aa16-86b10519330e/resource/25c200e3-e28a-4cf6-a2c9-9e59b571fb27/download/tza_admpop_adm0_2000_v2.csv" -o "$@"

12_Downloads\unfpa\tza_admpop_adm1_2000_v2.csv: 
	if not exist "12_Downloads/unfpa" md "12_Downloads/unfpa"
	curl "https://data.humdata.org/dataset/fcd33248-774d-4be2-aa16-86b10519330e/resource/89dd7ca4-4b73-4725-8ac8-0e0ef78d4fbd/download/tza_admpop_adm1_2000_v2.csv" -o "$@"

12_Downloads\unfpa\tza_admpop_adm2_2000_v2.csv: 
	if not exist "12_Downloads/unfpa" md "12_Downloads/unfpa"
	curl "https://data.humdata.org/dataset/fcd33248-774d-4be2-aa16-86b10519330e/resource/8af542c3-9f80-4f5c-9362-d5954d7824ec/download/tza_admpop_adm2_2000_v2.csv" -o "$@"





